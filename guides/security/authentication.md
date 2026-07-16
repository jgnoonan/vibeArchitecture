# Authentication — Why and How

> This guide explains authentication patterns, their tradeoffs, and common mistakes. Read it when choosing an auth approach or understanding why the rules recommend specific practices.

## Authentication vs. Authorization

These are different things that work together:

- **Authentication** answers: "Who are you?" (proving identity)
- **Authorization** answers: "What are you allowed to do?" (checking permissions)

A common mistake is checking authentication but skipping authorization. Knowing who someone is doesn't mean they should access everything. A logged-in user shouldn't see another user's private data.

## The Strong Recommendation: Don't Build It Yourself

Authentication is one of the areas where the gap between "looks like it works" and "actually secure" is enormous. Building your own auth system means getting all of these right:

- Password hashing with the right algorithm and parameters
- Timing-attack-resistant comparison
- Session management with secure random IDs
- CSRF protection
- Rate limiting on login attempts
- Account lockout without enabling denial-of-service
- Password reset flows that don't leak information
- Token generation, validation, and revocation
- Secure cookie configuration
- Multi-factor authentication support

Each of these has subtle failure modes. Missing any one creates a vulnerability.

**Use an established service or library instead:**
- **Full-service providers:** Auth0, Clerk, Supabase Auth, Firebase Auth, AWS Cognito. They handle everything and you integrate with their API.
- **Framework libraries:** Passport.js (Node), Django's auth system, Spring Security, Devise (Rails). They handle the crypto and session management; you configure and integrate.

The cost of these services is almost always less than the cost of a security breach from a homegrown auth system.

## If You Must Handle Passwords

If you're storing passwords yourself (even with a library helping), these rules are non-negotiable:

### Hashing

- **Use bcrypt, argon2, or scrypt.** These are purposefully slow algorithms. "Slow" is a feature — it means an attacker who steals your password database can only test a few thousand guesses per second instead of billions.
- **Never use MD5, SHA-1, or SHA-256 for passwords.** These are fast hash algorithms designed for data integrity, not passwords. An attacker with a stolen SHA-256 password database can test billions of guesses per second on consumer hardware.
- **Never store passwords in plain text.** This should be obvious, but it still happens. If your database is breached and passwords are in plain text, every user's password is instantly compromised — and since people reuse passwords, their accounts on other sites are too.

### Password Policies

- **Minimum length over complexity.** "Correct-Horse-Battery-Staple" is more secure and more memorable than "P@$$w0rd!". Require a minimum of 8 characters (12+ is better); don't force special characters.
- **Check against known breached passwords.** Libraries like `haveibeenpwned` let you check if a password appeared in a data breach. Reject common and known-compromised passwords.
- **Never limit maximum password length** to anything less than 128 characters. Users who use password managers generate long random passwords. Let them.

## Passkeys and WebAuthn — The Direction of Travel

Passkeys are the modern replacement for passwords, and in 2026 they've gone mainstream — Apple, Google, and Microsoft all support them across their platforms. For a new app, a passkey is increasingly the best sign-in option you can offer, and it belongs right alongside passwords as a first-class choice.

**How they work, in plain language:** Instead of a shared secret you both know (a password), the user's device holds a private key and your server holds the matching public key. When someone logs in, their device proves it holds the private key — usually unlocked with a fingerprint, face scan, or device PIN. The private key never leaves the device and is never sent to your server.

**Why this matters:**
- **Phishing-resistant.** A passkey is tied to your exact domain. A fake look-alike site can't trick the device into signing in, because the browser won't hand a `example.com` passkey to `examp1e.com`. This defeats the single most common way accounts get stolen.
- **Nothing to leak.** There's no password in your database to breach, and no "forgot password" flow to attack. If your database is stolen, the public keys in it are useless to an attacker.
- **Nothing to reuse.** Users can't pick a weak password or reuse one from a site that got breached, because there's no password at all.
- **They sync.** Modern passkeys back up and sync across a user's devices through their platform (iCloud Keychain, Google Password Manager) or a password manager, so losing one phone doesn't lock them out.

**The easy path:** Don't implement WebAuthn (the underlying standard) by hand. The providers this guide already recommends — Clerk, Auth0, Supabase Auth, and others — support passkeys with a configuration toggle. Turn it on and let them handle the cryptography and the account-recovery edge cases.

## Email Magic Links and One-Time Codes

