# Changelog

All notable changes to vibeArchitecture are documented here. The framework uses [Semantic Versioning](https://semver.org/) for its documentation releases.

## [1.5.0] - 2026-08-27

Standards-refresh and agentic-security release: an end-to-end review of the framework against mid-2026 standards, correction of every verified defect, one new domain (agentic AI security), and tooling that catches drift automatically.

### Added

- **Agentic AI security** — new `guides/multi-agent/agentic-security.md` mapped to the OWASP Top 10 for Agentic Applications (2026), plus an "Agentic Systems" rule section in `rules/multi-agent.md`: agent identity and delegated scoped credentials (no shared master key), inter-agent trust boundaries, memory/context poisoning, tool-description poisoning and MCP server vetting, computer-use/browser agents, hard spend caps with a kill switch, loop caps, streaming (never act on a partial tool call), guardrail/moderation layer, prompt-caching cost mechanics; matching anti-patterns (The God Key, Trusting the Other Agent, Memory That Anyone Can Write, No Kill Switch)
- **MCP spec currency** (`guides/multi-agent/mcp-tool-patterns.md`) — revision 2026-07-28: OAuth 2.1 resource servers (RFC 9728/8707/9207), Dynamic Client Registration deprecated, tool annotations as untrusted hints, elicitation, structured output, tasks
- **Security rules and guide sections** (`rules/security.md`, `rules/api.md`, `guides/security/*`, `guides/api/*`): session fixation and log-out-everywhere, password-reset and email-change flows, account-enumeration defenses, NIST SP 800-63B-4 password policy, WebAuthn configuration, JWT validation per RFC 8725, OAuth per RFC 9700 / OAuth 2.1 with refresh-token rotation, DPoP, device authorization and token exchange flows, API key hygiene, multi-tenancy isolation (tenant_id + Postgres RLS), open redirect, prototype pollution, ReDoS, XXE/deserialization, request smuggling, cache poisoning/deception, GraphQL hardening, WebSocket Origin checks, `Idempotency-Key` storage rules, RFC 9457 Problem Details, IETF `RateLimit` headers, OpenAPI as contract, batch per-item authorization, outbound webhook signing, file-upload hardening (zip-slip, decompression bombs, polyglots, separate origin, presigned URLs), CSP nonces/`strict-dynamic`, COOP/CORP, subdomain takeover, secrets leaking through AI tool surfaces and client-exposed env prefixes
- **Mobile** (`rules/mobile.md`, `guides/security/mobile-security.md`): deep-link/Universal Link hijacking, PKCE via system browser, WebView hardening, Play Integrity / App Attest, biometric-bound Keychain items, screenshot/clipboard protection
- **Data and infrastructure** (`rules/data.md`, `rules/infrastructure.md`, `rules/reliability.md`, `rules/observability.md`, `rules/performance.md`, `rules/system-design.md` and guides): multi-tenancy, `timestamptz`/UTC and money rules, UUIDv7 primary keys, partial indexes, zero-downtime migration mechanics, transactional outbox, event sourcing/CQRS "don't by default", object storage with presigned URLs, CDN cache invalidation and `Cache-Control: private`, idempotency-key implementation, cron reliability (overlap locks, dead-man's switch), domain/DNS hygiene, build-image secrets, SLO error budgets and burn-rate alerts, trace sampling, chaos/game days, read-your-own-writes on replicas, feature-flag implementation, semantic/hybrid search with pgvector, Postgres-native queues, hard cloud spend caps
- **Compliance and privacy** (`rules/compliance.md`, `rules/privacy.md`): COPPA amended rule (compliance deadline 22 Apr 2026), US state AI laws (Colorado, Texas, California SB 243/SB 942, CCPA ADMT), EU AI Act timeline after the Digital Omnibus (Art. 50 transparency live 2 Aug 2026; high-risk deferred to Dec 2027 / Aug 2028), EU CRA reporting obligations from 11 Sep 2026, HIPAA Security Rule NPRM note, EU-US Data Privacy Framework, model-API data residency, Global Privacy Control, automated-decision rights, AI disclosure to all users at Public tier, training-data opt-out disclosure, NIST AI RMF / AI 600-1 and ISO/IEC 42001 references
- **Accessibility** (`rules/accessibility.md`, `guides/accessibility/accessibility-basics.md`): WCAG 2.2 AA target (2.4.11, 3.3.7, 3.3.8 Accessible Authentication, 2.5.8), EN 301 549, ADA Title II deadlines (Apr 2027 / Apr 2028), Section 508, CI accessibility gates
- **Standards mapping** (`appendices/standards-mapping.md`): OWASP Top 10 2025, OWASP LLM Top 10 2026, OWASP Agentic Top 10 2026, NIST AI RMF, ISO 42001, NIST SSDF v1.1 + SP 800-218A, SLSA v1.1, CIS Controls v8.1, GDPR/CCPA, EU CRA tables; MASVS-PLATFORM row corrected
- **Glossary**: MCP, RAG, embeddings/vector database, lethal trifecta, DPA, DPIA, SBOM, correlation ID, sandbox, SSRF, CSRF, passkey, agentic, tool poisoning
- **Operations guides** now reachable from `rules/universal.md` (Operations section) and `rules/_index.md`; `guides/operations/*` were previously orphaned
- **Checklists**: admin MFA, CSRF, fail-closed guards, migrate-twice test, loud skipped tests, RTO/RPO, keyless deploys, SHA-pinned Actions, adversarial review + assurance register, AI disclosure, CRA readiness, ADA Title II
- **Repo hygiene**: `SECURITY.md`, `.github/CODEOWNERS`, `.github/dependabot.yml`, issue and PR templates, `.editorconfig`, `.markdownlint.json`, `.lycheeignore`; CI now has least-privilege `permissions`, SHA-pinned actions, a weekly link check, a markdownlint job; `scripts/sync.sh` derives the rule list from `rules/*.md`, rejects unknown arguments, checks the skill version stamp and the 8,000-character GPT instruction limit
- Integrations: plain "Read `vibeArchitecture/ARCHITECT.md` first" line in `AGENTS.md` for tools that don't expand `@` imports; README rows for GitHub Copilot (`.github/copilot-instructions.md`), Gemini CLI (`GEMINI.md`), Windsurf, and any AGENTS.md-aware tool; Claude Code skill install path; "which option?" table and "project root" definition at the top of the README

### Changed

- **Claude/Cursor skill renamed** to `vibe-architecture` (directories `ClaudeSkill/vibe-architecture/`, `CursorSkill/vibe-architecture/`) to satisfy the Agent Skills naming rules; skill version stamp now tracked by `sync.sh`
- **Tier decisions made consistent across every file**: children's data → Regulated; admin MFA at Shared; login/signup/reset throttling at Shared (general API rate limiting at Public); encryption at rest at Business; secrets manager preferred at Shared and required at Business; JWT access tokens 15 min–1 h; ordinary GDPR/EU users → privacy overlay, not Regulated; critical downtime + sensitive data → Regulated; tier-upgrade logic identical in questionnaire, skill, tier definitions, BOOTSTRAP, and GPT
- **Password hashing**: argon2id first (bcrypt 72-byte limit noted); account lockout replaced by progressive per-IP + per-account throttling
- **Retries**: retry 5xx/429/408 honoring `Retry-After`; never other 4xx or 501/505 (was "never retry 4xx", contradicting the 429 rule)
- **Health checks**: shallow public liveness; deep dependency checks network-restricted
- **Alerting**: Page = >5% errors for 5 min; Ticket = sustained 1–5%, fix next business day (undefined band removed)
- **Decomposition signals**: guide aligned to the rule's four signals, "2+ → seriously evaluate; modular monolith first"
- **Composite-index rule** rewritten (equality before range, left-prefix) — "most selective column first" was wrong
- **Security headers**: CSP `frame-ancestors` primary, `X-Frame-Options` legacy fallback; Permissions-Policy in the baseline
- **CI pinning**: GitHub Actions by full commit SHA, not tag; `tfsec` dropped (merged into Trivy); "Terraform or OpenTofu"; "Redis or Valkey"
- **Tooling refresh**: Node 24/22 and Postgres 18 in examples; `npm ci --omit=dev`; Supavisor; Cloudflare TCP/Hyperdrive and Vercel Fluid Compute caveats; PlanetScale/Railway/AWS free-tier descriptions; Cloud Run functions; BullMQ; Microsoft Agent Framework replaces AutoGen; current agent SDKs listed; Outlook.com sender requirements; Gmail 0.1% spam target
- **Model references**: dated model IDs replaced with tier language plus one "example only" ID; fallback providers must be under the same DPA/BAA and residency constraints
- **Supply chain**: current incident examples (xz-utils, polyfill.io, tj-actions/changed-files, Shai-Hulud), npm trusted publishing, install cooldowns, `--ignore-scripts`, workflow `permissions:`
- **Rules layer compressed ~17%** (37.6K → 31.2K tokens across `rules/*.md`) by moving rationale, RFC lists, and regulatory timelines into the guides (notably a new "Regulatory Timelines (checked August 2026)" section in `guides/infrastructure/regulated-deployment.md` and "WCAG 2.2 Criteria Behind the Rules" in `guides/accessibility/accessibility-basics.md`); every rule line is preserved
- **Release procedure and local checks** documented in `CONTRIBUTING.md`; releases are tagged `vX.Y.Z` and ship a pre-built `vibe-architecture.zip`; README gains a "Coming from 1.4.0 or earlier" migration section
- **Deduplication**: single canonical homes for sessions-vs-JWT and token storage (`state-management.md`), prompt injection (`llm-security.md` LLM01), LLM-as-judge tips, budget alerts, retry/circuit-breaker config (`resilience-patterns.md`), idempotency (`concurrency.md`), alerting (`monitoring.md`), connection pooling (`database-performance.md`), incident lifecycle (`incident-response.md`); `regulated-deployment.md` no longer restates `rules/compliance.md`; the "confirm what's active" paragraph lives in `ARCHITECT.md`
- `ARCHITECTURAL_FRAMEWORK_OUTLINE.md` moved to `docs/history/` (it described a layout that never shipped and was the largest file at the repo root)
- README install guidance: copy-and-gitignore is the default, submodule the alternative (do not gitignore a submodule); Option B prompt uses the raw `BOOTSTRAP.md` URL; token-usage table re-measured; "What's Covered" lists every guide topic
- `BOOTSTRAP.md` and `CodeGuardian/gpt-instructions.md` condensed rules updated for 1.4.0 items that were missing (restart-safe migrations, loud skipped tests, exit codes, lock hierarchies, metadata-plane privacy) and for 1.5.0; GPT knowledge-file list now includes `rules/mobile.md`
- Intake: platform and downtime-impact questions asked everywhere the profile records them; Q0 wording unified; question list-order and duplicate step numbers fixed; AI SDK list refreshed

### Fixed

- `LICENSE`: copyright holder name and year corrected
- `guides/api/api-security.md`: same-origin policy explanation (SOP blocks reading responses, not sending them; CORS does not prevent CSRF); the real CORS bug is a reflected `Origin` with credentials, not `*` with credentials (also in `rules/security.md`, `rules/api.md`, `appendices/anti-patterns.md`)
- `guides/security/authentication.md`: in-memory JS tokens are not "safe from XSS"
- `guides/api/api-versioning.md`: `Sunset` takes an HTTP-date; `Deprecation` is RFC 9745 (`@unix-timestamp`)
- `guides/api/payments.md`: grant entitlement only when `payment_status == "paid"` or on `checkout.session.async_payment_succeeded`; PCI DSS 4.0.1 and SAQ A script-integrity requirements named
- `guides/infrastructure/containers.md`: multi-stage build no longer ships devDependencies
- `guides/performance/search-architecture.md`: `tsvector` column is now a generated column (the previous example never populated it)
- `guides/performance/database-performance.md`: Postgres syntax for the year example; `= ANY($1)` for large IN lists
- `guides/system-design/real-time-patterns.md`: cookies do work on the WebSocket handshake; the actual risk is cross-site WebSocket hijacking (validate `Origin`); `?token=` in URLs lands in logs; the six-connection limit is HTTP/1.1 only
- `guides/multi-agent/llm-architecture.md`: cost arithmetic; "log everything" contradiction with the observability rules; duplicate table rows
- `guides/multi-agent/testing-ai-systems.md`: tool-call checks are deterministic, tool-call decisions are not
- `guides/infrastructure/regulated-deployment.md`: Supabase BAA is Team plan and above; Render, Vercel, and Fly.io do offer BAAs on higher plans
- `rules/compliance.md`: HIPAA six-year rule applies to documentation, not audit logs; breach-notification thresholds; CRA timeline made concrete
- `rules/mobile.md`: AndroidX `EncryptedSharedPreferences` is deprecated; Sign in with Apple guideline 4.8 wording
- `guides/data/data-integrity.md`: soft delete does not satisfy GDPR/CCPA erasure (matches the rules)
- `appendices/glossary.md`: corrupted "Horizontal scaling"/"HSTS" and "Integration test"/"Jitter" entries repaired; alphabetical order restored
- `appendices/further-reading.md`: six Well-Architected pillars; Signal SPQR/Triple Ratchet; FIPS 205 and HQC; HTTPS link
- `examples/sample-PROJECT_PROFILE.md`: privacy overlay is on (it stores other people's names and emails)
- `intake/tier-definitions.md`: ordinary EU personal data no longer listed as Regulated; Shared tier no longer told it needn't worry about rate limiting

## [1.4.0] - 2026-07-29

Field-lessons release: distills recurring defect classes and verification practices from a year of adversarial reviews of production systems — including peer-to-peer and end-to-end-encrypted architectures — into rules, guides, and anti-patterns.

### Added

- **Fail-closed guards** (`rules/security.md` Authorization) — an errored authorization/validation check returns "denied," never "allowed"; matching **Fail-Open Guard** anti-pattern with code example
- **Device/session-scoped authorization** (`rules/security.md`) — client-supplied IDs (device, session, workspace) must be verified as belonging to the authenticated principal; the multi-device sibling of IDOR and a real account-takeover class in recovery flows
- **Self-attested data rules** (`rules/security.md` Input Validation) — never verify a signature against a key that arrived with the payload; validate untrusted input before it reaches a path, allocation, or decoder; matching **Trusting Self-Attested Data** anti-pattern
- **Cryptography section** (`rules/security.md`) and new **`guides/security/cryptography.md`** — established E2EE protocol patterns over invented ones, **hybrid post-quantum key agreement (X25519 + ML-KEM-768)** against harvest-now-decrypt-later, security-argument comments, anti-replay persistence, context binding, cryptographic deletion, out-of-band verification, and a practical note on formal verification (ProVerif/CryptoVerif)
- **Adversarial review method** — new **`guides/testing/adversarial-review.md`** (review by failure class, verify findings before believing them, close every finding or close it in writing, field-verify on devices) plus a "Reviewing an AI-Built Codebase" section in `rules/testing.md`; positioned as the solo developer's substitute for PR review
- **Assurance register template** (`appendices/assurance-register-template.md`) — the found/closed evidence table auditors and buyers actually ask for
- **Local-first & peer-to-peer guide** (`guides/system-design/local-first-and-p2p.md`) — key-loss recovery before launch, ciphertext backups, cryptographic deletion, multi-device as its own authorization plane, mobile-as-server realities, sync-conflict design
- **Metadata-plane privacy** (`rules/privacy.md` "If You Claim Privacy, Audit the Metadata") — operator threat model for privacy-marketed products, push payloads as third-party sharing, delete-don't-deprecate transition paths; companion "The Operator in the Mirror" section in `guides/security/threat-modeling.md`
- **Native mobile accessibility** (`rules/accessibility.md`) — Flutter/SwiftUI/Compose/React Native rules: accessible names, no bare gesture handlers, announced errors, computed contrast in both themes, 200% font-scale survival, 44pt/48dp targets, no unbounded animation
- **OWASP MASVS v2 mapping** (`appendices/standards-mapping.md` new section; baseline note in `rules/mobile.md`) — the mobile analog of ASVS, verified with MASTG
- **Push notification rules** (`rules/mobile.md`) — payloads transit APNs/FCM: opaque wake signals, content fetched on-device; push is best-effort
- **Restart-safe migrations** (`rules/data.md`) — startup-run migrations crash-loop production when they fail; guard re-run DDL, add a migrate-twice test, take an advisory lock for multi-instance startup
- **Silently-skipped tests** (`rules/testing.md`) — suites that skip without infrastructure read as green; make skips loud and confirm the database-backed tier actually ran
- **Toolchain and CI hygiene** (`rules/universal.md`) — lint/format gates as blocking; self-assessable vs. certification-grade standards distinction; **verify exit codes, not pipes** (with a matching anti-pattern); commit both sides of code generation with a CI drift check
- **Lock hierarchies** (`rules/reliability.md` Concurrency) — define one acquisition order across lock domains or never nest; matching **Lock-Order Inversion** anti-pattern
- **Localization working rules** (`guides/operations/internationalization.md`) — externalize user-visible strings (including accessibility labels) from day one; never extract log/developer strings; role-based key naming; machine-draft + native-review workflow

### Changed

- `BOOTSTRAP.md` condensed rules updated with fail-closed guards, device-scoped authorization, self-attested data, E2EE/post-quantum pointer, adversarial review at Business tier, and mobile push-payload + accessibility lines
- README coverage listing expanded (cryptography/E2EE/post-quantum, adversarial review, local-first/P2P, MASVS)

## [1.3.0] - 2026-07-16

Gap-analysis release: closes coverage gaps against OWASP Top 10 / ASVS / LLM Top 10 (2025), NIST SSDF, SLSA, CIS Controls, GDPR, the EU AI Act, and the EU Cyber Resilience Act.

### Added

- **SSRF rules** (`rules/security.md` Server-Side Requests) with attack explainer in `guides/security/input-validation.md` and an agent cross-reference in `rules/multi-agent.md`
- **MFA requirements** — mandatory for admin accounts at Shared tier and above; second-factor, recovery-code, and support-bypass guidance in `guides/security/authentication.md`
- **OAuth/OIDC flow rules** — authorization code flow with PKCE only, token validation, exact-match redirect URIs, `state` parameter
- **Mass assignment rules** (`rules/security.md`) and anti-pattern example (`appendices/anti-patterns.md`)
- **SAST requirements** (`rules/universal.md` Code Scanning) — CodeQL/Semgrep in CI, merge blockers at Public tier and above; setup guidance in `guides/security/supply-chain.md`
- **RTO/RPO disaster-recovery objectives** (`rules/reliability.md` Disaster Recovery)
- **GDPR lawful bases and DPIA guidance** (`rules/privacy.md` Lawful Basis section)
- **EU AI Act section** (`rules/compliance.md`) — transparency obligations, prohibited practices, provider vs. deployer, high-risk escalation
- **EU Cyber Resilience Act paragraph** (`rules/compliance.md`)
- **SBOM, artifact provenance, and SLSA** guidance (`guides/security/supply-chain.md`)
- **Agent execution isolation rules and the "lethal trifecta"** (`rules/multi-agent.md`, `guides/multi-agent/mcp-tool-patterns.md`, `guides/multi-agent/llm-security.md`)
- **OpenTelemetry as the Business-tier instrumentation standard** (`rules/observability.md`, `guides/observability/monitoring.md`)
- **IaC scanning rules** (`rules/infrastructure.md`) — Checkov/tfsec/Trivy in CI
- **Branch protection and PR review rules** (`rules/universal.md` Version Control)
- **Modern security headers** — `Referrer-Policy`, `Permissions-Policy`, `__Host-` cookie prefix, Subresource Integrity (`rules/security.md`)
- **Load testing requirement** at Business tier (`rules/testing.md`, `checklists/production-readiness.md`)
- **Field-level envelope encryption guidance** at Business tier (`rules/data.md`)
- **Standards traceability appendix** (`appendices/standards-mapping.md`) mapping rules to OWASP Top 10, ASVS v5, OWASP LLM Top 10, and NIST SSDF
- **Keyless CI/CD deploys** — OIDC federation preferred over long-lived cloud keys (`rules/infrastructure.md`, `guides/security/supply-chain.md`)

### Changed

- `rules/compliance.md` applicability widened: the EU AI Act section applies at Public tier and above whenever EU users interact with an AI feature (`rules/_index.md` and the skill manifest updated); everyday GDPR/CCPA obligations below Regulated tier live in the `rules/privacy.md` overlay
- Checklists (`before-you-deploy.md`, `production-readiness.md`) gained SAST, IaC scanning, and load-testing line items
- README token estimates updated for grown rules files; added an "Updating From a Previous Version" section
- `BOOTSTRAP.md` refreshed with condensed v1.3.0 rules; `scripts/sync.sh` now fails when the ARCHITECT.md and BOOTSTRAP.md version stamps drift

## [1.2.0] - 2026-07-06

### Added

- **Privacy overlay** (`rules/privacy.md`) — data-subject-rights rules (export, deletion, consent, retention) that load whenever the app stores personal data about other people or has EU/UK/California users, independent of tier. Fixes GDPR/CCPA being reachable only at Regulated tier.
- **Payments guide** (`guides/api/payments.md`) — webhook signature verification, granting access on the verified webhook (not the client redirect), idempotency, and PCI scope reduction. Matching rules added to `rules/api.md`.
- **Email deliverability guide** (`guides/operations/email-deliverability.md`) — SPF/DKIM/DMARC, transactional providers, and the 2024 Gmail/Yahoo bulk-sender requirements.
- **Serverless & edge guide** (`guides/infrastructure/serverless-and-edge.md`) — translates long-server reliability advice (graceful shutdown, two instances, connection pooling, in-memory rate limiting) to serverless/edge realities.
- **CSRF and abuse/bot controls** in `rules/security.md`; **passkeys/WebAuthn, magic links, and OAuth pitfalls** in `guides/security/authentication.md`; **dual-secret rotation** in `guides/security/secrets-management.md`.
- **App Store review** guidance in `guides/security/mobile-security.md` and **background jobs for solo/serverless** in `guides/system-design/async-patterns.md`.
- Biometric and children's-data tier triggers, and a user-region question, in the intake.

### Changed

- **OWASP LLM Top 10 updated to the 2025 list** (`guides/multi-agent/llm-security.md`) — adds System Prompt Leakage and Vector/Embedding Weaknesses, reframes Overreliance→Misinformation and Model DoS→Unbounded Consumption.
- `scripts/sync.sh` now also generates the Cursor `SKILL.md` and the derived integration files (`CLAUDE.md`, Android `AGENTS.md`, Cursor `.mdc`) from their canonical sources — closing the silent-drift gap. CI `--check` covers all of them.
- **BOOTSTRAP.md now applies the data-driven tier upgrades** (health→Regulated, payments→Business, etc.) it previously dropped, so the condensed path no longer under-tiers sensitive projects.
- `intake/tier-definitions.md` realigned with the rules' actual gating: testing at Shared, accessibility at Public, monitoring and deployment at Business (were mislabeled Public).
- Reconciled the forward-only vs. down-migration guidance and the soft-delete vs. real-deletion tension across `rules/data.md`, `rules/universal.md`, and the privacy overlay.
- Solo-operator alerting guidance in `rules/observability.md`; DPA/BAA rule for sending personal data to model providers in `rules/multi-agent.md`.
- README: softened the "prevents everything automatically" claim, added an Option B URL-fetch caveat, corrected the guide count, and expanded coverage/structure listings.

### Fixed

- GDPR/CCPA data-subject rights were unreachable through the intake (only health data routed to Regulated).
- `SKILL.md` and the integration entry-point files could drift silently — they were outside sync/CI coverage.

## [1.1.0] - 2026-06-13

### Added

- **Framework version** stamp in `ARCHITECT.md`
- **Cursor integration** via `integrations/cursor/vibeArchitecture.mdc` (modern `.cursor/rules/` format)
- **CursorSkill/** installable skill package (mirrors Claude Skill for Cursor IDE)
- **Mobile rules** (`rules/mobile.md`) and guide (`guides/security/mobile-security.md`)
- **Supply chain security** guide (`guides/security/supply-chain.md`) and expanded universal dependency rules
- **LLM security** guide mapping OWASP LLM Top 10 (`guides/multi-agent/llm-security.md`)
- **MCP / tool-use patterns** guide (`guides/multi-agent/mcp-tool-patterns.md`)
- **`scripts/sync.sh`** to keep skill references in sync with `rules/`
- **GitHub Actions** for sync validation and markdown link checking
- **`CHANGELOG.md`** for framework versioning

### Changed

- Renamed `PROJECT_PROFILE.md` → `PROJECT_PROFILE.template.md` (generated profiles still save as `PROJECT_PROFILE.md` in project roots)
- Updated all integration templates with production-readiness and incident checklists
- Integration templates (`CLAUDE.md`, `AGENTS.md`, Android Studio) now use `@./vibeArchitecture/ARCHITECT.md` import pattern
- Refreshed `BOOTSTRAP.md` with AI usage, experience level, and vibe-coding cost guidance
- Claude Skill and Cursor Skill now include `system-design.md` and conditional mobile rules
- Updated README and `integrations/README.md` with Cursor rules and Cursor Skill install steps
- Strengthened historical-only banner on `ARCHITECTURAL_FRAMEWORK_OUTLINE.md`
- CONTRIBUTING.md documents sync workflow for maintainers

### Fixed

- Claude Skill was missing `system-design.md` in `references/` (drift from main `rules/`)

## [1.0.0] - 2025

Initial public release: tiered rules, guides, intake questionnaire, checklists, IDE integrations, and Claude Skill.
