# Universal Rules

> Applies to: All tiers.
> These are foundational practices that apply to every project. For detailed explanations, see the relevant topic-specific guides in `guides/` (including `guides/security/supply-chain.md` for dependency and CI hygiene).

These apply to EVERY project regardless of tier. No exceptions.

## Version Control

- Use git. Commit early, commit often. Every meaningful change gets its own commit.
- Never commit secrets — API keys, passwords, database credentials, tokens, or private keys must never appear in any committed file. This includes source code, config files, documentation, and comments.
- Use `.gitignore`. At minimum ignore: `.env` files, dependency directories (`node_modules/`, `venv/`, etc.), build output, IDE settings, OS files (`.DS_Store`, `Thumbs.db`).
- If a secret is accidentally committed, it is compromised. Removing it from current code is not enough — it lives in git history. Rotate (change) the secret immediately.
- Once an app is deployed, protect the main branch: no direct pushes, and deploy only from main through CI. "What's in main" and "what's in production" should be the same answer.
- At Shared tier and above with collaborators, require pull request review before merging. At Business tier, use CODEOWNERS so changes to sensitive areas (auth, payments, infrastructure) automatically request the right reviewer.

## Secrets and Configuration

- Store secrets in environment variables loaded from a `.env` file that is NOT committed to version control.
- Add `.env` to `.gitignore` BEFORE creating the `.env` file. If you create the file first and commit it, the secret is already exposed.
- Provide a `.env.example` file (committed) showing required variables without real values.

## Error Handling

- Never show raw error details to users. Stack traces, database errors, and file paths help attackers and confuse users. Show a friendly message; log the details.
- Handle errors explicitly. Don't let the app crash silently or show a blank screen.
- Catch errors at boundaries (API endpoints, event handlers, background jobs) so one failure doesn't take down the whole application.
- Release builds run in production mode: no debug flags, developer-only endpoints, test accounts, or verbose error pages. Assert it on the built artifact, not only in config.

## Data Safety

- Have a backup plan, even for personal projects. Know how to export and restore your database.
- Prefer soft delete (marking records as deleted) over permanent deletion until you're certain the data isn't needed. This guards against *accidental* loss — it is not a substitute for real deletion when a user asks you to erase their personal data (see `rules/privacy.md` if that applies).
- Never run destructive operations (DROP TABLE, bulk DELETE) without a confirmed backup.

## Dependencies

- Use a lock file (`package-lock.json`, `poetry.lock`, `Cargo.lock`, etc.) so all environments use identical dependency versions.
- Keep dependencies updated. Outdated packages are the most common source of known security vulnerabilities.
- Evaluate before adding. Is it maintained? Does it have known vulnerabilities? Could you write it in a few lines instead of adding a dependency?
- Run dependency audits before deploy (`npm audit`, `pip-audit`, `cargo audit`). Fix critical and high severity issues.
- Enable secret scanning on the repository (GitHub secret scanning, plus gitleaks in the `check` command). A committed API key is compromised even if removed in the next commit.
- Pin CI action and base image versions. Pin GitHub Actions to a full commit SHA (`uses: actions/checkout@<40-char-sha> # v5.0.0`), not a mutable tag — tags can be moved to malicious code. Never use `latest` tags in production pipelines.

## Code Scanning

- Run static analysis (SAST) on your own code in the `check` command: the vibeArchitecture Semgrep rules, plus CodeQL (free for public GitHub repos) or Semgrep's own rules. Dependency scanning checks other people's code for known vulnerabilities; SAST checks yours for vulnerable patterns.
- At Public tier and above, treat new high-severity findings as merge blockers. This matters more for AI-generated code, not less — AI repeats the same plausible-looking mistakes, and SAST rules catch exactly those patterns.

## Automated Checks

See `guides/testing/automated-checks.md`. Set up with `vibeArchitecture/checks/install.sh`.

- One `check` command runs every automated check for the project's tier (secret scan, dependency audit, vibeArchitecture Semgrep rules, lint, tests). Git hooks, CI and the AI agent all call it; nothing re-implements it.
- Checks run in layers: pre-commit (seconds: secrets, formatting), pre-push (about a minute: lint, rules and tests on what changed), and before merge (everything). Only a server-side required check can't be skipped; Business tier and above must have one. Below that, a blocking pre-push hook is an acceptable gate.
- A task is done when `check push` exits 0. Never bypass or weaken a check to get there: no `--no-verify`, no skipped or deleted tests, no lowered thresholds, no edits to check config to make a failure pass. Fix the cause, or stop and ask.
- Existing findings go in a baseline with a reason and an expiry date; only new findings block, and the baseline only shrinks. Suppress a single finding inline with the rule id and a reason.
- Every fixed bug gets a test or check that fails on the broken version. Removing hosted CI is a migration: move each job into the local check or record the gap.

## Code Quality

- Functions do one thing. If you can't describe a function's purpose in one sentence, split it.
- Name things clearly. `calculateTotalPrice` beats `calc`. `userEmail` beats `x`.
- Avoid duplication — if you copy-paste the same logic three times, extract it. But don't over-abstract code used only once.
- Adopt the ecosystem's canonical linter and formatter (ESLint/Prettier, ruff, clippy + rustfmt, flutter_lints, golangci-lint) and treat new warnings in code you touch as blocking — even before CI enforces it. Lint rules encode exactly the plausible-looking mistakes AI-generated code repeats.
- Know the difference between free, self-assessable standards (OWASP ASVS, MASVS, WCAG, NIST SSDF) and paid certification-grade ones (FIPS 140-3, Common Criteria, a SOC 2 *audit*). Self-assess against the free ones now; pursue certification only when a buyer or regulator actually demands it.

## Operations

These are not tier-gated rules, but from Public tier upward the topics come up on every real deployment. Pointers, not padding:

- **Cost visibility.** Set a billing alert before the first deploy; know the two or three line items that can run away (egress, LLM tokens, storage). See `guides/operations/cost-management.md`.
- **Day-2 runbook.** Write down how to deploy, roll back, restore a backup, and rotate a secret before you need to do any of them under pressure. See `guides/operations/day2-operations.md`.
- **Email deliverability.** Transactional email (password resets, receipts) needs SPF, DKIM, and DMARC on the sending domain or it lands in spam. See `guides/operations/email-deliverability.md`.
- **Externalize user-facing strings.** Never hardcode text in templates, even for a single-language app; it is nearly free now and very expensive later. See `guides/operations/internationalization.md`.

## Working with AI Agents

- Review generated code before committing. AI produces plausible-looking code that can be subtly wrong.
- "It works on my machine" is not sufficient. Test with realistic data and conditions.
- If you don't understand what code does, ask the AI to explain it before committing.
- Be skeptical of AI-suggested architectural decisions. The AI optimizes for "getting it done" — these rules exist to also make sure it's done right.
- Verify exit codes, not pipes. `some-check | tail -1` returns *tail's* exit status, not the check's — a pipeline like that can mask a build-breaking failure while reporting success. Run gating checks bare and read the real status; a check whose exit code is consumed by a pipe is not a check.
- Commit both sides of code generation. When a tool generates code (API bindings, ORM clients, serializers), the generated output is committed together with its source, and CI verifies they match (regenerate and diff). Regenerating one side and forgetting the other breaks clean checkouts in ways that don't reproduce on the machine that made the change.
