#!/usr/bin/env bash
# Sync derived files from their canonical sources.
#
# Canonical sources and what they generate:
#   rules/*.md                     -> {Claude,Cursor}Skill/vibeArchitecture/references/*.md
#   intake/tier-definitions.md     -> {Claude,Cursor}Skill/vibeArchitecture/assets/tier-definitions.md
#   PROJECT_PROFILE.template.md     -> {Claude,Cursor}Skill/vibeArchitecture/assets/project-profile-template.md
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

if [[ "${1:-}" == "--check" ]]; then
  CHECK=true
fi

RULE_FILES=(
  universal security data testing api accessibility
  reliability infrastructure observability performance
  system-design multi-agent privacy compliance mobile
)

SKILL_DIRS=(
  "$ROOT/ClaudeSkill/vibeArchitecture"
  "$ROOT/CursorSkill/vibeArchitecture"
)

FAILED=false

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

1. Copy the `CursorSkill/vibeArchitecture/` folder from the repo into `~/.cursor/skills/vibeArchitecture/` (personal) or `.cursor/skills/vibeArchitecture/` (project-scoped)
2. Alternatively, ZIP the `vibeArchitecture/` folder so the archive contains `vibeArchitecture/SKILL.md` at the top level and import via Cursor Settings > Rules > Agent Skills

When the full framework is also present in a project as `vibeArchitecture/`, prefer reading `vibeArchitecture/ARCHITECT.md` and `vibeArchitecture/guides/` for deeper context beyond the compact `references/` files in this skill.
EOF
)
sync_generated "$ROOT/CursorSkill/vibeArchitecture/SKILL.md" <<EOF
$(cat "$ROOT/ClaudeSkill/vibeArchitecture/SKILL.md")
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

if [[ -z "$ARCHITECT_VERSION" || -z "$BOOTSTRAP_VERSION" ]]; then
  echo "Could not read framework version stamp from ARCHITECT.md or BOOTSTRAP.md" >&2
  FAILED=true
elif [[ "$ARCHITECT_VERSION" != "$BOOTSTRAP_VERSION" ]]; then
  echo "Version drift: ARCHITECT.md is $ARCHITECT_VERSION but BOOTSTRAP.md is $BOOTSTRAP_VERSION." >&2
  echo "BOOTSTRAP.md is hand-maintained - update its content for the new release, then bump its version stamp." >&2
  FAILED=true
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
