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
- Validate untrusted input **before** it reaches a dangerous sink: a filesystem path, an allocation size, a decompression routine, or a media/file decoder. A peer-supplied length field or filename must be bounds-checked and sanitized before any resource is committed to it.
- Self-attested data is not authenticated data. Never verify a signature against a key that arrived alongside the thing it signs, and never trust an identity, role, or ownership claim just because the record makes it about itself. Trust anchors (keys, identities) must come from a separate, earlier-established channel.
- Never bind a request body directly to a database model (`User.update(req.body)` style). This is mass assignment — the client controls every field, including ones they shouldn't. Explicitly allowlist the fields a client may set on each endpoint.
- Server-controlled fields (role, is_admin, balance, verified, owner_id) must never be settable from request input. Set them in server code only.

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
- Authorize the acting device or session, not just the account. Any identifier the client supplies — a device ID, session ID, workspace ID, team ID — must be verified as belonging to the authenticated principal, not merely well-formed. Account-level checks pass while a caller-supplied ID quietly points at someone else's resource; this is the multi-device sibling of IDOR and it enables full account takeover in recovery and device-management flows.
- Guards fail CLOSED. If an authorization or validation check hits an error — the database is unreachable, the cache times out, a lookup throws — the answer is "denied," never "allowed." A `catch` block that returns success, or a default-permit fallthrough, turns every transient outage into an open door. Write the failure path first and test it.

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
  - `Referrer-Policy: strict-origin-when-cross-origin` — stops full URLs from leaking to other sites via the Referer header
  - `Permissions-Policy` — disables browser features you don't use (camera, microphone, geolocation)
- Name session cookies with the `__Host-` prefix (e.g., `__Host-session`). The browser then enforces Secure, no Domain attribute, and Path=/ — locking the cookie to your exact host.
- Use Subresource Integrity (SRI) for third-party scripts loaded from CDNs. The `integrity` attribute makes the browser refuse a script that doesn't match the expected hash, so a compromised CDN can't inject code into your pages.
- Configure CORS with specific allowed origins. Never use `Access-Control-Allow-Origin: *` in production when credentials (cookies, auth headers) are involved.

## Cryptography

- Don't build your own cryptography. Use your platform's vetted libraries for hashing, encryption, and signatures. This rule has no tier where it stops applying.
- If the product itself IS the cryptography — end-to-end encrypted messaging, encrypted sync, encrypted storage — don't invent a protocol. Build on established, analyzed patterns (Signal-style X3DH/PQXDH handshakes, the Double Ratchet, HPKE, age/libsodium sealed boxes). See `guides/security/cryptography.md` before designing anything.
- **Harvest-now, decrypt-later is a today problem.** Encrypted traffic recorded now can be decrypted when quantum computers can break today's key exchange. Data whose confidentiality must last years needs **hybrid post-quantum key agreement** (X25519 combined with ML-KEM-768) — hybrid, never pure-PQ and never classical-only for new long-lived-secret designs. TLS stacks and browsers already default to hybrid groups; new application-layer protocols should too. Classical signatures remain acceptable for now; confidentiality can't wait.
- Every cryptographic function gets a comment stating its **security argument** — what property it provides, against which attacker — not just its mechanics. "Encrypts the payload" is mechanics; "seals the payload so the relay operator can't read it, bound to the recipient's key so it can't be re-targeted" is an argument the next reader can check.
- In end-to-end encrypted designs, deletion can be cryptographic: destroying the only key that decrypts data is deletion, and is sometimes the only deletion you can enforce on data other devices hold.

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
