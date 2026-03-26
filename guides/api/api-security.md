# API Security — Why and How

> This guide explains why API-specific security measures exist and how to implement them. Read it when building public-facing APIs or when you want to understand rate limiting, CORS, and API authentication.

## Why APIs Need Extra Security

When your application is accessed through a browser, the browser provides some built-in protections (same-origin policy, cookie handling, CSRF tokens). An API is called directly by code — a mobile app, a script, another server, or an attacker with `curl`. There's no browser enforcing rules.

This means your API must protect itself. Every endpoint is a door. Every door needs a lock appropriate to what's behind it.

## API Authentication Patterns

### API Keys

A long, random string that identifies the caller. The client includes it in every request, usually in a header:
```
Authorization: Bearer your-api-key-here
```

**Good for:** Identifying which application or integration is calling your API, rate limiting per client, usage tracking and billing.

**Not good for:** Identifying individual users. An API key identifies an application, not a person. If you need to know which user is making a request, use OAuth or session-based auth.

**Rules:**
- Generate keys with a cryptographically secure random generator (at least 32 bytes)
- Store only a hash of the key in your database (like passwords, if the database is breached, the keys aren't directly usable)
- Allow key rotation — users should be able to generate a new key and revoke the old one
- Scope keys to specific permissions when possible (read-only vs. read-write, specific resources)

### OAuth 2.0

The standard protocol for "log in with Google/GitHub/etc." and for granting third-party applications limited access to user accounts.

**When to use:** When other applications need to access your users' data with their permission. When you want "Sign in with Google" functionality. When building an API that third-party developers will integrate with.

**When it's overkill:** For simple app-to-API communication where you control both sides. For internal services. For personal projects.

OAuth is complex. Use an established library or service — don't implement the protocol from scratch.

### JWT Validation

If another service issues JWTs (your auth provider, for example), your API validates them:
- Verify the signature using the issuer's public key
- Check the expiration time
- Verify the audience claim (the token was issued for your API)
- Extract the user identity and permissions from claims

See the authentication guide for more on JWT tradeoffs.

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

### Implementation Guidelines

- **Return `429 Too Many Requests`** when the limit is hit
- **Include a `Retry-After` header** telling the client how long to wait (in seconds)
- **Include rate limit headers** so clients can self-regulate:
  ```
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 23
  X-RateLimit-Reset: 1623456789
  ```
- **Use different limits for different endpoints:**
  - Login/password reset: strict (5–10 per minute) to prevent brute-force
  - Read endpoints: generous (100–1000 per minute)
  - Write endpoints: moderate (30–100 per minute)
  - Search/expensive operations: strict (10–30 per minute)

### Rate Limit by What?

- **By API key** for authenticated requests
- **By IP address** for unauthenticated requests (not perfect — multiple users behind one IP — but good enough as a baseline)
- **By user ID** for per-user limits on authenticated endpoints

## CORS — Cross-Origin Resource Sharing

### What Problem CORS Solves

Browsers enforce a "same-origin policy": JavaScript on `frontend.com` cannot make requests to `api.example.com` by default. This prevents a malicious website from making requests to your bank's API using your cookies.

CORS is the mechanism that lets you explicitly allow specific origins to make cross-origin requests.

### Common CORS Mistakes

**Mistake: `Access-Control-Allow-Origin: *`**

This allows ANY website to call your API. For public, read-only, unauthenticated APIs (like a public dataset), this is fine. For anything involving authentication or private data, it's a security vulnerability — any malicious site could make requests to your API using a visitor's credentials.

**Mistake: Reflecting the request's Origin header as the allowed origin**

Some developers dynamically set the allowed origin to whatever the request says. This is functionally the same as allowing all origins.

**Correct approach:** Maintain a list of allowed origins and only include the header if the request's origin is in the list:
```
Allowed: https://myapp.com, https://staging.myapp.com
```

### CORS and Credentials

If your API uses cookies for authentication and you need cross-origin requests:
- You MUST specify exact origins (not `*`)
- Set `Access-Control-Allow-Credentials: true`
- The frontend must include `credentials: 'include'` in fetch requests

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

Use a validation library appropriate to your framework. Most have built-in schema validation.

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
