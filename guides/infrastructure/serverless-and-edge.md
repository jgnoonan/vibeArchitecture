# Serverless and Edge: When the Rules Change

> This guide explains how production reliability practices translate when your app runs on serverless or edge platforms instead of a long-running server. Read it when deploying to serverless or edge platforms (Vercel, Netlify, Cloudflare Workers, Lambda, Supabase Edge Functions).

## Why This Guide Exists

Most reliability advice — including parts of this framework's own `rules/reliability.md` — quietly assumes you're running a **long-running server**: a process that boots once, stays up for days, holds connections open, and shuts down gracefully when told to. Advice like "run two instances behind a load balancer," "add a graceful-shutdown hook," "keep a connection pool in the process," and "rate-limit with an in-memory counter" all assume that model.

On serverless and edge platforms, that model is gone. Some of this advice becomes meaningless, and some of it becomes actively harmful. The **goals** are the same — don't drop requests, don't exhaust the database, don't let one bot ruin everyone's day — but the **mechanisms** are different. This guide translates.

## The Execution Model Is Different

A long-running server is like a shop that opens in the morning and stays open all day. A serverless function is like a food truck that materializes the instant a customer walks up, serves them, and vanishes.

Concretely, on serverless/edge:

- **Functions are stateless and spin up per request.** There's no "the server" that stays running. Each invocation may start on a fresh instance. (Vercel's Fluid Compute is the notable exception: one instance can serve many concurrent requests, so module-level state *may* be shared across in-flight requests — treat that as an optimization you can't rely on, not a guarantee.)
- **Instances freeze and thaw.** After handling a request, an instance may be frozen (paused mid-memory) and reused later — or thrown away. You don't control which.
- **Many instances run concurrently.** A traffic spike doesn't make one server busier; the platform spins up dozens or hundreds of separate instances, each isolated from the others.
- **"Number of instances" is not yours to manage.** The platform scales instances up and down automatically. "Run two instances behind a load balancer" is handled for you — and you can't assume any particular count.

The consequences that trip people up:

