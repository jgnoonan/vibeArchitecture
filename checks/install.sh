#!/usr/bin/env bash
# Install or update the vibeArchitecture checks in a project.
#
#   vibeArchitecture/checks/install.sh [options] [project-dir]
#
# Options:
#   --tier <t>        personal | shared | public | business | regulated
#                     (default: read "**Tier:**" from PROJECT_PROFILE.md)
#   --ci <c>          github | gitlab | none      (default: github if .github/ or a github.com remote exists)
#   --agents <list>   claude,cursor | none        (default: claude,cursor)
#   --update          refresh framework-owned files (check script, rules, hooks) only
#   --dry-run         print what would change
#
# Framework-owned files are replaced on --update:
#   .va/check  .va/baseline.py  .va/hooks/guard.sh  .va/README.md  .va/semgrep/  .va/VERSION
# Project-owned files are created once and never overwritten:
#   .va/config.sh  .githooks/*  mise.toml  .gitleaks.toml  osv-scanner.toml  .semgrepignore
#   .github/workflows/va-checks.yml  .va/github-ruleset.json  .claude/settings.json  .cursor/hooks.json
set -euo pipefail
shopt -u patsub_replacement 2>/dev/null || true  # bash 5.2: keep "&" literal in substitutions

VA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$VA_ROOT/checks/templates"
TIER=""; CI_KIND=""; AGENTS="claude,cursor"; UPDATE=""; DRY=""; PROJECT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --tier) shift; TIER="${1:-}" ;;
    --ci) shift; CI_KIND="${1:-}" ;;
    --agents) shift; AGENTS="${1:-}" ;;
    --update) UPDATE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) PROJECT="$1" ;;
  esac
  shift
done

PROJECT="${PROJECT:-$(pwd)}"
PROJECT="$(cd "$PROJECT" && git rev-parse --show-toplevel 2>/dev/null)" || { echo "install.sh: $PROJECT is not inside a git repository (run git init first)" >&2; exit 2; }
if [ "$PROJECT" = "$VA_ROOT" ]; then echo "install.sh: run this from your project, not from the vibeArchitecture repo" >&2; exit 2; fi
cd "$PROJECT"

say() { printf '%s\n' "$*"; }
act() { if [ -n "$DRY" ]; then say "  would: $*"; else say "  $*"; fi; }

# ------------------------------------------------------------------ tier ---
if [ -z "$TIER" ] && [ -f PROJECT_PROFILE.md ]; then
  TIER=$(sed -n 's/^\*\*Tier:\*\*[[:space:]]*\([A-Za-z]*\).*/\1/p' PROJECT_PROFILE.md | head -1 | tr 'A-Z' 'a-z')
fi
case "$TIER" in
  personal|shared|public|business|regulated) ;;
  "") TIER=shared; say "No tier given and none found in PROJECT_PROFILE.md; using 'shared'. Pass --tier to change it." ;;
  *) echo "install.sh: unknown tier '$TIER'" >&2; exit 2 ;;
esac
TIERS="personal shared public business regulated"
tier_dirs() { local t; for t in $TIERS; do [ -d "$VA_ROOT/checks/semgrep/$t" ] && echo "$t"; [ "$t" = "$TIER" ] && break; done; }

VERSION=$(sed -n 's/^\*\*Framework version:\*\*[[:space:]]*//p' "$VA_ROOT/ARCHITECT.md" | head -1)
BRANCH=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
[ -z "$BRANCH" ] && BRANCH=$(git branch --show-current 2>/dev/null || true)
[ -z "$BRANCH" ] && BRANCH=main
if [ -z "$CI_KIND" ]; then
  if [ -d .github ] || git remote -v 2>/dev/null | grep -q 'github\.com'; then CI_KIND=github
  elif [ -f .gitlab-ci.yml ] || git remote -v 2>/dev/null | grep -q 'gitlab'; then CI_KIND=gitlab
  else CI_KIND=none; fi
fi

