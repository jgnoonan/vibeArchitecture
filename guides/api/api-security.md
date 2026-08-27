# API Security — Why and How

> This guide explains why API-specific security measures exist and how to implement them. Read it when building public-facing APIs or when you want to understand rate limiting, CORS, and API authentication.

## Why APIs Need Extra Security

When your application is accessed through a browser, the browser enforces some rules on its own (the same-origin policy, cookie attributes like `SameSite`). An API is called directly by code — a mobile app, a script, another server, or an attacker with `curl`. There's no browser enforcing anything, and even the browser's protections only limit what *other sites' scripts* can do, not what your own server accepts.

This means your API must protect itself. Every endpoint is a door. Every door needs a lock appropriate to what's behind it.

## API Authentication Patterns

### API Keys

A long, random string that identifies the caller. The client includes it in every request, usually in a header:
```
Authorization: Bearer sk_live_9f8a…
```

**Good for:** Identifying which application or integration is calling your API, rate limiting per client, usage tracking and billing.

**Not good for:** Identifying individual users. An API key identifies an application, not a person. If you need to know which user is making a request, use OAuth or session-based auth.

**Rules:**
- Generate keys with a cryptographically secure random generator (at least 32 bytes)
- Give keys a recognizable **prefix and checksum** (`sk_live_`, `sk_test_`, plus a short CRC at the end, the way Stripe and GitHub do). Secret scanners — GitHub push protection, gitleaks — match on the prefix and use the checksum to avoid false positives, so a key that leaks into a repo is caught in seconds.
- **Show the full key once**, at creation. After that, display only the prefix and last four characters.
- **Store only a hash** of the key (SHA-256 is fine here — keys are high-entropy, unlike passwords), and compare in constant time
- Record **last-used** time per key so owners can find and delete dead keys
- Give each key its **own scopes** (read-only vs. read-write, specific resources) and an optional expiry
- Allow rotation — users should be able to create a new key and revoke the old one with an overlap window

### OAuth 2.0 and OIDC

The standard protocol for "log in with Google/GitHub/etc." and for granting third-party applications limited access to user accounts. OpenID Connect adds the identity layer (a signed ID token) on top.

**When to use:** When other applications need to access your users' data with their permission. When you want "Sign in with Google" functionality. When building an API that third-party developers will integrate with.

**When it's overkill:** For simple app-to-API communication where you control both sides. For internal services. For personal projects.

OAuth is complex. Use an established library or service — don't implement the protocol from scratch. Follow **RFC 9700** (OAuth 2.0 Security Best Current Practice) / OAuth 2.1: authorization code + PKCE for every client, no implicit flow, exact redirect URIs, refresh-token rotation for public clients. For CLIs and agent tools that can't host a redirect, use the **Device Authorization flow (RFC 8628)**; for a service that must call another service on a user's behalf, use **token exchange (RFC 8693)** to mint a narrower downstream token rather than forwarding the original. If stolen bearer tokens are your main worry, **DPoP (RFC 9449)** binds each token to a client-held key. The full walkthrough is in `guides/security/authentication.md`.

### JWT Validation

If another service issues JWTs (your auth provider, for example), your API validates them (RFC 8725, JWT Best Current Practices):
- **Pin the algorithm.** Your verifier accepts exactly the algorithm(s) you configured — reject `alg: none`, and never let the token's header choose. The classic bypass sends an `HS256` token signed with your RSA *public key* as the HMAC secret; a verifier that "supports both" accepts it.
- Verify the signature against the key identified by `kid`, resolved **only** from the issuer's published JWKS (cached, refreshed on unknown `kid` with a rate limit) — never from a URL inside the token
- Check `exp` (and `nbf`), with a small clock-skew allowance
- Verify `iss` and `aud` — the token was issued by the provider you expect, for your API specifically
- Check `typ` where the issuer sets it (`at+jwt` for access tokens) so an ID token can't be replayed as an access token
- Extract the user identity and permissions from claims

See `guides/security/authentication.md` for JWT tradeoffs and `guides/security/state-management.md` for sessions vs. tokens.

## Rate Limiting

### Why Rate Limiting Exists

Without rate limiting:
- An attacker can make millions of requests, overwhelming your server (DDoS)
- A buggy client can accidentally create an infinite loop of API calls
- A single heavy user can degrade performance for everyone else
- A malicious user can brute-force passwords or scrape your entire database
- Your cloud bill can spike unexpectedly

### How Rate Limiting Works

The most common approach is the **token bucket**: each client gets a "bucket" of tokens. Each request uses a token. Tokens refill at a fixed rate. When the bucket is empty, requests are rejected until tokens refill.

Example: 100 requests per minute. The client can burst to 100 requests instantly, then must wait for the bucket to refill at ~1.67 requests per second.

