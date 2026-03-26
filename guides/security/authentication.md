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
- Admin accounts — always
- Accounts with access to sensitive data — strongly recommended
- All accounts — recommended for Business and Regulated tiers

**Implementation:** Use a library or service for TOTP (time-based one-time passwords, the kind authenticator apps generate). Don't build your own MFA implementation.
