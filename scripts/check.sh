#!/usr/bin/env bash
# This repository's own checks: what the pre-push hook and CI run.
# Enable the hook once per clone: git config core.hooksPath .githooks
# Tools: `mise install` (versions in mise.toml); markdownlint via npx.
set -u
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
failed=()
run() { # run <name> <cmd...>: bare, so the exit code is the tool's
  printf '\n== %s\n' "$1"; local name="$1"; shift
  "$@" || failed+=("$name")
}
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1 (run: mise install)"; failed+=("$1 missing"); return 1; }; }

run sync-check      ./scripts/sync.sh --check
run verify-matrix   python3 scripts/verify-matrix.py
need semgrep    && run semgrep-rules python3 scripts/test-semgrep-rules.py
run agent-guard     bash scripts/test-guard.sh
need shellcheck && run shellcheck shellcheck -S warning scripts/*.sh checks/install.sh \
  checks/templates/.va/check checks/templates/.va/hooks/guard.sh checks/templates/.githooks/pre-commit \
  checks/templates/.githooks/pre-push checks/templates/smoke-headers.sh
need gitleaks   && run secrets gitleaks git --redact --no-banner
need actionlint && run actionlint actionlint
need zizmor     && run zizmor zizmor --offline --min-severity medium .github/workflows
need npx        && run markdownlint npx --yes markdownlint-cli2 "**/*.md" "#node_modules"

if [ ${#failed[@]} -gt 0 ]; then printf '\nFAILED: %s\n' "${failed[*]}"; exit 1; fi
printf '\nAll checks passed.\n'
