#!/usr/bin/env swift
// Velvet UI CLI — copy one component into your app, no package dependency needed.
//
//   swift scripts/velvet.swift <command>      (or download this file alone: swift velvet.swift <command>)
//
// Foundation only. https://github.com/MatiasPC/velvet-ui · MIT License
//
// Testing knob: VELVET_REGISTRY=<path-or-url> makes the CLI read that registry.json
// instead of the checkout's / GitHub's. Component files are still read from the checkout
// when there is one, otherwise downloaded from GitHub.

import Foundation
import CryptoKit

let usage = """
Velvet UI CLI

USAGE
  swift velvet.swift <command> [options]

COMMANDS
  list                          List components and examples, grouped by category
  info <name>                   Summary, files, dependency closure, docs, platforms
  add <name>... [options]       Copy components (plus core and dependencies) into your app
  verify [--only <name>]        Maintainers: typecheck every entry (macOS Swift 5/6, iOS) + registry checks
  llms [--check]                Maintainers: generate llms.txt and llms-full.txt (--check: fail if stale)

ADD OPTIONS
  --dest <dir>      Destination folder (default ./VelvetUI)
  --ref <git-ref>   Branch, tag or commit to download from (default main; pin a tag or commit SHA)
  --force           Overwrite files you modified locally
  --dry-run         Show what would happen, write nothing

NAMES
  Case-insensitive, with or without the DS prefix (stepper = DSStepper), or any public
  symbol (DSSearchBar finds DSTextField). `core` adds only the shared foundation.

ENVIRONMENT
  VELVET_REGISTRY   Path or URL of a registry.json to use instead of the default (testing)
"""

// MARK: - Errors

enum VelvetError: Error, CustomStringConvertible {
    case usage(String)
    case unknown(name: String, suggestions: [String])
    case unknownDependency(entry: String, dependency: String)
    case cycle([String])
    case io(String)
    case network(String)
    case needsCheckout(String)
    case failed(String)

    var description: String {
        switch self {
        case .usage(let m), .io(let m), .network(let m), .failed(let m): return m
        case .unknown(let name, let suggestions):
            let hint = suggestions.isEmpty ? "Run `list` to see everything." : "Did you mean: \(suggestions.joined(separator: ", "))?"
            return "No component named '\(name)'. \(hint)"
        case .unknownDependency(let entry, let dep): return "\(entry) depends on '\(dep)', which is not in the registry."
        case .cycle(let path): return "Dependency cycle: \(path.joined(separator: " -> "))"
        case .needsCheckout(let cmd): return "`\(cmd)` is for maintainers and must run from a velvet-ui checkout (scripts/velvet.swift)."
        }
    }
}

// MARK: - Registry model

struct Registry: Decodable {
    struct Package: Decodable { let url: String; let product: String; let module: String; let from: String }
    struct Core: Decodable { let summary: String; let files: [String] }
    struct Entry: Decodable {
        let name: String, category: String, summary: String
        let symbols: [String], files: [String], dependencies: [String]
        let docs: String, stage: String?

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = try c.decode(String.self, forKey: .name)
            category = try c.decode(String.self, forKey: .category)
            summary = try c.decode(String.self, forKey: .summary)
            symbols = try c.decodeIfPresent([String].self, forKey: .symbols) ?? []
            files = try c.decode([String].self, forKey: .files)
            dependencies = try c.decodeIfPresent([String].self, forKey: .dependencies) ?? []
            docs = try c.decode(String.self, forKey: .docs)
            stage = try c.decodeIfPresent(String.self, forKey: .stage)
        }
        private enum CodingKeys: String, CodingKey { case name, category, summary, symbols, files, dependencies, docs, stage }
    }

    let name: String, summary: String, repository: String, raw: String
    let package: Package
    let platforms: [String: String]
    let core: Core
    let components: [Entry]
    let examples: [Entry]?

    var allEntries: [Entry] { components + (examples ?? []) }
    func isExample(_ e: Entry) -> Bool { (examples ?? []).contains { $0.name == e.name } }
}

// MARK: - Small helpers

final class Box<T>: @unchecked Sendable {
    private var value: T
    private let lock = NSLock()
    init(_ value: T) { self.value = value }
    func get() -> T { lock.lock(); defer { lock.unlock() }; return value }
    func set(_ v: T) { lock.lock(); value = v; lock.unlock() }
    func mutate(_ f: (inout T) -> Void) { lock.lock(); f(&value); lock.unlock() }
}

