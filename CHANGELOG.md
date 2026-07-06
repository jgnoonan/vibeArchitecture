# Changelog

All notable changes to vibeArchitecture are documented here. The framework uses [Semantic Versioning](https://semver.org/) for its documentation releases.

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
