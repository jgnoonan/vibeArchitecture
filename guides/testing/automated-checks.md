# Automated Checks

> This guide explains why vibeArchitecture verifies committed code with automated checks, where each check runs, and what each tier requires. For setup and commands, see `checks/README.md`. The compact rules are in `rules/universal.md` (Automated Checks).

## Why Rules Need Checks

The rules tell an AI agent how to build. That works while the agent is paying attention, but prose rules decay: a long session, a new contributor, a different tool, or a hurried fix, and a rule that was followed for weeks quietly stops being followed. Nothing notices until an incident does.

A check turns a rule into something that fails. vibeArchitecture classifies every rule by how it can be verified (`rules/verification.toml`):

| Method | Meaning | Example |
|---|---|---|
| tool | An off-the-shelf scanner decides it | secrets (gitleaks), vulnerable dependencies (osv-scanner), workflow pinning (zizmor) |
| pattern | A vibeArchitecture Semgrep rule decides it | SQL built by string concatenation, tokens in localStorage, `==` on HMACs, money stored as float |
| test | A test the project writes decides it | tenant isolation, fail-closed guards, release artifact has no debug endpoints |
| runtime | A check against the running system decides it | security headers on the deployed site, restore drill meets RTO |
| review | Needs judgment | whether authorization logic is correct |
| attest | A setting or process outside the code | admin MFA on the hosting dashboard, a written retention policy |

About two in five rules can be decided automatically. The rest need review or attestation. The matrix makes that split visible, so nothing is assumed to be enforced when it isn't (`scripts/verify-matrix.py --summary` prints it per tier).

## Where Checks Run

A check is worth the most at the earliest point where it's cheap enough to run. Each layer gets a time budget: go over it and people, and agents, start skipping it.

| Layer | Budget | What belongs | Can it be skipped? |
|---|---|---|---|
| Agent session | seconds | Hooks that block bypass commands; the agent runs `check push` before saying a task is done | The agent can't; a person can |
| pre-commit | seconds | Secret scan of staged changes, tracked `.env` files, formatting | Yes (`--no-verify`) |
| pre-push | about a minute | Lint, rules and dependency audit on what changed, unit tests, migration and workflow checks | Yes (`--no-verify`) |
| CI (required status check) | minutes | Everything on every file, database tests, migrate-twice, codegen drift | **No**: this is the enforcement point |
| Release | as needed | SBOM, image scan, release-artifact invariants | No, when the release pipeline runs it |
| Post-deploy and scheduled | n/a | Header smoke test, health checks, restore drills, weekly dependency audit | n/a |

All of these call one command, `.va/check`, with a profile (`fast`, `push`, `full`, `release`). CI doesn't re-implement anything, so "it passed locally" and "it passed in CI" mean the same thing.

## What Each Tier Requires

| Tier | Minimum |
|---|---|
| Personal | `.va/check` installed with the pre-commit hook (secrets, `.env`). Push hook recommended. |
| Shared | Hooks installed; `check push` must pass before a task is called done. Hosted CI or a blocking pre-push gate. |
| Public | CI runs `check full` on every pull request; the `check` job is a required status check where the plan allows it; general SAST (CodeQL default setup, or Semgrep registry rules). |
| Business | Required status check is mandatory. Release profile with SBOM and image scan. Accessibility checks in CI. AI or human review of every PR. Scheduled restore drill. |
| Regulated | Everything in Business, plus CI logs kept as evidence, at least one approving review from someone other than the author, CODEOWNERS on sensitive paths, and signed releases. |

Hosted CI is not required below Business tier. A solo project on a private repo can gate locally with the pre-push hook. That is a real control against honest mistakes, but anyone can skip it, so the profile should record it as an accepted gap. **Removing CI is a migration, not a deletion:** move every job into the local check, or record the gap. The common failure is dropping secret scanning and SAST without noticing.

## The Author Is Also the Enforcer

In vibe coding, the tool that writes the code is the one that meets the failing check, and it has every means of turning the check off: `git push --no-verify`, a skip variable, editing the check configuration, marking a test as skipped, loosening a threshold. An agent under pressure to finish will find these.

vibeArchitecture puts three controls in the way:

1. **The rule** (`rules/universal.md`): never bypass or weaken a check to get to green; fix the cause, or stop and ask.
2. **Agent hooks**: Claude Code and Cursor hooks deny the bypass commands outright and ask the user before the agent edits check configuration or adds a suppression.
3. **The server**: the required status check runs the same command, and no local action skips it.

The first two catch an honest agent that has lost the thread. Only the third holds when everything else fails.

## Adopting Checks on an Existing Codebase

Turning on a scanner over an existing codebase usually produces a wall of findings, and the usual response is to turn the scanner off. A baseline avoids that:

- Record today's findings once (`.va/check baseline`). Each entry expires, 180 days by default.
- From then on, only new findings block. Pre-push only looks at code you changed.
- The baseline only shrinks. Fixed findings are pruned, and additions need an explicit `accept` with a reason and an expiry, which shows up in code review.
- When an entry expires, its finding blocks again. Silence is not a decision.

The same idea applies everywhere: dependency exceptions carry `reason` and `ignoreUntil`; an inline `nosemgrep` carries the rule id and a reason on the same line.

## Checks That Can't Fail

A check that silently scans nothing is worse than no check, because it looks like coverage. Common ways it happens:

- **A pipe hides the exit code.** `scanner | tail` returns `tail`'s status. `.va/check` runs every tool bare.
- **A missing tool is treated as a pass.** `.va/check` fails the step with an install hint instead.
- **The suite skips itself.** Database tests that skip when there is no database read as green. `.va/check full` exports `VA_REQUIRE_DB=1`, and the suite must fail instead of skipping.
- **The scan finds nothing to scan.** Every invariant test asserts that it found at least one target, and every custom check ships a negative control: a known-bad example it must flag. vibeArchitecture's own Semgrep rules are held to this. Each has a fixture it must fire on and one it must stay quiet on, and CI fails otherwise.

## Incidents Become Checks

Most useful checks are written the week after something went wrong. When you fix a bug (`checklists/something-broke.md`), write the test or check that fails on the broken version and passes on the fix. If the pattern is generic, it belongs in `checks/semgrep/` for everyone.

## Evidence

The checks are also your evidence. CI keeps each run's logs as an artifact, the assurance register (`appendices/assurance-register-template.md`) lists which rule each check enforces and where it runs, and `checks/audit.py` reports which checks a tier expects that aren't in place. That's the honest answer to "how do you know this is enforced?"
