# Proposal: Progressive Guards

> **Status:** Proposed — not yet implemented.
> **Target:** 1.6.0
> **Date:** 2026-09-15

Enforcement that grows with the project: vibeArchitecture recommends automated guards at the moment the code first needs them, not only at project start.

---

## The Problem

The most common criticism of vibeArchitecture (VA) is that it front-loads its value. Intake, the tier decision, and the project profile happen once, in the first session. After that, everything VA contributes depends on the agent remembering to apply prose rules and surface checklists. Nothing VA provides runs outside the agent session, and nothing brings VA back into the project as the codebase changes.

The result: projects that follow VA still accumulate their real CI guards reactively — one incident at a time — even when VA's rules already described the risk.

### What exists today

- **CI advice is prose only.** Roughly 20 rules and checklist items describe automated checks (SAST, secret scanning, dependency audits, SHA pinning, migrate-twice, loud skipped tests, IaC scanning, accessibility gates, codegen drift). See [`rules/universal.md`](../rules/universal.md), [`rules/testing.md`](../rules/testing.md), [`rules/data.md`](../rules/data.md), and [`checklists/before-you-deploy.md`](../checklists/before-you-deploy.md). VA ships no workflow, hook, script, or test template for a consuming project.
- **Rules are not addressable.** Rules are markdown bullets under section headings with no IDs, severity, or per-rule tier tags. A check cannot cite the rule it enforces, and nothing can report which rules are enforced.
- **VA assumes hosted CI exists.** [`rules/testing.md`](../rules/testing.md) requires tests to run "automatically before deployment (CI pipeline)" at Public tier. Projects that deliberately run gates locally (cost, private repos, solo developers) are technically non-compliant for a reasonable choice.
- **No lifecycle hook for guards.** [`ARCHITECT.md`](../ARCHITECT.md) Step 4 surfaces checklists at milestones, but has no step that says "this change introduced a capability — add the guard for it."
- **No rule-to-check mapping.** The [assurance register](../appendices/assurance-register-template.md) has an "Other verification" table, but no place to record which rule is enforced by which check, where it runs, and whether it blocks.

---

## Evidence From the Field

A real Public-tier project built with VA (native mobile clients, a systems-language core, a small server fleet) was reviewed for this proposal. Over roughly ten weeks it accumulated about 25 automated guards. Findings:

1. **Nearly every guard was reactive.** Each traced to a specific incident or review finding — a push payload that leaked a phone number to a third-party transport, a migration that crash-looped production, a release binary that still contained a developer-only login path, a data-wipe path that destroyed a live encryption key, a health monitor that had been failing against a wrong endpoint since the day it was deployed.
2. **Most guards were generic.** Only 3–4 of the ~25 were truly project-specific. The rest apply to any project that has the same capability (migrations, release builds, logs, push notifications, crypto, destructive operations).
3. **VA already had rules for several of them** — but as prose, so nothing prompted the agent to turn the rule into a check when the relevant code first appeared.
4. **Hosted CI was removed for cost reasons** and replaced with a local gate runner plus a blocking pre-push hook. That worked well, but removing the workflow silently dropped SAST and secret scanning, with nothing local replacing them. VA had no guidance for this transition.
5. **Some rules stayed prose-only indefinitely** (e.g. "never use the raw debug print API", "commit both sides of codegen", lock ordering). No one noticed because nothing listed rules alongside their enforcement.
6. **The most valuable technique was the source-scanning test.** Without custom linters, the project enforced invariants with ordinary unit tests that read the project's own source or build manifest — each paired with a *negative control* proving the scan can fail. This pattern is portable to every stack and needs no CI infrastructure.

---

## Design Principles

- **Recommend at the moment of need.** A guard is proposed when the capability it protects first appears in the code — not in a day-one wall of checks the user will skip.
- **Host-agnostic.** A guard is a command with an exit code. It runs the same way from a pre-push hook, a hosted CI job, or a release script. Local gates are first-class, not a fallback.
- **One gate entry point.** Every guard is wired into a single gate script. CI (if any) calls the script; it never re-implements it.
- **Guards prove they can fail.** Every scanning guard ships with a negative control. A guard that silently scans nothing is worse than no guard.
- **Tier-scaled, never mandatory scaffolding.** Personal tier gets suggestions; Public tier and above get recommendations the agent actively raises; nothing is forced into a project without the user agreeing.
- **Incidents become guards.** Every fixed bug is an opportunity to add the check that would have caught it.

---

## Proposed Changes

### 1. Guard catalog — new `guards/` directory

A catalog of reusable guards, one file per guard (or one file per category, grouped). Each entry has a fixed structure so agents can match and apply it:

