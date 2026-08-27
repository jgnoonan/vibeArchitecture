# Scaling Strategies: Handling More Users

> For the compact rules, see `rules/performance.md`.

## What Is Scaling?

Scaling means making your application handle more work — more users, more data, more requests. When your app starts feeling slow because too many people are using it at once, you need a scaling strategy.

The good news: you almost certainly don't need to worry about scaling on day one. The bad news: when you do need it, you need to understand your options.

## Vertical Scaling — Get a Bigger Machine

The simplest scaling strategy: use a more powerful server. More CPU, more memory, faster disks.

**Analogy:** Your restaurant kitchen is too small for the dinner rush. Solution: build a bigger kitchen.

**When to use it:** Always try this first. It's the simplest approach with the least complexity. Most cloud platforms let you resize a server in minutes.

**How far it goes:** Surprisingly far. A single modern server with 8 CPUs and 32GB of RAM can handle thousands of concurrent users for a typical web application. A well-optimized PostgreSQL instance on a single server can handle millions of rows and hundreds of queries per second.

**When it stops working:** There's a ceiling — you can't buy an infinitely large server. If you've already upgraded to the biggest available instance and it's still not enough, you need horizontal scaling. But most applications never reach this ceiling.

**Cost:** Bigger servers cost more per hour, but you only have one to manage. Often cheaper than running many small servers when you factor in operational complexity.

## Horizontal Scaling — Add More Machines

Instead of one big server, run multiple copies of your application behind a load balancer. The load balancer distributes incoming requests across the copies.

**Analogy:** Instead of building one giant kitchen, open multiple restaurant locations.

**When to use it:** When vertical scaling hits its limit, or when you need redundancy (if one server dies, the others keep running).

**The catch — your app must be stateless:**
If your application stores anything in memory between requests (user sessions, uploaded files in a temp directory, cached data in a variable), that data exists on only one server. The next request might go to a different server that doesn't have it.

To scale horizontally, all shared state must live outside the application:
- Sessions → stored in a database or Redis/Valkey
- Uploaded files → stored in object storage (S3, R2, etc. — see `guides/infrastructure/cloud-fundamentals.md` for the presigned-URL pattern)
- Cached data → stored in Redis/Valkey or Memcached
- Background jobs → managed by a job queue

Ask your AI: *"Is my application stateless? Can it run multiple instances behind a load balancer?"*

### Load Balancing Strategies

A load balancer decides which server gets each request:

- **Round-robin:** Each server gets a turn. Simple, works well when all servers are identical.
- **Least connections:** Send the request to whichever server is least busy. Better when some requests take longer than others.
- **Session affinity (sticky sessions):** Send the same user to the same server every time. Use this as a crutch while you make your app stateless — not as a permanent solution.

## Database Scaling — The Hard Part

Application servers are relatively easy to scale horizontally. Databases are harder because they hold state — your data.

### Read Replicas

If your application reads much more than it writes (which most do), you can create "read replicas" — copies of your database that handle read queries while the primary handles writes.

**How it works:** The primary database replicates every change to one or more replicas. Your application sends read queries (SELECT) to replicas and write queries (INSERT, UPDATE, DELETE) to the primary.

**The tradeoff:** Replicas may be slightly behind the primary (usually milliseconds, occasionally seconds under load). If a user writes data and immediately reads it back, they might not see their change if the read goes to a replica that hasn't caught up yet. The user saves a profile edit, the page reloads from a replica, and their change is "gone" — the classic replica bug report.

**Read-your-own-writes — the fix:** guarantee that a session sees its own writes, without forcing every read to the primary.
- **Pin after write.** After any write, route that user's reads to the primary for a short window (a few seconds — longer than typical lag). Implement it as a `wrote_at` timestamp in the session or a short-lived cookie; the router checks it. Rails' automatic connection switching and most multi-DB ORM plugins do exactly this.
- **Wait for the replica to catch up.** Record the primary's write position (Postgres `pg_current_wal_lsn()`) after the write; a subsequent read on a replica first checks `pg_last_wal_replay_lsn() >= that position` and falls back to the primary if not. Precise, more work.
- **Route by query type by default.** Anything the user just changed, anything transactional, and anything in the same request as a write goes to the primary; browse/list/search traffic goes to replicas.

For most applications the first option is enough; the point is to *decide* rather than let the ORM's default routing surprise you.

### Connection Pooling

Each database connection uses memory. If you have 10 application servers each opening 20 connections, that's 200 connections to your database — which may only support 100–200 by default. A connection pooler (PgBouncer, Supavisor, RDS Proxy) between your application and the database multiplexes many app connections through a few real ones. This is often the first database scaling step you need, and it's simple to set up. Sizing, tools, and the serverless variant are in the connection-pooling section of `guides/performance/database-performance.md` (the canonical treatment).

### Database Sharding — Last Resort

Sharding splits your data across multiple databases. Users A–M on Database 1, users N–Z on Database 2.

**Don't do this unless you absolutely must.** Sharding adds enormous complexity: cross-shard queries, data redistribution when you add shards, maintaining consistency across shards. Most applications never need sharding. If your database is slow, first check: Are your queries optimized? Do you have proper indexes? Is connection pooling configured? Are you using read replicas?

Sharding is a sign you've reached very large scale. If you're reading this guide, you almost certainly don't need it yet.

## Auto-Scaling

Cloud platforms can automatically add or remove servers based on demand. More servers during peak hours, fewer during quiet times.

### Scale on the Right Metric

- **Good:** Scale based on request count, response time, or queue depth — metrics that directly reflect user experience.
- **Bad:** Scale based on CPU alone. CPU can spike for many reasons (garbage collection, a bad query, a log rotation) that don't mean you need more servers.

### Important Settings

- **Minimum instances:** Never go below this number. Set it to at least 2 for redundancy.
- **Maximum instances:** Cap this to prevent runaway costs. A traffic spike that scales you to 100 servers will be an expensive surprise.
- **Cooldown period:** After scaling up, wait a few minutes before scaling up again. Without this, a brief spike can trigger cascading scale-ups.
- **Pre-warming:** If you know traffic will spike (a marketing campaign, a product launch), scale up in advance. Auto-scaling reacts, which means there's always a brief lag.

## The Honest Scaling Advice

1. **Don't optimize for scale you don't have.** Build for your current and near-future needs. Design so you *can* scale later without rewriting everything, but don't pay the complexity cost until you need to.

2. **Optimize your code before adding servers.** A single server running optimized code will outperform ten servers running inefficient code — and cost a tenth as much.

3. **The order of scaling efforts:**
   - Fix slow queries and add missing indexes
   - Add connection pooling
   - Add caching for expensive or repetitive operations
   - Upgrade to a bigger server (vertical)
   - Add read replicas for the database
   - Add more application servers (horizontal)
   - Shard the database (last resort)

4. **Measure, don't guess.** Before adding infrastructure, profile your application to find the actual bottleneck. The bottleneck is almost never where you think it is.
