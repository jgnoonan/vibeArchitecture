# Security Architecture: How the Layers Work Together

> For the compact rules, see `rules/security.md`.
> For threat modeling, see `guides/security/threat-modeling.md`.

## Why a "Security Architecture"?

The other security guides cover specific topics — secrets management, input validation, authentication, threat modeling. This guide ties them together into a coherent picture of how security layers protect your application as a system.

No single security measure is enough. Passwords can be stolen. Input validation can have gaps. Firewalls can be misconfigured. The strategy is **defense in depth** — multiple layers of protection so that when one fails (and one will), the others still protect you.

## The Layers of Defense

Think of your application like a building. Each layer is a barrier that an attacker must get through. The more layers, the harder the attack.

### Layer 1: The Network Boundary

**What it does:** Controls who can reach your application at all.

- **HTTPS everywhere.** All traffic is encrypted. HTTP requests redirect to HTTPS. Without this, anyone on the network path (coffee shop Wi-Fi, ISP, compromised router) can read everything — passwords, tokens, personal data.
- **HSTS headers.** Tell browsers to always use HTTPS, even if someone types the HTTP address. This prevents downgrade attacks where an attacker intercepts the initial HTTP request before the redirect.
- **Firewall / security groups.** Only open the ports your application needs (typically 443 for HTTPS). Your database port should not be accessible from the internet — only from your application servers.
- **Rate limiting.** Limit how many requests a single client can make. This prevents brute-force attacks (trying thousands of passwords), credential stuffing, and denial-of-service attacks.
- **DDoS protection.** For public applications, use a CDN or cloud service with built-in DDoS mitigation (Cloudflare, AWS CloudFront, etc.). They absorb attack traffic before it reaches your servers.

### Layer 2: The Application Boundary

**What it does:** Controls what reaches your application code.

- **Security headers.** HTTP response headers that tell the browser how to protect your site:
  - `Content-Security-Policy` (CSP) — restricts which scripts, styles, and resources the browser is allowed to load. The strongest defense against XSS.
  - `X-Content-Type-Options: nosniff` — prevents the browser from guessing file types (which can turn a harmless file into an executable).
  - `X-Frame-Options: DENY` — prevents your site from being embedded in an iframe on another site (clickjacking protection).
  - `Referrer-Policy` — controls how much URL information is shared when navigating away from your site.
- **CORS configuration.** Explicitly list which domains are allowed to make requests to your API. Never use `Access-Control-Allow-Origin: *` with credentials. See `rules/security.md` for details.
- **Request size limits.** Set maximum sizes for request bodies, uploaded files, and URL lengths. An attacker shouldn't be able to crash your server by sending a 10GB request.

### Layer 3: Authentication

**What it does:** Verifies who the user claims to be.