A "magic link" logs a user in by emailing them a link they click; a one-time code (OTP) emails or texts a short code they type in. Both skip passwords entirely.

**The tradeoffs:**
- **Upside:** There's no password to leak, reset, or reuse. The account's security rides on the user's email inbox, which they already protect.
- **Downside:** Your login now depends entirely on email getting delivered promptly. If your messages land in spam or arrive ten minutes late, users simply can't log in. If you use this method, treat email deliverability as a core part of your auth system — see `guides/operations/email-deliverability.md`.

**Non-negotiable rules if you build this:**
- **Single-use.** A link or code must stop working the moment it's used once. Otherwise a forwarded or logged link is a permanent key to the account.
- **Short-lived.** Expire links and codes quickly (5–15 minutes). A link that works for days is a link that leaks.
- **Rate-limited.** Limit how often codes can be requested and how many wrong guesses are allowed, or an attacker can brute-force a short numeric code.

## Social Login and OAuth (Sign in with Google, etc.)

"Sign in with Google/Apple/GitHub" is genuinely a good option — you offload passwords and account security to a provider that does it well. As with everything else here, **use a provider (Auth0, Clerk, Supabase, Cognito) to wire it up** rather than hand-rolling the OAuth dance. But even through a provider, there are pitfalls a vibe coder hits, and getting them wrong creates real account-takeover holes:

- **Allowlist your redirect URIs exactly.** After login, the provider sends the user back to a URL you specify. Register only the exact URLs you control and nothing else — no wildcards, no "close enough." A loose redirect URI lets an attacker redirect the login (and its token) to a site they control.
- **Always use the `state` parameter.** `state` is a random value your app sends into the login flow and checks when the user comes back. It ties the response to the request that started it. Without it, an attacker can trick a victim into completing a login the attacker began — logging the victim into the attacker's account (login CSRF), or the reverse. Providers handle this for you; don't disable it.
- **Use the authorization-code flow with PKCE, not the implicit flow.** The implicit flow hands the token straight to the browser and is deprecated. Authorization-code-with-PKCE is the current standard and what every reputable provider defaults to — keep that default. AI tools routinely generate the deprecated pattern from older training data, so check what yours produced.
- **Never put tokens in URLs or query strings.** URLs get logged everywhere — server logs, proxies, browser history, analytics tools. (This is the core reason the implicit flow is dead.)
- **Validate every token you accept:** issuer (`iss` — did it come from the provider you expect?), audience (`aud` — was it issued for YOUR app?), expiry (`exp`), and signature. Skipping audience validation means a token issued for someone else's app can be replayed against yours.
- **Handle account linking and duplicate emails carefully.** The same person may sign in with Google today and email/password tomorrow. If both carry the same email, don't silently create two separate accounts, and don't let a new sign-in method attach to an existing account without proof. Before linking a new provider to an existing account, verify the person actually controls that email (or requires them to log in with the existing method first). Getting this wrong lets one login method hijack an account created with another.
- **Never trust `email_verified: false`.** Providers tell you whether they've confirmed the user owns the email. If that flag is false (or missing), treat the email as unverified — never use it to match or link to an existing account, or an attacker can register an unverified address to steal someone else's account.

## Sessions vs. Tokens (JWTs)

Two main approaches to "remembering" that a user is logged in:

### Server-Side Sessions

**How it works:** When a user logs in, the server creates a session record (stored in a database or cache), generates a random session ID, and sends it to the browser as a cookie. On each request, the browser sends the cookie, and the server looks up the session.

**Advantages:**
- Easy to invalidate — delete the session record, and the user is logged out immediately
- Session data stays on the server — the client only has a meaningless ID
- Well-understood, battle-tested pattern

**Disadvantages:**
- Requires server-side storage (database or Redis)
- Adds a database lookup on every request
- Harder to scale across multiple servers without shared session storage

**Best for:** Traditional web applications, applications where immediate session invalidation matters.

### Token-Based (JWT)

**How it works:** When a user logs in, the server creates a JSON Web Token containing user information (claims), signs it with a secret key, and sends it to the client. On each request, the client sends the token, and the server verifies the signature without needing to look anything up.

**Advantages:**
- No server-side session storage needed
- Works naturally across multiple servers
- Can carry useful information (user ID, roles) without a database lookup