func out(_ s: String = "") { print(s) }
func warn(_ s: String) { FileHandle.standardError.write(Data(("warning: " + s + "\n").utf8)) }
func pad(_ s: String, _ n: Int) -> String { s.count >= n ? s : s + String(repeating: " ", count: n - s.count) }
func unique(_ xs: [String]) -> [String] { var seen = Set<String>(); return xs.filter { seen.insert($0).inserted } }

func levenshtein(_ a: String, _ b: String) -> Int {
    let a = Array(a), b = Array(b)
    if a.isEmpty { return b.count }
    var prev = Array(0...b.count)
    for i in 1...a.count {
        var cur = [i] + Array(repeating: 0, count: b.count)
        for j in 1...max(b.count, 1) where !b.isEmpty {
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
        }
        prev = cur
    }
    return prev[b.count]
}

func readFile(_ path: String) throws -> String {
    do { return try String(contentsOfFile: path, encoding: .utf8) }
    catch { throw VelvetError.io("Cannot read \(path): \(error.localizedDescription)") }
}

func writeFile(_ path: String, _ text: String) throws {
    let dir = (path as NSString).deletingLastPathComponent
    do {
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try text.write(toFile: path, atomically: true, encoding: .utf8)
    } catch { throw VelvetError.io("Cannot write \(path): \(error.localizedDescription)") }
}

func download(_ urlString: String) throws -> String {
    guard let url = URL(string: urlString) else { throw VelvetError.network("Bad URL: \(urlString)") }
    let box = Box<Result<(Data, Int), Error>?>(nil)
    let sem = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: URLRequest(url: url, timeoutInterval: 30)) { data, response, error in
        if let error { box.set(.failure(error)) }
        else { box.set(.success((data ?? Data(), (response as? HTTPURLResponse)?.statusCode ?? 0))) }
        sem.signal()
    }.resume()
    sem.wait()
    switch box.get() {
    case .success((let data, 200))?:
        guard let text = String(data: data, encoding: .utf8) else { throw VelvetError.network("Not UTF-8 text: \(urlString)") }
        return text
    case .success((_, 404))?: throw VelvetError.network("Not found (404): \(urlString). Check --ref and the component name.")
    case .success((_, let code))?: throw VelvetError.network("HTTP \(code) from \(urlString)")
    case .failure(let e)?: throw VelvetError.network("Download failed for \(urlString): \(e.localizedDescription). Are you online?")
    case nil: throw VelvetError.network("No response from \(urlString)")
    }
}

/// Runs a process, capturing stdout+stderr via a temp file (no pipe deadlocks).
func runProcess(_ exe: String, _ args: [String]) -> (status: Int32, output: String) {
    let log = FileManager.default.temporaryDirectory.appendingPathComponent("velvet-\(UUID().uuidString).log")
    FileManager.default.createFile(atPath: log.path, contents: nil)
    defer { try? FileManager.default.removeItem(at: log) }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: exe)
    p.arguments = args
    if let h = try? FileHandle(forWritingTo: log) { p.standardOutput = h; p.standardError = h }
    do { try p.run() } catch { return (127, "cannot run \(exe): \(error.localizedDescription)") }
    p.waitUntilExit()
    return (p.terminationStatus, (try? String(contentsOf: log, encoding: .utf8)) ?? "")
}

// MARK: - Options

struct Options {
    var positional: [String] = []
    var dest = "./VelvetUI"
    var ref: String? = nil
    var only: String? = nil
    var force = false, dryRun = false, check = false

    init(_ args: [String]) throws {
        var i = 0
        func value(_ flag: String) throws -> String {
            i += 1
            guard i < args.count else { throw VelvetError.usage("\(flag) needs a value.") }
            return args[i]
        }
        while i < args.count {
            switch args[i] {
            case "--dest": dest = try value("--dest")
            case "--ref": ref = try value("--ref")
            case "--only": only = try value("--only")
            case "--force": force = true
            case "--dry-run": dryRun = true
            case "--check": check = true
            case let f where f.hasPrefix("--"): throw VelvetError.usage("Unknown option \(f).\n\n\(usage)")
            case let p: positional.append(p)
            }
            i += 1
        }
    }
}

// MARK: - Source of files (checkout or GitHub)

struct Context {
    static let defaultRaw = "https://raw.githubusercontent.com/MatiasPC/velvet-ui"
    let root: String?          // velvet-ui checkout containing this script, if any
    let ref: String
    let registry: Registry

