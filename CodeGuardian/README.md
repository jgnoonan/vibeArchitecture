# Vibe Code Guardian (ChatGPT GPT)

Configuration for the [Vibe Code Guardian](https://chatgpt.com/g/g-69cd25c7200c8191938a6de92ddc56fb-vibe-code-guardian) GPT — the zero-setup ChatGPT form of vibeArchitecture (Option A in the README).

The GPT is configured manually at chatgpt.com and does **not** update from this repo. This directory is the version-controlled source of truth for what's uploaded there. When the framework releases a new version, update the GPT from these files and the manifest below.

## Instructions

`gpt-instructions.md` — paste into the GPT builder's **Instructions** field. Must stay under ChatGPT's 8,000-character limit (`scripts/sync.sh --check` enforces this). It is a condensation of `BOOTSTRAP.md` adapted for the GPT format; when `BOOTSTRAP.md` changes materially, re-condense.

## Knowledge files (20-file limit)

ChatGPT GPTs allow at most 20 knowledge files. Upload these, exactly:

| # | Upload from | Why |
|---|-------------|-----|
| 1 | `rules/universal.md` | All tiers |
| 2 | `rules/security.md` | Shared+ |
| 3 | `rules/data.md` | Shared+ |
| 4 | `rules/testing.md` | Shared+ |
| 5 | `rules/privacy.md` | Privacy overlay |
| 6 | `rules/api.md` | Public+ |
| 7 | `rules/accessibility.md` | Public+ |
| 8 | `rules/reliability.md` | Business+ |
| 9 | `rules/infrastructure.md` | Business+ |
| 10 | `rules/observability.md` | Business+ |
| 11 | `rules/performance.md` | Business+ |
| 12 | `rules/mobile.md` | Conditional (native mobile) |
| 13 | `rules/multi-agent.md` | Conditional (AI usage) |
| 14 | `intake/tier-definitions.md` | Intake |
| 15 | `intake/questionnaire.md` | Intake |
| 16 | `checklists/before-you-build.md` | Checklist |
| 17 | `checklists/before-you-deploy.md` | Checklist |
| 18 | `checklists/production-readiness.md` | Checklist |
| 19 | `checklists/something-broke.md` | Checklist |
| 20 | `appendices/anti-patterns.md` | Reference |

Not uploaded (over the limit — deliberate omissions): `appendices/glossary.md` (the instructions already require plain language), `rules/compliance.md` and `rules/system-design.md` (Regulated-tier and experienced-developer material; the GPT escalates to the full framework), and all of `guides/` (too large; the compact rules carry the load — including `guides/multi-agent/agentic-security.md`, whose rules are summarized in `rules/multi-agent.md`).

## Update procedure

This is the last step of the release procedure in `CONTRIBUTING.md` — do it after the release is tagged and pushed, so the GPT never runs ahead of what's published.

1. `git diff --stat v<previous>..v<current> -- rules/ intake/ checklists/ appendices/` (releases are tagged `vX.Y.Z`; for the first tagged release, diff against the previous release commit from `CHANGELOG.md`) to see which knowledge files changed.
2. In the GPT builder, delete and re-upload only the changed files. Keep the count at exactly the 20 listed above — the builder silently ignores a 21st.
3. If `gpt-instructions.md` changed (it should already have been re-condensed and checked against the 8,000-character limit before tagging), paste the whole file into the Instructions field — replace, don't append.
4. Test with one intake conversation before saving publicly: confirm it asks the platform and downtime questions and names the tier plus the privacy overlay before writing code.
5. Note the framework version the GPT now matches in the release notes or the release PR.