```markdown
## G-LOG-NO-PII — No personal data in server logs

- **Enforces:** rules/privacy.md (If You Claim Privacy, Audit the Metadata) · rules/observability.md (Structured Logging)
- **Tier:** Shared+ (suggest) · Public+ (recommend)
- **Trigger:** first server-side log call that takes a user identifier, phone,
  email, or message content as a parameter
- **Runs in:** gate (pre-push / CI)
- **Blocks:** yes
- **Technique:** source-scanning test over log helper signatures
- **Negative control:** a fixture or known-bad helper the scan must flag
- **Templates:** Rust · TypeScript · Python · Dart · Go
- **Why:** logs are retained for weeks and aggregated; a log of who-contacted-whom
  is a metadata record the privacy policy likely says does not exist.
```

Templates are short and copy-pasteable. The catalog also includes a **technique** section documenting the source-scanning-test pattern once (read source or manifest → assert invariant → assert the scan found at least one target → negative control), so individual guards can reference it instead of repeating it.

### 2. Trigger-based recommendation

The heart of the proposal. Each guard declares a trigger — a code signal the agent can recognize while it is writing or reviewing the change. When the agent introduces or observes a trigger, it proposes the matching guard in the same change.

| When this first appears in the code… | …VA proposes |
|---|---|
| Any code at all (Shared+) | Gate runner, pre-push hook, blocking lint/format, dependency audit, secret scan |
| First database migration | Migrate-twice test; fail loudly when DB-backed tests skip |
| First codegen step (API bindings, ORM, FFI bridges) | Codegen drift check (regenerate and diff) |
| A developer-only feature, flag, or endpoint | "Not reachable in release" guard, asserted on the build manifest or artifact |
| First log call handling user identifiers or content | No-PII-in-logs guard |
| First push notification, email, SMS, or webhook to a third party | Payload allowlist guard (no content or identity in third-party transports) |
| First crypto library dependency | Import-boundary guard: only one module may import crypto primitives |
| Any delete, wipe, key-destroy, or reset code path | Tests for the guard logic on the irreversible action |
| Developer tools that destroy data (reset scripts, seeders) | Allowlist guard — tools refuse targets not on an explicit list |
| Admin or operator commands | Capability guard — operator paths cannot reach user-secret derivation |
| First release build script | Release packaging guard: version monotonic, not debug-signed, no dev endpoints in the artifact, SBOM produced |
| First deploy script that restarts a service | Validate config before restart; post-deploy health check fails the deploy |
| First health monitor or alert | Prove the monitor passes against a healthy target before trusting it |
| First backup job | Scheduled restore drill with a logged PASS/FAIL |
| User-facing strings in more than one locale | Localization completeness guard |
| User-facing UI (Public+) | Automated accessibility gate |
| Decoders or parsers for untrusted input | Fuzz target (advisory, not gating) |

### 3. Host-agnostic gate runner

VA ships stack-neutral templates:

- **`gates.sh` template** — runs each guard bare (no pipes masking exit codes), records which gates ran, writes a dated log as evidence, and exits non-zero on any failure.
- **Pre-push hook template** — calls the gate script; supports a logged emergency bypass (e.g. `GATES_SKIP=1` appends to a skips log); clears inherited git environment variables so tools behave the same from worktrees.
- **Optional CI wrapper** — a minimal, SHA-pinned, least-privilege GitHub Actions workflow that runs the same `gates.sh`. Other CI providers follow the same shape.

**Rule wording change.** Replace "must run in CI" with "must pass an automated gate before merge/deploy (hosted CI or a blocking local gate)". Affected: [`rules/testing.md`](../rules/testing.md) (Test Expectations by Tier), [`rules/universal.md`](../rules/universal.md) (Code Scanning), [`rules/accessibility.md`](../rules/accessibility.md), [`rules/infrastructure.md`](../rules/infrastructure.md), [`checklists/production-readiness.md`](../checklists/production-readiness.md), and the condensed equivalents in [`BOOTSTRAP.md`](../BOOTSTRAP.md).

**New rule: removing CI is a migration, not a deletion.** When a project removes hosted CI, every job must be accounted for — moved into the local gate, or explicitly accepted as a gap in the register. SAST and secret scanning in particular must have a local replacement (e.g. Semgrep and gitleaks in the pre-push gate).

### 4. Lifecycle integration

**[`ARCHITECT.md`](../ARCHITECT.md) Step 4 — add a guard check:**

> When a change introduces a capability listed in the guard catalog triggers, propose the matching guard in the same change. Explain what it protects in one sentence. If the user declines, record it as an accepted gap.

**Guard audit (on demand, and at existing milestones).** A new mode in the Claude and Cursor skills, also invocable by asking "run a guard audit":