    static func load(ref: String?) throws -> Context {
        let root = findCheckout()
        let ref = root != nil ? localRef(root: root!) : (ref ?? "main")
        let data: String
        if let override = ProcessInfo.processInfo.environment["VELVET_REGISTRY"], !override.isEmpty {
            data = override.hasPrefix("http") ? try download(override) : try readFile(override)
        } else if let root {
            data = try readFile(root + "/registry.json")
        } else {
            data = try download("\(defaultRaw)/\(ref)/registry.json")
        }
        do {
            let registry = try JSONDecoder().decode(Registry.self, from: Data(data.utf8))
            return Context(root: root, ref: ref, registry: registry)
        } catch { throw VelvetError.io("registry.json is invalid: \(error)") }
    }

    var isLocal: Bool { root != nil }

    /// "local" or "local <short sha>" when files come from a checkout's working tree.
    static func localRef(root: String) -> String {
        let r = runProcess("/usr/bin/git", ["-C", root, "rev-parse", "--short", "HEAD"])
        let sha = r.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return r.status == 0 && !sha.isEmpty && !sha.contains(" ") ? "local \(sha)" : "local"
    }

    static func findCheckout() -> String? {
        let candidates = [CommandLine.arguments.first ?? "", #filePath]
        for c in candidates where c.hasSuffix(".swift") {
            let scripts = URL(fileURLWithPath: c).standardizedFileURL.deletingLastPathComponent()
            let root = scripts.deletingLastPathComponent().path
            if FileManager.default.fileExists(atPath: root + "/registry.json") && scripts.lastPathComponent == "scripts" { return root }
        }
        return nil
    }

    func requireRoot(_ command: String) throws -> String {
        guard let root else { throw VelvetError.needsCheckout(command) }
        return root
    }

    func source(of path: String) throws -> String {
        if let root { return try readFile(root + "/" + path) }
        return try download("\(registry.raw)/\(ref)/\(path)")
    }
}

// MARK: - Resolution

enum Target { case core, entry(Registry.Entry) }

struct Resolver {
    let registry: Registry

    func find(_ query: String) throws -> Target {
        let q = query.lowercased()
        if q == "core" { return .core }
        let variants = Set([q, "ds" + q, q.hasPrefix("ds") ? String(q.dropFirst(2)) : q])
        let entries = registry.allEntries
        if let e = entries.first(where: { variants.contains($0.name.lowercased()) }) { return .entry(e) }
        if let e = entries.first(where: { $0.symbols.contains { variants.contains($0.lowercased()) } }) { return .entry(e) }
        throw VelvetError.unknown(name: query, suggestions: suggestions(for: q))
    }

    private func suggestions(for q: String) -> [String] {
        let bare = q.hasPrefix("ds") ? String(q.dropFirst(2)) : q
        var scored: [(String, Int)] = []
        for e in registry.allEntries {
            let best = ([e.name] + e.symbols).map { cand -> Int in
                let c = cand.lowercased(), cb = c.hasPrefix("ds") ? String(c.dropFirst(2)) : c
                if !bare.isEmpty && (cb.contains(bare) || bare.contains(cb)) { return 0 }
                return levenshtein(bare, cb)
            }.min() ?? 99
            if best <= max(2, bare.count / 2) { scored.append((e.name, best)) }
        }
        return Array(scored.sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0 < $1.0 }.prefix(3).map { $0.0 })
    }

