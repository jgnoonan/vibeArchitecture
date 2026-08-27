# Day 2 Operations — What Happens After You Deploy

> This guide covers what to do after your application is live. Read it when you've deployed and need to understand ongoing maintenance, updates, and incident handling.

## What "Day 2" Means

"Day 1" is building and deploying your application. "Day 2" is everything that happens after: keeping it running, fixing problems, updating dependencies, responding to incidents, and evolving the application over time.

Most vibe coders focus entirely on Day 1. Day 2 is where the real work — and the real problems — begin. A launched application needs ongoing attention, like a garden that needs watering and weeding, not just planting.

## Routine Maintenance

### Dependency Updates

Your application depends on libraries and frameworks that receive security patches, bug fixes, and new features. Outdated dependencies are the #1 source of known security vulnerabilities.

**Routine:**
- Check for dependency updates weekly or biweekly
- Enable automated vulnerability scanning (Dependabot, Snyk, npm audit)
- Apply security patches promptly (within days, not months)
- Test after updating — even minor version bumps can introduce breaking changes
- Update one dependency at a time for major versions to isolate issues

### Database Maintenance

- **Monitor storage growth.** Is the database growing as expected, or is something filling up faster than anticipated?
- **Review slow query logs.** As data grows, queries that were fast might become slow. Review monthly.
- **Verify backups.** Don't just trust that automated backups are running — check that they are, and run a test restore quarterly.
- **Clean up stale data.** Expired sessions, old logs, soft-deleted records past their retention period. Set up automated cleanup jobs.

### Certificate and Secret Rotation

- **TLS certificates** expire. If you're using Let's Encrypt (via your hosting platform), renewal is usually automatic. Verify it's working — an expired certificate means your site shows a scary warning.
- **API keys and secrets** should be rotated periodically. Set calendar reminders if the rotation isn't automated.
- **Review access.** Periodically check who has access to your hosting platform, database, and other services. Remove access for people who no longer need it.

### Scheduled Jobs (Cron) That Actually Run

Nightly backups, cleanup jobs, digest emails, trial-expiry checks — cron is the quietest way for a system to break, because a job that stops running produces no error. Three habits:

- **Overlap locks.** If tonight's job is still running when tomorrow's starts, you get two copies fighting over the same rows (or double-sending the digest). Take a lock at the start — `pg_try_advisory_lock(<job id>)` in Postgres, `SET NX` with an expiry in Redis/Valkey, or your job library's `unique`/`singleton` option — and exit immediately if it's held. Give the lock a TTL so a crashed run doesn't block forever.
- **Missed-run detection with a dead-man's switch.** Alerting on failure doesn't catch a job that never started (the scheduler died, the deploy dropped the cron entry, the timezone shifted). Instead, have the job *ping* a heartbeat URL when it finishes — healthchecks.io, Cronitor, Better Stack heartbeats, or your monitor's "expect a check-in every N hours" feature — and let the monitor alert when the ping *doesn't* arrive. Pair it with a start ping and a fail ping to get duration and failure alerts for free.
- **Idempotent work.** A job that dies at 60% will run again. Make it safe: process in batches with a stable cursor, mark rows as done, skip what's already handled. The idempotency mechanics are in `guides/reliability/concurrency.md`.

Also: pin the schedule's timezone explicitly (UTC, usually), and put the job list in code (`crontab` in the repo, `vercel.json` crons, `pg_cron` migrations) so a new host runs the same schedule. The compact rule is in `rules/reliability.md` under Scheduled Jobs.

### Domain, DNS, and Certificates

The cheapest outage is the one where everything is running and nobody can reach it.

- **Domain expiry.** Expired domains take down the site, the email, *and* the password resets — and squatters buy them within hours. Enable auto-renew on a payment method that won't expire, register the domain under a company account with 2FA and registrar lock (transfer lock) turned on, and put the renewal date on a calendar that more than one person sees. Renew for multiple years.
- **DNS provider risk.** Your DNS host is a single point of failure for everything. Use a provider with a real track record and an API (Cloudflare, Route 53, DNSimple, NS1) — ideally separate from the registrar, so one compromised account can't both transfer the domain and rewrite records. Keep an export of your zone file in the repo.
- **DNSSEC.** Signs your DNS answers so resolvers can detect forged records. Enable it if both your registrar and DNS host support it (most do); it's a checkbox plus a DS record. Test with a validator afterward — a botched DNSSEC rollout makes the domain unresolvable, which is worse than not having it.
- **Lower TTLs before migrations.** Records with a 24-hour TTL take up to a day to change everywhere. A day *before* moving hosts, CDNs, or DNS providers, drop the affected records' TTL to 60–300 seconds; do the cutover; keep the old target alive until the old TTL has fully expired; then raise the TTL back. This makes the rollback as fast as the cutover.
- **Certificates** (below) usually renew automatically; the DNS `CAA` record limits which CAs may issue for your domain.

