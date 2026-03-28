# Incident Response: When Things Go Wrong in Production

> For the quick triage checklist, see `checklists/something-broke.md`.
> For the compact rules, see `rules/reliability.md`.

## What Is an Incident?

An incident is anything that degrades your application for users — errors, slowness, outages, data issues. Not every bug is an incident. An incident is when the impact is real and happening now.

The `something-broke.md` checklist helps you triage in the moment. This guide is about building the habits and systems that make incidents less scary, less frequent, and less damaging.

## The Incident Lifecycle

Every incident follows the same basic pattern, whether it lasts 5 minutes or 5 hours:

**1. Detect** — Know something is wrong. This should come from your monitoring, not from an angry user email. Set up alerts for error rates, response time spikes, and health check failures.

**2. Triage** — How bad is it? Is the whole app down or just one feature? Are users affected right now? This determines how urgently you respond.

**3. Mitigate** — Stop the bleeding. Your first priority is NOT finding the root cause — it's reducing the impact. Roll back a deployment, redirect traffic, disable a broken feature, switch to a fallback. Get users back to a working state as fast as possible.

**4. Resolve** — Fix the underlying problem. Now that users are no longer suffering, take the time to understand what happened and implement a proper fix.

**5. Learn** — After the dust settles, figure out how to prevent it from happening again. This is where postmortems come in.

The critical insight: **mitigate first, investigate later.** Many teams waste precious time debugging while users are down. Roll back the last deployment, and you've likely fixed the problem in 2 minutes. You can figure out *why* after the fire is out.

## Runbooks: Step-by-Step Guides for Common Problems

A runbook is a checklist for a specific type of incident. When the database is maxing out connections at 2 AM and your brain is foggy, you don't want to figure things out from scratch. You want a step-by-step guide you wrote when you were calm and thinking clearly.

### What to Put in a Runbook

- **The symptom:** What does this problem look like? (e.g., "API returns 500 errors, database connection pool exhausted")
- **Quick checks:** What to look at first (dashboard links, log queries, specific metrics)
- **Steps to mitigate:** How to reduce the impact immediately (restart the service, increase connection pool, switch to read-only mode)
- **Steps to resolve:** How to fix the underlying problem
- **Who to contact:** If you can't fix it, who knows this system? Phone numbers, not just Slack handles.

### When to Write Runbooks

- **After every incident.** If it happened once, it can happen again. The runbook for next time is your "thank you" to your future self.
- **For known failure modes.** If you know the database occasionally runs out of connections, write the runbook before it happens.
- **When setting up new infrastructure.** What do you do when the cache server goes down? Write it down now.

### Where to Keep Runbooks

In your project repository, next to the code. A common structure:

```
docs/
  runbooks/
    database-connection-exhausted.md
    deployment-rollback.md
    high-error-rate.md
```

Or keep them in your monitoring system, linked directly from alerts. The key: they must be findable in 30 seconds during a crisis.

## Postmortems: Learning from Incidents

A postmortem (also called a "retrospective" or "incident review") is a structured look at what happened after an incident is resolved. The goal is not to assign blame — it's to make the system more resilient.

### The Golden Rule: Blameless

People make mistakes. Always. A postmortem that blames individuals creates a culture where people hide problems instead of reporting them. A blameless postmortem asks "why did the system allow this mistake to cause an outage?" not "whose fault was it?"

Bad: "John deployed a bad config and took down the site."
Good: "A configuration change was deployed without validation. Our deployment pipeline didn't catch the error because there's no config validation step."

The second version leads to a fix (add config validation). The first version leads to John being afraid to deploy.

### Postmortem Template

```
## Incident: [Brief description]
**Date:** [When it happened]
**Duration:** [How long it lasted]
**Impact:** [What users experienced]
**Severity:** [Critical / Major / Minor]

## Timeline
- [Time] — First alert fired
- [Time] — Team member acknowledged
- [Time] — Root cause identified
- [Time] — Mitigation applied
- [Time] — Full resolution confirmed

## Root Cause
[What actually went wrong — be specific]

## What Went Well
- [Things that worked during the response]

## What Could Be Improved
- [Things that slowed down detection or recovery]

## Action Items
- [ ] [Specific fix with an owner and a deadline]
- [ ] [Another specific fix]
```

### When to Write a Postmortem

- **Always** for incidents that affected users for more than a few minutes
- **Always** for incidents involving data loss
- **Recommended** for near-misses (something almost went wrong but was caught in time — these are valuable learning opportunities)
- **Not needed** for trivial issues fixed in under a minute with no user impact

## On-Call for Small Teams

If you're a solo developer or a tiny team, formal on-call rotations don't make sense. But you still need to know when your app is down:

**Set up basic monitoring.** Free tools like UptimeRobot, Better Stack, or your hosting platform's built-in monitoring can send you a text or push notification when your site goes down.

**Have a plan for when you're unavailable.** If you're the only person who can fix things, what happens when you're sick, on vacation, or asleep? For solo projects, the honest answer might be "the app is down until I'm available." That's okay if your users know it. But document how to restart things so someone else could follow the steps in an emergency.

**Keep your phone notifications on for critical alerts.** Mute everything else, but when your payment system is down at midnight, you want to know.

## Communication During Incidents

If people depend on your application, they need to know when something is wrong and when it will be fixed. Silence during an outage is worse than bad news.

**For small projects:** A simple status page or a pinned message in your community channel is enough. "We're aware of the issue and working on it. Updates every 30 minutes."

**For business applications:** Use a status page service (Instatus, Betterstack, Atlassian Statuspage). Post updates at regular intervals even if there's no new information — "Still investigating, no further impact identified."

**What to communicate:**
- We know about the problem
- What's affected (and what's still working)
- What we're doing about it
- When to expect the next update

**What NOT to communicate during an incident:**
- Technical details that users don't need
- Blame ("a developer made a mistake")
- Promises about exact resolution times you can't keep

## Building Incident Response Habits

1. **Set up monitoring before you need it.** Alerts should tell you about problems before users report them.
2. **Write your first runbook today.** Pick the most likely failure (deployment goes wrong, database gets slow) and write the steps to recover.
3. **Practice rolling back a deployment.** Know the commands, know the process. Don't learn it for the first time during an emergency.
4. **After every incident, write a short postmortem.** Even a 5-line summary helps. The habit matters more than the format.
5. **Review and improve.** Once a month, look at your recent incidents. Are the same problems recurring? Is detection getting faster? Are runbooks still accurate?
