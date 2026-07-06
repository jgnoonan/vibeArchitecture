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

## Authentication

- Never store passwords in plain text or with reversible encryption. Use bcrypt, argon2, or scrypt. These are intentionally slow, making stolen password databases extremely hard to crack.
- Implement account lockout or rate limiting on login attempts to block brute-force attacks.
- Use established authentication libraries or services (Auth0, Firebase Auth, Supabase Auth, Clerk, etc.) rather than building your own. Authentication is deceptively difficult to get right.
- If using sessions: generate cryptographically random session IDs, set appropriate expiration, invalidate on logout and password change.
- If using tokens (JWT): keep expiration short (minutes to hours, not days), store securely, include only the minimum necessary information in the token.
- Never store authentication tokens in localStorage. Use httpOnly cookies (the browser protects these from JavaScript access) or secure, short-lived memory storage.

## Authorization

- Authentication (who are you?) and authorization (what can you do?) are separate checks. Always do both.
- Check permissions on the server for every request. Client-side checks improve the user experience but are trivially bypassed — they are not security.
- Don't rely on hiding UI elements as access control. If a button is hidden but the API endpoint isn't protected, the data is exposed.
- Verify that users can only access THEIR OWN data. "Can user A see user B's records?" is one of the most common security bugs (Insecure Direct Object Reference). Always filter queries by the authenticated user's identity.

## Cross-Site Request Forgery (CSRF)

- If you authenticate with cookies (including httpOnly session cookies — the recommended default above), you MUST defend against CSRF. Without it, a malicious page can make the user's browser send authenticated requests to your app (the cookie rides along automatically) and perform actions as them.
- Set session cookies to `SameSite=Lax` (or `Strict`) — this alone blocks most cross-site cookie sends. Add `Secure` and `HttpOnly`.
- For state-changing requests (POST/PUT/PATCH/DELETE), also use anti-CSRF tokens (synchronizer token or double-submit cookie). Most web frameworks and auth libraries provide this — turn it on.
- Token-based auth sent in an `Authorization` header (not a cookie) is not vulnerable to CSRF in the same way, because the browser doesn't attach it automatically — but then you've taken on the token-storage risk noted above. Pick one model and secure it fully.

## Abuse and Bot Controls

- Public signup, login, password-reset, contact, and comment endpoints attract bots. Rate limit them (see `rules/api.md`) and add friction where needed: CAPTCHA or a privacy-friendly challenge (hCaptcha, Cloudflare Turnstile) on signup and other abuse-prone forms.
- Block disposable/temporary email domains on signup if account quality matters. Require email verification before granting anything valuable.
- For any user-generated content shown to others, plan for moderation from the start: length/link limits, profanity/spam filtering, a report mechanism, and the ability to remove content and ban users. Unmoderated UGC becomes a spam and abuse vector fast.

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
