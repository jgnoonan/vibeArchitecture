# Security Architecture: How the Layers Work Together

> For the compact rules, see `rules/security.md`.
> For threat modeling, see `guides/security/threat-modeling.md`.

## Why a "Security Architecture"?

The other security guides cover specific topics — secrets management, input validation, authentication, threat modeling. This guide ties them together into a coherent picture of how security layers protect your application as a system.

No single security measure is enough. Passwords can be stolen. Input validation can have gaps. Firewalls can be misconfigured. The strategy is **defense in depth** — multiple layers of protection so that when one fails (and one will), the others still protect you.

## The Layers of Defense

Think of your application like a building. Each layer is a barrier that an attacker must get through. The more layers, the harder the attack. (`guides/security/threat-modeling.md` lists the same seven layers with the same numbering as a quick checklist.)

### Layer 1: The Network Boundary

**What it does:** Controls who can reach your application at all.

- **HTTPS everywhere.** All traffic is encrypted. HTTP requests redirect to HTTPS. Without this, anyone on the network path (coffee shop Wi-Fi, ISP, compromised router) can read everything — passwords, tokens, personal data.
- **HSTS headers.** Tell browsers to always use HTTPS, even if someone types the HTTP address. This prevents downgrade attacks where an attacker intercepts the initial HTTP request before the redirect.
- **Firewall / security groups.** Only open the ports your application needs (typically 443 for HTTPS). Your database port should not be accessible from the internet — only from your application servers.
- **Rate limiting.** Limit how many requests a single client can make. Login, signup, and password-reset endpoints are throttled from Shared tier; general API rate limiting from Public tier. This blunts brute-force, credential stuffing, and denial-of-service. Counters must live in shared state (Redis or a platform limiter) — in-memory counters don't work on serverless or multi-instance deploys.
- **DDoS protection.** For public applications, use a CDN or cloud service with built-in DDoS mitigation (Cloudflare, AWS CloudFront, etc.). They absorb attack traffic before it reaches your servers.

### Layer 2: The Application Boundary

**What it does:** Controls what reaches your application code.

- **Security headers.** HTTP response headers that tell the browser how to protect your site:
  - `Content-Security-Policy` (CSP) — restricts which scripts, styles, and resources the browser is allowed to load. The strongest defense against XSS. A per-response nonce plus `'strict-dynamic'` is the modern form — host allowlists are bypassed too easily. Its `frame-ancestors` directive is the primary clickjacking control.
  - `X-Content-Type-Options: nosniff` — prevents the browser from guessing file types (which can turn a harmless file into an executable).
  - `X-Frame-Options: DENY` — legacy fallback for `frame-ancestors`; set both.
  - `Referrer-Policy` — controls how much URL information is shared when navigating away from your site.
  - `Cross-Origin-Opener-Policy` and `Cross-Origin-Resource-Policy` — isolate your window and responses from other origins.
  - `Permissions-Policy` — turns off browser features you don't use (camera, microphone, geolocation), so an injected script can't turn them on either.
  - `Cross-Origin-Opener-Policy: same-origin` blocks tab-nabbing and cross-site leaks through `window.opener`; `Cross-Origin-Resource-Policy: same-origin` (or `same-site`) stops other origins loading your responses as subresources.
- **`__Host-` cookie prefix.** Naming the session cookie `__Host-session` makes the browser enforce `Secure`, no `Domain` attribute, and `Path=/`, so a cookie planted from a sibling subdomain can't shadow yours.
- **Subresource Integrity (SRI).** Third-party scripts loaded from a CDN carry an `integrity` attribute with the expected hash; the browser refuses a file that doesn't match, so a compromised CDN can't inject code into your pages.
- **Subdomain takeover.** A DNS record that still points at a deleted S3 bucket, Heroku app, or GitHub Pages site can be claimed by anyone, who then serves content, and receives cookies scoped to your domain, on your subdomain. Remove the records when you remove the resource.
- **CORS configuration.** Maintain a fixed allowlist of origins. The dangerous bug is reflecting whatever `Origin` header arrives while sending `Access-Control-Allow-Credentials: true` — that gives any site read access to your API as the logged-in user. See `guides/api/api-security.md`.
- **Request size limits.** Set maximum sizes for request bodies, uploaded files, and URL lengths. An attacker shouldn't be able to crash your server by sending a 10GB request.

### Layer 3: Authentication

**What it does:** Verifies who the user claims to be.

