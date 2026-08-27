# Cloud Fundamentals: Running Your App on Someone Else's Computers

> For the compact rules, see `rules/infrastructure.md`.

## What Is "The Cloud"?

When you deploy your application "to the cloud," you're renting computers, storage, and networking from a company like Amazon (AWS), Google (GCP), or Microsoft (Azure) instead of buying and maintaining your own servers.

That's really all it is. "The cloud" sounds magical, but it's just someone else's data center — well-managed, highly reliable, available on demand, and billed by the hour.

## The Shared Responsibility Model

This is the single most important concept in cloud computing, and it trips up even experienced teams:

**The cloud provider is responsible for the security and reliability of the cloud** — the physical servers, networking, storage hardware, and the data center itself.

**You are responsible for the security and reliability of what you put in the cloud** — your application code, your data, your configurations, your access controls.

**Analogy:** You rent an apartment. The building owner maintains the structure, the plumbing, the electrical system. But if you leave your front door unlocked, that's on you. If water damage ruins your furniture because you left the windows open, that's on you too.

Common mistakes from not understanding this:
- "My data is in AWS, so it's backed up" — No. Unless you configured backups, there are no backups.
- "My database is in the cloud, so it's secure" — No. Unless you configured access controls, it may be accessible to the entire internet.
- "The cloud provider will stop my app from being hacked" — No. They secure their infrastructure. You secure your application.

## Regions and Availability Zones

Cloud providers organize their infrastructure geographically:

**Regions** are large geographic areas (US East, Europe West, Asia Pacific). Your data lives in the region you choose. This matters for:
- **Performance:** Users in Europe get faster responses from a European server than from one in Virginia
- **Legal compliance:** Some regulations require data to stay within certain countries (GDPR for EU data)
- **Cost:** Prices vary slightly by region

**Availability Zones (AZs)** are separate data centers within a region, connected by fast private networks. Each zone has independent power, cooling, and networking. If one zone has a problem, the others keep running.

**Practical advice:** Pick a region close to your users. Within that region, spread your servers across at least two availability zones for redundancy (most managed services do this for you automatically).

## Managed Services vs. Self-Hosted

For almost every piece of infrastructure, you have a choice: manage it yourself or let the cloud provider manage it.

### Managed Services (Recommended for Most Teams)

The cloud provider handles updates, backups, scaling, and maintenance. You use it.

Examples:
- **Managed database** (AWS RDS, Google Cloud SQL, Azure Database): You get a database. They handle backups, updates, failover, and scaling.
- **Managed cache** (AWS ElastiCache, Google Memorystore): You get Redis or Valkey (both are now Valkey-first, the open-source fork). They keep it running.
- **Managed hosting** (Railway, Fly.io, Render, Vercel, Heroku): You push code. They handle everything.

**Pros:** Less work, fewer things to go wrong, security patches applied automatically, built-in backups and monitoring.
**Cons:** More expensive than self-hosting, less control over configuration, vendor lock-in.

### Self-Hosted (When You Have a Specific Reason)

You install and manage the software on cloud servers (virtual machines) yourself.

**Pros:** Full control, potentially lower cost at scale, no vendor lock-in.
**Cons:** You're responsible for updates, security patches, backups, monitoring, scaling, and disaster recovery. When it breaks at 2 AM, it's your problem.

**The recommendation for most projects:** Use managed services. The cost premium is small compared to the operational burden of managing infrastructure yourself. You should be spending your time building features, not patching database servers.

**Self-host when:**
- A managed version doesn't exist for what you need
- Cost is a primary concern at significant scale
- You need configuration options that managed services don't offer
- Regulatory requirements dictate specific infrastructure controls

## Cloud Costs: Avoiding Surprises

Cloud billing surprises are one of the most common pain points. Things that cost money:

- **Compute:** Virtual machines and containers, billed by the hour or second
- **Storage:** Data stored on disk, billed per GB per month
- **Data transfer:** Data leaving the cloud (egress), billed per GB. Data coming in is usually free. This is the sneaky one — it adds up fast.
- **Managed services:** Database instances, caches, queues — each has its own pricing
- **Unused resources:** That test database you forgot about is still running and costing money

### Practical Cost Management

1. **Set billing alerts.** Every cloud provider lets you set alerts at spending thresholds. Set one at 50%, 80%, and 100% of your budget. Do this on day one.

2. **Start small, scale up.** Begin with the smallest instance size that works. You can always upgrade. Starting big "just in case" wastes money.

3. **Use free tiers wisely — and check current terms.** They change often. AWS moved new accounts to a credit-based model in July 2025 (up to $200 of credits over 6 months, then pay-as-you-go); GCP and Azure offer starter credits plus small always-free allowances. Railway has no free tier (a one-time trial credit, then a paid plan); Render has a free tier for small services; Fly.io is pay-as-you-go. Verify before you plan around "free."

4. **Set a hard spend cap where the platform offers one.** Alerts tell you about a runaway bill; caps stop it. AWS Budgets can run *actions* (stop instances, deny IAM permissions) when a threshold trips; Vercel has account spend limits that pause deployments; Cloudflare Workers lets you cap daily requests. For LLM API spend — the fastest-growing surprise bill — see the Cost Controls section of `rules/multi-agent.md`.

5. **Turn off what you're not using.** Development databases, staging environments, test servers. If nobody's using it right now, shut it down.

