## What changed and why

<!-- One topic per PR. Say what improves for the reader or the AI, not just what moved. -->

## Checklist

- [ ] I edited the **canonical source** only (`rules/*.md`, `intake/tier-definitions.md`, `PROJECT_PROFILE.template.md`, `ClaudeSkill/vibe-architecture/SKILL.md`, `integrations/AGENTS.md`) and then ran `./scripts/sync.sh`
- [ ] `./scripts/sync.sh --check` passes locally
- [ ] New or changed rule bullets are classified in `rules/verification.toml` (`python3 scripts/verify-matrix.py` passes)
- [ ] New or changed Semgrep rules cite `metadata.va_rules` and have firing and quiet fixtures (`python3 scripts/test-semgrep-rules.py` passes)
- [ ] `npx markdownlint-cli2 "**/*.md" "#node_modules"` passes locally (see "Local Checks" in CONTRIBUTING.md)
- [ ] If tier-determination logic changed: `intake/questionnaire.md`, `intake/tier-definitions.md`, `BOOTSTRAP.md`, and `SKILL.md` all agree
- [ ] New or changed internal paths exist (`ls` them)
- [ ] Factual, legal, or standards claims cite a source in the PR description
- [ ] Plain-language content stays jargon-free; rules files stay compact (see CONTRIBUTING.md)