**Disadvantages:**
- **Cannot be easily revoked.** Once issued, a JWT is valid until it expires. If a user logs out or is compromised, you can't invalidate the token without additional infrastructure (a token blacklist, which partially negates the stateless advantage).
- Tokens can be large (they carry data), adding to every request
- If the signing secret is compromised, every token is compromised

**Best for:** APIs consumed by mobile apps or SPAs, microservices architectures, situations where statelessness is a priority.

### The Honest Recommendation

For most web applications, **server-side sessions are simpler and more secure.** The ability to instantly revoke sessions is valuable, and the "scaling" disadvantage rarely matters until you're running many servers. Use JWT when you have a specific reason (API-only backend, microservices, mobile clients), and keep token expiration short (15 minutes to a few hours).

## Token Storage

Where the browser stores the authentication credential matters:

| Storage | Security | Notes |
|---------|----------|-------|
| **httpOnly cookie** | Best | JavaScript can't access it. Automatically sent with requests. Requires CSRF protection. |
| **Memory (JS variable)** | Good | Lost on page refresh. No persistence. Safe from XSS but inconvenient. |
| **sessionStorage** | Moderate | Accessible to JavaScript (XSS risk). Cleared when tab closes. |
| **localStorage** | Worst | Accessible to JavaScript (XSS risk). Persists forever. Never store auth tokens here. |

**The recommendation:** httpOnly, Secure, SameSite cookies. They get the best security properties with the least effort.

**A cookie catch:** anything stored in a cookie is sent automatically by the browser on every request — including requests triggered by other sites. That's exactly what CSRF (cross-site request forgery) abuses. If you use cookie-based sessions, you must add CSRF protection (a `SameSite` cookie setting plus anti-CSRF tokens). See `rules/security.md`.

## Common Authentication Mistakes

**Insecure Direct Object Reference (IDOR):** Your API checks that a user is logged in but not that they're accessing their own data. Example: User A calls `/api/users/123/orders` and gets User B's orders because the API didn't verify that user A is user 123. Always filter by the authenticated user's identity.

**Client-side-only access control:** Hiding an "Admin" button in the UI but not protecting the admin API endpoints. Anyone who inspects network requests can call those endpoints directly.

**Not invalidating sessions on security events:** When a user changes their password, all existing sessions should be invalidated. Otherwise, an attacker who stole a session continues to have access even after the password change.

**Leaking information in auth responses:** "Invalid password" tells an attacker the username exists. Use generic messages: "Invalid email or password" for both cases.

**No rate limiting on login:** Without rate limiting, an attacker can try millions of password combinations. Implement lockout after 5–10 failed attempts, or add progressive delays.

## Multi-Factor Authentication (MFA)

MFA requires two or more forms of identification:
- Something you **know** (password)
- Something you **have** (phone, security key)
- Something you **are** (fingerprint, face)

**When to require it:**
- Admin and privileged accounts — always, from day one (Shared tier and above)
- Accounts with access to sensitive data — strongly recommended
- All users — offer it at Public tier and above; recommended to require for Business and Regulated tiers

### Choosing a Second Factor

From strongest to last resort:

- **Passkeys / WebAuthn security keys** — phishing-resistant: the credential is bound to your domain, so a fake login page can't capture it. Passkeys work as a second factor or can replace passwords entirely. Prefer these when your auth provider supports them (most do now).
- **Authenticator apps (TOTP)** — the six-digit codes from apps like Google Authenticator or 1Password. Widely supported, works offline, no phone number needed. A solid default.
- **SMS codes** — last resort only. Attackers take over phone numbers through SIM-swapping (convincing the carrier to transfer the number to their SIM), and then receive the victim's codes. Better than nothing, but don't offer it as the primary option if you can avoid it.

### Recovery and Lockout

- **Generate recovery codes at enrollment.** A set of one-time-use codes the user stores somewhere safe. Without them, a lost phone means a locked-out user. Store them hashed, like passwords.
- **Don't let support become the bypass.** Attackers who can't beat MFA call support pretending to be locked out. Define a strict identity-verification procedure for MFA resets, and log every reset. An MFA system that support will disable over one email is theater.
- **Step-up for sensitive actions.** Even within an authenticated session, re-prompt for the password or MFA before email/password changes, payout changes, or data exports. A stolen session cookie shouldn't be enough to take over the account.

**Implementation:** Use a library or service for TOTP and WebAuthn — auth providers (Auth0, Clerk, Supabase Auth, etc.) have MFA built in. Don't build your own MFA implementation.
