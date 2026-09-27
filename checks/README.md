# vibeArchitecture checks

The rules in `rules/` tell an AI agent how to build. The checks here verify that what was committed actually follows them, using standard tools, in the places a CI practitioner expects: git hooks, CI, and a required status check on the default branch.

```bash
# from your project root, with vibeArchitecture/ present
vibeArchitecture/checks/install.sh          # reads the tier from PROJECT_PROFILE.md
mise install                                # pinned scanner versions
.va/check doctor
.va/check full
```

## How it fits together

```
rules/*.md ──── rules/verification.toml ──── checks/catalog.toml
   │              (how each rule is verified)      (what each check is)
   │                       │
   │            checks/semgrep/  ── VA Semgrep rules, each citing the rule it enforces
   │                       │
   ▼                       ▼
 agent            .va/check  fast | push | full | release
 builds               ▲          ▲           ▲
                pre-commit    pre-push    CI job `check` ── required status check
                  hook          hook
```

**One command.** `.va/check` is the only entry point. The git hooks call `fast` and `push`, CI calls `full`, and the agent runs `push` before saying a task is done. Nothing re-implements it, so local and CI results match. Tool versions come from one `mise.toml`, used both locally and by `jdx/mise-action` in CI.

**Layers.**

| Layer | Budget | Runs |
|---|---|---|
| pre-commit (`fast`) | seconds | gitleaks on staged changes, tracked `.env` files, formatter check |
| pre-push (`push`) | about a minute | gitleaks on the pushed range; VA Semgrep rules on new code only (`--baseline-commit`); osv-scanner when a manifest or lockfile changed; lint; tests; migration immutability; actionlint + zizmor when workflows changed |
| CI (`full`) | minutes | everything, on all files: full-history secret scan, all findings against the baseline file, database tests with `VA_REQUIRE_DB=1`, migrate-twice, codegen drift |
| release | as needed | `full` + `RELEASE_CMD` (SBOM, image scan, release-artifact invariants) |
| post-deploy / scheduled | n/a | `templates/smoke-headers.sh`, health checks, restore drills, a weekly CI run for new advisories |

**Only the server enforces.** Hooks give fast feedback, and anyone (or any agent) can skip them. The required `check` status on the default branch is the control that can't be skipped. Business and Regulated tiers must have it; `.va/check doctor` reports whether it's in place.

**The agent can't turn the checks off.** `templates/.va/hooks/guard.sh` is wired into Claude Code (PreToolUse) and Cursor (beforeShellExecution). It denies `--no-verify`, `git commit -n`, changes to `core.hooksPath`, and skip variables. It asks the user before the agent edits check configuration or adds a `nosemgrep`, a `.skip`, or a similar suppression. Cursor's hooks can't intercept file edits, only shell commands, so for Cursor the server-side check is the backstop.

**Adopting on an existing codebase.** `.va/check baseline` records today's Semgrep findings, each with an expiry. After that only new findings block, and the baseline only shrinks. osv-scanner exceptions carry a `reason` and `ignoreUntil` in `osv-scanner.toml`; gitleaks uses `.gitleaksignore` for leaks that have been rotated.

## What's here

| Path | What it is |
|---|---|
| `semgrep/<tier>/*.yaml` | VA Semgrep rules, one directory per tier. Every rule cites `metadata.va_rules`, and each rule file is paired with fixtures (`ruleid:` / `ok:` lines) proving it fires and stays quiet. |
| `catalog.toml` | Every check id the verification matrix may reference: kind, layer, tier, and how VA provides it. |
| `install.sh` | Installs or updates the checks in a project (`--tier`, `--ci`, `--agents`, `--update`, `--dry-run`). |
| `audit.py` | Coverage report for a project: which checks its tier expects are wired, not configured, or missing, and which rules need review or attestation. Exits 1 on gaps. |
| `templates/` | Everything the installer copies: `.va/check`, `baseline.py`, the agent guard, `config.sh`, git hooks, `mise.toml`, scanner configs, and the GitHub and GitLab CI templates, ruleset and AI review workflow. |
| `invariant-tests/` | Templates for project-specific rules enforced as ordinary tests, each with a negative control. |

## Tools

| Tool | Check | Why this one |
|---|---|---|
| [gitleaks](https://github.com/gitleaks/gitleaks) | `secrets` | Fast and offline, with staged, commit-range and full-history modes; baselines and `.gitleaksignore`. |
| [osv-scanner](https://github.com/google/osv-scanner) | `deps` | One tool for every ecosystem's lockfile; exceptions carry a reason and an expiry. |
| [Semgrep CE](https://github.com/semgrep/semgrep) | `va-rules` | Rules read like the code they match, so VA's prose rules become checkable. Diff-aware with `--baseline-commit`. |
| [actionlint](https://github.com/rhysd/actionlint), [zizmor](https://github.com/zizmorcore/zizmor) | `workflows` | Workflow correctness, SHA pinning, least privilege, credential persistence, template injection. |
| [squawk](https://github.com/sbdchd/squawk) (optional) | `migration-lint` | Postgres migration safety (locks, blocking DDL). |
| [mise](https://mise.jdx.dev) | all | Pins every tool version in one file, locally and in CI. |

## Maintaining the rules (this repo)

- `scripts/test-semgrep-rules.py` fails on any config error, failing fixture, rule without a `ruleid:` fixture, rule without an `ok:` fixture, or rule without `metadata.va_rules`. (`semgrep --test` on its own reports success in several of those cases.)
- `scripts/verify-matrix.py` fails when any bullet in `rules/*.md` has no entry in `rules/verification.toml`, when a "pattern" entry has no Semgrep rule citing it, or when a check id isn't in the catalog. `--summary` prints the automation coverage per tier.
- Adding a rule means classifying it in the matrix. If it can be a pattern, write the Semgrep rule with fixtures in the same PR. See `CONTRIBUTING.md`.