- **Use an established auth provider** (Auth0, Clerk, Firebase Auth, Supabase Auth) unless you have a specific reason to build your own. Authentication is deceptively hard to get right.
- **Hash passwords with bcrypt, scrypt, or argon2.** Never store passwords in plain text. Never use MD5 or SHA-256 for passwords (they're fast to compute, which makes them fast to brute-force).
- **Enforce account lockout.** After 5–10 failed login attempts, temporarily lock the account or add increasing delays. This stops brute-force attacks.
- **Support two-factor authentication (2FA)** for Business tier and above. It's the single most effective protection against stolen passwords.
- **Session management.** Sessions expire when idle and have an absolute maximum lifetime. Session cookies use `HttpOnly`, `Secure`, and `SameSite` flags. See `guides/security/state-management.md` for the full guide.

### Layer 4: Authorization

**What it does:** Controls what an authenticated user is allowed to do.

- **Check permissions on the server for every request.** Never rely on the client hiding UI elements as a security measure. If a user can craft a request to `/admin/delete-user/123`, the server must verify they have admin privileges — regardless of whether the admin button is visible in their browser.
- **Principle of least privilege.** Give users and services the minimum access they need. A regular user doesn't need admin access. A reporting service doesn't need write access to the database. An AI agent doesn't need access to every tool.
- **Resource-level authorization.** Don't just check "is this user an admin?" Check "is this user allowed to access this specific resource?" A user should not be able to view another user's orders by changing the ID in the URL (this is the IDOR vulnerability — Insecure Direct Object Reference).

### Layer 5: Input Validation and Data Protection

**What it does:** Ensures data entering and leaving your system is safe and correct.

- **Validate all input on the server.** Client-side validation is for user convenience. Server-side validation is for security. Never skip it.
- **Use parameterized queries.** This single practice prevents SQL injection — one of the most common and dangerous web vulnerabilities. See `guides/security/input-validation.md`.
- **Sanitize output.** When displaying user-provided content, ensure it can't execute as code (XSS prevention). Use your framework's built-in escaping.
- **Encrypt sensitive data at rest.** Enable database encryption. Encrypt particularly sensitive fields (SSN, financial data) at the application level for an extra layer.
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

## Supply Chain Security

Your application doesn't run in isolation. It depends on hundreds of libraries (npm packages, Python packages, Ruby gems), cloud services, and tools. Each of these is a potential attack vector.

### The Risk

In 2021, a malicious package published to npm was downloaded millions of times before being detected. It stole environment variables (including API keys and database credentials) from developer machines and CI/CD pipelines. This wasn't a theoretical risk — it happened, and it affected real projects.

### Practical Defenses

**Keep dependencies updated.**
Outdated packages with known vulnerabilities are the easiest attack vector. Run `npm audit`, `pip-audit`, `bundler-audit`, or your language's equivalent regularly. Fix critical and high vulnerabilities promptly.

**Use lock files and commit them.**
Lock files (`package-lock.json`, `poetry.lock`, `Gemfile.lock`, `Cargo.lock`) pin exact dependency versions. Without them, a `npm install` might pull in a different version than what you tested — including a compromised one. Always commit your lock file to version control.

**Review new dependencies before adding them.**
Before running `npm install some-package`, spend 60 seconds checking:
- Does it have a reasonable number of downloads and stars?
- Is it actively maintained (recent commits)?
- Does the author seem legitimate (not a randomly generated username)?
- Do you actually need this package, or could you write the 20 lines of code yourself?

The last question matters more than people think. Every dependency is code you're trusting to run in your application. Fewer dependencies means a smaller attack surface.

**Use a dependency scanner in CI.**
Tools like Dependabot (GitHub), Snyk, or Renovate automatically flag vulnerable dependencies and can create pull requests to update them. Set this up once and it works continuously.

**Be cautious with installation scripts.**
Some packages run scripts during installation (`postinstall` in npm). These scripts execute with your permissions on your machine. For critical projects, consider using `--ignore-scripts` and running necessary scripts manually after review.

## The "Swiss Cheese" Model

Imagine each security layer as a slice of Swiss cheese. Each slice has holes (weaknesses), but the holes are in different places. Stack enough slices and no single hole goes all the way through.

- Your firewall might misconfigure one port → but authentication stops unauthorized access
- A user's password might be stolen → but two-factor authentication blocks the attacker
- An XSS vulnerability might exist → but `HttpOnly` cookies prevent session theft
- A SQL injection attempt might be crafted → but parameterized queries neutralize it
- An attacker might gain read access → but encryption at rest makes the data unreadable

No individual layer is perfect. Together, they make your application dramatically harder to attack.

## Security by Tier

Not every project needs every layer. Here's what's proportionate:

| Tier | Minimum Security Layers |
|------|------------------------|
| **Personal** | HTTPS, secrets in env vars, basic input validation |
| **Shared** | Above + authentication, session management, security headers |
| **Public** | Above + rate limiting, authorization, CORS, dependency scanning |
| **Business** | Above + 2FA, audit logging, monitoring/alerting, incident response plan |
| **Regulated** | Above + encryption at rest, penetration testing, compliance-specific controls |

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