6. **Watch data transfer costs.** If your application serves large files (images, videos), use a CDN (Content Delivery Network) which caches content at edge locations worldwide. CDN egress is much cheaper than cloud egress. For file storage, prefer egress-free object storage (Cloudflare R2, Bunny Storage, Backblaze B2 via the Bandwidth Alliance) over S3 when users download what you store — S3 egress is often the biggest line on a media-heavy bill.

7. **Review your bill monthly.** Look at what's actually costing money. Often one or two things dominate, and you can optimize those specifically.

Ask your AI: *"Review my cloud setup and identify anything that's costing money unnecessarily."*

## Choosing a Cloud Provider

### For Beginners: Platform-as-a-Service (PaaS)

Start here. These platforms handle nearly everything and let you focus on your code:

- **Railway** — Simple, usage-based pricing (trial credit, no free tier), supports many languages
- **Render** — Good all-around platform, free tier for small projects
- **Fly.io** — Great for global distribution, Docker-based
- **Vercel** — Excellent for Next.js and frontend applications
- **Heroku** — The original PaaS, simple but more expensive

These are not "lesser" platforms. Many successful businesses run entirely on PaaS providers.

## Object Storage and File Uploads

User files (avatars, documents, exports) belong in object storage (S3, R2, GCS, Azure Blob, Supabase Storage), not on your server's disk — disks vanish on redeploy and don't scale across instances. The pattern that keeps it cheap and safe:

1. **The bucket is private.** No public listing, no world-readable objects. Public assets (marketing images) live in a separate, deliberately public bucket or behind the CDN.
2. **Uploads go direct-to-bucket.** Your API authorizes the user, then returns a short-lived presigned URL (or presigned POST) that permits exactly one upload: a fixed object key you chose, an allowed content type, a maximum size, and an expiry of a few minutes. The browser uploads straight to the bucket. Your app server never buffers the bytes — no memory spikes, no request timeouts on a 2 GB video.
3. **Downloads use presigned GETs** (minutes to an hour), generated only after an authorization check. Never hand out a permanent link to a private object.
4. **Verify after upload.** The client can lie about what it uploaded. Confirm the object exists, check its size and magic bytes, re-encode images, and only then record it as "ready" in your database. Set a lifecycle rule to delete orphaned objects that never got confirmed.
5. **Set CORS on the bucket** for the origins allowed to upload, and a lifecycle policy that moves old objects to cheaper tiers.

The security side (magic-byte validation, separate file origin, `Content-Disposition: attachment`) is in `rules/security.md` and `guides/security/`. Egress cost is covered above — for download-heavy apps, an egress-free bucket (R2, Bunny) plus a CDN is the default choice.

### For Growth: The Big Three

When your needs outgrow PaaS (or you need specific services), the major cloud providers offer everything:

- **AWS (Amazon Web Services)** — The largest, most services, steepest learning curve
- **Google Cloud Platform (GCP)** — Strong in data and machine learning, good developer experience
- **Microsoft Azure** — Strong enterprise integration, good if you're already in the Microsoft ecosystem

Unless you have a specific reason to choose one, **AWS** has the most documentation, tutorials, and community support. But honestly, for most applications, the PaaS providers are the right choice — they're built on top of the big three anyway.

## Vendor Lock-In: How Much to Worry

"Vendor lock-in" means your application becomes so dependent on one cloud provider's specific services that switching to another would require a major rewrite.

**The reality:** Some lock-in is fine. If you're using standard services (a database, a web server, a file store), switching providers is work but it's doable. If you're deeply integrated into a provider's proprietary services (AWS Lambda + DynamoDB + Step Functions + SQS), switching is a very big project.

**Practical advice:**
- Use standard, portable technologies where possible (PostgreSQL over DynamoDB, Docker over proprietary container services, standard S3 API over provider-specific storage)
- Don't avoid cloud services out of lock-in fear — the productivity benefit usually outweighs the theoretical switching cost
- Avoid building your architecture entirely around one provider's proprietary workflow tools unless you're confident you'll stay with them

## Infrastructure as Code

Instead of clicking buttons in a cloud provider's console to create servers and databases, you write configuration files that describe what you want. Then a tool creates it for you.

This is called "Infrastructure as Code" (IaC), and it matters because:

- **It's reproducible.** You can create an identical environment by running the same configuration.
- **It's version-controlled.** Your infrastructure definition lives in Git, just like your code. You can see what changed, when, and why.
- **It's reviewable.** Before making infrastructure changes, you can review the configuration changes — just like reviewing code.

Popular IaC tools:
- **Terraform or OpenTofu** — Cloud-agnostic, the most widely used. OpenTofu is the open-source fork, drop-in compatible; pick either.
- **Pulumi** — Like Terraform but you write actual code (Python, TypeScript, etc.) instead of a special configuration language
- **AWS CDK / CloudFormation** — AWS-specific

**When to adopt IaC:** From day one — but "IaC" scales with your tier, which is how this reconciles with `rules/infrastructure.md`. On a PaaS, your `fly.toml`, `render.yaml`, `railway.json`, or `vercel.json` committed to the repo *is* your infrastructure as code; that's enough. The moment you're composing raw cloud primitives yourself (a VPC, an RDS instance, a bucket policy, IAM roles), stop clicking in the console and write Terraform/OpenTofu or Pulumi — that's where drift and un-reproducible environments start. Ask your AI: *"Help me convert my current cloud setup to Terraform."*
