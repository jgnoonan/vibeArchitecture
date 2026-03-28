# Production Readiness Checklist

> **When to use this:** Before launching a Business or Regulated tier application to real users, or when promoting an existing application from a lower tier. This is the "are we actually ready?" check.
>
> **Not building a Business or Regulated app?** You don't need this checklist. The `before-you-deploy.md` checklist covers what Personal, Shared, and Public tier projects need.

## How to Use This

Work through this checklist with your AI agent. For each item, ask: *"Is this done? If not, help me set it up."* Items marked **Critical** must be completed before launch. Items marked **Important** should be addressed within the first month. Items marked **Recommended** can be prioritized after launch.

You don't need to complete everything in one session. This is a roadmap, not a gate.

---

## Security (Critical)

- [ ] **No secrets in code.** All API keys, database passwords, and credentials are in environment variables — not in source code, config files, or comments. Run: *"Scan the codebase for hardcoded secrets."*
- [ ] **HTTPS everywhere.** All traffic is encrypted. HTTP requests redirect to HTTPS. No mixed content.
- [ ] **Authentication is production-ready.** Sessions expire, passwords are hashed with a modern algorithm (bcrypt, argon2), account lockout after failed attempts, password reset works.
- [ ] **Authorization is enforced on the server.** Every API endpoint checks that the requesting user is allowed to perform the action. Client-side checks are cosmetic — the server is the authority.
- [ ] **Input is validated.** Every piece of user input is validated on the server before use. SQL injection, XSS, and command injection are prevented.
- [ ] **Dependencies are checked for vulnerabilities.** Run `npm audit`, `pip-audit`, or equivalent. Address critical and high vulnerabilities.
- [ ] **Security headers are configured.** Content-Security-Policy, X-Frame-Options, X-Content-Type-Options at minimum.
- [ ] **Admin and debug endpoints are protected or removed.** No debug routes, status pages, or admin tools exposed without authentication.

## Data (Critical)

- [ ] **Backups are configured and tested.** Your database is backed up automatically. You have tested restoring from a backup at least once. A backup you've never tested is not a backup.
- [ ] **Sensitive data is encrypted at rest.** Database encryption is enabled. This is usually a checkbox in managed database services.
- [ ] **Personal data is handled according to your privacy policy.** If you collect emails, names, or any personal information, your privacy policy matches what you actually do with the data.
- [ ] **Data retention is defined.** How long do you keep user data? What happens when someone deletes their account?

## Reliability (Critical)

- [ ] **Health check endpoint exists.** A simple endpoint (like `/health`) that returns 200 when the app is running. Used by load balancers and monitoring.
- [ ] **Graceful shutdown is implemented.** When the app receives a shutdown signal, it finishes in-progress requests before stopping — instead of dropping them mid-response.
- [ ] **External service calls have timeouts.** Every HTTP call to an external service (payment processor, email provider, third-party API) has a timeout configured. No call should wait indefinitely.
- [ ] **Error handling covers the unhappy paths.** Database unavailable, external service down, invalid data, permission denied — these are handled with appropriate error messages, not stack traces.

## Reliability (Important)

- [ ] **Retry logic has backoff.** When retrying failed operations, wait progressively longer between attempts (1s, 2s, 4s...) instead of hammering the failing service.
- [ ] **At least two instances are running.** If one crashes, the other handles traffic while the first recovers. A single instance is a single point of failure.
- [ ] **Database connection pooling is configured.** Your application isn't opening a new database connection for every request.
- [ ] **The application is stateless.** No critical state is stored in application memory. Sessions, caches, and files are in external services. This allows horizontal scaling and safe restarts.

## Observability (Critical)

- [ ] **Structured logging is in place.** Logs are in a parseable format (JSON), not free-form text. Logs include request IDs so you can trace a single request through the system.
- [ ] **Error tracking is configured.** Errors are sent to a service (Sentry, Bugsnag, etc.) that aggregates them, alerts on new errors, and shows stack traces with context.
- [ ] **Uptime monitoring is active.** An external service checks your application regularly and alerts you when it's down. Free options: UptimeRobot, Better Stack.

## Observability (Important)

