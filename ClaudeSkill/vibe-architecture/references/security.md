# Security Rules

> Applies to: Shared tier and above.
> For detailed explanations: see `guides/security/`. Each section names the guide that carries the WHY, examples, and RFC references.

## Input Validation

See `guides/security/input-validation.md` (The Major Attack Types; Mass Assignment and Self-Attested Data).

- Validate ALL input at the boundary where it enters your system (form fields, API parameters, URL parameters, headers, file uploads), even from your own frontend.
- Use allowlists (what IS valid) over denylists.
- Validate type, length, format, and range on every field.
- Never build database queries by concatenating user input; use parameterized queries or your ORM (SQL injection).
- Never insert user content into HTML without encoding it (XSS).
- Never use user input to build file paths or system commands (path traversal, command injection).
- Validate untrusted input **before** it reaches a dangerous sink (filesystem path, allocation size, decompression routine, media/file decoder); bounds-check peer-supplied lengths and sanitize filenames before committing any resource.
- Self-attested data is not authenticated data: never verify a signature against a key that arrived with the thing it signs, and never trust an identity, role, or ownership claim a record makes about itself. Trust anchors come from a separate, earlier-established channel.
- Never bind a request body directly to a database model (mass assignment); allowlist the settable fields per endpoint.
- Server-controlled fields (role, is_admin, balance, verified, owner_id) are never settable from request input.
- Never redirect to a user-supplied URL without validating it against an allowlist of your own paths or hosts (open redirect).
- Reject `__proto__`/`constructor`/`prototype` keys when merging untrusted JSON, use `Object.create(null)` maps, and keep merge libraries current (prototype pollution).
- Never run a regex with nested or overlapping quantifiers (`(a+)+`, `(\w+\s?)*`) on untrusted input; use a linear-time engine (RE2, Rust `regex`) or bound input length (ReDoS).
- Disable external entities and DTDs in every XML parser (XXE); never deserialize untrusted input with a native format that instantiates classes (Java serialization, `pickle`, PHP `unserialize`, YAML `load`); use JSON with a schema.
- Behind a proxy or CDN: prefer HTTP/2 end-to-end, reject requests carrying both `Content-Length` and `Transfer-Encoding`, and keep edge and origin on the same vendor/configuration (request smuggling).
- Send `Cache-Control: private, no-store` on authenticated responses and `Vary` on every header that changes output; never let a shared cache store a per-user response (cache poisoning/deception).

## Server-Side Requests (SSRF)

See `guides/security/input-validation.md` (SSRF).

- Never fetch a user-supplied URL (link previews, "summarize this page", RAG ingestion, webhook callbacks) without validating it first.
- Allowlist the `https` scheme; allow `http` only for explicitly public link-preview-style features; reject `file://`, `ftp://`, `gopher://`, and everything else.
- Allowlist destination hosts where the feature only needs a few known services.
- Resolve the hostname and reject private, reserved, and link-local ranges: IPv4 127.0.0.0/8, 0.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, 169.254.0.0/16; IPv6 `::1`, `fc00::/7`, `fe80::/10`, and IPv4-mapped forms like `::ffff:169.254.169.254`. Block cloud metadata endpoints by name and address (169.254.169.254, `metadata.google.internal`).
- Connect to the resolved IP you validated, not to the hostname again (DNS rebinding).
- Re-check the destination after every redirect.
- On AWS, require IMDSv2 and set the metadata hop limit to 1; use the equivalent metadata hardening on other clouds.
- Set timeouts and response size limits on all fetched content.
- Run URL-fetching features with egress-restricted networking where the platform allows.

## Authentication

See `guides/security/authentication.md` (Hashing; Password Policies; Login Throttling; Password Reset; Email Change; Passkeys; Social Login, OAuth, and OIDC; Sessions vs. Tokens; MFA).