    /// Entries in dependency order (dependencies first), without duplicates.
    func closure(of roots: [Registry.Entry]) throws -> [Registry.Entry] {
        let byName = Dictionary(registry.allEntries.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        var done = Set<String>(), ordered: [Registry.Entry] = []
        func visit(_ e: Registry.Entry, _ stack: [String]) throws {
            if stack.contains(e.name) { throw VelvetError.cycle(stack + [e.name]) }
            if done.contains(e.name) { return }
            for dep in e.dependencies {
                guard let d = byName[dep] else { throw VelvetError.unknownDependency(entry: e.name, dependency: dep) }
                try visit(d, stack + [e.name])
            }
            done.insert(e.name); ordered.append(e)
        }
        for r in roots { try visit(r, []) }
        return ordered
    }

    /// Core files first, then each entry's files in closure order, deduped.
    func files(for entries: [Registry.Entry], includeCore: Bool = true) -> [String] {
        unique((includeCore ? registry.core.files : []) + entries.flatMap { $0.files })
    }
}

// MARK: - Materializing files (shared by add and verify)

struct OutputFile { let source: String; let relative: String; let contents: String; var body: String }

/// A registry path is safe when it is relative and has no `..` component.
func isSafeRegistryPath(_ p: String) -> Bool {
    !p.isEmpty && !p.hasPrefix("/") && !p.hasPrefix("~") && !p.components(separatedBy: "/").contains("..")
}

func sha16(_ text: String) -> String {
    SHA256.hash(data: Data(text.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
}

struct Installer {
    let ctx: Context
    static let license = "// https://github.com/MatiasPC/velvet-ui · MIT License"
    static let importLine = "import VelvetUI"
    static let importReplacement = "// import VelvetUI — not needed: Velvet sources are compiled into this target"
    static let hashMarker = " · sha256:"
    static let previewKeepPath = "Sources/VelvetUI/Preview/DSPreviewSupport.swift"

    func relativeDestination(_ path: String) -> String {
        let prefix = "Sources/VelvetUI/"
        return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : "Examples/" + (path as NSString).lastPathComponent
    }

    func docsURL(for path: String) -> String {
        let reg = ctx.registry
        if let e = reg.components.first(where: { $0.files.contains(path) }) { return "\(reg.repository)/blob/main/\(e.docs)" }
        return "\(reg.repository)#readme"
    }

    /// Cuts the trailing `// MARK: - Preview` section (previews use other components, which a copy may lack).
    func stripPreviews(_ body: String, path: String) -> String {
        guard path.hasPrefix("Sources/VelvetUI/"), path != Installer.previewKeepPath else { return body }
        let lines = body.components(separatedBy: "\n")
        guard let idx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "// MARK: - Preview" && $0.hasPrefix("// MARK: - Preview") })
        else { return body }
        let note = "// Previews aren't copied (they use other components). See \(docsURL(for: path))"
        return (Array(lines[..<idx]) + [note, ""]).joined(separator: "\n")
    }

    func header(_ path: String, body: String) -> String {
        "// Velvet UI \(ctx.ref) — \(path)\(Installer.hashMarker)\(sha16(body))\n" + Installer.license + "\n"
    }

    func prepare(_ path: String) throws -> OutputFile {
        guard isSafeRegistryPath(path) else { throw VelvetError.failed("Unsafe path in registry: \(path) (absolute paths and '..' are not allowed).") }
        let raw = try ctx.source(of: path).components(separatedBy: "\n")
            .map { $0 == Installer.importLine ? Installer.importReplacement : $0 }.joined(separator: "\n")
        let body = stripPreviews(raw, path: path)
        return OutputFile(source: path, relative: relativeDestination(path), contents: header(path, body: body) + body, body: body)
    }

    /// For a file previously written by this tool: its body and the hash recorded in its header (nil for old headers).
    static func parseWritten(_ text: String) -> (body: String, hash: String?)? {
        let lines = text.components(separatedBy: "\n")
        guard lines.count >= 2, lines[0].hasPrefix("// Velvet UI "), lines[1] == license else { return nil }
        var hash: String? = nil
        if let r = lines[0].range(of: hashMarker, options: .backwards) {
            let h = String(lines[0][r.upperBound...])
            if h.count == 16, h.allSatisfy({ $0.isHexDigit }) { hash = h }
        }
        return (lines.dropFirst(2).joined(separator: "\n"), hash)
    }
}

// MARK: - Commands: list / info

func printEntries(_ title: String, _ entries: [Registry.Entry]) {
    guard !entries.isEmpty else { return }
    out("\n\(title.uppercased())")
    let width = (entries.map { $0.name.count }.max() ?? 0) + 2
    for e in entries { out("  \(pad(e.name, width))\(e.summary)") }
}

func commandList(_ ctx: Context) {
    out("\(ctx.registry.name) — \(ctx.registry.components.count) components. Add one with: swift velvet.swift add <name>")
    for category in unique(ctx.registry.components.map { $0.category }) {
        printEntries(category, ctx.registry.components.filter { $0.category == category })
    }
    printEntries("examples", ctx.registry.examples ?? [])
    out("\n  core  \(ctx.registry.core.summary)")
}

func commandInfo(_ ctx: Context, _ opts: Options) throws {
    guard let query = opts.positional.first else { throw VelvetError.usage("Usage: info <name>") }
    let resolver = Resolver(registry: ctx.registry)
    let platforms = ctx.registry.platforms.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)+" }.joined(separator: ", ")
    switch try resolver.find(query) {
    case .core:
        out("core\n  \(ctx.registry.core.summary)\n\nFiles:")
        ctx.registry.core.files.forEach { out("  \($0)") }
    case .entry(let e):
        let closure = try resolver.closure(of: [e])
        out("\(e.name)  [\(e.category)]\n  \(e.summary)\n")
        out("Symbols:      \(e.symbols.joined(separator: ", "))")
        out("Platforms:    \(platforms)")
        out("Docs:         \(ctx.registry.repository)/blob/main/\(e.docs)")
        out("Depends on:   \(closure.dropLast().map { $0.name }.joined(separator: ", ").nonEmpty ?? "(nothing besides core)")")
        out("\nFiles (core is added once, then dependencies, then \(e.name)):")
        out("  core (\(ctx.registry.core.files.count) files)")
        resolver.files(for: closure, includeCore: false).forEach { out("  \($0)") }
    }
}