- [ ] **Key metrics are tracked.** Response time, error rate, and throughput at minimum. Your hosting platform may provide these automatically.
- [ ] **Alerts are configured for critical conditions.** Error rate spikes, response time degradation, disk space running low, database connection pool exhaustion.
- [ ] **Logs are retained for a reasonable period.** At least 30 days for Business, at least 90 days for Regulated.

## Infrastructure (Critical)

- [ ] **Deployment is automated.** Pushing code triggers an automated pipeline: run tests, build, deploy. No manual SSH-and-copy deployments.
- [ ] **Rollback is possible and practiced.** You can revert to the previous version in under 5 minutes. You have done this at least once (not during an emergency).
- [ ] **Environment separation exists.** At minimum: production and development. Ideally also staging (a production-like environment for testing before release).
- [ ] **Environment variables differ between environments.** Production and development use different database URLs, API keys, and secrets. There is zero chance of a development action hitting production data.

## Infrastructure (Important)

- [ ] **Billing alerts are configured.** You know when cloud costs approach your budget. No surprise bills.
- [ ] **SSL/TLS certificates auto-renew.** Expired certificates cause outages. Use services that handle renewal automatically (Let's Encrypt, cloud provider certificates).
- [ ] **Infrastructure changes are tracked.** Ideally through Infrastructure as Code. At minimum, a log of what changed, when, and why.

## Testing (Important)

- [ ] **Critical business logic has tests.** The code that handles money, permissions, and core workflows is tested.
- [ ] **Tests run automatically before deployment.** The CI pipeline blocks deployment if tests fail.
- [ ] **Test database is separate from production.** Tests never touch real data.

## Testing (Recommended)

- [ ] **API endpoints have integration tests.** Key endpoints are tested with realistic requests and responses.
- [ ] **Error handling is tested.** Tests verify that failures (database down, bad input, permission denied) produce correct error responses — not crashes.

## Performance (Important)

- [ ] **Database queries are optimized.** Slow query logging is enabled. Queries taking more than 1 second are identified and have appropriate indexes.
- [ ] **No N+1 queries.** Loading a list of items doesn't trigger a separate query for each item's related data.
- [ ] **Static assets use a CDN.** Images, CSS, JavaScript, and other static files are served from a CDN — not from your application server.

## Documentation (Recommended)

- [ ] **Architecture decisions are recorded.** Major choices (database, hosting, auth provider) are documented with reasoning. See `appendices/adr-template.md`.
- [ ] **A runbook exists for the most likely failure.** "What do I do if the database is down?" has a written answer. See `guides/reliability/incident-response.md`.
- [ ] **Deployment process is documented.** Someone new to the project can deploy by following written instructions.
- [ ] **API is documented.** If external clients use your API, the endpoints, parameters, and responses are documented.

## Regulated Tier: Additional Items

These are for applications handling data subject to compliance requirements (HIPAA, PCI-DSS, SOC 2, GDPR). See `rules/compliance.md` for details.

- [ ] **Audit logging is implemented.** Who did what, when, from where — for all actions on sensitive data.
- [ ] **Access is logged and reviewable.** You can answer "who accessed patient record X in the last 30 days?"
- [ ] **Data encryption meets regulatory requirements.** At rest and in transit, using approved algorithms.
- [ ] **User consent is recorded.** If consent is required for data processing, it's recorded with timestamps.
- [ ] **Data deletion/export is possible.** Users can request their data (GDPR right of access) and request deletion (right to be forgotten).
- [ ] **Compliance documentation exists.** Policies, procedures, and evidence of controls for your relevant regulation.
- [ ] **Penetration testing or security assessment is scheduled.** At least annually for regulated applications.

---

## Using This Checklist with Your AI

The most effective way to work through this:

1. Share this checklist with your AI agent
2. Ask: *"Let's work through the production readiness checklist. Start with the Critical security items. For each one, check if it's done in our codebase and tell me the status."*
3. For items that aren't done, ask: *"Help me implement [this item]."*
4. Track progress by checking off items as you complete them

Don't try to do everything in one sitting. Start with Critical items, then Important, then Recommended. Each completed item makes your application meaningfully more solid.
