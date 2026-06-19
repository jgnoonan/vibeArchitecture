# Project Profile

> **This is an example** of a completed profile after intake — not a template. Your AI generates a file like this in **your project root** as `PROJECT_PROFILE.md`. See [first-success-walkthrough.md](first-success-walkthrough.md) for how we got here.

## Project Overview

- **Project name:** Recipe Box
- **Description:** A web app where family members save and share recipes, with photos and ingredient lists.
- **Date created:** 2026-06-13
- **Experience level:** beginner
- **AI usage:** none
- **Platform:** web

## Project Tier

**Tier:** Shared

See `intake/tier-definitions.md` for what this tier means.

## Key Decisions

| Question | Answer |
|----------|--------|
| Who is this for? | People I know — extended family (~15 people) |
| User accounts required? | Yes — each family member has their own login |
| Data sensitivity | Names, emails, optional recipe photos (no payments, no health data) |
| Access method | Web app in the browser |
| Hosting | Small VPS or PaaS (Railway/Fly.io), ~$5–10/month |
| Expected users | 15–30 at most |
| Downtime impact | Annoying but not catastrophic — family dinner planning, not a business |
| Budget | Minimal — prefer free tiers where possible |
| New or existing project? | New |

## Active Rule Sets

Based on the tier, these rule files are enforced:

- [x] `rules/universal.md`
- [x] `rules/security.md`
- [x] `rules/data.md`
- [x] `rules/testing.md`
- [ ] `rules/api.md`
- [ ] `rules/accessibility.md`
- [ ] `rules/reliability.md`
- [ ] `rules/infrastructure.md`
- [ ] `rules/observability.md`
- [ ] `rules/performance.md`
- [ ] `rules/system-design.md`
- [ ] `rules/multi-agent.md`
- [ ] `rules/mobile.md`
- [ ] `rules/compliance.md`

## Warnings and Flags

- Storing names and emails → privacy policy recommended before inviting family outside the household
- Recipe photos may include people in the background — consider optional blur/crop guidance in the UI

## Cost Estimate

**AI-assisted build:** One focused weekend to get a working MVP (auth, add/view recipes, basic search). Another few evenings for polish (photo upload, sharing links).

**Ongoing:** ~$5–10/month hosting + domain (~$12/year). No paid API dependencies.

**Traditional bracket (if hiring):** A small agency might quote $8k–15k and 6–10 weeks for the same scope — mostly because of meetings, design iterations, and handoffs you skip when vibe coding.