extension String { var nonEmpty: String? { isEmpty ? nil : self } }

// MARK: - Command: add

enum FileStatus: String { case added, updated, unchanged, skipped = "skipped (modified locally)", overwritten }

func looksLikePackageUser() -> Bool {
    let fm = FileManager.default
    guard let walker = fm.enumerator(atPath: fm.currentDirectoryPath) else { return false }
    while let rel = walker.nextObject() as? String {
        let name = (rel as NSString).lastPathComponent
        if walker.level > 3 || name.hasPrefix(".") || name == "node_modules" { walker.skipDescendants(); continue }
        guard name == "Package.resolved" || name.hasSuffix(".pbxproj") else { continue }
        if let text = try? String(contentsOfFile: fm.currentDirectoryPath + "/" + rel, encoding: .utf8), text.contains("velvet-ui") { return true }
    }
    return false
}

func commandAdd(_ ctx: Context, _ opts: Options) throws {
    guard !opts.positional.isEmpty else { throw VelvetError.usage("Usage: add <name>... [--dest <dir>] [--ref <git-ref>] [--force] [--dry-run]") }
    let resolver = Resolver(registry: ctx.registry)
    var roots: [Registry.Entry] = []
    for q in opts.positional { if case .entry(let e) = try resolver.find(q) { roots.append(e) } }
    let closure = try resolver.closure(of: roots)
    let paths = resolver.files(for: closure)
    let installer = Installer(ctx: ctx)
    let dest = (opts.dest as NSString).expandingTildeInPath

    if looksLikePackageUser() {
        warn("this project already depends on the VelvetUI Swift package. Mixing it with copied sources causes duplicate symbols; use one or the other.")
    }
    if ctx.isLocal, opts.ref != nil { warn("--ref ignored: copying from the local checkout at \(ctx.root ?? "")") }
    let source = ctx.root.map { _ in "local checkout (\(ctx.ref))" } ?? "\(ctx.registry.raw)/\(ctx.ref)"
    out("Adding \(roots.isEmpty ? "core" : closure.map { $0.name }.joined(separator: ", ")) from \(source)\(opts.dryRun ? " (dry run)" : "")")

    // 1. Prepare everything (download/read + transform) before touching the destination.
    var plan: [(file: OutputFile, target: String, status: FileStatus)] = []
    var seen: [String: String] = [:]
    for path in paths {
        let file = try installer.prepare(path)
        if let other = seen[file.relative] {
            throw VelvetError.failed("\(other) and \(path) would both be written to \(file.relative). Nothing was written.")
        }
        seen[file.relative] = path
        let target = try safeTarget(dest: dest, relative: file.relative)
        plan.append((file, target, try plannedStatus(file, at: target, force: opts.force)))
    }
    // 2. Write.
    var counts: [FileStatus: Int] = [:]
    for item in plan {
        if !opts.dryRun, [.added, .updated, .overwritten].contains(item.status) { try writeFile(item.target, item.file.contents) }
        counts[item.status, default: 0] += 1
        out("  \(pad(item.status.rawValue, 27)) \(item.file.relative)")
    }
    let summary = [FileStatus.added, .updated, .overwritten, .unchanged, .skipped].compactMap { s in counts[s].map { "\($0) \(s.rawValue)" } }
    out("\n\(summary.joined(separator: ", ")) -> \(opts.dest)")
    if counts[.skipped, default: 0] > 0 { out("Skipped files were edited locally (or are not Velvet files). Re-run with --force to overwrite them.") }
    printNextSteps(ctx, opts)
}

