# API Rules

> Applies to: Public tier and above.
> For detailed explanations: see `guides/api/`

## Design Consistency

- Use a consistent URL structure. Resources are nouns (`/users`, `/orders`), HTTP methods are verbs (GET reads, POST creates, PUT/PATCH updates, DELETE removes).
- Use consistent naming in JSON fields. Pick `camelCase` or `snake_case` and use it everywhere. Mixing conventions confuses every client developer.
- Return errors as RFC 9457 Problem Details (`Content-Type: application/problem+json`) from every endpoint. Extend it with your own fields (`code`, `errors`) rather than inventing a new envelope:
  ```json
  {
    "type": "https://api.example.com/problems/validation-error",
    "title": "Validation failed",
    "status": 400,
    "detail": "Email address is required",
    "instance": "/users",
    "errors": [{ "field": "email", "message": "Email address is required" }]
  }
  ```
- Publish an OpenAPI document and treat it as the contract: generate or validate request/response schemas from it, run it in CI against the implementation, and version it with the code. Hand-maintained docs drift; a contract that is enforced does not.

## HTTP Status Codes

- Use them correctly — they are how clients know what happened:
  - `200` Success
  - `201` Created (after a POST that creates something)
  - `400` Bad request (client sent invalid data)
  - `401` Unauthorized (not authenticated)
  - `403` Forbidden (authenticated but not permitted)
  - `404` Not found
  - `409` Conflict (duplicate, already exists)
  - `422` Unprocessable (valid format but fails business rules)
  - `429` Too many requests (rate limited)
  - `500` Server error (something broke on your end)
- Never return 200 with an error in the body. Use the correct error status code.

## Input Validation

- Validate all input at the API boundary before it reaches business logic. Check types, required fields, string lengths, numeric ranges, and allowed values.
- Enforce maximum request body size. Without limits, an attacker can send a multi-gigabyte payload.
- For file uploads via API: enforce size limits, validate content types, process safely (see `rules/security.md`, File Uploads).
- GraphQL: enforce query depth and complexity/cost limits, cap aliases and batched operations per request, disable introspection in production (or gate it behind auth), and authorize at the resolver/field level — one endpoint doesn't mean one permission check.

## Authentication and Authorization

- Every endpoint that accesses or modifies user data must verify identity and permissions. No exceptions.
- Don't put secrets (API keys, tokens) in URL query parameters. They appear in server logs, browser history, and referrer headers. Use request headers.
- For public APIs: use API keys for identification and rate limiting; use OAuth tokens for accessing user data.
- API keys you issue: prefixed and checksummed (`sk_live_…`) so secret scanners recognize them, shown once, stored hashed, with per-key scopes and a last-used timestamp. Compare them in constant time.
- Batch endpoints authorize each item individually and return per-item results; one unauthorized ID must not fail open for the rest.
- WebSocket handshakes are not protected by CORS. Check the `Origin` header against your allowlist on every upgrade request (cross-site WebSocket hijacking), and authenticate the connection the same way as an HTTP request.

## Rate Limiting

- Implement rate limiting on all public-facing endpoints (Public tier and above; login/signup/reset endpoints are rate limited from Shared tier — see `rules/security.md`). Without it, one abusive client can overwhelm your server or inflate your cloud bill.
- Return `429 Too Many Requests` with a `Retry-After` header when a client hits the limit. Expose limits with the IETF `RateLimit` / `RateLimit-Policy` headers (draft standard) and, for older clients, `X-RateLimit-Limit`/`-Remaining`/`-Reset`. Say what `Reset` means: the IETF form is seconds until reset; many `X-RateLimit-Reset` implementations send a Unix timestamp. Don't mix them.
- Use stricter limits for sensitive endpoints (login, password reset, account creation) than for read-only endpoints.
- **In-memory rate limiting does not work on serverless or multi-instance deploys.** A per-process counter resets on every cold start and isn't shared across instances, so an attacker isn't actually limited. Use shared state (Redis/Upstash), your platform's rate-limit primitive, or a WAF/CDN layer. See `guides/infrastructure/serverless-and-edge.md`.

## Idempotency

- Accept an `Idempotency-Key` header on every non-idempotent write (POST that creates, charges, or sends). Store `(key, principal)` with a unique constraint, the request fingerprint, and the final response; replay the stored response for a repeat, return `409` while the original is still in progress, and expire keys after ~24 hours. Reject a reused key with a different body (`422`).

## Webhooks and Payments

- **Verify webhook signatures before trusting any webhook payload.** An unverified webhook endpoint lets anyone POST a fake "payment succeeded" or "subscription active" event. Check the provider's signature header against your signing secret first, in constant time, and reject timestamps outside a tolerance window (~5 minutes) to stop replays.
- **Grant paid access on the verified webhook, never on a client success-redirect.** Users can open the `/success` URL without paying. Fulfil orders and unlock features only when you receive and verify the server-to-server event and it confirms payment (Stripe: `checkout.session.completed` with `payment_status == "paid"`, or `checkout.session.async_payment_succeeded` for delayed methods).
- Make webhook handlers idempotent — providers retry and may deliver the same event more than once. Dedupe on the event ID. See `guides/api/payments.md`.
- Webhooks you **send**: sign each delivery (HMAC over timestamp + body, secret per endpoint), include the timestamp and a unique event ID, retry with exponential backoff over hours to days, and automatically disable endpoints that keep failing while notifying the owner. See `guides/api/api-security.md`.

## Pagination

- Every endpoint returning a list must support pagination. An unbounded query returning thousands of rows will time out, exhaust memory, or both.
- Prefer cursor-based pagination (an opaque token for "next page") over offset-based (`?page=5`). Offset pagination becomes slow on large datasets and gives inconsistent results when data changes between pages.
- Return pagination metadata: whether more pages exist, the cursor for the next page, and total count if feasible.

## Error Handling

- Never expose internal details in error responses. Stack traces, database errors, file paths, and SQL queries give attackers information. Log them server-side; return a safe message to the client.
- Distinguish client errors (4xx — they sent bad data or lack permission) from server errors (5xx — something broke on your end). This helps clients respond correctly.
- Return actionable messages. "Invalid request" tells the developer nothing. "The 'email' field must be a valid email address" tells them exactly what to fix.

## Versioning

- Plan for versioning from day one, even if you only have v1. You will eventually need a breaking change.
- URL path versioning (`/api/v1/users`) is the simplest and most visible approach.
- When making breaking changes: release a new version, support the old version for a defined period, communicate the deprecation timeline (`Deprecation` and `Sunset` headers — see `guides/api/api-versioning.md`), then retire the old version.

## Request and Response Hygiene

- HTTPS for all API traffic. No exceptions.
- Set CORS headers from a fixed allowlist. Never reflect the request's `Origin` (or `null`) into `Access-Control-Allow-Origin` while sending `Access-Control-Allow-Credentials: true` — that hands any site read access as the logged-in user. `*` is acceptable only for public APIs authenticated by header tokens, never cookies.
- Send `Cache-Control: private, no-store` on authenticated responses and `Vary` on any header that changes the output so a CDN never serves one user's data to another.
- Include a request ID in every response (generate one if the client doesn't provide it). This makes tracing a specific request through logs straightforward.
- Set response timeouts. If an operation takes more than 30 seconds, it should probably be handled asynchronously — accept the request, return a `202 Accepted`, and let the client check back for the result.
