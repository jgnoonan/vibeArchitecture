# Reliability Rules

> Applies to: Business tier and above.
> For detailed explanations: see `guides/reliability/`

## Design for Failure

- Assume every external call can fail: database queries, API requests, file operations, DNS lookups, email sends. Write code that handles the failure, not just the success.
- Classify every external dependency as **hard** (the app can't function without it) or **soft** (nice to have, but not essential). Hard dependencies get the strongest protection. Soft dependencies should fail silently with fallbacks.
- Never assume a service that's working now will be working in five minutes. Networks partition, servers restart, certificates expire, rate limits get hit.

## Timeouts

- Set explicit timeouts on every external call — HTTP requests, database queries, cache lookups, message queue operations. No unbounded waits, ever.
- Use three distinct timeouts where applicable: **connection timeout** (how long to wait to establish a connection), **read timeout** (how long to wait for a response), and **overall timeout** (total time budget for the operation).
- If an operation has a user waiting, the total timeout should be seconds, not minutes. If it takes longer, make it asynchronous — accept the request, return immediately, process in the background, notify when done.
- When a timeout fires, handle it explicitly. Log it, return a meaningful error, and don't leave resources (connections, file handles) hanging open.

## Retries

- Retry only on transient failures (network errors, 5xx responses, timeouts). Never retry on client errors (4xx) — repeating a bad request won't fix it.
- Use exponential backoff: wait 1 second, then 2, then 4, then 8. This prevents hammering a struggling service.
- Add jitter (randomness) to retry delays. Without jitter, hundreds of clients that failed simultaneously will all retry at the same instant, creating a thundering herd that makes the problem worse.
- Set a maximum retry count (typically 3–5). Infinite retries can loop forever if the problem is persistent.
- Make retried operations idempotent — safe to execute multiple times without side effects. If you retry a payment charge, you must not charge the customer twice.

## Circuit Breakers

- Use the circuit breaker pattern for calls to external services. It works like an electrical breaker: after enough failures, the circuit "opens" and stops making calls, giving the failing service time to recover.
- Three states: **closed** (normal, requests flow through), **open** (too many failures, requests are rejected immediately without calling the service), **half-open** (after a cooldown period, let one test request through to see if the service recovered).
- When the circuit is open, return a fallback response: cached data, a default value, a degraded experience, or a clear error message. Don't just fail with a cryptic error.
- Configure sensibly: open after 5–10 consecutive failures or a 50%+ error rate within a window; try half-open after 30–60 seconds.

## Graceful Degradation

- The system should get worse gradually, not fail catastrophically. If the recommendation engine is down, show popular items instead. If the email service is down, queue emails for later. If the cache is down, serve from the database (slower but functional).
- Use feature flags to disable non-critical features without redeploying. When a component is causing problems, flip it off while you fix it.
- Cached or stale data is almost always better than an error page. If you can serve a slightly outdated response while the backend recovers, do it.
- Design "read-only mode" as a fallback for write-path failures. Users can still browse and view data even when writes are temporarily unavailable.

## Concurrency

- When multiple threads, processes, or agents can access the same resource (a file, a database row, a shared variable, an API), assume they WILL access it at the same time. Design for it, don't hope it won't happen.
- Protect shared state with the appropriate mechanism for your platform: mutexes/locks for threads, database transactions with proper isolation for data, file locks for filesystem operations, atomic operations for simple counters and flags.
- Prefer "share nothing" over shared state. If each thread, process, or worker has its own copy of the data it needs, there's nothing to conflict over. Merge results afterward.
- Use optimistic concurrency for low-contention resources: read the data, do your work, then check if someone else changed it before you write. If they did, retry. Optimistic approaches avoid holding locks and work well when conflicts are rare.
- Use pessimistic concurrency (explicit locks) for high-contention or critical resources: lock first, do your work, then release. Use this when conflicts are frequent or the cost of a conflict is high (financial transactions, inventory counts).
- Never hold locks while waiting on external calls. If you lock a resource, call an API that takes 10 seconds, then unlock — everything else that needs that resource is blocked for those 10 seconds. Do the external call first, then lock, write, unlock.
- Design operations to be idempotent — running them twice produces the same result as running them once. This is essential for retries, message queues, and any situation where "did my operation actually succeed?" is uncertain. Use unique request IDs or idempotency keys to detect and deduplicate repeated operations.
- Be especially careful with file operations. Most operating systems don't lock files automatically. If two processes write to the same file simultaneously, you get corrupted data. Use file locks, write to a temporary file and rename atomically, or use a database instead of files for shared state.
- For Rust specifically: the compiler enforces memory safety and prevents data races, but logical race conditions (two threads reading a value, both deciding to update, one overwriting the other's work) are still your responsibility. `Mutex`, `RwLock`, channels, and atomic types are your tools.

## Health Checks

- Every deployed service must have a health check endpoint (typically `GET /health` or `GET /healthz`).
- **Shallow health check:** Returns 200 if the application process is running. Used by load balancers to route traffic.
- **Deep health check:** Verifies connectivity to critical dependencies (database, cache, essential APIs). Used by monitoring to detect degraded state. Keep it fast — don't run expensive queries.
- Health checks must not require authentication. Load balancers and monitoring systems need to call them without credentials.
- Don't report healthy when a critical dependency is unreachable. If the database is down and your app can't serve any requests, the health check should reflect that.

## Dependency Isolation

- Separate connection pools or thread pools for critical vs. non-critical operations. A slow analytics query shouldn't exhaust the connection pool that serves user requests.
- If one external service slows down, it must not cascade to others. Timeouts and circuit breakers per dependency prevent one slow service from dragging everything down.
- Queue non-urgent work for background processing instead of handling it in the request path. Email notifications, analytics events, and image processing don't need to happen before responding to the user.
