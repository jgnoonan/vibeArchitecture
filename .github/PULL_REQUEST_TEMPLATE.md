## What changed and why

<!-- One topic per PR. Say what improves for the reader or the AI, not just what moved. -->

## Checklist

- [ ] I edited the **canonical source** only (`rules/*.md`, `intake/tier-definitions.md`, `PROJECT_PROFILE.template.md`, `ClaudeSkill/vibe-architecture/SKILL.md`, `integrations/AGENTS.md`) and then ran `./scripts/sync.sh`
- [ ] `./scripts/sync.sh --check` passes locally
- [ ] `npx markdownlint-cli2 "**/*.md" "#node_modules"` passes locally (see "Local Checks" in CONTRIBUTING.md)
- [ ] If tier-determination logic changed: `intake/questionnaire.md`, `intake/tier-definitions.md`, `BOOTSTRAP.md`, `SKILL.md`, and `CodeGuardian/gpt-instructions.md` all agree
- [ ] New or changed internal paths exist (`ls` them)
- [ ] Factual, legal, or standards claims cite a source in the PR description
- [ ] Plain-language content stays jargon-free; rules files stay compact (see CONTRIBUTING.md)
