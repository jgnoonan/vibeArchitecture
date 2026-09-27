#!/usr/bin/env bash
# Tests for the agent guard (checks/templates/.va/hooks/guard.sh): each case feeds a
# hook payload and asserts the decision. Includes cases that must be allowed, so the
# guard can't pass by denying everything.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/checks/templates/.va/hooks/guard.sh"
fail=0; n=0

check() { # check <expected allow|ask|deny> <mode> <json> <label>
  local out got
  out=$(printf '%s' "$3" | sh "$GUARD" "$2")
  got=$(printf '%s' "$out" | sed -nE 's/.*"(permissionDecision|permission)":"([a-z]*)".*/\2/p')
  got=${got:-allow}
  n=$((n + 1))
  if [ "$got" != "$1" ]; then printf 'FAIL %-40s expected %s, got %s\n' "$4" "$1" "$got"; fail=1; fi
}

B='{"tool_name":"Bash","tool_input":{"command":'
check deny  claude "$B\"git commit -m fix --no-verify\"}}"            "commit --no-verify"
check deny  claude "$B\"git push --no-verify origin main\"}}"         "push --no-verify"
check deny  claude "$B\"git commit -anm wip\"}}"                      "commit -anm"
check deny  claude "$B\"git config core.hooksPath /dev/null\"}}"      "hooksPath elsewhere"
check deny  claude "$B\"VA_SKIP=tests VA_SKIP_REASON=x git push\"}}"  "VA_SKIP"
check deny  claude "$B\"HUSKY=0 git push\"}}"                         "HUSKY=0"
check ask   claude "$B\"sed -i s/a/b/ .va/config.sh\"}}"              "sed -i on .va/config.sh"
check ask   claude "$B\"rm .githooks/pre-push\"}}"                    "rm hook"
check ask   claude "$B\"echo x > .gitleaks.toml\"}}"                  "redirect into scanner config"
check allow claude "$B\"git commit -m \\\"fix login\\\"\"}}"          "normal commit"
check allow claude "$B\"git push origin feature\"}}"                  "normal push"
check allow claude "$B\"git config core.hooksPath .githooks\"}}"      "install hooks"
check allow claude "$B\"cat .va/config.sh\"}}"                        "read config"
check allow claude "$B\".va/check push\"}}"                           "run the checks"
check ask   claude '{"tool_name":"Edit","tool_input":{"file_path":"/p/.va/config.sh","old_string":"a","new_string":"b"}}' "Edit check config"
check ask   claude '{"tool_name":"Write","tool_input":{"file_path":"/p/.github/workflows/va-checks.yml","content":"x"}}' "Write CI check workflow"
check ask   claude '{"tool_name":"Edit","tool_input":{"file_path":"/p/src/a.ts","old_string":"a","new_string":"q(x) // nosemgrep"}}' "adds nosemgrep"
check ask   claude '{"tool_name":"Write","tool_input":{"file_path":"/p/t/a.test.ts","content":"it.skip(\"x\", f)"}}' "adds it.skip"
check ask   claude '{"tool_name":"Write","tool_input":{"file_path":"/p/t/test_a.py","content":"@pytest.mark.skip\ndef test_a(): pass"}}' "adds pytest skip"
check allow claude '{"tool_name":"Edit","tool_input":{"file_path":"/p/src/a.ts","old_string":"a","new_string":"b"}}' "normal edit"
check allow claude '{"tool_name":"Write","tool_input":{"file_path":"/p/src/a.py","content":"sys.exit(1)"}}' "exit( is not xit("
check deny  claude "$B\"git commit --no-verif -m x\"}}"            "abbreviated --no-verif"
check deny  claude "$B\"git push --no-ver origin main\"}}"          "abbreviated --no-ver"
check deny  claude "$B\"git -c core.hookspath=/tmp commit -m x\"}}" "core.hookspath via -c, lower case"
check deny  claude "$B\"git config core.HooksPath /dev/null\"}}"    "hooksPath mixed case"
check ask   claude "$B\"echo src/ >> .gitignore\"}}"                "append to .gitignore"
check ask   claude "$B\"rm eslint.config.js\"}}"                    "remove lint config"
check allow claude "$B\".va/check push 2>&1 | tee check.log\"}}"    "run checks with tee"
check allow claude "$B\"git commit -m \\\"docs: explain -n flag\\\"\"}}" "-n inside a commit message"
check allow claude "$B\"grep -rn -- --no-verify docs/\"}}"          "grep for --no-verify"
check allow claude '{"tool_name":"Edit","tool_input":{"file_path":"/p/src/a.py","old_string":"x = 1  # noqa","new_string":"x = 1"}}' "removing a noqa"
check ask   claude '{"tool_name":"Edit","tool_input":{"file_path":"/p/src/a.ts","old_string":"a","new_string":"// @ts-ignore\nb"}}' "adds @ts-ignore"
check ask   claude '{"tool_name":"Write","tool_input":{"file_path":"/p/t/a.test.ts","content":"fdescribe(\"x\", f)"}}' "adds fdescribe"
check ask   claude '{"tool_name":"Edit","tool_input":{"file_path":"/p/.eslintrc.json","old_string":"a","new_string":"b"}}' "edit eslint config"
check deny  cursor '{"command":"git push --no-verify","cwd":"/p"}'   "cursor --no-verify"
check ask   cursor '{"command":"rm -rf .va/semgrep","cwd":"/p"}'     "cursor rm rules"
check allow cursor '{"command":"npm test","cwd":"/p"}'               "cursor npm test"

if [ $fail = 0 ]; then echo "agent guard: $n cases pass"; else exit 1; fi
