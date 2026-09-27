#!/bin/sh
# vibeArchitecture agent guard. Framework-owned.
# Called by Claude Code (PreToolUse) and Cursor (beforeShellExecution) with the
# tool call as JSON on stdin:  guard.sh claude | guard.sh cursor
#
#   deny  commands that bypass the checks: --no-verify, `git commit -n`,
#         changing core.hooksPath, VA_SKIP / SKIP / LEFTHOOK=0 / HUSKY=0
#   ask   writes to check configuration (.va/, .githooks/, scanner configs,
#         the CI check workflow, agent hook settings), and edits that add a
#         suppression or a skipped/focused test
#
# The agent can still reach these files through a person: "ask" hands the
# decision to the user. Hooks are guardrails for an honest agent; the
# required status check on the server is what actually enforces.
# POSIX sh + grep/sed only (no jq or python), so it runs anywhere git does.

mode="${1:-claude}"
input=$(cat)

json_str() { # json_str <key>: first string value for "key" (escapes kept minimal)
  printf '%s' "$input" | tr '\n' ' ' \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\\(\\([^\"\\\\]\\|\\\\.\\)*\\)\".*/\\1/p" \
    | sed 's/\\"/"/g; s/\\\\/\\/g' | head -n 1
}

decide() { # decide <deny|ask> <reason>
  case "$mode" in
    cursor)
      printf '{"permission":"%s","user_message":"vibeArchitecture: %s","agent_message":"vibeArchitecture: %s"}\n' "$1" "$2" "$2" ;;
    *)
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"vibeArchitecture: %s"}}\n' "$1" "$2" ;;
  esac
  exit 0
}

PROTECTED='(^|[^[:alnum:]_.-])(\.va/|\.githooks/|\.gitleaks\.toml|\.gitleaksignore|osv-scanner\.toml|\.semgrepignore|zizmor\.ya?ml|mise\.toml|\.github/workflows/va-checks\.ya?ml|\.claude/settings\.json|\.cursor/hooks\.json)'
BYPASS_MSG="this would bypass the project checks. Fix what the check reports; if you believe the check is wrong, stop and explain it to the user instead."

tool=$(json_str tool_name)
cmd=$(json_str command)

if [ -n "$cmd" ] && { [ "$mode" = cursor ] || [ "$tool" = "Bash" ] || [ -z "$tool" ]; }; then
  if printf '%s' "$cmd" | grep -Eq -- '--no-verify'; then decide deny "$BYPASS_MSG"; fi
  if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+commit([[:space:]]+[^;&|]*)?[[:space:]]-[a-zA-Z]*n[a-zA-Z]*([[:space:]]|$)'; then
    decide deny "git commit -n skips the pre-commit checks. $BYPASS_MSG"
  fi
  if printf '%s' "$cmd" | grep -Eq 'core\.hooksPath' && ! printf '%s' "$cmd" | grep -Eq 'core\.hooksPath[[:space:]]+\.githooks([[:space:]]|$|;|&)'; then
    decide deny "changing core.hooksPath disables the project hooks. $BYPASS_MSG"
  fi
  if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])(VA_SKIP|SKIP|LEFTHOOK|HUSKY)=|LEFTHOOK_EXCLUDE='; then
    decide deny "skip variables turn checks off. $BYPASS_MSG"
  fi
  if printf '%s' "$cmd" | grep -Eq "$PROTECTED" \
     && printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|])(sed[[:space:]]+-i|perl[[:space:]]+-[a-z]*i|rm|mv|cp|tee|truncate|chmod|git[[:space:]]+(checkout|restore|rm|mv))([[:space:]]|$)|>'; then
    decide ask "this command modifies check configuration. The user should approve changes to how the project is checked."
  fi
  exit 0
fi

case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit)
    file=$(json_str file_path)
    [ -z "$file" ] && file=$(json_str notebook_path)
    rel=${file#"${CLAUDE_PROJECT_DIR:-$PWD}"/}
    if printf '/%s' "$rel" | grep -Eq "$PROTECTED"; then
      decide ask "$rel is check configuration. The user should approve changes to how the project is checked."
    fi
    if printf '%s' "$input" | grep -Eq 'nosemgrep|gitleaks:allow|eslint-disable|# *noqa|@pytest\.mark\.skip|pytest\.skip\(|(^|[^[:alnum:]_])(it|test|describe)\.(skip|only)\(|(^|[^[:alnum:]_])x(it|describe|test)\(|t\.Skip\(|#\[ignore\]|@Disabled'; then
      decide ask "this edit adds a check suppression or a skipped/focused test. Say why it is a false positive or why the test must not run, and let the user decide."
    fi
    ;;
esac
exit 0