/// Resolves `<dest>/<relative>` and asserts it stays inside `dest`.
func safeTarget(dest: String, relative: String) throws -> String {
    let base = URL(fileURLWithPath: dest).standardizedFileURL.path
    let url = URL(fileURLWithPath: base + "/" + relative).standardizedFileURL
    guard url.path.hasPrefix(base + "/") else { throw VelvetError.failed("Refusing to write outside \(dest): \(relative)") }
    return url.path
}

/// Decides what installing `file` at `target` would do, without writing.
func plannedStatus(_ file: OutputFile, at target: String, force: Bool) throws -> FileStatus {
    guard FileManager.default.fileExists(atPath: target) else { return .added }
    let existing = try readFile(target)
    if let written = Installer.parseWritten(existing) {
        if let recorded = written.hash {
            if sha16(written.body) == recorded { return written.body == file.body ? .unchanged : .updated }
        } else if written.body == file.body { return .unchanged }   // old header: no hash, can only compare
    }
    return force ? .overwritten : .skipped
}

func printNextSteps(_ ctx: Context, _ opts: Options) {
    out("""

    Next steps
      1. Make sure \(opts.dest) is part of your app target (Xcode 16+ folders added to the project are synced automatically).
      2. Inject a theme once at the root of your app:  .dsTheme(DSTheme(gradient: .sunset))
      3. Docs: \(ctx.registry.repository)#readme
    """)
    if !ctx.isLocal && ctx.ref == "main" {
        out("\nTip: pin a release tag or a commit SHA with --ref for reproducible installs.")
    }
}

// MARK: - Command: verify

struct Job: Sendable { let entry: String, label: String, args: [String], dir: String }
struct JobResult: Sendable { let entry: String, label: String, ok: Bool, errors: [String] }

func structuralChecks(_ ctx: Context, root: String) -> [String] {
    let reg = ctx.registry, fm = FileManager.default
    var problems: [String] = []
    func exists(_ p: String) -> Bool { fm.fileExists(atPath: root + "/" + p) }

    let names = reg.allEntries.map { $0.name }
    for n in Set(names) where names.filter({ $0 == n }).count > 1 { problems.append("duplicate entry name: \(n)") }
    for p in reg.core.files where !isSafeRegistryPath(p) { problems.append("core: unsafe path \(p)") }
    for e in reg.allEntries { for p in e.files where !isSafeRegistryPath(p) { problems.append("\(e.name): unsafe path \(p)") } }
    for p in reg.core.files where !exists(p) { problems.append("core: missing file \(p)") }
    let resolver = Resolver(registry: reg)
    for e in reg.allEntries {
        for p in e.files where !exists(p) { problems.append("\(e.name): missing file \(p)") }
        if !exists(e.docs) { problems.append("\(e.name): missing docs \(e.docs)") }
        do { _ = try resolver.closure(of: [e]) } catch { problems.append("\(e.name): \(error)") }
    }
    let covered = Set(reg.core.files + reg.allEntries.flatMap { $0.files })
    let ignored: Set<String> = ["Sources/VelvetUI/VelvetUI.swift", "Sources/VelvetUI/Preview/ComponentCatalog.swift"]
    let sources = (fm.enumerator(atPath: root + "/Sources/VelvetUI")?.allObjects as? [String] ?? [])
        .filter { $0.hasSuffix(".swift") }.map { "Sources/VelvetUI/" + $0 }.sorted()
    for s in sources where !covered.contains(s) && !ignored.contains(s) { problems.append("uncovered source file: \(s)") }
    let pages = ((try? fm.contentsOfDirectory(atPath: root + "/docs/components")) ?? []).filter { $0.hasSuffix(".md") }.sorted()
    let referenced = Set(reg.allEntries.map { $0.docs })
    for p in pages where !referenced.contains("docs/components/" + p) { problems.append("unreferenced docs page: docs/components/\(p)") }
    return problems
}

func sdkPath(_ sdk: String) -> String {
    runProcess("/usr/bin/xcrun", ["--sdk", sdk, "--show-sdk-path"]).output.trimmingCharacters(in: .whitespacesAndNewlines)
}

