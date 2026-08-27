#!/usr/bin/env bash
# Sync derived files from their canonical sources.
#
# Canonical sources and what they generate:
#   rules/*.md                     -> {Claude,Cursor}Skill/vibe-architecture/references/*.md
#   intake/tier-definitions.md     -> {Claude,Cursor}Skill/vibe-architecture/assets/tier-definitions.md
#   PROJECT_PROFILE.template.md     -> {Claude,Cursor}Skill/vibe-architecture/assets/project-profile-template.md
#   ClaudeSkill/.../SKILL.md       -> CursorSkill/.../SKILL.md   (Claude body + Cursor install appendix)
#   integrations/AGENTS.md         -> integrations/CLAUDE.md
#                                     integrations/android-studio/AGENTS.md
#                                     integrations/cursor/vibeArchitecture.mdc  (mdc frontmatter + AGENTS body)
#
# NOTE: integrations/cursorrules is intentionally NOT generated. The legacy
# .cursorrules format does not support the `@./...` import used in AGENTS.md,
# so it carries a standalone prose instruction and is maintained by hand.
#
# Usage:
#   ./scripts/sync.sh          # apply sync
#   ./scripts/sync.sh --check  # exit 1 if anything would change (for CI)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK=false

case "${1:-}" in
  "") ;;
  --check) CHECK=true ;;
  -h|--help)
    sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "Unknown argument: $1 (expected --check or nothing)" >&2
    exit 2
    ;;
