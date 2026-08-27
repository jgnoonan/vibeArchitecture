# Reliability Rules

> Applies to: Business tier and above.
> For detailed explanations: see `guides/reliability/` (`resilience-patterns.md` for timeouts, retries, circuit breakers, fallbacks, health checks; `concurrency.md` for locking and idempotency; `failure-modes.md` for dependency classification; `high-availability.md` for RTO/RPO).
> **Deploying to serverless or edge (Vercel, Netlify, Cloudflare Workers, Lambda, Supabase functions)?** Rules that assume a long-running server (graceful shutdown, two instances, in-process pools) translate differently there; see `guides/infrastructure/serverless-and-edge.md`.

## Design for Failure

- Assume every external call can fail (database, API, file, DNS, email) and handle the failure path, not just success.
- Classify every external dependency as **hard** (app can't function without it) or **soft** (degrade gracefully); hard gets the strongest protection, soft fails silently with a fallback (`guides/reliability/failure-modes.md`).
- Never assume a service working now will be working in five minutes.

## Timeouts

- Set explicit timeouts on every external call (HTTP, database, cache, queue); no unbounded waits.
- Use three timeouts where applicable: **connection**, **read**, and **overall**.
- If a user is waiting, the total timeout is seconds, not minutes; longer work becomes asynchronous (accept, return, process in background, notify).
- Handle a fired timeout explicitly: log it, return a meaningful error, release connections and file handles.

## Retries

- Retry only transient failures: network errors, timeouts, `408`, `429` (honor `Retry-After`), `500`/`502`/`503`/`504`. Never retry other 4xx (`400`, `401`, `403`, `404`, `409`, `422`) or `501`/`505`. Status semantics follow `rules/api.md`.
- Use exponential backoff (1s, 2s, 4s, 8s).
- Add jitter to every retry delay (prevents thundering herds).
- Cap retries (typically 3–5).
- Make retried operations idempotent (a retried payment must not charge twice).

## Circuit Breakers

- Wrap calls to external services in a circuit breaker with closed / open / half-open states.
- When open, return a fallback: cached data, a default, a degraded experience, or a clear error.
- Configure: open after 5–10 consecutive failures or a 50%+ error rate in a window; try half-open after 30–60 seconds. Tuning: `guides/reliability/resilience-patterns.md` (Circuit Breaker).

## Graceful Degradation

- Degrade gradually, never catastrophically: popular items when recommendations are down, queued email when the mailer is down, database reads when the cache is down.
- Use feature flags to disable non-critical features without redeploying.
- Prefer cached or stale data over an error page.
- Design a read-only mode as the fallback for write-path failures.

## Concurrency

See `guides/reliability/concurrency.md` (Common Mistakes; Lock Ordering Across Subsystems).

- Assume any shared resource (file, row, variable, API) WILL be accessed concurrently; design for it.
- Protect shared state with the platform-appropriate mechanism: mutexes/locks for threads, transactions with proper isolation for data, file locks for the filesystem, atomics for counters and flags.
- Prefer share-nothing (each worker owns its data, merge afterward) over shared state.
- Optimistic concurrency (read, work, check-then-write, retry on conflict) for low-contention resources.
- Pessimistic concurrency (explicit locks) for high-contention or critical resources (financial transactions, inventory counts).
- Never hold a lock while waiting on an external call; call first, then lock, write, unlock.
- With two lock domains (storage + crypto state, cache + session), define one acquisition order and never nest in the other direction; better, never nest: gather under one lock, release, then take the other.
- Design operations to be idempotent; use request IDs or idempotency keys to deduplicate.
- File operations: most OSes don't lock files automatically. Use file locks, write-to-temp-then-atomic-rename, or a database instead of files for shared state.
- Rust: the compiler prevents data races, not logical races (read-decide-write overwrites); `Mutex`, `RwLock`, channels, and atomics are still your responsibility.

## Health Checks

See `guides/reliability/resilience-patterns.md` (Health Checks).

- Every deployed service has a health endpoint (`GET /health` or `/healthz`).
- **Shallow check:** 200 if the process is running; used by load balancers.
- **Deep check:** verifies critical dependencies (database, cache, essential APIs) for monitoring; keep it fast.
- Health checks don't require authentication, so the public one stays shallow; expose the deep check (which maps your dependencies) only on an internal path, port, or load-balancer target.
- Never report healthy when a critical dependency is unreachable.

## Disaster Recovery

- Pick **RTO** (how long you can be down) and **RPO** (how much data you can lose) explicitly at Business tier; they determine backup frequency, replication, and failover.
- Test that a real restore meets them (daily backups don't satisfy a 1-hour RPO; a 3-hour restore doesn't satisfy a 15-minute RTO). Backup rules: `rules/data.md`; typical values: `guides/reliability/high-availability.md`.

## Dependency Isolation

- Separate connection/thread pools for critical vs. non-critical operations.
- Per-dependency timeouts and circuit breakers so one slow service can't cascade.
- Queue non-urgent work (email, analytics, image processing) for background processing instead of the request path.

## Scheduled Jobs

- Every cron job has an overlap lock (Postgres advisory lock or keyed Redis/Valkey lock), missed-run detection (a dead-man's switch such as healthchecks.io or Cronitor that alerts when the job *doesn't* check in), and idempotent work. See `guides/operations/day2-operations.md`.
