#!/bin/sh
# vibeArchitecture agent guard. Framework-owned.
# Called by Claude Code (PreToolUse) and Cursor (beforeShellExecution) with the
# tool call as JSON on stdin:  guard.sh claude | guard.sh cursor
#
#   deny  commands that bypass the checks: git --no-verify (or any abbreviation
#         git accepts), `git commit -n`, changing core.hooksPath (any case),
#         VA_SKIP / SKIP / LEFTHOOK=0 / HUSKY=0
#   ask   writes to check configuration (.va/, .githooks/, scanner and linter
#         configs, .gitignore, the CI check workflow, agent hook settings), and
#         edits whose new text adds a suppression or a skipped/focused test
#
# "ask" hands the decision to the user. Hooks are guardrails for an honest
# agent; the required status check on the server is what actually enforces.
# POSIX sh + grep/sed -E only (no jq, no python, no GNU extensions), so it
# behaves the same on macOS and Linux.

mode="${1:-claude}"
input=$(cat)
flat=$(printf '%s' "$input" | tr '\n' ' ')

json_str() { # json_str <key> [text]: first JSON string value for "key", minimally unescaped
  printf '%s' "${2:-$flat}" \
    | sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\\1/p" \
    | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g' | head -n 1
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

# Paths whose edits change how the project is checked.
PROTECTED='(^|[^[:alnum:]_.-])((\.va|\.githooks)/|(\.gitleaks\.toml|\.gitleaksignore|osv-scanner\.toml|\.semgrepignore|\.gitignore|zizmor\.ya?ml|mise\.toml|\.github/workflows/va-checks\.ya?ml|\.claude/settings\.json|\.cursor/hooks\.json|\.eslintrc(\.[a-z]+)?|eslint\.config\.[cm]?[jt]s|\.?ruff\.toml|\.golangci\.ya?ml|clippy\.toml|analysis_options\.yaml|\.pre-commit-config\.yaml|lefthook\.ya?ml)([^[:alnum:]_.]|$))'
# Text that switches a check off for a line, a file, or a test.
SUPPRESS='nosemgrep|gitleaks:allow|eslint-disable|@ts-ignore|@ts-nocheck|//[[:space:]]*nolint|#[[:space:]]*noqa|#[[:space:]]*nosec|NOSONAR|pylint:[[:space:]]*disable|@pytest\.mark\.skip|pytest\.skip\(|(^|[^[:alnum:]_.])(it|test|describe)\.(skip|only)\(|(^|[^[:alnum:]_.])[xf](it|describe|test)\(|t\.Skip\(|#\[ignore\]|@Disabled'
BYPASS_MSG="this would bypass the project checks. Fix what the check reports; if you believe the check is wrong, stop and explain it to the user instead."

tool=$(json_str tool_name)
cmd=$(json_str command)

if [ -n "$cmd" ] && { [ "$mode" = cursor ] || [ "$tool" = "Bash" ] || [ -z "$tool" ]; }; then
  # Drop quoted strings (commit messages, grep patterns) before looking at flags.
  bare=$(printf '%s' "$cmd" | sed -E -e 's/"([^"\\]|\\.)*"/""/g' -e "s/'[^']*'/''/g")
  if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]][^;&|]*)?[[:space:]]--no-ver(i|[^[:alnum:]b-]|$)'; then
    decide deny "$BYPASS_MSG"
  fi
  if printf '%s' "$bare" | grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+([^;&|]*[[:space:]])?commit([[:space:]]+[^;&|]*)?[[:space:]]-[a-zA-Z]*n[a-zA-Z]*([[:space:]]|$)'; then
    decide deny "git commit -n skips the pre-commit checks. $BYPASS_MSG"
  fi
  if printf '%s' "$bare" | grep -Eiq 'core\.hookspath' \
     && ! printf '%s' "$bare" | grep -Eiq '^[[:space:]]*git[[:space:]]+config([[:space:]]+--local)?[[:space:]]+core\.hookspath[[:space:]]+\.githooks[[:space:]]*$'; then
    decide deny "changing core.hooksPath disables the project hooks. $BYPASS_MSG"
  fi
  if printf '%s' "$bare" | grep -Eq '(^|[[:space:];&|(])(VA_SKIP|SKIP|LEFTHOOK|HUSKY|LEFTHOOK_EXCLUDE)='; then
    decide deny "skip variables turn checks off. $BYPASS_MSG"
  fi
  # A write whose target is check configuration: an editing command with a
  # protected path among its arguments, or a redirect into a protected path.
  if printf '%s' "$bare" | grep -Eq "(^|[[:space:];&|(])(sed[[:space:]]+-[a-zA-Z]*i|perl[[:space:]]+-[a-zA-Z]*i|rm|mv|cp|tee|truncate|chmod|ln|git[[:space:]]+(checkout|restore|rm|mv))([[:space:]][^;&|]*)?$PROTECTED" \
     || printf '%s' "$bare" | grep -Eq ">>?[[:space:]]*[^[:space:];&|]*$PROTECTED"; then
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
    # Only the text being written counts: drop old_string values first.
    new_text=$(printf '%s' "$flat" | sed -E 's/"old_string"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"//g')
    if printf '%s' "$new_text" | grep -Eq "$SUPPRESS"; then
      decide ask "this edit adds a check suppression or a skipped/focused test. Say why it is a false positive or why the test must not run, and let the user decide."
    fi
    ;;
esac
exit 0
