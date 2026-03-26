# Failure Modes — Why and How

> This guide explains how systems fail and why designing for failure matters. Read it when you want to understand why the reliability rules exist.

## The Fundamental Mindset Shift

Most developers build for the happy path: "When everything works, do this." Reliability engineering adds a question: "When this breaks, what happens?"

This isn't pessimism — it's realism. In a system with multiple components, failures are not exceptional events. They are routine. Networks partition. Servers restart. Databases become slow. External APIs go down. Disks fill up. Certificates expire. DNS caches go stale. Memory leaks accumulate. Deployment goes wrong.

The question is never "will something fail?" It's "when it fails, will the system handle it gracefully or catastrophically?"

## Types of Failures

### Transient Failures

The problem goes away on its own. A network blip, a momentary overload, a brief DNS hiccup. If you retry in a few seconds, it works.

**How to handle:** Retry with exponential backoff. Wait 1 second, then 2, then 4. Most transient failures resolve within seconds.

**The danger:** Retrying too aggressively makes things worse. If a service is overloaded and 100 clients all retry immediately, the overload gets worse, not better. This is why backoff and jitter matter.

### Persistent Failures

The problem isn't going away soon. A server is down, a database is corrupted, a third-party service has an outage.

**How to handle:** Circuit breakers (stop calling the failing service), fallbacks (use cached data, default values, or degraded functionality), and alerts (notify someone who can investigate).

### Cascading Failures

The most dangerous kind. One component fails, which causes another to fail, which causes another, until the whole system is down. Like dominos.

**Example:** A payment service becomes slow (not down, just slow). Your API keeps calling it, waiting for responses. The waiting requests consume all your server's connections. Now your server can't handle any requests — even ones that don't involve payments. Users can't log in, can't browse, can't do anything.

**How to handle:** Timeouts (never wait forever), circuit breakers (stop calling the slow service), bulkheads (separate resources for different operations so one slow path can't consume everything).

### Capacity Failures

The system can't handle the load. Too many users, too much data, too many requests.

**How to handle:** Auto-scaling (add more servers), load shedding (reject excess requests gracefully rather than crashing), backpressure (slow down producers when consumers can't keep up), and capacity planning (know your limits before you hit them).

## The Cascading Failure Pattern in Detail

Understanding how cascading failures happen helps you prevent them:

1. **Service A** depends on **Service B**
2. **Service B** becomes slow (not down — slow is often worse than down)
3. **Service A** waits for **Service B** responses. Requests to A pile up, consuming threads/connections.
4. **Service A** exhausts its connection pool. New requests to A are rejected or time out.
5. **Service C** depends on **Service A**. Now C starts failing too.
6. Users see errors everywhere. The root cause is Service B being slow, but the visible symptoms are across the entire system.

**Prevention:**
- **Timeouts** on every call to Service B. If it doesn't respond in 2 seconds, give up.
- **Circuit breaker** on the connection to Service B. After 5 timeouts, stop trying for 30 seconds.
- **Separate connection pools** for calls to Service B vs. other operations. Even if B's pool is exhausted, other operations continue.
- **Fallback** when Service B is unavailable. Serve cached data, a default response, or degrade gracefully.

## Hard Dependencies vs. Soft Dependencies

Classify every external dependency:

**Hard dependency:** The application fundamentally cannot function without it.
- Your primary database (no database = no data)
- Your authentication service (no auth = no one can log in)

**Soft dependency:** Nice to have, but the app can work without it.
- Email service (queue emails for later)
- Analytics service (skip tracking temporarily)
- Recommendation engine (show popular items instead)
- Image processing service (show unprocessed images, process later)

**The rule:** Hard dependencies get the strongest protection (retries, circuit breakers, health monitoring, alerts). Soft dependencies should fail silently with graceful fallbacks — the user should barely notice.

## The Real-World Impact

When reliability fails, the consequences scale with your tier:

- **Personal project:** You're annoyed. You fix it when you get to it.
- **Shared project:** Your friends text you "is your app down?"
- **Public project:** Users leave negative reviews. Twitter threads happen.
- **Business project:** Revenue stops. Customers churn. Support tickets flood in. Your team gets paged at 2 AM.
- **Regulated project:** Depending on the industry, people might not get their medication, financial transactions might fail, or emergency services might be unreachable.

The rules aren't theoretical. They exist because every experienced engineer has lived through these scenarios and wished they'd been better prepared.