- Never store passwords in plain text or reversibly encrypted; hash with argon2id (preferred), scrypt, or bcrypt (bcrypt truncates at 72 bytes).
- Password policy (NIST SP 800-63B-4): minimum 8 characters, 15+ recommended, allow at least 64, no composition rules, no periodic forced rotation, screen against breached-password lists (Pwned Passwords k-anonymity API).
- Rate limit login, signup, and password-reset per IP and per account with progressive delay; lockout is a last resort and must notify the owner. Counters live in shared state (Redis or a platform/WAF limiter), never in process memory (see `rules/api.md`).
- Use established authentication libraries or services (Auth0, Firebase Auth, Supabase Auth, Clerk, etc.) rather than building your own.
- Sessions: cryptographically random IDs, regenerated on login and on any privilege change, invalidated on logout and password change; defaults 30-minute idle and 24-hour absolute lifetime (longer for low-risk consumer apps if documented).
- Offer "log out everywhere" (revoke every session and refresh token in one action, for users and support); trigger it automatically on password change and MFA reset.
- JWTs: access tokens live 15 minutes to 1 hour, carry minimum claims; validation pins `alg` (reject `none`, never verify RS as HS), checks `iss`, `aud`, `exp`, `typ`, and resolves `kid` only against a trusted JWKS (RFC 8725). Rotate refresh tokens on every use for public clients and revoke the family on reuse.
- Never store authentication tokens in localStorage; use httpOnly cookies (see `guides/security/state-management.md`).
- Admin and privileged accounts MUST have MFA from day one (Shared tier and above); offer MFA to all users at Public tier and above.
- Prefer passkeys or TOTP over SMS as the second factor; syncable passkeys satisfy NIST AAL2.
- TOTP codes are single-use: record the last accepted time-step per user, reject replays, accept at most one step of skew each way.
- WebAuthn/passkeys: RP ID = registrable domain, `userVerification: "required"` for passwordless, `attestation: "none"` unless policy requires otherwise, multiple credentials per user, conditional UI (autofill).
- Password reset tokens are single-use, high-entropy, stored hashed, expire in ≤15 minutes; reset, signup, and login return the same generic response and timing whether or not the account exists (no enumeration).
- Email change verifies both addresses (confirm from the new, notify the old with a revert link) and requires step-up auth to start.
- Compare API keys, HMAC signatures, reset tokens, and OTPs with a constant-time function (`crypto.timingSafeEqual`, `hmac.compare_digest`), never `==`.
- Require re-authentication or step-up (fresh password or MFA) for sensitive actions: email/password changes, payout or bank detail changes, data exports.
- OAuth/OIDC: follow RFC 9700 / OAuth 2.1, authorization code flow with PKCE for every client; never implicit flow, resource-owner password grant, or tokens in URLs.
- Validate every token you accept (issuer, audience, expiry, signature); register exact-match redirect URIs (no wildcards); use `state` against login CSRF.
- Use Device Authorization (RFC 8628) for CLIs and agent tools, token exchange (RFC 8693) for on-behalf-of calls, and DPoP (RFC 9449) where stolen bearer tokens are the main worry.

## Authorization

See `guides/security/security-architecture.md` (Layer 4: Authorization).

- Authentication (who are you?) and authorization (what can you do?) are separate checks; always do both.
- Check permissions on the server for every request; client-side checks are UX, not security.
- Never rely on hidden UI elements as access control.
- Users can only access THEIR OWN data: filter every query by the authenticated identity (IDOR).
- Authorize the acting device or session, not just the account: verify every client-supplied identifier (device ID, session ID, workspace ID, team ID) belongs to the authenticated principal, not merely that it is well-formed.
- Batch and bulk endpoints authorize every item and report per-item results.
- Guards fail CLOSED: an error in an authorization or validation check (DB unreachable, cache timeout, lookup throws) means "denied," never "allowed." Write and test the failure path first.

### Multi-Tenancy Isolation

- Every query carries the tenant ID from the authenticated session, never from the request body or URL alone.
- Enforce isolation in the database (Postgres row-level security keyed on a per-request setting, or a schema/database per tenant when the tier justifies it), not only in application code.
- Use unguessable, tenant-scoped IDs, and test isolation explicitly: log in as tenant A and try every endpoint with tenant B's IDs.

## Cross-Site Request Forgery (CSRF)

See `guides/security/state-management.md` (cookie flags and CSRF).

- Cookie-based authentication (including httpOnly session cookies) MUST have CSRF protection.
- Set session cookies `SameSite=Lax` (or `Strict`), `Secure`, and `HttpOnly`.
- Use anti-CSRF tokens (synchronizer or double-submit) on all state-changing requests (POST/PUT/PATCH/DELETE); turn on your framework's implementation.
- Header-borne tokens (`Authorization`) are not CSRF-vulnerable but carry the token-storage risk above; pick one model and secure it fully.
- CORS does not prevent CSRF.

## Abuse and Bot Controls

See `guides/security/security-architecture.md` (Abuse and Bot Controls).

- Rate limit public signup, login, password-reset, contact, and comment endpoints (see `rules/api.md`) and add a CAPTCHA or privacy-friendly challenge (hCaptcha, Cloudflare Turnstile) on abuse-prone forms, always with an accessible alternative (WCAG 2.2 SC 3.3.8).
- Block disposable email domains on signup if account quality matters; require email verification before granting anything valuable.
- Plan moderation for any user-generated content shown to others from the start: length/link limits, spam/profanity filtering, a report mechanism, content removal, and user bans.

