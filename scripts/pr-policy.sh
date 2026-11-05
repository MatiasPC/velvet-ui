#!/usr/bin/env bash
# PR policy gate: the parts of the Definition of Done that a compiler can't see.
#
#   scripts/pr-policy.sh <base-ref> [--curator]
#
# Runs on Linux in CI (no Swift needed) and locally. Checks only what the PR
# *adds*, so existing code is never re-litigated. `--curator` adds the stricter
# rules for PRs opened by the autonomous curator (label `curator`), which are
# auto-merged once CI is green.
#
# Escape hatch for a line that legitimately trips the token lint: end it with
#   // policy:allow <reason>
set -uo pipefail

BASE="${1:?usage: pr-policy.sh <base-ref> [--curator]}"
CURATOR=false
[[ "${2:-}" == "--curator" ]] && CURATOR=true

fail=0
err()  { echo "::error::$*"; fail=1; }
note() { echo "  · $*"; }

MERGE_BASE=$(git merge-base "$BASE" HEAD)
changed() { git diff --name-only --diff-filter="${1}" "$MERGE_BASE" HEAD; }

ADDED=$(changed A)
ALL=$(changed ACMRD)

echo "Policy check against $BASE ($(echo "$ALL" | grep -c . ) files changed, curator=$CURATOR)"

# ── 1. Every new public source file ships with tests, docs, registry, changelog ──
NEW_SOURCES=$(echo "$ADDED" | grep -E '^Sources/VelvetUI/(Components|Animation|Layout)/DS[A-Za-z0-9]+\.swift$' || true)
for src in $NEW_SOURCES; do
  name=$(basename "$src" .swift)
  echo "New source: $name"

  # Tests: a changed test file must mention the type (or the dsModifier spelling).
  lower="ds${name#DS}"   # DSStretchyHeader → dsStretchyHeader (modifier spelling)
  if ! echo "$ALL" | grep -E '^Tests/VelvetUITests/.*\.swift$' | xargs -r grep -lE "(\b$name\b|\.$lower\b|\b$lower\b)" >/dev/null 2>&1; then
    err "$name: no test in Tests/VelvetUITests/ references it. Add DS<Name>Tests.swift (logic + doc snippets verbatim)."
  else note "tests ✓"; fi

  # Docs page.
  if ! echo "$ALL" | grep -E '^docs/components/.*\.md$' | xargs -r grep -lE "($name|\.$lower)" >/dev/null 2>&1; then
    err "$name: no docs/components/*.md page documents it."
  else note "docs ✓"; fi

  # Registry.
  if ! grep -q "\"$src\"" registry.json; then
    err "$name: $src is not listed in registry.json."
  else note "registry ✓"; fi

  # #Preview with light and dark.
  if ! grep -q '#Preview' "$src"; then
    err "$name: no #Preview in $src."
  elif ! grep -qiE 'colorScheme|\.dark|preferredColorScheme|dsPreviewBothSchemes|Dark' "$src"; then
    err "$name: #Preview doesn't show dark mode."
  else note "preview ✓"; fi

  # Catalog section.
  if ! grep -qE "(\b$name\b|\.$lower\b|\b$lower\b)" Sources/VelvetUI/Preview/ComponentCatalog.swift; then
    err "$name: no section in Sources/VelvetUI/Preview/ComponentCatalog.swift."
  else note "catalog ✓"; fi
done

if [[ -n "$NEW_SOURCES" ]] && ! echo "$ALL" | grep -qx 'CHANGELOG.md'; then
  err "New component(s) without a CHANGELOG.md line under [Unreleased]."
fi

# ── 2. Token lint on added lines of library code (not Tokens/, not Preview/) ──
LINT='Color\((red|white|hue|hex|\.sRGB)|\.font\(\.system\(size: *[0-9]|Font\.system\(size: *[0-9]|\.border\(|\.padding\([^)]*\b[1-9][0-9]*(\.[0-9]+)?\)|cornerRadius: *[1-9]|spacing: *[1-9]|Color\.(red|blue|green|black|white|gray|orange|yellow|pink|purple)\b'
VIOLATIONS=$(git diff -U0 "$MERGE_BASE" HEAD -- 'Sources/VelvetUI/Components' 'Sources/VelvetUI/Animation' 'Sources/VelvetUI/Layout' \
  | awk '/^\+\+\+ /{f=substr($0,7)} /^\+[^+]/{print f": "substr($0,2)}' \
  | grep -E "$LINT" | grep -v 'policy:allow' || true)
if [[ -n "$VIOLATIONS" ]]; then
  # Lines inside #Preview blocks may use DSColors statics and literals; we can't
  # parse Swift here, so only flag files where the hit is above the first #Preview.
  while IFS= read -r v; do
    file="${v%%: *}"; line="${v#*: }"
    pv=$(grep -n '#Preview' "$file" | head -1 | cut -d: -f1)
    hit=$(grep -nF -- "$line" "$file" | head -1 | cut -d: -f1)
    if [[ -z "$pv" || -z "$hit" || "$hit" -lt "$pv" ]]; then
      err "Raw value instead of a token in $file: ${line#"${line%%[![:space:]]*}"}"
    fi
  done <<< "$VIOLATIONS"
fi

# ── 3. Curator-only rules (auto-merged PRs must stay small and in their lane) ──
if $CURATOR; then
  PROTECTED=$(echo "$ALL" | grep -E '^(\.github/|scripts/pr-policy\.sh$|docs/curator/|Package\.swift$|LICENSE$|SECURITY\.md$)' || true)
  [[ -n "$PROTECTED" ]] && err "Curator PRs can't touch protected paths (needs a human PR): $(echo $PROTECTED)"

  n_new=$(echo "$NEW_SOURCES" | grep -c . || true)
  [[ "$n_new" -gt 1 ]] && err "Curator PRs add at most one component; this one adds $n_new."

  DELETED=$(changed D | grep -E '^Sources/' || true)
  [[ -n "$DELETED" ]] && err "Curator PRs can't delete library sources: $(echo $DELETED)"

  # Removing public API breaks users; renames need a human.
  REMOVED_PUBLIC=$(git diff -U0 "$MERGE_BASE" HEAD -- Sources/VelvetUI | grep -E '^-[^-].*\bpublic\b' | grep -vE '^-\s*//' || true)
  ADDED_PUBLIC=$(git diff -U0 "$MERGE_BASE" HEAD -- Sources/VelvetUI | grep -E '^\+[^+].*\bpublic\b' || true)
  if [[ -n "$REMOVED_PUBLIC" ]]; then
    # A changed line shows up as -old/+new; only fail when a public symbol name disappears entirely.
    while IFS= read -r r; do
      sym=$(echo "$r" | grep -oE '(func|var|let|init|struct|enum|class|case|protocol|typealias)\s+[A-Za-z_][A-Za-z0-9_]*' | head -1 | awk '{print $2}')
      [[ -z "$sym" ]] && continue
      echo "$ADDED_PUBLIC" | grep -qw "$sym" || err "Curator PR removes public symbol '$sym' (breaking change → human PR)."
    done <<< "$REMOVED_PUBLIC"
  fi
fi

if [[ $fail -ne 0 ]]; then
  echo; echo "Policy check failed. See CONTRIBUTING.md → Definition of done."
  exit 1
fi
echo "Policy check passed."
