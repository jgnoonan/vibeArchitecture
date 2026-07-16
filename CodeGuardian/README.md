# Vibe Code Guardian (ChatGPT GPT)

Configuration for the [Vibe Code Guardian](https://chatgpt.com/g/g-69cd25c7200c8191938a6de92ddc56fb-vibe-code-guardian) GPT — the zero-setup ChatGPT form of vibeArchitecture (Option A in the README).

The GPT is configured manually at chatgpt.com and does **not** update from this repo. This directory is the version-controlled source of truth for what's uploaded there. When the framework releases a new version, update the GPT from these files and the manifest below.

## Instructions

`gpt-instructions.md` — paste into the GPT builder's **Instructions** field. Must stay under ChatGPT's 8,000-character limit (check with `wc -c`). It is a condensation of `BOOTSTRAP.md` adapted for the GPT format; when `BOOTSTRAP.md` changes materially, re-condense.

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
| 12 | `rules/system-design.md` | Conditional |
| 13 | `rules/multi-agent.md` | Conditional (AI usage) |
| 14 | `intake/tier-definitions.md` | Intake |
| 15 | `intake/questionnaire.md` | Intake |
| 16 | `checklists/before-you-build.md` | Checklist |
| 17 | `checklists/before-you-deploy.md` | Checklist |
| 18 | `checklists/production-readiness.md` | Checklist |
| 19 | `checklists/something-broke.md` | Checklist |
| 20 | `appendices/anti-patterns.md` | Reference |

Not uploaded (over the limit — deliberate omissions): `appendices/glossary.md` (the instructions already require plain language), `rules/compliance.md` and `rules/mobile.md` (niche; the GPT escalates to the full framework), and all of `guides/` (too large; the compact rules carry the load).

## Update procedure

1. `git log --oneline -- rules/ intake/ checklists/ appendices/` since the version last uploaded — or diff against the release tag — to see which knowledge files changed.
2. In the GPT builder, delete and re-upload only the changed files.
3. If `BOOTSTRAP.md` changed materially, refresh `gpt-instructions.md` here and paste it into the Instructions field.
4. Test with one intake conversation before saving publicly.
