# Resilience Patterns — Why and How

> This guide explains the key patterns for building systems that handle failure gracefully. Read it when you want to understand circuit breakers, retries, bulkheads, and other reliability techniques.

## Retry with Exponential Backoff and Jitter

### The Pattern

When a request fails, wait a bit and try again. Each retry waits longer than the last (exponential backoff), with some randomness added (jitter).

### Why Exponential Backoff

If a service is overloaded and 100 clients all retry after exactly 1 second, the service gets hit with 100 requests at the same instant. That's not recovery — that's a recurring pile-on.

Exponential backoff spreads retries over time:
- Retry 1: wait ~1 second
- Retry 2: wait ~2 seconds
- Retry 3: wait ~4 seconds
- Retry 4: wait ~8 seconds

### Why Jitter

Even with exponential backoff, if 100 clients all started at the same time, they'll all retry at 1 second, then 2 seconds, then 4 seconds — synchronized pulses hitting the server. Jitter adds randomness so retry 1 might wait 0.5–1.5 seconds, retry 2 might wait 1.5–3.5 seconds, etc. This spreads the load evenly.

### When to Retry (and When Not To)

**Retry these:**
- Network timeouts
- Connection errors
- HTTP 500, 502, 503, 504 (server errors that might be transient)
- Database connection failures

**Don't retry these:**
- HTTP 400 (bad request — your data is wrong, retrying won't fix it)
- HTTP 401/403 (authentication/authorization — retrying won't grant access)
- HTTP 404 (not found — the resource doesn't exist)
- HTTP 422 (validation error — the data fails business rules)
- Any error where retrying can't possibly help

### Implementation Rules

- Set a **maximum retry count** (3–5 is typical). Infinite retries can loop forever.
- Set a **maximum total timeout**. Don't let retries extend an operation beyond a reasonable deadline.
- **Make operations idempotent.** If you retry a request that actually succeeded (but the response was lost), the operation must be safe to repeat.
- **Log retries.** If an operation consistently needs retries, that's a signal the dependency is unhealthy.

## Circuit Breaker

### The Analogy

An electrical circuit breaker trips when there's too much current, preventing a fire. A software circuit breaker "trips" when there are too many failures, preventing cascading collapse.

### The Three States

**Closed (normal operation):** Requests flow through to the external service. The circuit breaker monitors for failures.

**Open (protecting the system):** Too many failures have occurred. Requests are immediately rejected WITHOUT calling the external service. This gives the failing service time to recover and prevents your application from wasting resources waiting for responses that won't come.

**Half-Open (testing recovery):** After a cooldown period, the circuit breaker allows a single test request through. If it succeeds, the circuit closes (back to normal). If it fails, the circuit opens again.

### Configuration

- **Failure threshold:** How many failures before opening. Too low and it trips on normal noise. Too high and it doesn't protect you. Start with 5 consecutive failures or 50% failure rate in a 60-second window.
- **Cooldown period:** How long to stay open before trying half-open. Start with 30 seconds.
- **Half-open test count:** How many successful requests before fully closing. Start with 1–3.

### What to Do When the Circuit Is Open

The circuit breaker rejects requests instantly — but your application still needs to respond to the user. Options:

- **Return cached data** — serve the last known good response
- **Return a default value** — "recommendations unavailable" instead of an error
- **Degrade the feature** — show a simplified version that doesn't need the failing service
- **Queue for later** — accept the request and process it when the service recovers
- **Return a clear error** — "This feature is temporarily unavailable. Please try again later."

The worst option: crash or show a cryptic error message.

## Bulkhead

### The Analogy

Ships have bulkheads — watertight compartments. If one compartment floods, the others stay dry and the ship stays afloat. Without bulkheads, a single hull breach sinks the ship.

### The Pattern

Isolate different parts of your application so one failing part can't take everything down.

**Connection pool isolation:** Instead of one shared database connection pool for all operations, use separate pools for critical operations (user login, checkout) and non-critical operations (analytics, reporting). If the reporting query runs away and exhausts its pool, login and checkout still work.

**Thread/worker isolation:** Separate worker pools for different types of background jobs. A flood of notification emails shouldn't prevent order processing.

**Service isolation:** If your application calls multiple external services, a slow response from one shouldn't block requests to others. Separate timeouts and circuit breakers per service.

### When to Use

Bulkheads add complexity. Use them when:
- You have critical operations that must stay available even when non-critical parts fail
- You've experienced (or can foresee) a scenario where one slow dependency brought everything down
- Your application calls multiple external services with different reliability characteristics

## Timeout

### The Rule

Every external call gets a timeout. Every single one. No exceptions.

### Why

A missing timeout means your application can wait forever. "Forever" in practice means until resources are exhausted: all connections are used up waiting for responses, all threads are blocked, all memory is consumed by pending requests. Then everything fails.

### Types of Timeouts

- **Connection timeout:** How long to wait to establish a connection. If the server is unreachable, fail fast (1–5 seconds).
- **Read timeout:** How long to wait for a response after connecting. Depends on the expected operation time (1–30 seconds for most API calls).
- **Overall operation timeout:** The total time budget for the complete operation, including retries. This is the outer boundary.

### Timeout Budgets

If a user request triggers multiple downstream calls, each call gets a share of the total budget:
- User clicks "checkout" → total budget: 10 seconds
- Inventory check: 2 second timeout
- Payment processing: 5 second timeout
- Email confirmation: 2 second timeout
- Buffer: 1 second

If inventory check takes 3 seconds, you've already consumed more than its budget. Either fail fast or reduce the timeout for remaining operations.

## Fallback Strategies

When the primary approach fails, fall back to something that still provides value:

| Scenario | Primary | Fallback |
|----------|---------|----------|
| Recommendation engine down | Personalized recommendations | Show most popular items |
| Search service down | Full-text search | Basic database LIKE query |
| Image CDN down | Optimized images | Original images from storage |
| Email service down | Send email immediately | Queue for retry in 5 minutes |
| Real-time price feed down | Live prices | Last known prices with "as of" timestamp |
| Analytics service down | Track event | Silently skip (don't degrade user experience) |

The key insight: a degraded experience is almost always better than a broken experience. Users tolerate "some features are slow right now" much better than "the whole thing is down."

## Health Checks

### Shallow Health Check

```
GET /health → 200 OK { "status": "healthy" }
```

Confirms the application process is running and can respond to HTTP requests. Used by load balancers to decide whether to route traffic to this instance.

Fast, cheap, always available. Doesn't check dependencies.

### Deep Health Check

```
GET /health/detailed → 200 OK
{
  "status": "healthy",
  "checks": {
    "database": { "status": "healthy", "latency_ms": 12 },
    "cache": { "status": "healthy", "latency_ms": 3 },
    "payment_api": { "status": "degraded", "latency_ms": 2500 }
  }
}
```

Verifies connectivity to critical dependencies. Used by monitoring systems to detect degraded state before users notice.

**Rules:**
- Keep it fast — don't run expensive queries. A simple `SELECT 1` is enough for the database.
- Don't require authentication (monitoring systems need to call it freely).
- Return unhealthy if a hard dependency is unreachable.
- Include latency information — a dependency that's technically responding but taking 5 seconds is a problem worth knowing about.