say "vibeArchitecture checks $VERSION -> $PROJECT"
say "  tier: $TIER   ci: $CI_KIND   agents: $AGENTS   branch: $BRANCH${UPDATE:+   (update)}"

# --------------------------------------------------------- copy helpers ---
put() { # put <src> <dest> <owned: framework|project>
  local src="$1" dest="$2" owner="$3"
  if [ -e "$dest" ] && [ "$owner" = project ]; then say "  keep   $dest (project-owned)"; return; fi
  if [ -e "$dest" ] && cmp -s "$src" "$dest"; then return; fi
  act "write  $dest"
  [ -n "$DRY" ] && return
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

# ------------------------------------------------------ framework-owned ---
say "framework files:"
put "$TPL/.va/check" .va/check framework
put "$TPL/.va/baseline.py" .va/baseline.py framework
put "$TPL/.va/hooks/guard.sh" .va/hooks/guard.sh framework
put "$TPL/.va/README.md" .va/README.md framework
if [ -z "$DRY" ]; then
  rm -rf .va/semgrep
  for t in $(tier_dirs); do
    mkdir -p ".va/semgrep/$t"
    cp "$VA_ROOT/checks/semgrep/$t"/*.yaml ".va/semgrep/$t/"
  done
  printf '%s\n' "$VERSION" > .va/VERSION
  chmod +x .va/check .va/baseline.py .va/hooks/guard.sh
fi
act "rules  .va/semgrep/ ($(tier_dirs | tr '\n' ' ')) and .va/VERSION = $VERSION"

if [ -n "$UPDATE" ]; then
  say "updated framework files. Project config was not touched. Run: .va/check doctor"
  exit 0
fi

# -------------------------------------------------------- stack detection ---
FMT=""; LINT=""; TEST=""
pm="npm"
[ -f pnpm-lock.yaml ] && pm="pnpm"; [ -f yarn.lock ] && pm="yarn"; { [ -f bun.lockb ] || [ -f bun.lock ]; } && pm="bun"
has_script() { [ -f package.json ] && grep -Eq "\"$1\"[[:space:]]*:" package.json; }
run_script() { case "$pm" in npm) echo "npm run $1";; *) echo "$pm run $1";; esac; }
if [ -f package.json ]; then
  if has_script "format:check"; then FMT=$(run_script format:check)
  elif grep -q '"prettier"' package.json; then FMT="npx prettier --check ."; fi
  has_script lint && LINT=$(run_script lint)
  if has_script test && ! grep -Eq '"test"[[:space:]]*:[[:space:]]*"echo \\"Error: no test specified' package.json; then TEST="$pm test"; fi
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  pre=""; [ -f uv.lock ] && pre="uv run "
  if grep -qs 'ruff' pyproject.toml requirements*.txt; then FMT="${pre}ruff format --check ."; LINT="${pre}ruff check ."; fi
  grep -qs 'pytest' pyproject.toml requirements*.txt && TEST="${pre}pytest -q"
elif [ -f Cargo.toml ]; then
  FMT="cargo fmt --all -- --check"; LINT="cargo clippy --all-targets --all-features -- -D warnings"; TEST="cargo test --all-features"
elif [ -f go.mod ]; then
  FMT='test -z "$(gofmt -l .)"'; LINT="golangci-lint run"; TEST="go test ./..."
elif [ -f pubspec.yaml ]; then
  FMT="dart format --output=none --set-exit-if-changed ."; LINT="flutter analyze --fatal-infos"; TEST="flutter test"
fi

fill() { # fill <template> <dest>: substitute detected values
  local s
  s=$(cat "$1")
  s=${s//__TIER__/$TIER}
  s=${s//__FORMAT_CHECK_CMD__/$FMT}
  s=${s//__LINT_CMD__/$LINT}
  s=${s//__TEST_CMD__/$TEST}
  s=${s//__BRANCH__/$BRANCH}
  if [ -e "$2" ]; then say "  keep   $2 (project-owned)"; return; fi
  act "write  $2"
  [ -n "$DRY" ] && return
  mkdir -p "$(dirname "$2")"
  printf '%s\n' "$s" > "$2"
}

# -------------------------------------------------------- project-owned ---
say "project files:"
fill "$TPL/.va/config.sh" .va/config.sh
put "$TPL/.githooks/pre-commit" .githooks/pre-commit project
put "$TPL/.githooks/pre-push" .githooks/pre-push project
put "$TPL/mise.toml" mise.toml project
put "$TPL/.gitleaks.toml" .gitleaks.toml project
put "$TPL/osv-scanner.toml" osv-scanner.toml project
put "$TPL/.semgrepignore" .semgrepignore project
case "$CI_KIND" in
  github)
    fill "$TPL/github/va-checks.yml" .github/workflows/va-checks.yml
    put "$TPL/github/ruleset.json" .va/github-ruleset.json project
    case "$TIER" in business|regulated) fill "$TPL/github/va-ai-review.yml" .github/workflows/va-ai-review.yml ;; esac ;;
  gitlab) put "$TPL/gitlab/va-checks.gitlab-ci.yml" .va/va-checks.gitlab-ci.yml project ;;
esac

merge_json() { # merge_json <template> <dest>: add our hook entries to an existing JSON config
  local src="$1" dest="$2"
  if [ ! -e "$dest" ]; then put "$src" "$dest" project; return; fi
  if grep -q '.va/hooks/guard.sh' "$dest"; then say "  keep   $dest (hook already present)"; return; fi
  if ! command -v python3 >/dev/null 2>&1; then say "  MERGE BY HAND: add the hook from $src to $dest"; return; fi
  act "merge  hook into $dest"
  [ -n "$DRY" ] && return
  python3 - "$src" "$dest" <<'PY'
import json, sys
src, dest = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
def merge(a, b):
    for k, v in a.items():
        if k not in b: b[k] = v
        elif isinstance(v, dict) and isinstance(b[k], dict): merge(v, b[k])
        elif isinstance(v, list) and isinstance(b[k], list): b[k].extend(x for x in v if x not in b[k])
merge(src, dest)
json.dump(dest, open(sys.argv[2], "w"), indent=2); open(sys.argv[2], "a").write("\n")
PY
}
case ",$AGENTS," in *,claude,*) merge_json "$TPL/claude/settings.json" .claude/settings.json ;; esac
case ",$AGENTS," in *,cursor,*) merge_json "$TPL/cursor/hooks.json" .cursor/hooks.json ;; esac

# -------------------------------------------------------------- gitignore ---
add_ignore() { grep -qxF "$1" .gitignore 2>/dev/null || { act "ignore $1"; [ -z "$DRY" ] && printf '%s\n' "$1" >> .gitignore; }; }
say "gitignore:"
add_ignore ".env"
add_ignore ".env.*"
add_ignore "!.env.example"
add_ignore ".va/logs/"
add_ignore ".va-rules/"
add_ignore ".claude/settings.local.json"
add_ignore "claude_desktop_config.json"

if [ -z "$DRY" ]; then
  chmod +x .githooks/* 2>/dev/null || true
  git config core.hooksPath .githooks
  say "  git hooks: core.hooksPath = .githooks"
fi

cat <<EOF

Next:
  1. mise install                      # pinned gitleaks, osv-scanner, semgrep, actionlint, zizmor
  2. review .va/config.sh              # detected: lint='${LINT:-?}' test='${TEST:-?}' format='${FMT:-?}'
  3. .va/check doctor
  4. .va/check full                    # first full run; on an existing codebase, then:
     .va/check baseline                #   record today's findings so only new ones block
  5. commit .va/ .githooks/ and the config files, and push
EOF
if [ "$CI_KIND" = github ]; then cat <<'EOF'
  6. require the `check` job on your default branch (private repos need a paid plan):
     gh api -X POST repos/{owner}/{repo}/rulesets --input .va/github-ruleset.json
EOF
fi
say "Details: .va/README.md"
