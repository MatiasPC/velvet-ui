# Velvet UI curator playbook

The procedure the autonomous curator follows on every run. The scheduled task's prompt only says "read this file and follow it", so the procedure is versioned, reviewed and improved like code.

**This file, `.github/` and `scripts/pr-policy.sh` are protected.** The curator never edits them; the Policy check fails any `curator` PR that does. To change how the curator works, the curator *suggests* the change in the ledger and the maintainer makes it in a human PR.

## Mission

Make Velvet UI a little better every day without anyone babysitting it. One run produces **at most one PR**, and that PR merges itself only when every check is green. Doing nothing is a correct outcome when nothing clears the bar.

## How a PR gets into `main`

```
curator run ─▶ PR (label: curator, auto-merge on) ─▶ CI  ─┬─ green ─▶ squash-merged by GitHub
                                                          └─ red   ─▶ curator fixes it (this run or the next)
                                                                       3 failed attempts ─▶ closed, logged
```

Required checks on `main`: `macOS · swift build & test`, `iOS Simulator · xcodebuild`, `PR policy`.

- **CI** proves it compiles on macOS and iOS, every test passes (tokens, contrast, accessibility, doc snippets, registry), every component compiles standalone in Swift 5 and 6, the Gallery builds and `llms.txt` is current.
- **PR policy** (`scripts/pr-policy.sh`) proves the Definition of done: a test that references the new type, a docs page, a registry entry, a `#Preview` with dark mode, a `ComponentCatalog` section, a CHANGELOG line, no raw colors/fonts/numbers in added library lines. With the `curator` label it also enforces scope: one component max, no protected paths, no deleted sources, no removed public symbols.

Green checks prove correctness, not taste. The motion still has to feel right, so the bar in step 3 is yours to hold.

## Environment

- Linux sandbox. **SwiftUI does not compile here**, so `swift build` / `swift test` on the package will fail; CI on macOS is the compiler. Don't burn the run trying.
- A Linux Swift toolchain *can* run the repo scripts. Install it once per run if you need `llms` (Ubuntu 24.04):
  ```bash
  curl -sSLO https://download.swift.org/swift-6.1-release/ubuntu2404/swift-6.1-RELEASE/swift-6.1-RELEASE-ubuntu24.04.tar.gz
  tar xzf swift-6.1-RELEASE-ubuntu24.04.tar.gz && export PATH="$PWD/swift-6.1-RELEASE-ubuntu24.04/usr/bin:$PATH"
  swift scripts/velvet.swift llms          # regenerate llms.txt + llms-full.txt after editing registry/docs
  bash scripts/pr-policy.sh origin/main --curator   # run the policy gate locally before pushing
  ```
  If the download is refused, hand-edit `llms.txt` / `llms-full.txt` to match the generator in `scripts/velvet.swift` (`LLMs.index()` / `LLMs.full()`) exactly. CI's `llms --check` will tell you if it drifted.
- GitHub: use the REST API (`gh api repos/MatiasPC/velvet-ui/...`). GraphQL is unavailable. To turn on auto-merge in a Claude Code session use `PUT /repos/MatiasPC/velvet-ui/pulls/{n}/ccr/auto_merge` (squash); elsewhere `gh pr merge {n} --auto --squash`.
- Use whatever branch name the session lets you push (often `claude/…`). The **`curator` label** is what marks a curator PR, not the branch name.

## The run

### 0. Orient (always)

Read `AGENTS.md`, `CONTRIBUTING.md`, `docs/engineering-notes.md` (especially "How to add a component" and the gotchas), `docs/tokens.md`, `registry.json`, and the source **and** test file of the existing component closest to what you'll touch. `DSLikeButton.swift` + `Tests/VelvetUITests/DSLikeButtonTests.swift` is the reference for a complete component PR (PR #150 shows the full file set).

### 1. Housekeeping first (this outranks new work)

1. **Is `main` green?** `GET /actions/runs?branch=main&event=push&per_page=1`. If the last run failed, today's only job is a `fix:` PR that makes it green. Stop there.
2. **Open curator PRs** (`GET /pulls?state=open`, label `curator`):
   - Checks pending: leave it, and don't start new work (one curator PR in flight at a time; that's what prevents eight copies of the same idea).
   - Checks red: read the failing job's log (`GET /actions/runs/{id}/jobs`, then `GET /actions/jobs/{id}/logs`), fix on the same branch, push, and comment `curator-attempt: N`. Fix the cause, never the test: don't delete, skip, loosen or `XCTSkip` a test to get green.
   - Third failed attempt: close the PR with a short post-mortem comment and log it as `rejected: ci`.
   - Merge conflict: merge `origin/main` into the branch and push.
   - The maintainer left review comments: address them first, they're the highest-signal input you get.
   - Label `hold`: the maintainer paused it. Only act on their comments; never remove the label yourself.
3. If housekeeping produced a push, the run is done. Log it (step 6) and stop.

### 2. Remember (dedupe before you research)

Build the "already done or already refused" list from:

- `registry.json` and `Sources/VelvetUI/**` (what exists),
- **every** PR title, open and closed (`GET /pulls?state=all&per_page=100`, paginate). A PR closed without merging means the maintainer said no: never re-propose that idea under a new name (a "DSStatusMark" is a "DSSuccessCheck"),
- the **Curator ledger** issue (label `curator-ledger`): every past run's candidates and verdicts, plus the maintainer's replies.

### 3. Choose today's work

In this order, take the first that applies:

