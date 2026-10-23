import XCTest

/// Keeps `registry.json` honest: every file exists, every source file and docs page
/// is registered, and every Gallery stage name is a real `Stage` case.
final class RegistryTests: XCTestCase {

    // MARK: - Minimal model (independent of scripts/velvet.swift)

    private struct Registry: Decodable {
        struct Core: Decodable { let files: [String] }
        struct Entry: Decodable {
            let name: String
            let files: [String]
            let dependencies: [String]?
            let docs: String
            let stage: String?
        }
        let core: Core
        let components: [Entry]
        let examples: [Entry]?
        var entries: [Entry] { components + (examples ?? []) }
    }

    private static let uncheckedSources: Set<String> = [
        "Sources/VelvetUI/VelvetUI.swift",
        "Sources/VelvetUI/Preview/ComponentCatalog.swift",
    ]

    private let fm = FileManager.default

    // `Tests/VelvetUITests/RegistryTests.swift` -> repo root
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private func loadRegistry() throws -> Registry {
        let data = try Data(contentsOf: root.appendingPathComponent("registry.json"))
        return try JSONDecoder().decode(Registry.self, from: data)
    }

    private func exists(_ path: String) -> Bool { fm.fileExists(atPath: root.appendingPathComponent(path).path) }

    private func assertNone(_ problems: [String], _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(problems.isEmpty, "\(message):\n  " + problems.sorted().joined(separator: "\n  "), file: file, line: line)
    }

    // MARK: - Tests

    func testEntryNamesAreUnique() throws {
        let names = try loadRegistry().entries.map(\.name)
        let duplicates = Dictionary(grouping: names, by: { $0 }).filter { $0.value.count > 1 }.keys
        assertNone(Array(duplicates), "Duplicate registry entry names")
    }

    func testEveryFileAndDocsPathExists() throws {
        let registry = try loadRegistry()
        var missing = registry.core.files.filter { !exists($0) }.map { "core: \($0)" }
        for entry in registry.entries {
            missing += entry.files.filter { !exists($0) }.map { "\(entry.name): \($0)" }
            if !exists(entry.docs) { missing.append("\(entry.name): \(entry.docs)") }
        }
        assertNone(missing, "registry.json points at files that do not exist")
    }

    func testDependenciesResolve() throws {
        let registry = try loadRegistry()
        let names = Set(registry.entries.map(\.name))
        let unresolved = registry.entries.flatMap { entry in
            (entry.dependencies ?? []).filter { !names.contains($0) }.map { "\(entry.name) -> \($0)" }
        }
        assertNone(unresolved, "Dependencies that name no registry entry")
    }

    func testEverySourceFileIsCovered() throws {
        let registry = try loadRegistry()
        let covered = Set(registry.core.files + registry.entries.flatMap(\.files))
        let sourcesRoot = root.appendingPathComponent("Sources/VelvetUI")
        let found = (fm.enumerator(atPath: sourcesRoot.path)?.allObjects as? [String] ?? [])
            .filter { $0.hasSuffix(".swift") }
            .map { "Sources/VelvetUI/" + $0 }
        let uncovered = found.filter { !covered.contains($0) && !Self.uncheckedSources.contains($0) }
        assertNone(uncovered, "Source files in no registry entry (add them to `core` or a component's `files`)")
    }

    func testEveryComponentDocsPageIsReferenced() throws {
        let registry = try loadRegistry()
        let referenced = Set(registry.entries.map(\.docs))
        let pages = (try? fm.contentsOfDirectory(atPath: root.appendingPathComponent("docs/components").path)) ?? []
        let unreferenced = pages.filter { $0.hasSuffix(".md") }.map { "docs/components/" + $0 }.filter { !referenced.contains($0) }
        assertNone(unreferenced, "Docs pages no registry entry points at")
    }

    func testEveryStageIsAGalleryCase() throws {
        let registry = try loadRegistry()
        let stageFile = root.appendingPathComponent("Examples/VelvetGallery/VelvetGallery/Stages/Stage.swift")
        let source = try String(contentsOf: stageFile, encoding: .utf8)
        let caseLines = source.components(separatedBy: "\n").filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("case ") }
        let identifiers = Set(caseLines.flatMap { $0.split(whereSeparator: { !($0.isLetter || $0.isNumber || $0 == "_") }).map(String.init) })
        let missing = registry.entries.compactMap { entry in
            entry.stage.flatMap { identifiers.contains($0) ? nil : "\(entry.name): stage '\($0)'" }
        }
        assertNone(missing, "Stages missing from the Stage enum in Stage.swift")
    }
}