- **No in-memory state you can rely on.** A variable you set on one request may be gone on the next, or may live on a different instance entirely. Counters, session data, and "I'll just cache it in a global variable" all break.
- **No in-process cache you can trust.** A cache in memory is per-instance and vanishes on freeze/redeploy. For shared caching, use an external store (Redis/Valkey or Upstash, the platform's KV/edge cache, or a CDN).
- **No graceful-shutdown hooks.** There's no long-lived process to shut down, so `SIGTERM` handlers, "finish in-flight work on shutdown," and cleanup-on-exit logic don't run reliably. Finish your work **within the request**, or hand it to a queue (see Background Work).

## Database Connections: The #1 Footgun

This is the single most common way serverless apps fall over in production, so read this section twice.

A traditional Postgres or MySQL server allows a limited number of open connections at once — Postgres defaults to around 100. On a long-running server that's fine: the process opens a pool of, say, 10 connections once and reuses them forever.

On serverless, each concurrent function invocation is typically its own isolated instance (Vercel Fluid Compute shares an instance across concurrent requests, which helps but doesn't remove the problem), and each one may open **its own database connection**. Under load, 200 concurrent invocations try to open 200 connections. The database hits its limit and starts **rejecting every new connection** — including from your healthy traffic. Your whole app goes down, and the error ("too many connections" / "remaining connection slots are reserved") often looks unrelated to the traffic spike that caused it.

**The fix: put a connection pooler between your functions and the database.** A pooler maintains a small set of real connections to the database and lets a large number of clients share them. Your hundreds of function invocations talk to the pooler; the pooler talks to Postgres over a handful of connections.

Options, in plain terms:

- **A managed pooler in transaction mode** — Supabase's pooler (**Supavisor**, on port 6543), or **PgBouncer** in transaction mode. "Transaction mode" hands a connection back to the pool after each transaction instead of holding it for a whole session, which is exactly what short-lived functions need.
- **A serverless-native database endpoint** — **Neon's pooled connection string**, **Prisma Accelerate**, or **AWS RDS Proxy**. These are built for this pattern; you point your app at their URL instead of the raw database.
- **An HTTP / serverless data API** — some platforms (Neon, Supabase, PlanetScale, Turso) let you query over HTTP instead of a raw database socket. HTTP has no persistent connection to exhaust, which sidesteps the problem entirely and works well on edge runtimes.

Two practical rules:

1. **Use the pooled connection string, not the direct one.** Most providers give you two URLs. On serverless, use the pooled one. This is the whole ballgame.
2. **Don't size your own pool large.** The in-process pool advice in `guides/performance/database-performance.md` (5–20 connections per instance) assumes a few long-running instances. On serverless, keep the per-instance pool tiny (often 1) and let the external pooler do the real pooling — see that guide's connection-pooling note, which already flags PgBouncer for "many app instances or serverless functions." On Vercel Fluid Compute, where one instance handles concurrent requests, a per-instance pool of a few connections is reasonable — but the total across instances still has to fit under the pooler's limit.

## Rate Limiting Needs Shared State

`rules/api.md` requires rate limiting on public endpoints so one abusive client can't overwhelm you or inflate your cloud bill. The classic implementation is an in-memory counter: "this IP has made 40 requests this minute."

On serverless that counter is **per instance**, and there are many instances. A bot spraying requests gets spread across dozens of instances, each of which sees only a few requests and happily lets them all through. Your rate limit does nothing against the exact attacker it was meant to stop.

Rate limiting needs a **shared** count that every invocation reads and writes. Options:

- **A shared store** — Redis or Valkey, or **Upstash** (a serverless-friendly Redis-compatible store with an HTTP API and ready-made rate-limit libraries). Every invocation increments the same counter.
- **The platform's built-in rate-limit primitive** — Vercel, Cloudflare, and others offer managed rate limiting you configure rather than code.
- **A WAF or CDN layer in front** — Cloudflare, AWS WAF, and similar block or throttle abusive traffic before it ever reaches your function. This is often the cheapest and most robust place to do it, because it stops the load before you pay to run a function.

Rule of thumb: rate limiting must live somewhere **shared across all invocations** — never in function memory.

## Background Work and Long Tasks

Serverless functions have short timeouts (often 10–60 seconds; edge runtimes are stricter still). You **cannot** run a 10-minute report, a video transcode, or a batch email job inside a request handler — the platform will kill it partway through, and the user is left waiting on an open connection anyway.

This is the same principle as `rules/reliability.md`'s timeout advice ("if it takes longer, make it asynchronous — accept the request, return immediately, process in the background") — serverless just makes it non-negotiable.

Do the small, fast part in the request; hand the slow part to a background primitive:

- **The platform's queue / background-function / cron primitives** — Vercel Queues and Cron Jobs, Cloudflare Queues and Cron Triggers, AWS Lambda triggered by SQS or EventBridge, Supabase scheduled functions and `pg_cron`.
- **A hosted queue** — Upstash QStash, Inngest, Trigger.dev, or a cloud queue (SQS). You enqueue a job and return immediately; a separate function processes it, with retries handled for you.

See `guides/system-design/async-patterns.md` for the queue, worker, and job-status patterns this relies on.

## Cold Starts, Timeouts, and Idempotency

- **Cold starts.** When no warm instance exists, the platform boots a new one, which adds latency to that request (tens to hundreds of milliseconds; more for heavy dependencies). Keep functions small, minimize dependencies, and prefer edge/lightweight runtimes for latency-sensitive paths. Don't paper over cold starts with an in-memory cache — see the execution-model section.
- **Timeouts.** Every platform enforces a maximum execution time. Set your own timeouts on outbound calls (`rules/reliability.md`) so a slow dependency doesn't consume your entire budget and get killed with no useful error.
- **Idempotency — the one that bites in production.** Platforms and queues **retry on failure and can invoke your function more than once for a single event** (at-least-once delivery). If your handler charges a card or sends an email, a retry can do it twice. Make handlers **idempotent**: use an idempotency key or unique request ID, record "I already processed this ID," and skip the duplicate. This is the same idempotency rule from `rules/reliability.md`, and on serverless it is not optional. Storage mechanics (key scoped per principal, stored response, in-progress state, TTL) are in `guides/reliability/concurrency.md`.

## Secrets and Config

Never hardcode secrets or read them from files you deploy. Use the **platform's environment-variable or secret store** — Vercel/Netlify environment variables, Cloudflare Workers secrets, AWS Lambda environment variables plus Secrets Manager or SSM Parameter Store, Supabase secrets. This matches `guides/infrastructure/deployment.md`: same code everywhere, config injected per environment.

One gotcha specific to **edge runtimes** (Cloudflare Workers, and the edge runtime option in Vercel functions): they are **not full Node.js**. Some Node built-ins, native modules, and filesystem access are unavailable, and many libraries assume APIs they don't have. Outbound TCP is no longer the blocker it was — Cloudflare Workers support raw sockets via `connect()` and `nodejs_compat`, and **Hyperdrive** pools Postgres connections for Workers so the standard `pg`/`postgres.js` drivers work — but a cold-started edge isolate opening a fresh database connection on every request still has the pooling problem above, so use Hyperdrive or an HTTP data API. On Vercel, "Edge Functions" are no longer a separate product: the edge runtime is a per-function option (`export const runtime = 'edge'`) alongside the Node.js runtime, and most database-heavy code belongs in the Node runtime. Check that your dependencies support the edge runtime before shipping, or keep database-heavy work in standard serverless functions and reserve the edge for lightweight, latency-sensitive logic.

## Translation Table

For each classic long-running-server practice, here's the serverless/edge equivalent.

| Classic (long-running server)                         | Serverless / edge equivalent                                                        |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Run two+ instances behind a load balancer             | Handled by the platform — it scales instances automatically; you can't set a count  |
| Graceful shutdown hook (`SIGTERM`, drain in-flight)   | No long-lived process; finish work in the request or hand it to a queue             |
| In-process connection pool (5–20 connections)         | External pooler (PgBouncer transaction mode, Supavisor/Neon pooled URL, RDS Proxy, Hyperdrive) |
| In-memory cache / global variables                    | External store (Redis/Valkey/Upstash, platform KV, CDN) — per-instance memory is unreliable |
| In-memory rate-limit counter                          | Shared store (Upstash/Redis/Valkey), platform rate-limit primitive, or WAF/CDN      |
| Long background job in a request thread               | Queue / cron / background-function primitive, or a hosted queue                     |
| `GET /health` polled by a load balancer               | Handled by the platform — health/liveness is managed for you; monitor via logs/errors |
| Session state held in server memory                   | External session store (Redis/Valkey, database, signed cookies / JWT)               |
| Warm process, negligible startup cost                 | Cold starts — keep functions small; expect first-request latency                    |
| "Retries are rare and I control them"                 | At-least-once invocation is normal — make every handler idempotent                  |

## When a Long-Running Server Is the Better Choice

Serverless is not always the right answer. Be honest about the tradeoffs. A traditional long-running server (or container on Railway, Render, Fly.io, ECS, etc.) is often better when you have:

- **WebSockets or other persistent connections.** Serverless is request/response by nature; long-lived, stateful connections fight the model. A persistent server (or a managed realtime service) is the natural fit.
- **Heavy or continuous background processing.** If you're constantly grinding through jobs, a running worker is simpler and cheaper than orchestrating thousands of function invocations.
- **Predictable, sustained high traffic.** Serverless shines for spiky or low-baseline traffic where you'd hate to pay for idle servers. At steady high volume, always-on servers are frequently cheaper and avoid cold starts entirely.
- **Long-running requests, large in-memory working sets, or specialized runtimes** that don't fit inside a function's time and memory limits.

The reasonable default for a vibe-coded app with spiky or unknown traffic is serverless — you get scaling and zero idle cost without managing servers. Reach for a long-running server when one of the reasons above clearly applies. Many real apps do both: serverless for the web/API surface, one small always-on worker for background and realtime work.

## Quick Checklist

- [ ] Database access goes through a **connection pooler** or HTTP data API — using the **pooled** connection string, not the direct one.
- [ ] No reliance on **in-memory state, caches, or global variables** persisting between requests.
- [ ] **Rate limiting** lives in a shared store, a platform primitive, or a WAF/CDN — never in function memory.
- [ ] Long or slow work is offloaded to a **queue, cron, or background function** — nothing over the timeout runs in a request handler.
- [ ] Every handler is **idempotent** (idempotency keys) so retries and duplicate invocations don't double-charge or double-send.
- [ ] Secrets come from the **platform's env/secret store**; no secrets in code.
- [ ] If deploying to the **edge**, verified that dependencies work without full Node APIs, and database access goes through Hyperdrive, a pooled URL, or an HTTP data API.
- [ ] Removed dead long-server assumptions: no graceful-shutdown hooks, no manual instance counts, no self-hosted health-check endpoint you expect a load balancer to poll.

## Related Reading

- `rules/reliability.md` — timeouts, retries, idempotency, and the failure-design principles this guide adapts.
- `rules/api.md` — rate limiting and API hardening requirements.
- `guides/performance/database-performance.md` — connection pooling in depth (see the note on PgBouncer for serverless functions).
- `guides/system-design/async-patterns.md` — queues, workers, and background-job patterns.
- `guides/infrastructure/deployment.md` — same code, different config; production-mode and environment configuration.
