#!/usr/bin/env bash
# End-to-end test of the checks templates: install into a scratch project with a
# local "origin", then assert that clean pushes pass and each planted violation
# is rejected by the real pre-commit / pre-push hooks. This is the negative
# control for the gate itself.
#
# Needs the tools from mise.toml on PATH (gitleaks, osv-scanner, semgrep,
# actionlint, zizmor), python3, and network access for osv-scanner.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export NO_COLOR=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
fail=0; n=0

expect() { # expect <pass|fail> <label> <cmd...>
  local want="$1" label="$2"; shift 2
  local log="$WORK/last.log"
  if "$@" >"$log" 2>&1; then got=pass; else got=fail; fi
  n=$((n + 1))
  if [ "$got" = "$want" ]; then printf 'ok    %-52s (%s)\n' "$label" "$got"
  else printf 'FAIL  %-52s expected %s, got %s\n' "$label" "$want" "$got"; sed 's/^/      | /' "$log" | tail -40; fail=1; fi
}

git init -q --bare -b main "$WORK/origin.git"
git clone -q "$WORK/origin.git" "$WORK/app" 2>/dev/null
cd "$WORK/app" || exit 1
git checkout -q -b main
cat > package.json <<'JSON'
{ "name": "app", "version": "1.0.0", "private": true, "scripts": { "lint": "node -e 0", "test": "node test.js" } }
JSON
printf '{"name":"app","version":"1.0.0","lockfileVersion":3,"requires":true,"packages":{"":{"name":"app","version":"1.0.0"}}}\n' > package-lock.json
echo 'console.log("tests pass")' > test.js
mkdir -p src
printf 'exports.find = (db, id) => db.query("SELECT * FROM users WHERE id = $1", [id]);\n' > src/db.js
printf '# App\n\n**Tier:** Shared\n' > PROJECT_PROFILE.md
git add -A && git commit -qm init && git push -q -u origin main 2>/dev/null

expect pass "installer runs"                       bash "$ROOT/checks/install.sh" --ci none
expect pass "doctor finds every tool"              .va/check doctor
expect pass "commit + push clean code with checks" sh -c 'git add -A && git commit -qm "add checks" && git push -q'

# SQL injection must be rejected at pre-push.
printf 'exports.s = (db, req) => db.query(`SELECT * FROM p WHERE name = %s${req.query.q}%s`);\n' "'" "'" > src/search.js
git add -A && git commit -qm search >/dev/null 2>&1
expect fail "push with SQL built from request input"  git push -q
git reset -q --hard origin/main

# A realistic-looking secret must be rejected at pre-commit (gitleaks, staged).
printf 'const key = "%s";\n' "ghp_$(printf 'a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6q7R8')" > src/config.js
git add -A
expect fail "commit containing a GitHub token"     git commit -qm leak
git reset -q --hard origin/main

# Tracked .env must be rejected at pre-commit.
echo "DB_PASSWORD=x" > .env.production && git add -f .env.production
expect fail "commit tracking .env.production"      git commit -qm env
git reset -q --hard origin/main; rm -f .env.production

# A known-vulnerable dependency must be rejected (osv-scanner, lockfile changed).
cat > package-lock.json <<'JSON'
{"name":"app","version":"1.0.0","lockfileVersion":3,"requires":true,"packages":{"":{"name":"app","version":"1.0.0","dependencies":{"lodash":"4.17.15"}},"node_modules/lodash":{"version":"4.17.15","resolved":"https://registry.npmjs.org/lodash/-/lodash-4.17.15.tgz"}}}
JSON
git add -A && git commit -qm "old lodash" >/dev/null 2>&1
expect fail "push with a vulnerable lockfile entry" git push -q
git reset -q --hard origin/main

# An unpinned GitHub Action must be rejected (zizmor).
mkdir -p .github/workflows
printf 'name: ci\non: [push]\npermissions: {}\njobs:\n  a:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n        with:\n          persist-credentials: false\n' > .github/workflows/ci.yml
git add -A && git commit -qm ci >/dev/null 2>&1
expect fail "push with an action pinned to a tag"  git push -q
git reset -q --hard origin/main

# Baseline: existing finding recorded, full passes; a new one still fails.
printf 'exports.s = (db, req) => db.query(`SELECT * FROM p WHERE id = ${req.params.id}`);\n' > src/legacy.js
git add -A && git commit -qm legacy --no-verify >/dev/null 2>&1
expect fail "full with an unbaselined finding"     .va/check full
expect pass "record the adoption baseline"         .va/check baseline
expect pass "full with the finding baselined"      .va/check full
expect fail "baseline cannot be re-recorded"       .va/check baseline
printf 'exports.r = (cp, req) => cp.exec("ls " + req.query.dir);\n' > src/admin.js
git add -A && git commit -qm admin --no-verify >/dev/null 2>&1
expect fail "full with a new finding past baseline" .va/check full

echo
if [ $fail = 0 ]; then echo "checks templates: $n end-to-end cases pass"; else exit 1; fi
