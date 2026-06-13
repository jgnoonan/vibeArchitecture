# API Rules

> Applies to: Public tier and above.
> For detailed explanations: see `guides/api/`

## Design Consistency

- Use a consistent URL structure. Resources are nouns (`/users`, `/orders`), HTTP methods are verbs (GET reads, POST creates, PUT/PATCH updates, DELETE removes).
- Use consistent naming in JSON fields. Pick `camelCase` or `snake_case` and use it everywhere. Mixing conventions confuses every client developer.
- Return a consistent error format from every endpoint:
  ```json
  {
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Email address is required",
      "field": "email"
    }
  }
  ```

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
- For file uploads via API: enforce size limits, validate content types, process safely.

## Authentication and Authorization

- Every endpoint that accesses or modifies user data must verify identity and permissions. No exceptions.
- Don't put secrets (API keys, tokens) in URL query parameters. They appear in server logs, browser history, and referrer headers. Use request headers.
- For public APIs: use API keys for identification and rate limiting; use OAuth tokens for accessing user data.

## Rate Limiting

- Implement rate limiting on all public-facing endpoints. Without it, one abusive client can overwhelm your server or inflate your cloud bill.
- Return `429 Too Many Requests` with a `Retry-After` header when a client hits the limit.
- Use stricter limits for sensitive endpoints (login, password reset, account creation) than for read-only endpoints.

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
- When making breaking changes: release a new version, support the old version for a defined period, communicate the deprecation timeline, then retire the old version.

## Request and Response Hygiene

- HTTPS for all API traffic. No exceptions.
- Set CORS headers explicitly. List specific allowed origins. Never use `Access-Control-Allow-Origin: *` with credentials.
- Include a request ID in every response (generate one if the client doesn't provide it). This makes tracing a specific request through logs straightforward.
- Set response timeouts. If an operation takes more than 30 seconds, it should probably be handled asynchronously — accept the request, return a `202 Accepted`, and let the client check back for the result.