1. Read `PROJECT_PROFILE.md` for tier and overlays.
2. Scan the repo for trigger signals (migrations, release scripts, crypto dependencies, log helpers, push senders, destructive paths).
3. Inventory existing guards (gate script, hooks, CI workflows, source-scanning tests, lint config strictness).
4. Output a gap list: *trigger present → recommended guard → missing / present / present-but-not-blocking*.
5. Flag drift: rules the profile claims are enforced but no check backs, and checks that exist but are not wired into the gate.

The audit runs automatically alongside the existing milestone checklists: [`before-you-deploy.md`](../checklists/before-you-deploy.md) and [`production-readiness.md`](../checklists/production-readiness.md) each gain a "run a guard audit" item.

**Existing-project intake.** The "Existing Project Analysis" in [`intake/questionnaire.md`](../intake/questionnaire.md) already looks for CI config; it gains a guard-audit pass so existing projects start with a gap list instead of only a prose gap assessment.

### 5. Guard register

Add a **Guards** section to the [assurance register template](../appendices/assurance-register-template.md) (and a pointer from [`PROJECT_PROFILE.template.md`](../PROJECT_PROFILE.template.md)):

| Rule | Guard | Runs in | Blocks | Last run | Notes |
|---|---|---|---|---|---|
| universal: secret scanning | G-SECRETS (gitleaks) | pre-push | yes | log link | |
| data: restart-safe migrations | G-MIGRATE-TWICE | gate (DB tier) | yes | log link | fails if DB tier skipped |
| house: no raw debug print | — | — | — | — | **prose only — gap** |

Rows for project-specific ("house") rules are encouraged. The point of the table is to make *prose-only* rules visible.

Optionally, [`appendices/standards-mapping.md`](../appendices/standards-mapping.md) gains an "Automatable guard" column so standards controls (SSDF, SLSA, ASVS, MASVS) link to the guards that evidence them.

### 6. Incident → guard loop

