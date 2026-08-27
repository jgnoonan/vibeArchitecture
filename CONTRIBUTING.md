# Contributing to vibeArchitecture

Thank you for your interest in improving vibeArchitecture. This framework exists to help people build better software with AI, and community contributions make it stronger.

## How to Contribute

### Reporting Issues

- **Incorrect or outdated advice** — If a rule, guide, or recommendation is wrong, misleading, or outdated, open an issue describing the problem and suggesting a correction.
- **Missing topics** — If there's an important architectural concern not covered, open an issue describing what's missing and why it matters.
- **Language clarity** — If something uses jargon without explanation or is confusing to a non-technical reader, that's a bug. Report it.
- **Broken links or formatting** — Small fixes matter. Report them or submit a PR directly.

### Submitting Changes

1. Fork the repository
2. Create a branch for your change (`git checkout -b improve-security-guide`)
3. Make your changes to the **canonical source only** (see "Canonical sources" below)
4. If you edited any canonical source, run `./scripts/sync.sh` to regenerate the derived files
5. Run `./scripts/sync.sh --check` to verify everything is in sync before opening a PR (CI runs this too)
6. Submit a pull request with a clear description of what you changed and why

### Canonical sources and what they generate

`scripts/sync.sh` keeps derived copies in lockstep with these canonical files — **edit the canonical file, never the generated copy:**

| Canonical source | Generates |
|------------------|-----------|
| `rules/*.md` (all except `_index.md`) | `{Claude,Cursor}Skill/vibe-architecture/references/*.md` |
| `intake/tier-definitions.md` | both skills' `assets/tier-definitions.md` |
| `PROJECT_PROFILE.template.md` | both skills' `assets/project-profile-template.md` |
| `ClaudeSkill/vibe-architecture/SKILL.md` | `CursorSkill/vibe-architecture/SKILL.md` (Claude body + Cursor install appendix) |
| `integrations/AGENTS.md` | `integrations/CLAUDE.md`, `integrations/android-studio/AGENTS.md`, `integrations/cursor/vibeArchitecture.mdc` |

`integrations/cursorrules` is intentionally **not** generated — the legacy (deprecated) `.cursorrules` format can't use the `@./…` import, so it's a small standalone file maintained by hand. Note that `@./…` imports are a Claude Code / Gemini CLI feature, not a universal one; that's why `integrations/AGENTS.md` opens with a plain-text "read `vibeArchitecture/ARCHITECT.md`" line that every tool understands.

The intake logic exists in five places — the full `intake/questionnaire.md`, `intake/tier-definitions.md`, the condensed `BOOTSTRAP.md`, the `SKILL.md` package (Cursor copy is generated), and `CodeGuardian/gpt-instructions.md`. These are not auto-synced; if you change tier-determination logic, update all of them together. `scripts/sync.sh --check` also verifies that the version stamps in `ARCHITECT.md`, `BOOTSTRAP.md`, and `SKILL.md` agree and that the GPT instructions stay under the 8,000-character limit.

### What Makes a Good Pull Request

- **One topic per PR.** A PR that fixes a typo in the glossary and rewrites the caching guide should be two separate PRs.
- **Explain the "why."** Don't just say what you changed — explain why the change improves the framework.
- **Respect the audience.** This framework is written for people who may not have a software engineering background. Technical accuracy matters, but so does accessibility.

### Signed commits (maintainers)

This project recommends **verified signed commits** on `main` — a reasonable trust signal for a security-focused framework. Contributors are not required to sign, but maintainers should sign when possible.

To enable locally, see GitHub's guide: [Signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits). SSH signing (`git config gpg.format ssh`) is the simplest path on modern macOS.

To require verified commits on the default branch, a repo admin can enable **Branch protection → Require signed commits** in GitHub repository settings.

## Local Checks

CI runs three jobs on every push and pull request (`.github/workflows/validate.yml`). Run the same checks locally before opening a PR:

