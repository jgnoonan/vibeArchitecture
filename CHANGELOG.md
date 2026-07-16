# Changelog

All notable changes to vibeArchitecture are documented here. The framework uses [Semantic Versioning](https://semver.org/) for its documentation releases.

## [1.2.0] - 2026-07-16

Gap-analysis release: closes coverage gaps against OWASP Top 10 / ASVS / LLM Top 10 (2025), NIST SSDF, SLSA, CIS Controls, GDPR, the EU AI Act, and the EU Cyber Resilience Act.

### Added

- **SSRF rules** (`rules/security.md` Server-Side Requests) with attack explainer in `guides/security/input-validation.md` and an agent cross-reference in `rules/multi-agent.md`
- **MFA requirements** — mandatory for admin accounts at Shared tier and above; second-factor, recovery-code, and support-bypass guidance in `guides/security/authentication.md`
- **OAuth/OIDC flow rules** — authorization code flow with PKCE only, token validation, exact-match redirect URIs, `state` parameter
- **Mass assignment rules** (`rules/security.md`) and anti-pattern example (`appendices/anti-patterns.md`)
- **SAST requirements** (`rules/universal.md` Code Scanning) — CodeQL/Semgrep in CI, merge blockers at Public tier and above; setup guidance in `guides/security/supply-chain.md`
- **RTO/RPO disaster-recovery objectives** (`rules/reliability.md` Disaster Recovery)
- **GDPR lawful bases and DPIA guidance** (`rules/compliance.md` GDPR section)
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

- `rules/compliance.md` applicability widened: the GDPR and EU AI Act sections now apply at Public tier and above whenever the app serves EU users (`rules/_index.md` and both skill manifests updated)
- Checklists (`before-you-deploy.md`, `production-readiness.md`) gained SAST, IaC scanning, and load-testing line items
- README token estimates updated for grown rules files
- `BOOTSTRAP.md` refreshed with condensed v1.2.0 rules; `scripts/sync.sh` now fails when the ARCHITECT.md and BOOTSTRAP.md version stamps drift

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