1. **Maintainer requests**: open issues labeled `curator-idea` or `component-request`. Oldest first.
2. **Bugs**: open issues labeled `bug` that touch library code.
3. **Improve something that exists**, if the last two ledger entries were new components: a missing test for real logic, an accessibility gap (VoiceOver value/traits, Reduce Motion, Reduce Transparency, 44 pt targets), a Swift 6 warning, a doc snippet that doesn't match the API. Commit as `improve:` / `fix:` / `test:`.
4. **A new component or modifier** from research.

**Research sources** for (4): Apple sample code and WWDC sessions (iOS 18 APIs), Swift with Majid, SwiftUI Lab, Sarunw, Holy Swift, Kavsoft, Point-Free, Swift by Sundell, trending SwiftUI repos on GitHub, the SwiftUI community on X. Prefer iOS 18 APIs: `PhaseAnimator`, `KeyframeAnimator`, `symbolEffect`, `scrollTransition`, `visualEffect`, `onScrollGeometryChange`, `MeshGradient`, `TextRenderer`, custom `Layout`, `matchedTransitionSource`. Write an original implementation; credit the technique, don't port code.

**The bar.** Score each candidate 1–5 and put the table in the PR:

| Criterion | Question |
|---|---|
| Reusable | Would three unrelated apps use it? |
| Polished | Does the motion and haptic feel premium, not demo-ware? |
| Unique | Not in the registry, not a renamed PR the maintainer closed, not a thin wrapper over one modifier |
| On-brand | Glass surfaces, no borders, springs, haptics: does it look like Velvet? |
| Small API | One obvious initializer, sensible defaults, ≤ ~5 parameters |
| Testable | Is there real logic (a timeline, a mapping, a state machine) a unit test can pin? |

Proceed only if **every** score is ≥ 4. Otherwise log what you evaluated and stop. That is a successful run.

### 4. Implement (one change, done completely)

For a new component, the full file set (CI and Policy enforce most of it):

- `Sources/VelvetUI/Components/DS<Name>.swift` (or `Animation/` for a pure motion modifier, `Layout/` for a `Layout`). Doc comments and `// MARK:` sections like its neighbours. `#Preview` in light and dark on `.dsBackdrop()`.
- Rules from `CONTRIBUTING.md`, non-negotiable: tokens only; colors from `@DSThemed private var theme` (never `DSColors` outside `#Preview`); overridable colors are `Color? = nil`; no borders; `DSPress` for press; `DSAnimation` springs for state changes; `DSHapticEngine` on the meaningful beat, not every frame; iOS-only API inside `#if os(iOS)`; Reduce Motion, Reduce Transparency, VoiceOver label/value/traits, Dynamic Type via `.ds(_:)`.
- Put the logic in an internal, pure type (e.g. `DSLikeButtonTimeline`) so it's testable without rendering.
- `Tests/VelvetUITests/DS<Name>Tests.swift`: unit tests for that logic (bounds, clamping, the haptic beat, Reduce Motion path), every code snippet from the docs page **verbatim** in a `DocSnippets<Name>` enum so the docs can't drift, and if you render anything, guard platform code with `#if canImport(UIKit)` / `#elseif canImport(AppKit)`.
- `docs/components/DS<Name>.md`, an entry in `docs/components.md`, a row in the README component table, a row in the `AGENTS.md` component chooser.
- `registry.json` entry (files, dependencies, docs page, stage), then regenerate `llms.txt` / `llms-full.txt`.
- `ComponentCatalog.swift` section; a VelvetGallery screen and recording stage (see `docs/RECORDING.md`; editing `project.pbxproj` by hand: copy the exact pattern an existing screen uses and keep IDs unique).
- `CHANGELOG.md` line under `[Unreleased]`; any gotcha in `docs/engineering-notes.md`.
- Adding a token is allowed when you truly need a value that doesn't exist: put it in `Tokens/` and document it in `docs/tokens.md`.

**Self-review before pushing.** Grep that every symbol you reference exists with that exact signature. Check `Sendable` / `@MainActor` (the registry verify compiles each component standalone in Swift 6 mode). Diff your file against the reference component for conventions. Run `bash scripts/pr-policy.sh origin/main --curator`.

### 5. Open the PR and see it through

- Commit subject per convention: `add: DS<Name> — <one line>`, `improve: …`, `fix: …`, `test: …`.
- Open the PR with the repo template, add the label **`curator`**, then enable **auto-merge (squash)**.
- Body: what and why (the UX problem), the scorecard, source links (attribution), public API + usage, what the tests cover, and a short **"What CI can't see"** list for the maintainer: motion feel, haptic timing on device, light/dark in the Gallery stage.
- **Watch CI in this run**: poll the PR's check runs every few minutes for up to ~30 minutes. If something fails, fix it now (counts toward the three attempts). If it's still pending when you have to stop, the next run's housekeeping picks it up.

### 6. Log (every run, including "did nothing")

Comment on the Curator ledger issue:

```
**YYYY-MM-DD** · mode: housekeeping | add | improve | fix | skip
Evaluated: <candidate> (<link>) — <score or reason>, …
Decision: <what you did and why> · PR #N
Playbook suggestion (optional): <a change to this file or the policy that would have helped today>
```

The suggestion line is how the curator improves its own process: the maintainer reads it and edits this file.

## Hard limits

- Never push to `main`, never merge by hand, never bypass or disable a check, never force-push someone else's branch.
- Never edit `.github/`, `scripts/pr-policy.sh`, `docs/curator/`, `Package.swift`, `LICENSE`.
- Never remove or rename public API, never change an existing parameter's label or position.
- Never weaken a test to get green.
- At most one PR and one component per run; never more than one curator PR open.
- Only close or delete branches of curator PRs.