func commandVerify(_ ctx: Context, _ opts: Options) throws {
    let root = try ctx.requireRoot("verify")
    let resolver = Resolver(registry: ctx.registry), installer = Installer(ctx: ctx)
    var failures = 0

    out("Registry checks")
    let problems = structuralChecks(ctx, root: root)
    problems.forEach { out("  FAIL  \($0)") }
    if problems.isEmpty { out("  ok    names, files, docs, dependencies, coverage") }
    failures += problems.count

    // Targets: "core" plus every entry, or just --only
    var targets: [(name: String, entries: [Registry.Entry])] = [("core", [])]
    targets += ctx.registry.allEntries.map { ($0.name, [$0]) }
    if let only = opts.only {
        switch try resolver.find(only) {
        case .core: targets = [("core", [])]
        case .entry(let e): targets = [(e.name, [e])]
        }
    }

    let macSDK = sdkPath("macosx"), iosSDK = sdkPath("iphonesimulator")
    let temp = FileManager.default.temporaryDirectory.appendingPathComponent("velvet-verify-\(UUID().uuidString)").path
    defer { try? FileManager.default.removeItem(atPath: temp) }
    // Every config also defines DEBUG (as Xcode's Debug configuration does): no source uses `#if !DEBUG`/`#else`, so it is a superset.
    let configs: [(label: String, args: [String])] = [
        ("macOS/Swift 5", ["-sdk", macSDK, "-target", "arm64-apple-macos15", "-swift-version", "5", "-D", "DEBUG"]),
        ("macOS/Swift 6", ["-sdk", macSDK, "-target", "arm64-apple-macos15", "-swift-version", "6", "-D", "DEBUG"]),
        ("iOS/Swift 5", ["-sdk", iosSDK, "-target", "arm64-apple-ios18.0-simulator", "-swift-version", "5", "-D", "DEBUG"]),
    ]

    var jobs: [Job] = [], buildErrors: [String: String] = [:]
    for (name, entries) in targets {
        do {
            let dir = temp + "/" + name
            let files = resolver.files(for: try resolver.closure(of: entries))
            var written: [String] = []
            for path in files {
                let f = try installer.prepare(path)
                try writeFile(dir + "/" + f.relative, f.contents)
                written.append(dir + "/" + f.relative)
            }
            for c in configs {
                jobs.append(Job(entry: name, label: c.label,
                                args: ["swiftc", "-typecheck", "-parse-as-library", "-module-name", "App"] + c.args + written, dir: dir))
            }
        } catch { buildErrors[name] = "\(error)" }
    }

    out("\nTypechecking \(targets.count) entries (\(jobs.count) compiles, 4 at a time)...")
    let results = runConcurrently(jobs, limit: 4)
    for (name, _) in targets {
        if let e = buildErrors[name] { out("  FAIL  \(pad(name, 20)) \(e)"); failures += 1; continue }
        let order = configs.map { $0.label }
        let mine = results.filter { $0.entry == name }.sorted { order.firstIndex(of: $0.label) ?? 0 < order.firstIndex(of: $1.label) ?? 0 }
        let bad = mine.filter { !$0.ok }
        out("  \(bad.isEmpty ? "ok   " : "FAIL ")  \(pad(name, 20)) \(mine.map { ($0.ok ? "ok " : "FAIL ") + $0.label }.joined(separator: " | "))")
        for b in bad { out("        [\(b.label)]"); b.errors.forEach { out("          \($0)") } }
        failures += bad.count
    }
    out("\n\(failures == 0 ? "All checks passed" : "\(failures) failure(s)") — \(targets.count) entries, \(problems.count) registry problem(s).")
    if failures > 0 { throw VelvetError.failed("verify failed") }
}

func runConcurrently(_ jobs: [Job], limit: Int) -> [JobResult] {
    let results = Box<[JobResult]>([])
    let gate = DispatchSemaphore(value: limit), group = DispatchGroup()
    for job in jobs {
        gate.wait()
        DispatchQueue.global().async(group: group) {
            let r = runProcess("/usr/bin/xcrun", job.args)
            let errors = r.output.components(separatedBy: "\n").filter { $0.contains("error:") }.prefix(6)
                .map { $0.replacingOccurrences(of: job.dir + "/", with: "") }
            results.mutate { $0.append(JobResult(entry: job.entry, label: job.label, ok: r.status == 0, errors: Array(errors))) }
            gate.signal()
        }
    }
    group.wait()
    return results.get()
}

// MARK: - Command: llms

struct LLMs {
    let ctx: Context, root: String
    var raw: String { ctx.registry.raw + "/main/" }

    var header: String {
        let r = ctx.registry
        return """
        # \(r.name)

        > \(r.summary)

        Add it with Swift Package Manager (\(r.package.url), product `\(r.package.product)`, from \(r.package.from)) and `import \(r.package.module)`, or copy a single component and the core it needs into your app with the CLI: download \(r.raw)/main/scripts/velvet.swift, then run `swift velvet.swift add <Name>`. Inject a `DSTheme` once at the root with `.dsTheme(DSTheme(gradient: .sunset))`, wrap screens in `DSScreen(backdrop: true)` for the glass look, use design tokens only (never raw colors, fonts or spacing), and read AGENTS.md first.

        """
    }

