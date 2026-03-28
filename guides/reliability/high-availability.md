# High Availability: Keeping Your App Running

> For the compact rules, see `rules/reliability.md`.

## What Is High Availability?

High availability (HA) means your application stays running even when things go wrong — a server crashes, a network connection drops, a database becomes unresponsive. Instead of going down completely, the system continues to work (maybe in a reduced capacity) while the problem is fixed.

**Analogy:** A hospital has backup generators. When the power goes out, the lights stay on because there's a second system ready to take over.

## Do You Need High Availability?

Not every application does. HA adds complexity and cost. Be honest about what your application requires:

**You probably DON'T need HA if:**
- It's a personal project or internal tool
- A few minutes of downtime is acceptable
- You can fix problems during business hours
- Nobody loses money or access to critical services when it's down

**You probably DO need HA if:**
- Paying customers depend on it
- Downtime directly costs money (e-commerce, SaaS)
- People's safety or health depends on it
- Legal or contractual obligations require a certain uptime level

If you're unsure, start without HA and add it when you have evidence it's needed. Over-engineering availability for an app with 50 users is a waste of money and time.

## Understanding Uptime: The Nines Table

Uptime is usually expressed as a percentage. The difference between each "nine" is bigger than it looks:

| Uptime | Downtime per year | Downtime per month |
|--------|------------------|--------------------|
| 99% ("two nines") | 3.65 days | 7.3 hours |
| 99.9% ("three nines") | 8.8 hours | 43.8 minutes |
| 99.95% | 4.4 hours | 21.9 minutes |
| 99.99% ("four nines") | 52.6 minutes | 4.4 minutes |
| 99.999% ("five nines") | 5.3 minutes | 26.3 seconds |

Most business applications aim for 99.9% (three nines). Getting to 99.99% or higher requires significant engineering effort and cost. Each additional nine is dramatically harder and more expensive than the last.

## SLA, SLO, and SLI — What They Mean

These three terms come up constantly in reliability discussions:

**SLI (Service Level Indicator)** — The actual measurement. "Our API responded successfully to 99.7% of requests this month." This is what your monitoring system reports.

**SLO (Service Level Objective)** — Your internal target. "We aim for 99.9% of API requests to succeed." This is what your team uses to decide if the system is healthy enough. Set your SLO stricter than your SLA so you have a buffer.

**SLA (Service Level Agreement)** — A promise to your customers, often with financial consequences. "We guarantee 99.5% uptime. If we miss it, we'll credit your account." This is a business and legal commitment.

**In plain terms:** SLI is what you measure. SLO is what you aim for. SLA is what you promise.

For most early-stage applications, you don't need a formal SLA. But having an internal SLO helps you make engineering decisions: "Is this improvement worth the effort to get from 99.5% to 99.9%?"

## How to Build for High Availability

### Eliminate Single Points of Failure

A single point of failure is anything where, if it breaks, your entire system goes down. Common ones:

- **One application server.** If it crashes, the app is down. Fix: run at least two servers behind a load balancer.
- **One database server.** If it crashes, the app can't read or write data. Fix: use a managed database with automatic failover (most cloud databases offer this).
- **One availability zone.** If that data center has a problem, everything in it is affected. Fix: spread your servers across multiple availability zones (most cloud platforms make this straightforward).

You don't need to eliminate every single point of failure on day one. Start with the most critical: if your database goes down, nothing works, so database redundancy usually comes first.

### Health Checks and Automatic Recovery

Health checks are simple endpoints that report whether your application is working. Load balancers and orchestration platforms use them to detect problems and take action automatically.

- **If a server fails its health check:** The load balancer stops sending it traffic. Other servers handle the load.
- **If a server keeps failing:** The orchestration platform restarts it or replaces it with a new one.

This means many failures are handled automatically without anyone waking up at 2 AM.

### Multi-Zone Deployment

Cloud providers organize their infrastructure into "availability zones" — essentially separate data centers in the same region. If one zone has a power outage or network issue, the others are unaffected.

Running your application across at least two zones means a zone failure doesn't take you down. Most managed cloud services (databases, caches, load balancers) support multi-zone deployment with a checkbox.

### Failover

Failover is the process of switching from a failed component to a backup.

**Automated failover:** The system detects the failure and switches automatically. Managed databases typically handle this — if the primary database crashes, a standby takes over within seconds to minutes.

**Manual failover:** A human detects the problem and initiates the switch. Slower, but simpler to set up and less risky (automated failover can sometimes trigger incorrectly).

For most applications, use automated failover for your database (let the managed service handle it) and automated recovery for your application servers (let the load balancer and orchestration platform handle it).

## Recovery Objectives: RTO and RPO

Two numbers drive your availability design:

**RTO (Recovery Time Objective):** How quickly do you need to be back up after a failure? If your RTO is 5 minutes, you need automated failover. If your RTO is 4 hours, manual recovery might be fine.

**RPO (Recovery Point Objective):** How much data can you afford to lose? If your RPO is zero, you need real-time replication. If your RPO is 1 hour, hourly backups are sufficient.

| Scenario | Typical RTO | Typical RPO |
|----------|-------------|-------------|
| Personal blog | Hours to days | Days |
| Internal business tool | 1–4 hours | 1 hour |
| Customer-facing SaaS | Minutes | Minutes |
| E-commerce / payments | Seconds to minutes | Zero (no data loss) |
| Healthcare / regulated | Seconds to minutes | Zero |

Ask yourself: "If the system goes down right now, how long can my users wait? And how much of their recent work can I afford to lose?" Your answers define your RTO and RPO, which define your architecture.

## The Cost of Availability

More nines = more money. Be deliberate about what level of availability your application actually needs.

- Running 2 servers instead of 1: roughly 2x compute cost
- Multi-zone database: usually 2–3x database cost
- Multi-region deployment: 2x+ everything, plus significant engineering complexity

For many applications, the practical sweet spot is:
- Two application servers across two availability zones
- Managed database with automatic failover
- Automated health checks and recovery
- Daily backups with point-in-time recovery

This gets you to roughly 99.9% availability without excessive cost or complexity.
