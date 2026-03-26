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
- **Verify backups.** Don't just trust that automated backups are running — periodically check that they are, and test a restore.
- **Clean up stale data.** Expired sessions, old logs, soft-deleted records past their retention period. Set up automated cleanup jobs.

### Certificate and Secret Rotation

- **TLS certificates** expire. If you're using Let's Encrypt (via your hosting platform), renewal is usually automatic. Verify it's working — an expired certificate means your site shows a scary warning.
- **API keys and secrets** should be rotated periodically. Set calendar reminders if the rotation isn't automated.
- **Review access.** Periodically check who has access to your hosting platform, database, and other services. Remove access for people who no longer need it.

### Monitoring Review

- **Review alerts monthly.** Are you getting alerts that aren't actionable? Remove them. Are there problems you weren't alerted about? Add new alerts.
- **Review dashboards.** Do they still show what matters? Has your application changed in ways that make existing dashboards obsolete?
- **Review costs.** Cloud bills tend to grow over time. Monthly review keeps them in check.

## Handling Incidents

### When Something Breaks

Refer to `checklists/something-broke.md` for the immediate triage steps. This section covers the broader process.

### The Incident Response Flow

1. **Detect:** Something alerts you — monitoring, user reports, error notifications
2. **Assess severity:** Is this affecting users? How many? Is data at risk?
3. **Communicate:** If users are affected, acknowledge the problem. A simple status update ("We're aware of an issue and investigating") builds trust.
4. **Mitigate:** Stop the bleeding. Rollback a bad deployment, restart a crashed service, switch to a fallback. Mitigation first, root cause later.
5. **Investigate:** Once the immediate problem is resolved, find the root cause.
6. **Fix:** Implement a proper fix (not just a band-aid).
7. **Learn:** Write a brief postmortem.

### Postmortems

After every significant incident, write a short document:

- **What happened:** Timeline of events
- **Impact:** How many users were affected, for how long, what was the business impact
- **Root cause:** Why it happened (not "who messed up" — focus on systems, not people)
- **What we did:** Steps taken to detect, mitigate, and resolve
- **What we'll change:** Action items to prevent recurrence, with owners and deadlines

Postmortems are not about blame. They're about learning. If a human made a mistake, the question is "what about our system made it easy to make that mistake?" not "who should be punished?"

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
