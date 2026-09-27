# Project checks (vibeArchitecture)

This folder holds the automated checks for this project. One command runs them, and the git hooks, CI and the AI agent all call that same command, so "it passed on my machine" and "it passed in CI" mean the same thing.

## Commands

| Command | When it runs | What it checks |
|---|---|---|
| `.va/check fast` | pre-commit hook | secrets in staged changes, tracked `.env` files, formatting |
| `.va/check push` | pre-push hook; the agent runs it before saying a task is done | the above, plus lint, the vibeArchitecture Semgrep rules and dependency audit on what changed, tests, migration and workflow checks |
| `.va/check full` | CI on every pull request and on the default branch | everything, on every file, including database tests and migrate-twice |
| `.va/check release` | release pipeline | `full`, plus `RELEASE_CMD` (SBOM, artifact checks, image scan) |
| `.va/check doctor` | when something seems off | tool versions, hook installation, agent hooks, branch protection |
| `.va/check list` | any time | which steps each profile runs |

`push` looks at what changed since the remote branch (or the merge-base with the default branch); add `--all` to scan everything. A step prints "n/a" when it doesn't apply (no migrations, no workflows, a command not configured). A missing tool is a failure, never a silent skip.

## Setup on a new clone

```bash
mise install                 # tools pinned in mise.toml
.va/check install-hooks      # git config core.hooksPath .githooks
.va/check doctor
```

Commands for your stack (lint, tests, migrations, codegen, release) live in `.va/config.sh`.

## When a check fails

Fix the cause. The pre-commit and pre-push hooks exist so problems are found in seconds on your machine instead of minutes later in CI.

- **Secret found:** remove it and rotate the key. It is already exposed if it was ever pushed. If gitleaks flags something that isn't a secret, add `gitleaks:allow` in a comment on that line, or add the finding's fingerprint to `.gitleaksignore` with a note.
- **Vulnerable dependency:** upgrade it. If no fix exists and the vulnerable code isn't reachable, add an `[[IgnoredVulns]]` entry to `osv-scanner.toml` with a `reason` and an `ignoreUntil` date.
- **vibeArchitecture rule (va-…):** the message names the rule, for example `[VA SEC-004]`. Look it up in `vibeArchitecture/rules/`. For a genuine false positive, add `// nosemgrep: <rule-id>` (or `# nosemgrep: <rule-id>`) on that line and give the reason in the same comment.

## Skipping, and why it's hard

- `git push --no-verify` skips the hooks locally. CI still runs `.va/check full`, and CI is what blocks the merge.
- `VA_SKIP=deps VA_SKIP_REASON="offline on a plane" git push` skips one named step locally. It is logged to `.va/logs/skips.tsv` and is ignored in CI.
- The AI agent hooks (`.claude/settings.json`, `.cursor/hooks.json`) block the agent from using `--no-verify`, skip variables or hook-path changes. They also ask you before the agent edits check configuration or adds a suppression or a skipped test.

## Baselines (adopting checks on an existing codebase)

Run `.va/check baseline` once. It records today's Semgrep findings in `.va/baselines/semgrep.json`, each with an expiry date (180 days by default). From then on only new findings block. The file can only shrink:

- `python3 .va/baseline.py prune .va/logs/semgrep-full.json --baseline .va/baselines/semgrep.json` removes fixed entries.
- Adding entries needs `accept` with `--reason` and `--expires`. It shows up in code review as a diff to this file.

When an entry expires, its finding blocks again.

## Branch protection (the part that actually enforces)

Hooks can be skipped, but a required status check on the server can't. On GitHub, require the `check` job on the default branch:

```bash
gh api -X POST repos/{owner}/{repo}/rulesets --input .va/github-ruleset.json
```

This needs admin rights on the repo, and a paid plan for private repos. Business and Regulated tiers must have it; `.va/check doctor` reports whether it's in place. On GitLab, turn on **Pipelines must succeed** for merge requests.

## Files

| Path | Owner | Purpose |
|---|---|---|
| `.va/check`, `.va/baseline.py`, `.va/hooks/guard.sh`, `.va/semgrep/`, `.va/VERSION`, this README | vibeArchitecture | replaced by `vibeArchitecture/checks/install.sh --update` |
| `.va/config.sh`, `.va/baselines/`, `.githooks/`, `mise.toml`, `.gitleaks.toml`, `osv-scanner.toml`, `.semgrepignore`, CI workflow, agent hook settings | this project | edit freely; updates never overwrite them |
| `.va/logs/` | local | run history and skips (gitignored; CI uploads it as an artifact) |
