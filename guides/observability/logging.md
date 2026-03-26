# Logging — Why and How

> This guide explains structured logging practices and why they matter. Read it when setting up logging for your application or when you want to understand why the rules recommend specific approaches.

## Why Logging Matters

Logs are the first thing you look at when something goes wrong. They're the written record of what your application did, when it did it, and what happened as a result. Without good logs, debugging a production problem is like solving a mystery with no witnesses and no evidence.

Good logs let you:
- Find out why a specific user request failed
- Track down intermittent bugs that only happen in production
- Detect suspicious activity (repeated failed logins, unusual access patterns)
- Understand system behavior over time (how often does this error occur? Is it getting worse?)
- Reconstruct what happened during an incident

## Structured vs. Unstructured Logging

### Unstructured (The Old Way)

```
[2024-03-15 14:23:01] ERROR: Failed to process order for user john@example.com - payment declined
[2024-03-15 14:23:01] INFO: Retrying payment for order #12345
```

This is readable by humans. But try searching for "all payment errors in the last hour" or "all errors for user john@example.com" across thousands of log lines. You're reduced to text searching with regex patterns, which is fragile and slow.

### Structured (The Right Way)

```json
{
  "timestamp": "2024-03-15T14:23:01.456Z",
  "level": "error",
  "message": "Payment processing failed",
  "service": "order-service",
  "correlation_id": "req-abc-123",
  "user_id": "user_456",
  "order_id": "order_12345",
  "error_code": "PAYMENT_DECLINED",
  "payment_provider": "stripe",
  "duration_ms": 2340
}
```

This is machine-parseable. Your log aggregation tool can:
- Filter by any field: `level == "error" AND service == "order-service"`
- Aggregate: "How many payment errors per hour this week?"
- Alert: "Notify me when the error rate exceeds 5%"
- Correlate: "Show me everything that happened for correlation_id req-abc-123"

### How to Implement

Most languages have structured logging libraries:
- **Node.js:** pino, winston (with JSON format)
- **Python:** structlog, python-json-logger
- **Java:** Logback with JSON encoder, Log4j2
- **Go:** zerolog, zap
- **Ruby:** semantic_logger

The key: configure the library to output JSON and include standard fields in every entry.

## Log Levels — Using Them Correctly

Log levels tell you the severity of each entry. Using them correctly means you can filter your logs to see only what matters.

### ERROR

Something broke that requires attention. A real problem that needs investigation.

**Good ERROR logs:**
- An unhandled exception crashed a request
- A database query failed
- A payment charge failed
- A required external service is unreachable

**Not ERROR (common mistakes):**
- A user entered an invalid email (that's expected behavior — log at WARN or INFO)
- A 404 for a missing page (expected — log at WARN)
- A user failed to log in (expected — log at WARN, unless there's a suspicious pattern)

### WARN

Something unexpected happened, but the system handled it. No immediate action needed, but it might indicate a developing problem.

**Good WARN logs:**
- A retry succeeded after an initial failure
- A cache miss that fell back to the database
- A deprecated API endpoint was called
- A request took longer than expected but still completed
- Rate limit approaching threshold

### INFO

Significant events in the normal operation of the application. Business events, lifecycle events, operational milestones.

**Good INFO logs:**
- User signed up, user logged in, user deleted account
- Order placed, payment processed, shipment sent
- Application started, deployment completed
- Scheduled job ran successfully
- Configuration loaded

### DEBUG

Technical details useful for troubleshooting. Typically OFF in production (too verbose and expensive). Enabled temporarily when investigating a specific problem.

**Good DEBUG logs:**
- SQL queries being executed
- Request/response payloads for external API calls
- Cache hit/miss details
- Internal state during complex operations

## What to Log

### Always Log

- **Request metadata:** HTTP method, path, status code, response time. For every request. This is your most basic telemetry.
- **Errors with context:** The error message alone isn't enough. Include what operation was being attempted, what parameters were involved, and the stack trace.
- **Authentication events:** Login, logout, failed login attempts, password changes, token refreshes. These are critical for security investigations.
- **Business-significant events:** User registration, purchases, subscription changes, data exports. These tell you if the business logic is working.
- **Slow operations:** If a database query, API call, or processing step takes longer than expected, log it with timing information.

### Never Log

- **Passwords** — not even hashed ones in logs
- **Authentication tokens** — session IDs, JWTs, API keys
- **Credit card numbers** — not even partially (log last 4 digits at most, and only if needed)
- **Social Security Numbers or government IDs**
- **Health information**
- **Full request/response bodies** in production (they often contain sensitive data)

If you must log something that might contain sensitive fields, implement a redaction filter that strips or masks sensitive values before writing the log entry.

## Correlation IDs — The Single Most Valuable Practice

A correlation ID is a unique identifier generated for every incoming request and passed through every operation that request triggers.

### Why It Matters

Without a correlation ID, when a user reports "I clicked submit and got an error," you're searching through thousands of log entries from multiple services trying to piece together what happened for that specific request.

With a correlation ID, you search for one string and see every log entry related to that request, in order, across every service it touched.

### How to Implement

1. **Generate it early:** At the first point of entry (API gateway, load balancer, or the first middleware in your application), generate a UUID or similar unique ID.
2. **Pass it through:** Include the ID in every internal call — as a header (`X-Request-ID`), as a field in message queue payloads, as a parameter to background jobs.
3. **Log it everywhere:** Every log entry includes the correlation ID as a field.
4. **Return it to the client:** Include it in the API response as a header. When a user reports a problem, ask for this ID — it's the key to finding their specific request in your logs.

### Practical Implementation

Most web frameworks support middleware that generates and propagates correlation IDs. Many libraries handle this out of the box. The effort is small; the debugging time savings are enormous.

## Log Aggregation

### The Problem with Local Logs

If your application runs on one server, you can SSH in and read the logs. If it runs on three servers behind a load balancer, the request might have hit any of them. If it runs in containers that get replaced on every deployment, the logs disappear with the old container.

### The Solution: Centralized Logging

Send all logs to one place where they can be searched, filtered, and analyzed:

- **Platform built-in:** Vercel, Railway, Fly.io, Heroku all have log viewers. Start here.
- **CloudWatch Logs** (AWS), **Cloud Logging** (GCP), **Azure Monitor** — cloud-native, integrates easily, pay-per-use.
- **Better Stack (formerly Logtail)** — developer-friendly, generous free tier.
- **Datadog** — comprehensive but can get expensive. Great for larger applications.
- **Grafana Loki** — open-source, pairs with Grafana dashboards.
- **ELK Stack** (Elasticsearch, Logstash, Kibana) — powerful, self-hosted, operationally heavy.

### Retention

Logs cost storage. Set retention policies:
- **Hot storage (searchable):** 30–90 days of full logs
- **Warm storage (archived):** 6–12 months of compressed logs
- **Regulatory requirement:** Some compliance frameworks require specific retention periods

Don't keep logs forever by default — review storage costs monthly.