**Where the counter lives matters.** A counter in process memory resets on every serverless cold start and isn't shared between instances, so on Vercel, Lambda, Cloud Run, or any multi-instance deploy it limits nothing. Use Redis/Upstash, your platform's rate-limit primitive, or a WAF/CDN rule. See `guides/infrastructure/serverless-and-edge.md`.

### Implementation Guidelines

- **Return `429 Too Many Requests`** when the limit is hit
- **Include a `Retry-After` header** telling the client how long to wait (in seconds)
- **Include rate limit headers** so clients can self-regulate. The IETF standard form (`RateLimit` / `RateLimit-Policy`, draft-ietf-httpapi-ratelimit-headers) is what new APIs should emit; the older `X-RateLimit-*` family is what most existing clients parse, so many APIs send both:
  ```
  RateLimit-Policy: "default";q=100;w=60
  RateLimit: "default";r=23;t=37
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 23
  X-RateLimit-Reset: 37
  ```
  **Say what "reset" means.** In the IETF form, `t` is *seconds until* the window resets. `X-RateLimit-Reset` has no standard: GitHub sends a Unix timestamp, many others send seconds. Document yours and don't mix them.
- **Use different limits for different endpoints:**
  - Login/password reset: strict (5–10 per minute) to prevent brute-force
  - Read endpoints: generous (100–1000 per minute)
  - Write endpoints: moderate (30–100 per minute)
  - Search/expensive operations: strict (10–30 per minute)

### Rate Limit by What?

- **By API key** for authenticated requests
- **By IP address** for unauthenticated requests (not perfect — multiple users behind one IP — but good enough as a baseline)
- **By user ID** for per-user limits on authenticated endpoints

## Idempotency Keys

Retries are how clients cope with unreliable networks, and a retried `POST /charges` is a double charge unless the server can recognize it. The convention (Stripe's, now widely copied):

- The client sends `Idempotency-Key: <uuid>` on any non-idempotent write.
- The server stores the key **scoped to the caller** — unique on `(key, principal)` so two customers using the same UUID never collide — together with a fingerprint of the request (method, path, body hash) and, once finished, the status code and response body.
- A repeat with the same key and fingerprint gets the **stored response**, byte for byte, without re-executing.
- A repeat while the first attempt is still running returns `409 Conflict` (the request is in progress) — record the key *before* doing the work, in the same transaction, so a concurrent duplicate can't slip through.
- The same key with a **different body** is a client bug: return `422`.
- Keys expire; 24 hours is the usual TTL.

See `guides/api/api-design.md` (Idempotency) for why POST needs this and GET/PUT/DELETE mostly don't.

## CORS — Cross-Origin Resource Sharing

### What CORS Actually Does

Browsers enforce the **same-origin policy**: JavaScript on `evil.com` can *send* a request to `api.example.com` — and the browser will attach `api.example.com`'s cookies to it — but the script is **not allowed to read the response**. That's the protection: a malicious page can't pull your bank balance out of your bank's API.

CORS is the mechanism your API uses to *relax* that rule for specific origins: "yes, `app.example.com` is allowed to read my responses." Two consequences people miss:

- **CORS does not prevent CSRF.** The request still goes out, cookies and all, and a state-changing endpoint still runs. What stops CSRF is `SameSite` cookies plus anti-CSRF tokens (see `rules/security.md`). CORS only governs who can read the answer.
- **CORS is a browser feature.** `curl`, mobile apps, and servers ignore it entirely. It protects your *users* from other sites; it does not protect your *API* from anyone.

### The Real Mistakes

**Reflecting the request's `Origin` header — with credentials.** The classic bug looks like this:

```js
res.setHeader('Access-Control-Allow-Origin', req.headers.origin);
res.setHeader('Access-Control-Allow-Credentials', 'true');
```

Browsers refuse `Access-Control-Allow-Origin: *` when credentials are involved — but a reflected origin isn't `*`, it's whatever the attacker's page sent, so the browser accepts it. Now `evil.com` can make cookie-authenticated requests to your API *and read the responses*. That's full read access to the victim's account. Regex "allowlists" that match `example.com.evil.com`, and code that accepts the literal origin `null` (sandboxed iframes and some file pages send it), are the same bug in disguise.

**`Access-Control-Allow-Origin: *` on its own** is only a problem if you think it's doing something it isn't. It's fine for public, header-token-authenticated APIs that never use cookies (the browser won't send credentials to a `*` origin anyway, and a token in a header is only attached by code that already has the token). It's wrong for anything cookie-based — and browsers will block it there — so if you find yourself "fixing" that block by reflecting the origin, stop: that's the bug above.

**Correct approach:** Maintain an exact-match list of allowed origins and echo the origin *only if it's in the list*; otherwise send no CORS headers at all. Add `Vary: Origin` so caches don't serve one origin's headers to another.
```
Allowed: https://myapp.com, https://staging.myapp.com
```

