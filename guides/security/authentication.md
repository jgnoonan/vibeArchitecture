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

## OAuth / OIDC: Getting the Flow Right

If you use "Sign in with Google/GitHub/Apple" or access third-party APIs on a user's behalf, you're using OAuth 2.0 — usually with OpenID Connect (OIDC) on top for identity. AI tools routinely generate deprecated OAuth patterns from older training data. The current rules:

- **Authorization code flow with PKCE — always.** PKCE (Proof Key for Code Exchange) protects the code exchange even in public clients like SPAs and mobile apps. Every modern provider supports it. This is the only flow you should use for user sign-in.
- **Never the implicit flow.** Older tutorials are full of it. It delivers tokens in the URL fragment, where they leak through browser history, referrer headers, and logs. It's deprecated for good reason.
- **Never put tokens in URLs or query strings.** URLs get logged everywhere — server logs, proxies, browser history, analytics tools.
- **Validate every token you accept:** issuer (`iss` — did it come from the provider you expect?), audience (`aud` — was it issued for YOUR app?), expiry (`exp`), and signature. Skipping audience validation means a token issued for someone else's app can be replayed against yours.
- **Exact-match redirect URIs.** Register the full redirect URI with the provider; never use wildcards. A wildcard redirect lets an attacker have authorization codes sent to a domain they control.
- **Use the `state` parameter.** A random value tied to the user's session, verified when the provider redirects back. This blocks CSRF attacks on the OAuth flow itself — an attacker silently logging you into THEIR account.

As with everything in auth: your provider's official SDK handles most of this correctly. Hand-rolled OAuth callback handlers are where these bugs appear.

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