    func index() -> String {
        let r = ctx.registry
        var s = header + "\n## Start here\n\n"
        s += "- [AGENTS.md](\(raw)AGENTS.md): Read this first: rules, component chooser, tokens, copyable patterns and anti-patterns\n"
        s += "- [README.md](\(raw)README.md): Install (package or copy-in), quick start, theming and accessibility\n"
        s += "- [docs/tokens.md](\(raw)docs/tokens.md): Every design token and its value\n"
        s += "- [registry.json](\(raw)registry.json): Machine-readable registry of components, files, dependencies and docs\n"
        s += "\n## Components\n\n" + r.components.map { "- [\($0.name)](\(raw)\($0.docs)): \($0.summary)" }.joined(separator: "\n") + "\n"
        if let ex = r.examples, !ex.isEmpty {
            s += "\n## Examples\n\n" + ex.map { "- [\($0.name)](\(raw)\($0.docs)): \($0.summary)" }.joined(separator: "\n") + "\n"
        }
        s += "\n## Optional\n\n"
        s += "- [CHANGELOG.md](\(raw)CHANGELOG.md): Every user-visible change\n"
        s += "- [docs/engineering-notes.md](\(raw)docs/engineering-notes.md): Architecture decisions, gotchas and roadmap\n"
        s += "- [llms-full.txt](\(raw)llms-full.txt): This index plus the full text of every page above in one file\n"
        return s
    }

    func full(warnings: inout [String]) -> String {
        let reg = ctx.registry
        let paths = unique(["AGENTS.md", "docs/tokens.md"] + reg.components.map { $0.docs } + (reg.examples ?? []).map { $0.docs })
        var s = header
        for path in paths {
            guard let text = try? String(contentsOfFile: root + "/" + path, encoding: .utf8) else {
                warnings.append("skipping \(path): file not found"); continue
            }
            s += "\n---\n<!-- source: \(path) -->\n\n" + text.trimmingCharacters(in: .newlines) + "\n"
        }
        return s
    }
}

func commandLLMs(_ ctx: Context, _ opts: Options) throws {
    let root = try ctx.requireRoot("llms")
    let gen = LLMs(ctx: ctx, root: root)
    var warnings: [String] = []
    let files = [("llms.txt", gen.index()), ("llms-full.txt", gen.full(warnings: &warnings))]
    warnings.forEach(warn)
    var stale: [String] = []
    for (name, content) in files {
        let path = root + "/" + name
        if opts.check {
            let current = try? String(contentsOfFile: path, encoding: .utf8)
            if current != content { stale.append(describeDiff(name, current, content)) }
        } else {
            try writeFile(path, content)
            out("wrote \(name) (\(content.utf8.count) bytes)")
        }
    }
    if opts.check {
        if stale.isEmpty { out("llms.txt and llms-full.txt are up to date") }
        else { throw VelvetError.failed(stale.joined(separator: "\n") + "\nRun `swift scripts/velvet.swift llms` to regenerate.") }
    }
}

func describeDiff(_ name: String, _ current: String?, _ expected: String) -> String {
    guard let current else { return "\(name) is missing." }
    let a = current.components(separatedBy: "\n"), b = expected.components(separatedBy: "\n")
    let line = (0..<max(a.count, b.count)).first { (a.indices.contains($0) ? a[$0] : nil) != (b.indices.contains($0) ? b[$0] : nil) } ?? 0
    return "\(name) is stale (\(a.count) lines on disk vs \(b.count) expected; first difference at line \(line + 1))."
}

// MARK: - Main

func runCLI(_ args: [String]) throws {
    guard let command = args.first, command != "help", command != "--help", command != "-h" else { out(usage); return }
    let opts = try Options(Array(args.dropFirst()))
    let ctx = try Context.load(ref: opts.ref)
    switch command {
    case "list": commandList(ctx)
    case "info": try commandInfo(ctx, opts)
    case "add": try commandAdd(ctx, opts)
    case "verify": try commandVerify(ctx, opts)
    case "llms": try commandLLMs(ctx, opts)
    default: throw VelvetError.usage("Unknown command '\(command)'.\n\n\(usage)")
    }
}

do {
    try runCLI(Array(CommandLine.arguments.dropFirst()))
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
