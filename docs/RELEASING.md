# Releasing

Velvet UI ships only through Swift Package Manager, so a release is an annotated git tag plus a GitHub release. SwiftPM resolves `from: "0.2.0"` against tags, and it accepts the `v` prefix (`v0.2.0`).

## Before tagging

- [ ] The release PR is merged and CI is green on `main`.
- [ ] `CHANGELOG.md`: the version's section carries the release date, `[Unreleased]` above it is empty, and the link references at the bottom point at the new tag.
- [ ] The README install snippet uses the version (`from: "0.2.0"`).
- [ ] The clips in `docs/media/` are real recordings, not placeholders (see [RECORDING.md](RECORDING.md)).

## v0.2.0

Run these from a clean checkout of `main`:

```bash
git switch main && git pull --ff-only
swift build && swift test

# 1. Tag
git tag -a v0.2.0 -m "Velvet UI 0.2.0"
git push origin v0.2.0

# 2. Release notes = the 0.2.0 section of the changelog
awk '/^## \[0\.2\.0\]/{found=1; next} /^## \[/{found=0} found' CHANGELOG.md > /tmp/velvet-ui-0.2.0-notes.md

# 3. GitHub release
gh release create v0.2.0 \
  --title "Velvet UI 0.2.0" \
  --notes-file /tmp/velvet-ui-0.2.0-notes.md \
  --verify-tag
```

## After tagging

Check that a fresh project resolves the version:

```bash
mkdir -p /tmp/velvet-check && cd /tmp/velvet-check
swift package init --type library --name VelvetCheck
# Add to Package.swift:
#   dependencies: [.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")]
#   and .product(name: "VelvetUI", package: "velvet-ui") in the target's dependencies
swift package resolve && swift build
```

## Next versions

1. Move the `[Unreleased]` entries under a new `## [x.y.z] — YYYY-MM-DD` heading and add its link reference at the bottom of the changelog.
2. Bump the version in the README install snippet and in the component pages (`grep -rl 'from: "0.2.0"' README.md docs`) if it's a minor or major bump.
3. Repeat the commands above with the new version.
