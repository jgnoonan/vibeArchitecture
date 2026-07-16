#!/usr/bin/env bash
# Sync derived files from canonical sources in rules/, intake/, and PROJECT_PROFILE.template.md
#
# Usage:
#   ./scripts/sync.sh          # apply sync
#   ./scripts/sync.sh --check  # exit 1 if anything would change (for CI)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK=false

if [[ "${1:-}" == "--check" ]]; then
  CHECK=true
fi

RULE_FILES=(
  universal security data testing api accessibility
  reliability infrastructure observability performance
  system-design multi-agent compliance mobile
)

SKILL_DIRS=(
  "$ROOT/ClaudeSkill/vibeArchitecture"
  "$ROOT/CursorSkill/vibeArchitecture"
)

sync_file() {
  local src="$1"
  local dest="$2"

  if [[ ! -f "$src" ]]; then
    echo "Missing source: $src" >&2
    exit 1
  fi

  if $CHECK; then
    if [[ ! -f "$dest" ]] || ! diff -q "$src" "$dest" >/dev/null 2>&1; then
      echo "Out of sync: $dest (expected to match $src)"
      exit 1
    fi
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "Synced: $dest"
  fi
}

for skill_dir in "${SKILL_DIRS[@]}"; do
  for rule in "${RULE_FILES[@]}"; do
    sync_file "$ROOT/rules/${rule}.md" "$skill_dir/references/${rule}.md"
  done
  sync_file "$ROOT/intake/tier-definitions.md" "$skill_dir/assets/tier-definitions.md"
  sync_file "$ROOT/PROJECT_PROFILE.template.md" "$skill_dir/assets/project-profile-template.md"
done

# Version stamps cannot be auto-synced (BOOTSTRAP.md is a hand-maintained
# condensation), but they must not drift. Fail loudly if they disagree.
ARCHITECT_VERSION=$(grep -m1 '^\*\*Framework version:\*\*' "$ROOT/ARCHITECT.md" | sed 's/.*\*\* *//')
BOOTSTRAP_VERSION=$(grep -m1 '^\*\*Framework version:\*\*' "$ROOT/BOOTSTRAP.md" | sed 's/.*\*\* *//')

if [[ -z "$ARCHITECT_VERSION" || -z "$BOOTSTRAP_VERSION" ]]; then
  echo "Could not read framework version stamp from ARCHITECT.md or BOOTSTRAP.md" >&2
  exit 1
fi

if [[ "$ARCHITECT_VERSION" != "$BOOTSTRAP_VERSION" ]]; then
  echo "Version drift: ARCHITECT.md is $ARCHITECT_VERSION but BOOTSTRAP.md is $BOOTSTRAP_VERSION." >&2
  echo "BOOTSTRAP.md is hand-maintained — update its content for the new release, then bump its version stamp." >&2
  exit 1
fi

if $CHECK; then
  echo "All derived files in sync."
else
  echo "Sync complete."
fi