| Check | Command | Notes |
|-------|---------|-------|
| Sync + version stamps + GPT length | `./scripts/sync.sh --check` | Bash 3.2 compatible; no dependencies |
| Markdown lint | `npx markdownlint-cli2 "**/*.md" "#node_modules"` | Uses `.markdownlint.json`; needs Node (`npx` fetches the tool on first run) |
| Link check (optional) | `lychee --no-progress --exclude-loopback --exclude 'mailto:*' '**/*.md'` | Only if [lychee](https://github.com/lycheeverse/lychee) is installed (`brew install lychee`); `.lycheeignore` lists URLs CI can't verify. CI also runs this weekly to catch link rot |

All GitHub Actions in the workflow are pinned to a full commit SHA (with the version tag in a trailing comment). Dependabot (`.github/dependabot.yml`) opens a weekly PR when a pinned action has a newer release — review the diff and merge; don't hand-edit the SHA.

## Release Procedure (maintainers)

Releases are tagged `vX.Y.Z` and follow [Semantic Versioning](https://semver.org/): patch for corrections, minor for new rules/guides or changed tier logic, major only if the file layout or integration contract changes in a way that breaks existing installs.

1. **Bump the three version stamps** — the `**Framework version:**` line in `ARCHITECT.md`, `BOOTSTRAP.md`, and `ClaudeSkill/vibe-architecture/SKILL.md` (the Cursor `SKILL.md` is regenerated). `./scripts/sync.sh --check` fails if any of them disagree.
2. **Update the condensations** — `BOOTSTRAP.md` and `CodeGuardian/gpt-instructions.md` are hand-maintained summaries of the rules. Fold in every rule change that matters at intake or in the first session, then confirm `gpt-instructions.md` is still under 8,000 characters (`wc -m CodeGuardian/gpt-instructions.md`; `sync.sh --check` enforces the limit).
3. **Re-measure the README token table** ("Token Usage" under *For developers*). Tokens are estimated as file bytes ÷ 4, summed over the rule files each tier loads (`rules/_index.md` lists them):
   ```bash
   for f in rules/*.md; do printf "%-28s %6d\n" "$f" $(( $(wc -c < "$f") / 4 )); done
   ```
   Update the per-tier totals, the conditional-set line, and the "Measured … at release X.Y.Z" sentence.
4. **Sync and verify** — `./scripts/sync.sh`, then `./scripts/sync.sh --check`, then `npx markdownlint-cli2 "**/*.md" "#node_modules"` (see Local Checks).
5. **Write the CHANGELOG entry** — a new `## [X.Y.Z] - YYYY-MM-DD` section at the top of `CHANGELOG.md` with Added / Changed / Fixed subsections. Note anything users must do by hand (renamed files, new profile fields, integration files to re-copy) so the README's "Updating From a Previous Version" table can point at it.
6. **Commit and tag** — commit on `main` (signed if you can), then:
   ```bash
   git tag vX.Y.Z
   git push origin main --tags
   ```
7. **Build the skill ZIP** — zip the Claude skill folder so `SKILL.md` sits at `vibe-architecture/SKILL.md` inside the archive (Claude.ai rejects a ZIP whose top level is loose files):
   ```bash
   (cd ClaudeSkill && zip -r ../vibe-architecture.zip vibe-architecture -x '*.DS_Store')
   unzip -l vibe-architecture.zip | head   # first entry must be vibe-architecture/
   ```
   Don't commit the ZIP; it's a release asset only.
8. **Create the GitHub Release** for the tag, paste the CHANGELOG entry as the body, and attach `vibe-architecture.zip`. With the GitHub CLI:
   ```bash
   gh release create vX.Y.Z vibe-architecture.zip --title "vX.Y.Z" --notes-file <(sed -n '/^## \[X.Y.Z\]/,/^## \[/p' CHANGELOG.md | sed '$d')
   ```
9. **Update the GPT** — follow the update procedure in `CodeGuardian/README.md` (diff the two tags to see which knowledge files changed, re-upload those, paste the refreshed instructions, test one intake conversation).
10. **Announce** — the README "Updating From a Previous Version" table should already describe any manual migration steps; if not, add them now and push a follow-up commit.

## Writing Standards

All content in vibeArchitecture follows these principles:

### For User-Facing Content (checklists, intake, tier definitions)

- **Zero jargon.** Every term should be understandable by someone who has never worked in software engineering.
- **Conversational tone.** Write as if you're explaining something to a smart friend over coffee.
- **Actionable.** Every item should tell the reader what to do or decide, not just what to know.

### For AI-Facing Content (rules)

- **Compact.** Rules files are loaded into AI context windows. Every line counts. No filler, no repetition, no lengthy introductions.
- **Direct.** State the rule, then state the consequence of breaking it. One to three lines per rule.
- **Technical terms are acceptable** since the AI understands them, but include instructions to explain in plain language when communicating with the user.

### For Guides (detailed explanations)

- **Explain the "why."** These exist to answer "why does this rule exist?" Lead with the reasoning, not the instruction.
- **Use analogies.** Good analogies make abstract concepts concrete. The textbook-index analogy for database indexes, the ship-bulkhead analogy for isolation — these help non-technical readers build mental models.
- **Include tradeoffs.** Don't pretend there's always one right answer. When there are real tradeoffs, present them honestly and make a recommendation.
- **Examples matter.** Show what bad code looks like and what good code looks like. Code examples should be language-agnostic or use the most commonly understood language for the concept.

### For All Content

- **Opinionated with escape hatches.** State the default clearly. Then briefly note when the default doesn't apply.
- **No padding.** If a sentence doesn't add information, cut it.
- **Token budget awareness.** Rules files should stay under 120 lines. Guides should stay under 300 lines. If a topic needs more space, consider splitting it into two files.

## Structure Conventions

- **Rules files** go in `rules/` and are named for their domain: `security.md`, `data.md`, etc. This is the **canonical source** for rule content.
- **Claude Skill and Cursor Skill** (`ClaudeSkill/vibe-architecture/`, `CursorSkill/vibe-architecture/`) `references/` directories are **generated** from `rules/` via `./scripts/sync.sh` — edit `rules/` first, then sync. The same script also generates the Cursor `SKILL.md` and the derived integration files (see "Canonical sources" above).
- **Guide files** go in `guides/{domain}/` and are named for their specific topic: `guides/security/authentication.md`.
- **Each rules file references its corresponding guides** with a note at the top: `> For detailed explanations: see guides/{domain}/`
- **Each guide starts with a note** explaining when to read it: `> This guide explains... Read it when...`

## Tier System

When adding or modifying rules, respect the tier system:

- **Universal** — applies to all projects, no exceptions
- **Shared** — adds security, data integrity, and testing basics
- **Public** — adds API hardening and accessibility
- **Business** — adds reliability, infrastructure, observability, performance, and deployment automation
- **Regulated** — adds compliance-specific requirements

There is also a **privacy overlay** (`rules/privacy.md`) that is not a tier: it loads whenever the app stores personal data about other people, or has EU/UK/California users, from Shared upward. Keep tier gating consistent across `rules/*.md` (`Applies to:` header), `rules/_index.md`, `intake/tier-definitions.md`, `intake/questionnaire.md`, `BOOTSTRAP.md`, and the README tier table — these must agree.

If a rule only matters for projects with paying customers, it belongs in Business tier or above — not in Universal. Overloading lower tiers with unnecessary rules defeats the purpose of the tiering system.

## Questions?

Open an issue using the "Question" template (it applies the "question" label). We're happy to discuss contributions before you invest time writing them.