- **Use an established auth provider** (Auth0, Clerk, Firebase Auth, Supabase Auth) unless you have a specific reason to build your own. Authentication is deceptively hard to get right.
- **Hash passwords with argon2id (preferred), scrypt, or bcrypt.** Never store passwords in plain text. Never use MD5 or SHA-256 for passwords (they're fast to compute, which makes them fast to brute-force).
- **Throttle login attempts without locking users out.** Progressive delays, per-IP and per-account limits, and a CAPTCHA (with an accessible alternative) under sustained abuse. Lockout is the last resort, temporary, and always notifies the account owner — a hard "lock after five failures" lets anyone lock anyone out. See `guides/security/authentication.md`.
- **Multi-factor authentication.** Mandatory for admin and privileged accounts from Shared tier; offered to all users from Public tier. It's the single most effective protection against stolen passwords.
- **Session management.** Regenerate the session ID on login, expire sessions when idle (30 minutes) and absolutely (24 hours), and let users revoke all sessions at once. Session cookies use `HttpOnly`, `Secure`, and `SameSite` flags. See `guides/security/state-management.md` for the full guide.

### Layer 4: Authorization

**What it does:** Controls what an authenticated user is allowed to do.

- **Check permissions on the server for every request.** Never rely on the client hiding UI elements as a security measure. If a user can craft a request to `/admin/delete-user/123`, the server must verify they have admin privileges — regardless of whether the admin button is visible in their browser.
- **Principle of least privilege.** Give users and services the minimum access they need. A regular user doesn't need admin access. A reporting service doesn't need write access to the database. An AI agent doesn't need access to every tool.
- **Resource-level authorization.** Don't just check "is this user an admin?" Check "is this user allowed to access this specific resource?" A user should not be able to view another user's orders by changing the ID in the URL (this is the IDOR vulnerability — Insecure Direct Object Reference). In multi-tenant systems the same rule applies to the tenant: every query carries the tenant ID from the session, ideally enforced by database row-level security.
- **Device- and session-scoped authorization.** Any identifier the client supplies (device ID, session ID, workspace ID, team ID) must be verified as belonging to the authenticated principal, not merely as well-formed. Account-level checks pass while a caller-supplied ID quietly points at someone else's resource; this is the multi-device sibling of IDOR and it enables full account takeover in recovery and device-management flows.
- **Batch endpoints authorize every item.** `POST /items/delete {ids: [...]}` checks ownership of each ID and reports per-item results; one authorized ID must not carry ten unauthorized ones through.
- **Guards fail closed.** When an authorization or validation check hits an error (the database is unreachable, the cache times out, a lookup throws) the answer is "denied," never "allowed." A `catch` block that returns success, or a default-permit fallthrough, turns every transient outage into an open door. Write the failure path first and test it.
- **Test tenant isolation explicitly.** Use unguessable, tenant-scoped IDs so an ID from one tenant means nothing in another, then log in as tenant A and try every endpoint with tenant B's IDs. Row-level security keyed on a per-request setting, or a schema/database per tenant when the tier justifies it, makes the forgotten `WHERE tenant_id = ?` impossible rather than merely unlikely.

### Layer 5: Input Validation and Data Protection

**What it does:** Ensures data entering and leaving your system is safe and correct.

- **Validate all input on the server.** Client-side validation is for user convenience. Server-side validation is for security. Never skip it.
- **Use parameterized queries.** This single practice prevents SQL injection — one of the most common and dangerous web vulnerabilities. See `guides/security/input-validation.md`.
- **Sanitize output.** When displaying user-provided content, ensure it can't execute as code (XSS prevention). Use your framework's built-in escaping.
- **Encrypt sensitive data at rest (Business tier and above).** Turn on database and object-store encryption, and add field-level envelope encryption for particularly sensitive fields (government IDs, third-party tokens). It's cheap enough that most managed databases have it on by default — leave it on at every tier.
- **Encrypt data in transit.** HTTPS for browser-to-server. TLS for server-to-database and server-to-server communication.

### Layer 6: Monitoring and Detection

**What it does:** Tells you when something is wrong so you can respond.

- **Log authentication events.** Failed logins, successful logins, password changes, permission changes. Unusual patterns (100 failed logins from the same IP) should trigger alerts.
- **Log authorization failures.** When a user tries to access something they're not allowed to. A spike in authorization failures might indicate someone probing for vulnerabilities.
- **Monitor for anomalies.** Unusual traffic patterns, requests from unexpected geographies, spikes in error rates.
- **Alert on critical events.** Admin account login, bulk data export, configuration changes, new API key creation.

### Layer 7: Backups and Recovery

**What it does:** Ensures you can recover when all else fails.

- **Regular, tested backups.** A backup you've never tested restoring is not a backup.
- **Backup encryption.** Backups contain all your data. They need the same protection as the live database.
- **Offsite backup storage.** If your primary infrastructure is compromised, your backups shouldn't be reachable from the same access.
- **Incident response plan.** When (not if) a security event happens, who does what? See `guides/reliability/incident-response.md`.

## Abuse and Bot Controls

Public signup, login, password-reset, contact, and comment endpoints attract automated abuse within days of launch: credential stuffing, fake-account farming, spam. Rate limiting (`rules/api.md`) is the first layer; the second is friction on abuse-prone forms: a CAPTCHA or a privacy-friendly challenge such as hCaptcha or Cloudflare Turnstile. Every challenge needs an accessible alternative (an object-recognition-free path, email or passkey login) because WCAG 2.2 SC 3.3.8 Accessible Authentication forbids a cognitive test with no alternative; see `rules/accessibility.md` (Forms). If account quality matters, block disposable and temporary email domains at signup and require email verification before granting anything of value, so a bot can't harvest trials or credits with throwaway addresses.

User-generated content shown to other users needs moderation designed in from the start, not bolted on after the first spam wave: length and link limits, profanity and spam filtering, a report mechanism, and the ability to remove content and ban users. Unmoderated UGC becomes a spam and abuse vector fast, and the cleanup is far more expensive than the controls.

## Supply Chain Security

Your application doesn't run in isolation. It depends on hundreds of libraries, cloud services, and build tools, and each is a way in that never touches your source code. In September 2025 the "Shai-Hulud" worm spread through hundreds of npm packages, harvesting developer and CI credentials from every machine that installed them and using those credentials to publish itself into more packages. The defenses — lock files, scanning, minimum release age, pinned CI actions, keyless publishing — are covered in `guides/security/supply-chain.md`; the compact rules are in `rules/universal.md` and `rules/security.md` (Dependency Security).

## The "Swiss Cheese" Model

Imagine each security layer as a slice of Swiss cheese. Each slice has holes (weaknesses), but the holes are in different places. Stack enough slices and no single hole goes all the way through.

- Your firewall might misconfigure one port → but authentication stops unauthorized access
- A user's password might be stolen → but multi-factor authentication blocks the attacker
- An XSS vulnerability might exist → but `HttpOnly` cookies prevent session theft (and CSP stops most payloads from running at all)
- A SQL injection attempt might be crafted → but parameterized queries neutralize it
- An attacker might gain read access → but encryption at rest makes the data unreadable

No individual layer is perfect. Together, they make your application dramatically harder to attack.

## Security by Tier

Not every project needs every layer. This table matches the tier thresholds in `rules/security.md`, `rules/api.md`, and `rules/universal.md`:

| Tier | Minimum Security Layers |
|------|------------------------|
| **Personal** | HTTPS, secrets in env vars, basic input validation, lock file committed |
| **Shared** | Above + authentication with MFA on admin accounts, authorization checks on every request, session management, security headers, CORS allowlist, throttling on login/signup/reset, CSRF protection, secrets manager preferred, dependency audit before deploy |
| **Public** | Above + general API rate limiting, MFA offered to all users, dependency scanning + secret scanning + SAST in CI, abuse/bot controls |
| **Business** | Above + encryption at rest with field-level envelope encryption for sensitive fields, secrets manager required, audit logging, monitoring/alerting, incident response plan, pinned CI actions, SBOM |
| **Regulated** | Above + penetration testing, compliance-specific controls, documented key management, approved dependency allowlist |

Start with the layers for your tier. Add more when you have evidence they're needed.

## Common Questions

**"Is my app even a target?"**
Yes. Automated bots scan every publicly accessible application on the internet. They're not targeting you specifically — they're scanning for known vulnerabilities in bulk. If you have a login form, bots are trying common passwords on it right now. The basic layers (HTTPS, input validation, secure authentication) stop these automated attacks.

**"How do I know if I've been breached?"**
Without monitoring and logging, you might not. Many breaches are discovered months later — or never. This is why Layer 6 (monitoring) matters. At minimum, log failed authentication attempts and watch for unusual patterns.

**"What's the most important thing to get right?"**
Secrets management. Hardcoded API keys and database credentials in your code repository are the #1 way applications get compromised. See `guides/security/secrets-management.md`. If you do nothing else, get your secrets out of your code.

**"Should I hire a security expert?"**
For Personal through Public tier: the rules in this framework cover the essentials. For Business tier: consider a security review before launch. For Regulated tier: yes, a professional security assessment is strongly recommended and may be legally required.