### CORS and Credentials

If your API uses cookies for authentication and you need cross-origin requests:
- You MUST echo an exact allowed origin (not `*`, not the reflected request origin)
- Set `Access-Control-Allow-Credentials: true`
- The frontend must include `credentials: 'include'` in fetch requests
- You still need CSRF protection — CORS didn't buy you any

## WebSockets: Check the Origin

CORS doesn't apply to WebSocket handshakes. A page on `evil.com` can open `wss://api.example.com/socket`, and the browser will send your session cookie with the upgrade request. If the server accepts it, the attacker's page has a live authenticated socket — **cross-site WebSocket hijacking (CSWSH)**. Check the `Origin` header on every upgrade against your allowlist, reject anything else, and authenticate the socket the way you'd authenticate an HTTP request (a token in the first message, or a cookie plus an Origin check).

## GraphQL

One endpoint, many queries — which means the usual "protect each route" instincts don't apply:

- **Depth and complexity limits.** A nested query (`user { friends { friends { friends … } } }`) or a query that requests 10,000 items at each level costs your database everything. Cap query depth and compute a cost per query before executing.
- **Aliases and batching.** `a: login(...) b: login(...) c: login(...)` in one request runs the mutation many times and dodges per-request rate limits; batched operations do the same. Count aliases and batched operations toward the limit.
- **Introspection off in production** (or behind auth). It's a map of every type and field, including ones you forgot to protect.
- **Authorize per field, not per request.** The endpoint is authenticated, but each resolver decides whether *this* user may see *this* field of *this* object. IDOR in GraphQL is fetching `node(id: "...")` for an object you don't own.
- Persisted/allowlisted queries are the strongest fix for public GraphQL: clients may only run queries you've registered.

## Outbound Webhooks (Webhooks You Send)

When your API notifies customers' servers of events, you're the provider, and everything you demand of Stripe applies to you:

- **Sign every delivery.** HMAC-SHA256 over `timestamp + "." + body` with a per-endpoint secret, sent as a header (`Webhook-Signature: t=1700000000,v1=…`). Receivers reconstruct and compare in constant time. Include the timestamp and reject deliveries older than ~5 minutes on the receiving side so captured payloads can't be replayed. The Standard Webhooks spec documents this exact shape.
- **Unique event ID** per event (stable across retries) so receivers can dedupe.
- **Retry with backoff.** Retry on non-2xx and timeouts with exponential backoff over hours to days (e.g. 1m, 5m, 30m, 2h, 12h, 24h), and expose the delivery log so customers can see and replay failures.
- **Disable dead endpoints.** After sustained failure (days), stop sending, mark the endpoint disabled, and notify the owner — don't retry into the void forever.
- **Secrets per endpoint, rotatable with an overlap window**, and SSRF-check the destination URL when it's registered (see `rules/security.md`). Don't deliver to private addresses.

The receiving side — verify before trusting, raw body, idempotent handlers — is in `guides/api/payments.md`.

## Request Validation at the API Boundary

### Size Limits

Set maximum request body sizes. Without them:
- An attacker sends a 5GB JSON payload. Your server tries to parse it, runs out of memory, crashes.
- A malicious file upload fills your disk.

Configure limits at both your web server/framework level and your application logic:
- JSON body: 1MB is generous for most APIs. Increase only for specific endpoints that need it.
- File uploads: set per-endpoint based on what's reasonable (5MB for profile photos, 50MB for documents, etc.)

### Schema Validation

Validate the structure and types of request data before processing:
- Required fields are present
- Data types match expectations (string, number, boolean, array)
- String lengths are within bounds
- Numeric values are in valid ranges
- Enum values match allowed options

Use a validation library appropriate to your framework. Most have built-in schema validation. If you publish an OpenAPI document, derive the validators from it (or validate the implementation against it in CI) so the contract and the code can't drift — see `guides/api/api-design.md`.

### Batch Endpoints

`POST /items/batch-delete {"ids": [1, 2, 3]}` is three authorization decisions, not one. Check ownership of every item, and return per-item results (`207`-style or a results array) rather than failing the whole batch or, worse, silently skipping the check for items after the first.

## Request Logging

Log API requests for debugging and security, but be careful about what you log:

**Do log:**
- Request method and path
- Response status code
- Response time
- Client identifier (API key name or user ID — not the key itself)
- Request ID / correlation ID
- IP address (for security investigation)

**Do NOT log:**
- Authorization headers (contains tokens/keys)
- Request bodies containing passwords or payment data
- Full response bodies containing sensitive data
- Cookies

Use structured logging (JSON) with consistent field names so logs are searchable. Include a request ID in every log entry and in the response so individual requests can be traced through the system.
