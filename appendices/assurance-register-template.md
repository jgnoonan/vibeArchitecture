# Assurance Register Template

> One table recording every review, audit, and verification pass a codebase has been through: what it targeted, what it found, and how much is closed. Keep it in the repo (e.g. `docs/assurance-register.md`) and update it as findings close.
>
> **Why bother:** this is the "evidence of controls" artifact that SOC 2 auditors, enterprise buyers, and technical due-diligence reviewers actually ask for — and for a solo or small team it's the honest answer to "how do you know this is solid?" It also stops reviews from silently expiring: an open count on a page you maintain is harder to ignore than findings scattered across old chat sessions. See `guides/testing/adversarial-review.md` for the review method itself.

---

```markdown
# Assurance register — <project name>

Every review and verification pass run against this codebase, with found/closed
counts. A review is **closed** only when every finding — LOW included — is
fixed or explicitly closed with a written rationale (linked per row).

Method note: reviews are adversarial passes (one failure class per pass),
followed by a verification stage in which each claimed defect is traced
end-to-end against the source before it is believed; claims that don't
reproduce are discarded and counted below.

## Reviews

| # | Review (lens, date, scope) | Found (by severity) | Closed | Evidence |
|---|----------------------------|---------------------|--------|----------|
| 1 | Authorization & access control — YYYY-MM-DD, whole tree | e.g. 6 (1 HIGH, 3 MED, 2 LOW); 2 raw claims refuted in verification | 6 of 6 | link to worklist / fix notes |
| 2 | Concurrency & data integrity — YYYY-MM-DD | … | … | … |
| 3 | Privacy & metadata — YYYY-MM-DD | … | … | … |
| 4 | Accessibility — YYYY-MM-DD, code pass + device pass | … | … | … |

## Other verification

| What | Date | Result | Evidence |
|------|------|--------|----------|
| Dependency audit + SAST in CI | continuous | link to workflow | |
| Load test against staging | YYYY-MM-DD | survived N concurrent users, p95 X ms | |
| Restore-from-backup drill | YYYY-MM-DD | met RTO/RPO (X min / Y min) | |
| Field verification on device matrix | YYYY-MM-DD | list of devices, what was verified | |

## Open items

| Finding | Severity | From review | Status / rationale |
|---------|----------|-------------|--------------------|
| … | … | … | open / accepted-risk because … |
```

---

## Rules for Keeping It Honest

- **Counts, not adjectives.** "Found 22, closed 22" is evidence; "extensively reviewed" is marketing.
- **Refuted claims are part of the record.** Noting how many raw findings verification discarded shows the numbers weren't inflated — and that a verification stage exists.
- **Every open item is visible.** An accepted risk with a written rationale is a legitimate state; a finding nobody can account for is not.
- **Link, don't summarize.** Each row points at the detailed worklist or fix commits, so a skeptical reader can drill down.
- **Update it when tiers close, not retroactively.** A register reconstructed the week before due diligence convinces no one.