esac
if [[ $# -gt 1 ]]; then
  echo "Too many arguments: $*" >&2
  exit 2
fi

# Rule files are derived from rules/*.md (everything except the index), so a
# new rule file is picked up automatically. bash 3.2 compatible (no mapfile).
RULE_FILES=()
for f in "$ROOT"/rules/*.md; do
  base="$(basename "$f" .md)"
  [[ "$base" == "_index" ]] && continue
  RULE_FILES+=("$base")
done

SKILL_DIRS=(
  "$ROOT/ClaudeSkill/vibe-architecture"
  "$ROOT/CursorSkill/vibe-architecture"
)

FAILED=false

# Temp files are tracked so they are removed even on early exit.
TMP_FILES=()
cleanup() {
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}"
  fi
}
trap cleanup EXIT

# Compare/copy an existing source file to a destination.
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
      FAILED=true
    fi
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "Synced: $dest"
  fi
}

# Compare/write generated content (passed on stdin) to a destination.
sync_generated() {
  local dest="$1"
  local tmp
  tmp="$(mktemp)"
  TMP_FILES+=("$tmp")
  cat > "$tmp"

  if $CHECK; then
    if [[ ! -f "$dest" ]] || ! diff -q "$tmp" "$dest" >/dev/null 2>&1; then
      echo "Out of sync (generated): $dest"
      FAILED=true
    fi
  else
    mkdir -p "$(dirname "$dest")"
    cp "$tmp" "$dest"
    echo "Generated: $dest"
  fi
  rm -f "$tmp"
}

# --- 1. Rule references + assets into both skill packages ---
for skill_dir in "${SKILL_DIRS[@]}"; do
  for rule in "${RULE_FILES[@]}"; do
    sync_file "$ROOT/rules/${rule}.md" "$skill_dir/references/${rule}.md"
  done
  sync_file "$ROOT/intake/tier-definitions.md" "$skill_dir/assets/tier-definitions.md"
  sync_file "$ROOT/PROJECT_PROFILE.template.md" "$skill_dir/assets/project-profile-template.md"
done

# --- 2. Cursor SKILL.md = Claude SKILL.md + Cursor install appendix ---
CURSOR_SKILL_APPENDIX=$(cat <<'EOF'

## Installing in Cursor

This skill is the Cursor edition of vibeArchitecture. To install:

1. Copy the `CursorSkill/vibe-architecture/` folder from the repo into `~/.cursor/skills/vibe-architecture/` (personal) or `.cursor/skills/vibe-architecture/` (project-scoped)
2. Cursor discovers skills in those directories automatically; see the Cursor docs for Agent Skills if your version needs the skill enabled or imported

When the full framework is also present in a project as `vibeArchitecture/`, prefer reading `vibeArchitecture/ARCHITECT.md` and `vibeArchitecture/guides/` for deeper context beyond the compact `references/` files in this skill.
EOF
)
sync_generated "$ROOT/CursorSkill/vibe-architecture/SKILL.md" <<EOF
$(cat "$ROOT/ClaudeSkill/vibe-architecture/SKILL.md")
${CURSOR_SKILL_APPENDIX}
EOF

# --- 3. Integration entry-point files from canonical integrations/AGENTS.md ---
sync_file "$ROOT/integrations/AGENTS.md" "$ROOT/integrations/CLAUDE.md"
sync_file "$ROOT/integrations/AGENTS.md" "$ROOT/integrations/android-studio/AGENTS.md"

MDC_FRONTMATTER=$(cat <<'EOF'
---
description: vibeArchitecture architectural guardrails — intake, tier rules, and checklists
alwaysApply: true
---
EOF
)
sync_generated "$ROOT/integrations/cursor/vibeArchitecture.mdc" <<EOF
${MDC_FRONTMATTER}

$(cat "$ROOT/integrations/AGENTS.md")
EOF

# --- 4. Version-stamp consistency ---
# BOOTSTRAP.md is a hand-maintained condensation and cannot be auto-generated,
# but its version must not drift from ARCHITECT.md. Fail loudly if they disagree.
ARCHITECT_VERSION=$(grep -m1 '^\*\*Framework version:\*\*' "$ROOT/ARCHITECT.md" | sed 's/.*\*\* *//')
BOOTSTRAP_VERSION=$(grep -m1 '^\*\*Framework version:\*\*' "$ROOT/BOOTSTRAP.md" | sed 's/.*\*\* *//')

SKILL_VERSION=$(grep -m1 '^\*\*Framework version:\*\*' "$ROOT/ClaudeSkill/vibe-architecture/SKILL.md" | sed 's/.*\*\* *//')

if [[ -z "$ARCHITECT_VERSION" || -z "$BOOTSTRAP_VERSION" || -z "$SKILL_VERSION" ]]; then
  echo "Could not read framework version stamp from ARCHITECT.md, BOOTSTRAP.md, or ClaudeSkill SKILL.md" >&2
  FAILED=true
else
  if [[ "$ARCHITECT_VERSION" != "$BOOTSTRAP_VERSION" ]]; then
    echo "Version drift: ARCHITECT.md is $ARCHITECT_VERSION but BOOTSTRAP.md is $BOOTSTRAP_VERSION." >&2
    echo "BOOTSTRAP.md is hand-maintained - update its content for the new release, then bump its version stamp." >&2
    FAILED=true
  fi
  if [[ "$ARCHITECT_VERSION" != "$SKILL_VERSION" ]]; then
    echo "Version drift: ARCHITECT.md is $ARCHITECT_VERSION but ClaudeSkill/vibe-architecture/SKILL.md is $SKILL_VERSION." >&2
    echo "Bump the SKILL.md version stamp (the Cursor SKILL.md is regenerated from it)." >&2
    FAILED=true
  fi
fi

# --- 5. GPT instruction length ---
# The custom GPT's instruction field is capped at 8000 characters. Fail before
# someone pastes a truncated version into the GPT builder.
GPT_INSTRUCTIONS="$ROOT/CodeGuardian/gpt-instructions.md"
GPT_LIMIT=8000
if [[ -f "$GPT_INSTRUCTIONS" ]]; then
  GPT_CHARS=$(wc -m < "$GPT_INSTRUCTIONS" | tr -d ' ')
  if [[ "$GPT_CHARS" -gt "$GPT_LIMIT" ]]; then
    echo "CodeGuardian/gpt-instructions.md is $GPT_CHARS characters; the GPT builder limit is $GPT_LIMIT." >&2
    FAILED=true
  fi
else
  echo "Missing: $GPT_INSTRUCTIONS (skipping length check)" >&2
fi

if $CHECK; then
  if $FAILED; then
    echo "Derived files are out of sync. Run ./scripts/sync.sh to fix." >&2
    exit 1
  fi
  echo "All derived files in sync."
else
  if $FAILED; then
    echo "Sync completed with errors (see above)." >&2
    exit 1
  fi
  echo "Sync complete."
fi
