# Observability Rules

> Applies to: Business tier and above.
> For detailed explanations: see `guides/observability/`

## Core Principle

- You cannot fix what you cannot see. Instrument your application as you build it, not after something breaks. Adding observability after an incident is like installing smoke detectors after the fire.

## Structured Logging

- Use structured logging (JSON format) instead of plain text. Structured logs can be searched, filtered, and analyzed by tools. Plain text logs require human eyeballs.
- Every log entry should include at minimum: `timestamp`, `level`, `message`, and `service` name. Add contextual fields: `user_id`, `request_path`, `duration_ms`, `correlation_id` where available.
- Use log levels correctly:
  - **ERROR**: Something failed that needs human attention. A database connection dropped, a payment failed, an unhandled exception occurred.
  - **WARN**: Something unexpected happened but was handled. A retry succeeded, a cache miss fell back to the database, a deprecated API was called.
  - **INFO**: Significant business events. A user signed up, an order was placed, a deployment completed.
  - **DEBUG**: Technical detail for troubleshooting. Query parameters, response payloads, internal state. Off by default in production.
- **What to log:** Request metadata (method, path, status code, duration), errors with stack traces, business events, authentication events (login, logout, failed attempts), slow operations.
- **What NOT to log:** Passwords, tokens, credit card numbers, SSNs, health information, or any sensitive data. If you must log something containing sensitive fields, redact them.

## Correlation IDs

- Generate a unique ID for every incoming request at the entry point of your application (API gateway, load balancer, or first middleware).
- Pass this ID through every internal service call, background job, and database operation triggered by that request.
- Include the correlation ID in every log entry related to that request.
- Return the correlation ID in the response (usually as a header like `X-Request-ID`). When a user reports a problem, this ID lets you trace the entire chain of events for that specific request.
- This single practice saves more debugging time than almost any other observability investment.

## Health Checks and Metrics

- Expose a health check endpoint (`/health`). See reliability rules for shallow vs. deep health checks.
- Track the four golden signals:
  - **Latency**: How long requests take. Track distributions (p50, p95, p99), not just averages. Averages hide problems — if 1% of users wait 30 seconds, the average might still look fine.
  - **Traffic**: Request rate. How many requests per second/minute. Know what normal looks like so you can spot abnormal.
  - **Errors**: Error rate by type. What percentage of requests fail? Which endpoints fail most? Are errors increasing?
  - **Saturation**: How full are your resources? CPU, memory, disk, database connections, queue depth. Know when you're approaching limits before you hit them.
- Track business metrics alongside technical metrics: sign-ups, orders, revenue, active users. A technical dashboard that shows "everything green" while orders have dropped to zero is useless.

## Alerting

- Alert on symptoms, not causes. Alert on "error rate exceeded 5%" not "CPU is at 80%." High CPU with happy users is fine. Low CPU with failing requests is not.
- Every alert must be actionable. If you get an alert and there's nothing you can do about it, it's not an alert — it's noise. Noise leads to alert fatigue, and alert fatigue leads to ignored pages.
- Use severity levels:
  - **Page** (wake someone up): The service is down, data is being lost, users are impacted right now.
  - **Ticket** (fix this week): Performance is degraded, a non-critical component is failing, a disk is 80% full.
  - **Inform** (FYI): An unusual pattern, a threshold approaching, a scheduled task took longer than usual.
- Start with a few critical alerts and add more as you learn what matters. Too many alerts from day one guarantees they'll be ignored.

## Log Aggregation

- Centralize logs from all services and instances into one place. Searching across 5 different servers or log files is unworkable during an incident.
- Use your hosting platform's built-in log viewer at minimum. For more capability: CloudWatch, Datadog, Grafana Loki, Better Stack, or an ELK stack.
- Set retention policies. Logs cost storage. Keep detailed logs for 30–90 days, aggregated metrics longer. Adjust based on compliance requirements and budget.

## Incident Preparedness

- Write runbooks for known failure scenarios before they happen. A runbook is a step-by-step guide: "If [this alert fires], do [these steps]." You don't want to figure out the steps for the first time at 2 AM.
- After every significant incident, write a brief postmortem: what happened, why, what you'll change. Blameless — focus on systems, not people. Share it. Incidents are learning opportunities.
- Know how to access your logs, metrics, and dashboards before you need them. Practice navigating to them so it's muscle memory during a crisis.
