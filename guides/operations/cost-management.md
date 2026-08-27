# Cost Management — Why and How

> This guide explains cloud cost awareness and practical cost management. Read it when planning your infrastructure budget or when you want to avoid surprise cloud bills.

## Why This Matters

Cloud services make it easy to start building — but they also make it easy to spend money without realizing it. Unlike buying a physical server where the cost is obvious and fixed, cloud costs are usage-based and can escalate quietly.

Common surprises:
- A database that costs $15/month during development costs $200/month with real traffic
- A forgotten test environment running 24/7 for months
- Data transfer charges that are invisible until the bill arrives
- A logging service that ingests far more data than expected
- An auto-scaling configuration that spins up expensive instances during a traffic spike

The fix isn't to avoid the cloud — it's to be aware of costs from day one.

## Understand Your Bill

### Review Monthly (At Minimum)

Log into your cloud provider's billing dashboard monthly. Know:
- Total spend this month vs. last month
- Which services cost the most
- Whether anything unexpected appeared
- Whether you're on track to stay within budget

### Know What's Free (and What Isn't)

Free tiers change often — **check current terms** before planning around one. As of this writing:
- **AWS:** New accounts (since July 2025) get a credit-based free tier — up to $200 of credits over 6 months, then pay-as-you-go — instead of the old 12-month resource allowance. Some always-free services remain (Lambda requests, DynamoDB storage, within limits).
- **Google Cloud:** $300 credit for 90 days, plus an always-free tier (Cloud Run, Cloud Run functions, Firestore, with limits)
- **Azure:** $200 credit for 30 days, plus an always-free tier
- **Vercel/Netlify/Cloudflare:** Hobby/free tiers for personal projects, with usage caps
- **Railway:** No free tier — a one-time trial credit, then a paid plan
- **Render/Fly.io:** Render has a free tier for small services; Fly.io is pay-as-you-go with no free allowance
- **Databases:** Neon and Supabase have free tiers (with auto-pause/inactivity limits). PlanetScale dropped its free tier and prices per instance; it now offers Postgres as well as MySQL.

When you exceed free tier limits, charges start. Know where those limits are and set billing alerts.

### Set Billing Alerts

Every cloud provider lets you set alerts at spending thresholds. Set them before you need them:
- Alert at 50% of your monthly budget
- Alert at 80% of your monthly budget
- Hard alert at 100%

This costs nothing and can save you from bill shock.

### Set Hard Spend Caps Where You Can

An alert arrives after the money is spent; a cap stops the spending. Use them wherever the platform offers one:
- **AWS Budgets actions:** a budget can *do* something when it trips — apply a deny-all IAM policy, stop EC2/RDS instances. Configure an action at 100–120% of budget for non-production accounts at minimum.
- **Vercel spend management:** set a spend limit on the account; deployments pause when it's reached. Cloudflare Workers can cap daily requests per Worker.
- **GCP / Azure:** budgets are alerts only by default — pair them with a Cloud Function / Automation runbook that disables billing or scales to zero.
- **Serverless concurrency and max-instance limits** are spend caps in disguise: a `max instances` of 10 on Cloud Run or a reserved-concurrency limit on Lambda bounds the worst case of a traffic spike or a bug in a loop.
- **LLM APIs** are the fastest-growing surprise line item. Set monthly limits in each provider's dashboard and per-request token caps in code; the Cost Controls section of `rules/multi-agent.md` covers the mechanics.

## Where the Money Goes

### Compute (Running Your Application)

The servers or containers running your code. Costs depend on:
- **Instance size:** CPU and memory. Start small, scale up only when metrics show you need it.
- **Hours running:** A server running 24/7 costs 24 hours × 30 days per month. If your app only needs to handle traffic during business hours, consider scaling down overnight.
- **Serverless:** Functions-as-a-service (AWS Lambda, Vercel Functions, Cloudflare Workers) charge per execution. Cheap at low scale, can get expensive at high scale.

**Savings tip:** Right-size your instances. Most development environments don't need a large server. Start with the smallest instance that works and increase based on actual load metrics.

### Database

Often the largest single cost for an application.
- **Managed databases** (RDS, Cloud SQL, PlanetScale, Supabase) charge for instance size, storage, backups, and data transfer.
- **Serverless databases** (Neon, DynamoDB on-demand, Turso) charge per compute-hour or per read/write and scale to zero. Cheaper at low scale, potentially expensive at high scale.

**Savings tips:**
- Use the smallest instance that provides acceptable performance
- Enable auto-scaling with sensible limits (minimum and maximum)
- Stop development/staging databases outside business hours if possible
- Consider serverless database options for low-traffic applications

### Storage