### Monitoring Review

- **Review alerts monthly.** Are you getting alerts that aren't actionable? Remove them. Are there problems you weren't alerted about? Add new alerts.
- **Review dashboards.** Do they still show what matters? Has your application changed in ways that make existing dashboards obsolete?
- **Review costs.** Cloud bills tend to grow over time. Monthly review keeps them in check.

## Handling Incidents

For the in-the-moment triage steps, use `checklists/something-broke.md`. The incident lifecycle (detect → triage → mitigate → resolve → learn), runbooks, the postmortem template, and status-page communication are all in `guides/reliability/incident-response.md` — this guide doesn't restate them. Which alerts should wake you is defined in `guides/observability/monitoring.md`. The Day 2 habit is simply: after every significant incident, write the short blameless postmortem that guide describes, turn its action items into tickets with owners, and add a runbook if the failure could recur.

## Evolving Your Application

### When to Revisit Architecture Decisions

Your initial architecture was appropriate for your initial scale and requirements. As the application grows, some decisions may need revisiting:

- **Scale:** What works for 100 users may not work for 10,000. Watch your performance metrics.
- **New features:** A feature that requires real-time updates might push you toward WebSockets. A feature that requires heavy computation might push you toward background processing.
- **Technical debt:** Shortcuts taken to ship faster will eventually slow you down. Address them before they become critical.

### Recognizing Warning Signs

**Performance is degrading:**
- Response times are slowly increasing
- Database queries that were fast are getting slower
- Memory usage is trending upward

**Action:** Profile and optimize. Add caching, indexes, or scale up.

**Incidents are more frequent:**
- You're spending more time firefighting than building
- The same types of problems keep recurring
- Small changes cause unexpected breakages

**Action:** Invest in testing, monitoring, and architecture improvements. Slow down on features temporarily to stabilize.

**Development is slowing down:**
- Simple changes take much longer than they should
- Developers are afraid to modify certain parts of the code
- New features have unexpected side effects

**Action:** Refactor the problematic areas. Pay down technical debt. Improve test coverage.

## Scaling Operations

As your application grows, so does the operational work. Here's when to consider each investment:

### For Solo Developers / Small Teams

- **Free uptime monitoring** (UptimeRobot, Better Stack free tier)
- **Error tracking** (Sentry free tier)
- **Automated backups** (managed database feature)
- **Simple deployment pipeline** (platform auto-deploy from git)
- **Monthly:** Review costs, update dependencies, check backups

### For Growing Applications

Everything above, plus:
- **Structured logging** with a log aggregation service
- **Application performance monitoring** (APM)
- **Automated security scanning** in CI
- **Staging environment** for testing before production
- **On-call rotation** (if multiple team members)
- **Runbooks** for common incidents
- **Weekly:** Review metrics, slow queries, error trends

### For Business-Critical Applications

Everything above, plus:
- **Comprehensive monitoring** with custom dashboards
- **Alerting with escalation policies**
- **Incident response process** with defined roles
- **Regular load testing** to understand capacity limits
- **Disaster recovery testing** (practice restoring from backup, practice failover)
- **Security audits** (at least annually)
- **Daily:** Check dashboards and alert trends

## The Most Common Day 2 Mistakes

| Mistake | Consequence | Prevention |
|---------|-------------|------------|
| Ignoring dependency updates | Security vulnerabilities accumulate | Automated scanning + regular update schedule |
| Never testing backups | Discover backup is broken when you need it most | Quarterly restore tests |
| No monitoring | Learn about outages from angry users | Set up basic monitoring before launch |
| Treating every problem as urgent | Burnout, never addressing root causes | Severity classification, scheduled non-urgent fixes |
| Not writing anything down | Same problems researched from scratch each time | Runbooks, postmortems, architecture decision records |
| Skipping staging | Bugs go directly to production | Even a minimal staging environment catches issues |
| Growing without refactoring | Development becomes painfully slow | Regular dedicated time for technical debt |