## HTTPS and Transport Security

See `guides/security/security-architecture.md` (Layers 1 and 2) and `guides/api/api-security.md` (CORS).

- All traffic uses HTTPS, including "internal" and "non-sensitive" pages.
- Set on all responses: `Strict-Transport-Security`; `Content-Security-Policy` (nonce-based with `'strict-dynamic'`, plus `frame-ancestors`); `X-Content-Type-Options: nosniff`; `X-Frame-Options: DENY` or `SAMEORIGIN` (legacy fallback, set both); `Referrer-Policy: strict-origin-when-cross-origin`; `Permissions-Policy` (disable unused features); `Cross-Origin-Opener-Policy: same-origin`; `Cross-Origin-Resource-Policy: same-origin` (or `same-site`).
- Name session cookies with the `__Host-` prefix (e.g., `__Host-session`).
- Use Subresource Integrity (`integrity` attribute) for third-party scripts loaded from CDNs.
- Configure CORS with a fixed origin allowlist (Shared tier and above); never reflect the incoming `Origin` (or `null`) with `Access-Control-Allow-Credentials: true`. `*` is fine only for public, header-token-only APIs that never use cookies.
- Remove DNS records that point at resources you no longer own (subdomain takeover).

## Cryptography

See `guides/security/cryptography.md`.

- Don't build your own cryptography; use your platform's vetted libraries. No tier exempts this.
- If the product IS the cryptography (E2E messaging, encrypted sync/storage), build on established patterns (X3DH/PQXDH, Double Ratchet, HPKE, age/libsodium sealed boxes), never a new protocol.
- Data whose confidentiality must last years needs hybrid post-quantum key agreement (X25519 + ML-KEM-768) today; keep TLS hybrid groups enabled.
- Encryption at rest is required at Business tier and above (database and object store), plus field-level envelope encryption (KMS-wrapped data keys) for high-sensitivity fields (see `rules/data.md`).
- Every cryptographic function gets a comment stating its security argument (what property, against which attacker), not just its mechanics.
- In E2E designs, destroying the only decrypting key is a valid, sometimes the only enforceable, deletion.

## Secrets Management (Beyond Universal Rules)

See `guides/security/secrets-management.md`.

- Use different secrets per environment (development, staging, production).
- Rotate secrets on a schedule, not only on compromise.
- Prefer a secrets manager (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, HashiCorp Vault, or platform encrypted secrets) over `.env` files at Shared tier; required at Business tier and above.
- Log access to secrets where possible.
- Only client-exposed prefixes (`NEXT_PUBLIC_`, `VITE_`, `EXPO_PUBLIC_`, `REACT_APP_`) may hold public values; never put a secret behind one.
- AI coding tools are a secret-leak surface (chat transcripts, `.mcp.json`, `claude_desktop_config.json`, `.claude/`, `.cursor/`, agent logs): reference secrets by env var name, add these paths to `.gitignore` and secret scanning, never paste a live key into a prompt.
- API keys you issue: recognizable prefix and checksum (`sk_live_` style), shown once at creation, stored only as a hash, last-used time recorded, per-key scopes.

## Dependency Security

See `guides/security/supply-chain.md`.

- Run automated dependency vulnerability scanning (`npm audit`, `pip-audit`, Dependabot, Snyk), in CI if you have a pipeline.
- Update promptly when a vulnerability is reported in a dependency you use.
- Audit new dependencies before adding: active maintenance, known vulnerabilities, download count, license compatibility.
- Pin CI actions to a full commit SHA, install with a minimum release age, and disable install scripts by default.

## File Uploads

See `guides/security/input-validation.md` (File Upload Validation).

- Validate file type by content (magic bytes), not extension.
- Enforce maximum size on compressed *and* decompressed archives (decompression bombs); reject entry paths that escape the extraction directory (zip-slip).
- Never store uploads under the web root; prefer a private bucket with presigned URLs (or presigned POST direct upload), and authorize every URL you sign.
- Serve user files from a separate origin with `Content-Disposition: attachment` and `X-Content-Type-Options: nosniff` (inline SVG/HTML on your main origin is stored XSS).
- Re-encode images and strip EXIF (including GPS) rather than storing original bytes.
- Generate random storage filenames; never use the user-provided filename in the path.
- Scan uploads for malware if other users can access them.
