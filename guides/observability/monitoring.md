# Monitoring and Alerting — Why and How

> This guide explains what to monitor, how to design alerts, and why the four golden signals matter. Read it when setting up monitoring for your application.

## Why Monitor?

Monitoring answers two questions:
1. **Is the system working right now?** (real-time health)
2. **How has the system been behaving over time?** (trends and patterns)

Without monitoring, you learn about problems when users complain — or when revenue drops. With monitoring, you detect problems early, often before users notice, and you have the data to diagnose them quickly.

## The Four Golden Signals

Google's SRE (Site Reliability Engineering) team identified four metrics that matter most for any service. If you monitor nothing else, monitor these:

### 1. Latency — How Long Things Take

**What to measure:** Response time for requests, broken down by type (success vs. failure) and percentile.

**Why percentiles, not averages:** An average can hide severe problems. If 99 users get a response in 100ms and 1 user waits 30 seconds, the average is ~400ms — looks fine! But that 1% of users is having a terrible experience.

Track these percentiles:
- **p50 (median):** What the typical user experiences
- **p95:** What the slow end of "normal" looks like
- **p99:** What the worst-case non-outlier experiences. If p99 is bad, a meaningful number of users are suffering.

**Alert on:** p95 or p99 exceeding your defined threshold (e.g., API response time p95 > 2 seconds for 5 minutes).

### 2. Traffic — How Much Work Is Being Done

**What to measure:** Requests per second (for APIs), page views per minute (for websites), messages processed per second (for queues).

**Why it matters:** Traffic tells you what "normal" looks like. A sudden drop in traffic might mean your app is down even if the server is healthy (maybe the load balancer is misconfigured). A sudden spike might mean you're being scraped or attacked, or you've gone viral and need to scale.

**Alert on:** Traffic dropping to near zero (likely an outage), traffic spiking well above normal (might need scaling or might be an attack).

### 3. Errors — How Often Things Fail

**What to measure:** Error rate as a percentage of total requests. Break down by error type (4xx vs. 5xx) and by endpoint.

**Why it matters:** A 0.1% error rate is probably normal. A 5% error rate means something is wrong. A 50% error rate means something is very wrong. Tracking by endpoint helps you pinpoint which feature is broken.

**Important distinction:**
- **5xx errors** (server errors) are almost always your problem. These need investigation.
- **4xx errors** (client errors) are usually normal (invalid input, unauthorized access). A spike in 401s might indicate a broken auth flow, though.

**Alert on:** 5xx error rate exceeding a threshold (e.g., > 1% for 5 minutes). Sudden spike in 4xx errors (might indicate a broken client or a misconfigured deployment).

### 4. Saturation — How Full Are Your Resources

**What to measure:** CPU usage, memory usage, disk usage, database connection pool utilization, queue depth.

**Why it matters:** Saturation tells you how close you are to running out of capacity. At 90% CPU, you're one traffic spike away from performance degradation. At 95% disk, you're one busy day away from the database crashing because it can't write.

**Alert on:** Any resource approaching its limit. Thresholds depend on the resource:
- CPU: sustained > 80%
- Memory: > 85%
- Disk: > 80%
- Connection pool: > 75% utilization
- Queue depth: growing consistently instead of draining

## Business Metrics

Technical metrics tell you the system is running. Business metrics tell you the system is working. Both are essential.

Track metrics that matter to the business:
- **User sign-ups per hour/day** — a drop might mean the registration flow is broken
- **Orders or transactions per hour** — the most direct revenue indicator
- **Active users** — is anyone actually using this?
- **Key workflow completion rate** — what percentage of users who start checkout actually finish?
- **Feature usage** — which features are people actually using?

A dashboard showing "all systems green" while orders have dropped to zero is not useful. Business metrics catch the problems that technical metrics miss.

## Alert Design

### The Critical Principle: Every Alert Must Be Actionable

If an alert fires and the response is "ignore it," that alert should not exist. Alert fatigue — too many alerts, too many false positives — is the #1 failure mode of monitoring systems. When everything alerts all the time, nothing gets noticed.

### Alert on Symptoms, Not Causes

**Bad alert:** "CPU usage > 80%"
- Maybe the application is just busy. Is anyone having a bad experience? If not, high CPU is fine.

**Good alert:** "API error rate > 5% for 5 minutes"
- This directly indicates user impact. Investigate the cause after you're alerted.

**Bad alert:** "Database connection count > 50"
- Maybe you scaled up and this is expected. Is anything actually failing?

**Good alert:** "Request latency p95 > 3 seconds for 10 minutes"
- This means users are waiting. Something needs attention.

### Severity Levels

Not all problems are equal. Match the alert severity to the impact:

**Page (wake someone up at 2 AM):**
- Service is completely down
- Error rate > 10% of requests
- Data loss is occurring
- Security breach detected

**Ticket (fix within the next business day):**
- Error rate elevated but under 5%
- Performance degraded but functional
- Disk usage approaching limits
- A non-critical service is down

**Inform (FYI, review during normal hours):**
- An unusual pattern that doesn't indicate a clear problem
- A scheduled job took longer than usual
- A new type of error appeared at low frequency
- Resource usage trending upward

### Start Small

Begin with 3–5 critical alerts:
1. The application is unreachable (health check failing)
2. Error rate exceeds threshold
3. Response latency exceeds threshold
4. A critical background job hasn't run on schedule
5. Disk or database storage approaching capacity

Add more alerts as you learn what problems actually occur. Remove alerts that consistently fire without requiring action.

## Dashboards

### The Overview Dashboard

One dashboard per service showing at-a-glance health:
- Request rate (traffic)
- Error rate
- Response time (p50, p95, p99)
- CPU and memory usage
- Active database connections
- Key business metric (orders/minute, active users, etc.)

This is the dashboard you look at when you get an alert. It should answer "what's the current state?" in under 10 seconds.

### Dashboard Rules

- **Every metric needs context.** A number without comparison is meaningless. Show current vs. 24 hours ago, or current vs. the same time last week.
- **Don't build dashboards nobody looks at.** If you check a dashboard less than once a week, it's clutter.
- **Keep them simple.** A dashboard with 50 graphs requires too much scanning. Highlight what matters.

## Getting Started with Monitoring

### For Simple Applications

1. Use your hosting platform's built-in metrics (Vercel Analytics, Railway Metrics, etc.)
2. Add a free uptime monitor (UptimeRobot, Better Stack) that pings your health endpoint
3. Add basic error tracking (Sentry free tier) to catch and group application errors
4. Set up 2–3 alerts: site down, high error rate, slow responses

### For Business Applications

Everything above, plus:
1. Dedicated monitoring platform (Datadog, Grafana Cloud, New Relic, or self-hosted Prometheus + Grafana)
2. Custom application metrics (business events, feature usage)
3. Database monitoring (query performance, connection pool, replication lag)
4. Structured dashboards for operations and business teams
5. On-call rotation with escalation policies