Where your files, images, backups, and logs live.
- **Object storage** (S3, Cloud Storage, R2): Very cheap per GB, but S3/GCS charge for access (GET/PUT requests) and, above all, for data transfer out. **Egress-free storage** — Cloudflare R2, Bunny Storage, Backblaze B2 (free egress to Cloudflare/Bunny CDNs) — charges nothing per GB downloaded, which for a media-heavy app can be the difference between a $20 and a $2,000 bill.
- **Block storage** (EBS, Persistent Disks): More expensive, used for database volumes.

**Savings tips:**
- Use storage tiers: frequently accessed data on standard storage, old backups on cheaper archive storage (S3 Glacier, Nearline)
- Set lifecycle policies to automatically move old data to cheaper tiers or delete it
- Don't keep old database snapshots indefinitely
- Clean up unused volumes and orphaned storage

### Data Transfer

The hidden cost. Data transfer between cloud services, between regions, and out to the internet all have charges.

- **Data in** (uploading to the cloud) is usually free
- **Data out** (serving to users) is charged per GB. This is how cloud providers make money on CDNs and APIs.
- **Data between services** in the same region is usually free or cheap. Between regions, it's expensive.

**Savings tips:**
- Use a CDN for static assets (reduces data transfer from your origin server)
- Keep services that communicate heavily in the same region
- Compress API responses (gzip/brotli)
- Avoid unnecessary large payloads (don't send data the client doesn't need)

### Third-Party Services

Every external service adds cost. Common ones:
- **Authentication:** Auth0, Clerk (free tiers are generous, paid tiers based on active users)
- **Email:** SendGrid, Postmark, SES ($1–5 per 10,000 emails)
- **Error tracking:** Sentry (free tier for small projects)
- **Monitoring:** Datadog, New Relic (can get expensive — be aware of per-host or per-event pricing)
- **AI APIs:** OpenAI, Anthropic, Google (per-token pricing adds up fast with heavy usage; see the Cost Controls section of `rules/multi-agent.md`)
- **Managed inference vs. self-hosted GPU:** pay-per-token managed APIs are cheaper until you have sustained, predictable volume; a rented GPU (or a self-hosted open-weights model) only wins when it's busy most of the hour, and it brings ops, scaling, and model-upgrade work with it. Start managed; revisit when the monthly token bill rivals a GPU's monthly rent.

**Savings tip:** Audit your third-party services quarterly. Are you using all of them? Are you on the right pricing tier?

## Cost-Aware Architecture Decisions

### Serverless vs. Always-On

**Serverless** (Lambda, Cloud Run functions, Vercel Functions):
- Pro: Pay only when code runs. Zero cost when idle.
- Con: Cold start latency. Per-execution pricing gets expensive at high volume.
- Best for: Low to moderate traffic, bursty workloads, background tasks.

**Always-on** (EC2, VPS, containers):
- Pro: Predictable cost. No cold starts. Better at sustained high throughput.
- Con: Pay even when idle. Requires capacity planning.
- Best for: Consistent traffic, latency-sensitive applications, high-volume workloads.

**The crossover point:** At some traffic level, serverless becomes more expensive than a dedicated server. For most small-to-medium applications, serverless is cheaper. Do the math for your specific workload.

### Managed vs. Self-Hosted

**Managed services** (RDS, managed Redis, managed Elasticsearch) cost more than running the software yourself on a VM. But they save you from:
- Patching and updating
- Backup management
- Failover configuration
- Performance tuning
- Security hardening
- 2 AM alerts when the database server's disk fills up

For most teams, the operational savings vastly exceed the price premium.

### Reserved Capacity

If you have a predictable workload (a server that runs 24/7), reserved instances or savings plans are 30–60% cheaper than on-demand pricing. The tradeoff: you commit to paying for a specific capacity for 1–3 years.

Worth considering when:
- Your production database runs continuously
- Your application servers have a stable baseline load
- You've been running for 3+ months and understand your usage pattern

## Practical Cost Management

### Tag Everything

Use tags (labels) on cloud resources to track what they belong to:
- `environment: production` / `environment: staging` / `environment: development`
- `project: my-app`
- `team: backend`

This lets you answer "what does staging cost us?" or "how much does this specific project cost?"

### Clean Up Regularly

Unused resources accumulate:
- Old database snapshots
- Unused elastic IPs / static IPs
- Idle load balancers
- Orphaned storage volumes
- Forgotten development environments
- Old container images in registries

Schedule a quarterly cleanup. Most cloud providers have tools to identify unused resources.

### Cost Estimation Before Building

Before choosing an architecture, estimate the monthly cost:
1. List every cloud service you'll use
2. Estimate the usage (requests, storage, compute hours)
3. Use the cloud provider's pricing calculator
4. Add 20–30% buffer for surprises
5. Compare against your budget

This takes 30 minutes and can save hundreds of dollars per month by catching expensive choices early.
