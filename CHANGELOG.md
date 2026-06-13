# Changelog

All notable changes to vibeArchitecture are documented here. The framework uses [Semantic Versioning](https://semver.org/) for its documentation releases.

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
