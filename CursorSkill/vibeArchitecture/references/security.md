# Security Rules

> Applies to: Shared tier and above.
> For detailed explanations: see `guides/security/`

## Input Validation

- Validate ALL input at the boundary where it enters your system — form fields, API parameters, URL parameters, headers, file uploads. Don't trust it because it came from your own frontend.
- Use allowlists (define what IS valid) over denylists (define what ISN'T). Allowlists reject anything unexpected by default.
- Validate type, length, format, and range. A "name" field shouldn't accept 10,000 characters. An "age" field shouldn't accept negative numbers.
- Never build database queries by concatenating user input into the query string. Use parameterized queries or your framework's ORM. This prevents SQL injection — one of the most common and dangerous attacks.
- Never insert user-provided content directly into HTML without encoding it first. This prevents cross-site scripting (XSS), where attackers inject code that runs in other users' browsers.
- Never use user input to build file paths or system commands. This prevents path traversal and command injection attacks.

## Server-Side Requests (SSRF)

- Never fetch a user-supplied URL without validating it first. When your server fetches URLs (link previews, "summarize this page", RAG ingestion, webhook callbacks), an attacker can point it at things only your server can reach — internal services, admin panels, cloud metadata endpoints.
- Allow only the `https` scheme. Reject `file://`, `ftp://`, and plain `http://` URLs.
- Where possible, allowlist destination hosts. If a feature only needs to reach a few known services, reject everything else.
- Resolve the hostname and reject private and reserved IP ranges: 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, and 169.254.0.0/16 — especially the cloud metadata endpoint 169.254.169.254, which hands out your server's cloud credentials.
- Re-check the destination after every redirect. A safe-looking URL can redirect to an internal address.
- Set timeouts and response size limits on all fetched content. One fetch must not hang your server or fill your disk.
- Where the platform allows, run URL-fetching features with egress-restricted networking so a validation bypass has nowhere to go.

## Authentication

- Never store passwords in plain text or with reversible encryption. Use bcrypt, argon2, or scrypt. These are intentionally slow, making stolen password databases extremely hard to crack.
- Implement account lockout or rate limiting on login attempts to block brute-force attacks.
- Use established authentication libraries or services (Auth0, Firebase Auth, Supabase Auth, Clerk, etc.) rather than building your own. Authentication is deceptively difficult to get right.
- If using sessions: generate cryptographically random session IDs, set appropriate expiration, invalidate on logout and password change.
- If using tokens (JWT): keep expiration short (minutes to hours, not days), store securely, include only the minimum necessary information in the token.
- Never store authentication tokens in localStorage. Use httpOnly cookies (the browser protects these from JavaScript access) or secure, short-lived memory storage.
- Admin and privileged accounts MUST have multi-factor authentication (MFA) from day one (Shared tier and above). Offer MFA to all users at Public tier and above.
- Prefer passkeys or authenticator apps (TOTP) over SMS codes as the second factor — SMS is vulnerable to SIM-swapping.
- Require re-authentication or a step-up check (fresh password or MFA prompt) for sensitive actions: email or password changes, payout or bank detail changes, data exports.
- For OAuth/OIDC ("Sign in with Google/GitHub/etc."): use the authorization code flow with PKCE. Never use the implicit flow — it's deprecated and puts tokens in URLs. Never pass tokens in URLs or query strings.
- Validate every token you accept: issuer, audience, expiry, and signature. Register exact-match redirect URIs (no wildcards) and use the `state` parameter to protect the OAuth flow itself against CSRF.

## Authorization

- Authentication (who are you?) and authorization (what can you do?) are separate checks. Always do both.
- Check permissions on the server for every request. Client-side checks improve the user experience but are trivially bypassed — they are not security.
- Don't rely on hiding UI elements as access control. If a button is hidden but the API endpoint isn't protected, the data is exposed.
- Verify that users can only access THEIR OWN data. "Can user A see user B's records?" is one of the most common security bugs (Insecure Direct Object Reference). Always filter queries by the authenticated user's identity.

## HTTPS and Transport Security

- All traffic must use HTTPS. No exceptions, including "internal" or "non-sensitive" pages.
- Set these security headers on all responses:
  - `Strict-Transport-Security` (HSTS) — forces browsers to always use HTTPS
  - `Content-Security-Policy` (CSP) — controls what resources can load on your pages
  - `X-Content-Type-Options: nosniff` — prevents MIME type sniffing
  - `X-Frame-Options: DENY` or `SAMEORIGIN` — prevents your site from being embedded in iframes (clickjacking)
- Configure CORS with specific allowed origins. Never use `Access-Control-Allow-Origin: *` in production when credentials (cookies, auth headers) are involved.

## Secrets Management (Beyond Universal Rules)

- Use different secrets for each environment (development, staging, production). A leaked dev key shouldn't compromise production.
- Rotate secrets on a regular schedule, not only when compromised.
- In production, prefer a secrets manager (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, HashiCorp Vault) over `.env` files.
- Log access to secrets where possible. Know who retrieved what and when.

## Dependency Security

- Run automated vulnerability scanning on dependencies (`npm audit`, `pip-audit`, Dependabot, Snyk). Enable it in CI if you have a pipeline.
- When a vulnerability is reported in a dependency you use, update promptly. Don't defer security updates.
- Audit new dependencies before adding them: active maintenance, known vulnerabilities, download count, license compatibility.

## File Uploads

- Validate file type by examining file content (magic bytes), not just the file extension. Extensions are trivially faked.
- Enforce maximum file size limits.
- Store uploaded files outside the web-accessible directory. Serve them through your application, not by direct URL.
- Generate random filenames for stored files. Never use the user-provided filename in the storage path.
- Scan uploads for malware if files will be accessible to other users.