[`checklists/something-broke.md`](../checklists/something-broke.md) Step 6 (After It's Fixed) gains:

> Write the guard that would have caught this — a test, scan, or gate check that fails on the broken version and passes on the fix. Include a negative control. Add it to the gate and the guard register. If a catalog guard already covered this, note that it was missing and why.

### 7. Rule IDs (scoped)

Guards need stable references. Rather than numbering all ~640 rule bullets, add short anchors only to rules that have at least one guard (e.g. `<a id="U-SECRETS"></a>` or a trailing `[U-SECRETS]` tag). The set grows as the catalog grows. `scripts/sync.sh --check` verifies every guard's `Enforces:` reference resolves to an existing rule anchor.

---

## Seed Catalog

Initial guards, drawn from the field evidence and existing VA rules. All generic.

| ID | Guard | Default tier | Enforces |
|---|---|---|---|
| G-GATE-RUNNER | Single gate script + blocking pre-push hook with logged bypass | Shared+ | universal (toolchain hygiene) |
| G-EXIT-CODES | Gates run bare; no pipes masking exit codes | Shared+ | universal (verify exit codes) |
| G-LINT-BLOCKING | Canonical linter/formatter at warnings-as-errors | Shared+ | universal (code quality) |
| G-DEP-AUDIT | Dependency audit on every lockfile; exceptions need a written reason | Shared+ | universal (dependencies) |
| G-SECRETS | Secret scan (gitleaks / truffleHog) | Shared+ | universal (dependencies) |
| G-SAST | SAST (Semgrep / CodeQL); new high findings block | Public+ | universal (code scanning) |
| G-CODEGEN-DRIFT | Regenerate and diff generated code | Shared+ | universal (codegen) |
| G-MIGRATE-TWICE | Apply all migrations twice on a real DB | Shared+ | data (migrations) |
| G-TIER-RAN | DB/integration suites fail loudly when skipped | Shared+ | testing (skipped tests) |
| G-RELEASE-NO-DEBUG | Dev features/endpoints unreachable in release, asserted on manifest | Public+ | security, mobile |
| G-ARTIFACT-SCAN | Built artifact contains no localhost/dev endpoints or debug config | Public+ | security, mobile |
| G-LOG-NO-PII | No personal data or content in server logs | Shared+ | privacy, observability |
| G-TRANSPORT-ALLOWLIST | Third-party push/email/webhook payloads use an allowlist of keys | Public+ | privacy |
| G-IMPORT-BOUNDARY | Sensitive libraries (crypto, raw SQL, network) imported in one module only | Public+ | security, system-design |
| G-DESTRUCTIVE-TESTS | Guard logic on wipe/delete/key-destroy paths is unit tested | Shared+ | reliability, data |
| G-DEVTOOL-ALLOWLIST | Destructive dev tools refuse targets not on an allowlist | Shared+ | operations |
| G-OPERATOR-CAPABILITY | Admin paths cannot reach user-secret derivation | Business+ | security |
| G-RELEASE-PACKAGING | Version monotonic, release-signed, production push environment | Public+ | mobile, infrastructure |
| G-SBOM | SBOM generated per release | Public+ | security (supply chain) |
| G-CONFIG-VALIDATE | Validate service config before restart | Shared+ | infrastructure |
| G-DEPLOY-HEALTH | Post-deploy health check fails the deploy | Public+ | reliability |
| G-MONITOR-PROVEN | Monitors verified against a healthy target | Public+ | observability |
| G-RESTORE-DRILL | Scheduled restore drill with logged result | Business+ | reliability, data |
| G-L10N-COMPLETE | Every key present in every locale; no placeholder-only strings | Public+ | accessibility |
| G-A11Y-GATE | Automated accessibility checks on user-facing UI | Public+ | accessibility |
| G-FUZZ-UNTRUSTED | Fuzz targets for decoders of untrusted input (advisory) | Public+ | security |

---

## Files Changed

| File | Change |
|---|---|
| `guards/` (new) | Catalog, technique page, per-stack templates, `gates.sh` and pre-push hook templates, optional CI wrapper |
| [`ARCHITECT.md`](../ARCHITECT.md) | Step 4 guard check; guard audit mode |
| [`BOOTSTRAP.md`](../BOOTSTRAP.md) | Condensed guard check + host-agnostic gate wording |
| [`rules/_index.md`](../rules/_index.md) | Enforcement section: guards and the register, not only conversation |
| [`rules/testing.md`](../rules/testing.md), [`rules/universal.md`](../rules/universal.md), [`rules/accessibility.md`](../rules/accessibility.md), [`rules/infrastructure.md`](../rules/infrastructure.md) | "Automated gate" wording; CI-removal rule; anchors on guarded rules |
| [`checklists/something-broke.md`](../checklists/something-broke.md) | Incident → guard step |
| [`checklists/before-you-deploy.md`](../checklists/before-you-deploy.md), [`checklists/production-readiness.md`](../checklists/production-readiness.md) | "Run a guard audit" item |
| [`appendices/assurance-register-template.md`](../appendices/assurance-register-template.md) | Guards table |
| [`PROJECT_PROFILE.template.md`](../PROJECT_PROFILE.template.md) | Gate runner field (hosted CI / local / none) + pointer to guard register |
| [`intake/questionnaire.md`](../intake/questionnaire.md) | Guard-audit pass in Existing Project Analysis |
| `ClaudeSkill/`, `CursorSkill/` | Guard check in the build step; guard audit mode; `guards/` shipped as references |
| `CodeGuardian/` | Condensed guard check within the 8,000-character limit |
| [`scripts/sync.sh`](../scripts/sync.sh) | Propagate `guards/` to skill references; verify guard → rule anchors resolve |

---

## Rollout

1. **Phase 1 — catalog and gate runner.** `guards/` with the seed catalog and technique page, `gates.sh` / pre-push / CI-wrapper templates, and the host-agnostic rule wording. Immediately useful even without lifecycle changes.
2. **Phase 2 — lifecycle.** Guard check in `ARCHITECT.md`, `BOOTSTRAP.md`, and both skills; guard audit mode; checklist items; incident → guard loop.
3. **Phase 3 — traceability.** Rule anchors for guarded rules, the guard register, standards-mapping column, and `sync.sh` reference checks.

Validate each phase against at least one existing VA-based project by running a guard audit and checking the gap list against what that project actually learned the hard way.

---

## Open Questions

- **Templates per stack.** Which stacks get first-class templates in Phase 1? Proposal: TypeScript/Node, Python, Rust, Dart/Flutter, Go — matching the linters already named in `rules/universal.md`.
- **Deterministic audit.** Should the guard audit stay agent-driven (portable, zero install) or also ship a script that detects triggers mechanically? Proposal: agent-driven first; script only if audits prove inconsistent.
- **Tier defaults.** Should Shared tier get the gate runner by default, or only a suggestion? Solo projects benefit most from a pre-push hook, but it is also where friction is least tolerated.
- **GPT budget.** How much of the guard check fits in the CodeGuardian 8,000-character limit?
- **Catalog growth.** Accept community-contributed guards via `CONTRIBUTING.md`, with the same "generic, with a negative control, with a why" bar?

## Non-Goals

- VA does not become a CI product or ship a runner, action, or hosted service.
- VA does not require hosted CI at any tier.
- Guards are never added to a project without the user agreeing; declined guards are recorded, not forced.
- Project-specific incident details from field projects are never copied into the catalog — only the generic pattern.
