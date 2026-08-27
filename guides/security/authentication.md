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

- **Use argon2id first; scrypt or bcrypt are acceptable.** These are purposefully slow, memory-hard (argon2id, scrypt) algorithms. "Slow" is a feature — it means an attacker who steals your password database can only test a few thousand guesses per second instead of billions. If you use bcrypt, know that it silently truncates passwords at 72 bytes — a 100-character passphrase is checked as its first 72 bytes. Don't "fix" this by pre-hashing with SHA-256 unless your library documents that pattern safely; prefer argon2id.
- **Never use MD5, SHA-1, or SHA-256 for passwords.** These are fast hash algorithms designed for data integrity, not passwords. An attacker with a stolen SHA-256 password database can test billions of guesses per second on consumer hardware.
- **Never store passwords in plain text.** This should be obvious, but it still happens. If your database is breached and passwords are in plain text, every user's password is instantly compromised — and since people reuse passwords, their accounts on other sites are too.

### Password Policies

These follow NIST SP 800-63B-4 (final, July 2025), which is what auditors and modern auth libraries now expect:

- **Minimum 8 characters (SHALL), 15 or more recommended (SHOULD).** Length is what makes a password hard to guess; "Correct-Horse-Battery-Staple" beats "P@$$w0rd!".
- **Allow at least 64 characters.** Password managers generate long random strings. Let them. (Watch the 72-byte bcrypt limit above.)
- **No composition rules.** Don't require uppercase, digits, or symbols. They push users toward predictable substitutions and don't measurably improve strength.
- **No periodic rotation.** Force a change only when you have evidence of compromise. Scheduled expiry produces `Summer2026!` → `Autumn2026!`.
- **Screen against breached passwords.** Check new passwords with the Pwned Passwords k-anonymity API (you send the first five characters of the SHA-1 hash, get back matching suffixes, and compare locally — the password never leaves your server) and reject any that appear. Also block your own product name and obvious context words.
- **Show a strength meter, allow paste, and offer a "show password" toggle.** These are usability rules that produce stronger passwords than any composition rule.

### Login Throttling Without Locking Users Out

Brute-force defense is a rate-limiting problem, not a lockout problem. A hard rule like "lock after five failures" means an attacker who knows a victim's email can lock them out at will — a denial of service you built yourself.

- **Throttle per IP and per account independently.** Per-IP catches spraying across many accounts; per-account catches targeted guessing through many IPs.
- **Use progressive delay.** After a few failures, add a growing delay (1s, 2s, 4s…) or require a CAPTCHA with an accessible alternative. This makes guessing impractical while a legitimate user who mistyped twice barely notices.
- **Lock as a last resort, and notify.** If you do lock after sustained abuse, make it temporary (minutes, growing), email the owner with a "this wasn't me" link, and never reveal in the login response that the account exists or is locked in a way that differs from a wrong password.
- **Counters live in shared state.** In-memory counters reset on every serverless cold start and are not shared across instances. Use Redis or your platform's limiter (see `rules/api.md`).

### Password Reset

- Reset tokens are single-use, high-entropy (32+ random bytes), stored **hashed** (a database leak must not hand out live reset links), and expire quickly — 15 minutes is plenty.
- The "forgot password" endpoint returns the same response, in the same time, whether or not the email exists: "If that address is registered, we've sent a link." Anything else is an account-enumeration oracle.
- Signup must not enumerate either. "That email is already registered" tells an attacker who your users are; instead, send an email to the address ("you already have an account — here's how to log in") and show the same "check your email" screen both ways. Watch timing too — hashing a password only on the "new user" path is a measurable difference.
- Completing a reset invalidates every other outstanding reset token and all existing sessions for the account.

### Email Change

Changing the address that controls account recovery is the most sensitive settings change you have. Verify **both** addresses: send a confirmation link to the new address and switch only when it's clicked; send a notice with a revert link to the old address; and require step-up authentication (password or MFA) before starting. Until the new address is confirmed, keep sending security notices to the old one.

## Passkeys and WebAuthn — The Direction of Travel

Passkeys are the modern replacement for passwords. Apple, Google, and Microsoft all support them across their platforms, and every major auth provider offers them. For a new app, a passkey is the best sign-in option you can offer, and it belongs alongside passwords as a first-class choice. NIST SP 800-63B-4 recognizes syncable passkeys as meeting AAL2.

**How they work, in plain language:** Instead of a shared secret you both know (a password), the user's device holds a private key and your server holds the matching public key. When someone logs in, their device proves it holds the private key — usually unlocked with a fingerprint, face scan, or device PIN. The private key never leaves the device and is never sent to your server.

**Why this matters:**
- **Phishing-resistant.** A passkey is tied to your exact domain. A fake look-alike site can't trick the device into signing in, because the browser won't hand a `example.com` passkey to `examp1e.com`. This defeats the single most common way accounts get stolen.
- **Nothing to leak.** There's no password in your database to breach, and no "forgot password" flow to attack. If your database is stolen, the public keys in it are useless to an attacker.
- **Nothing to reuse.** Users can't pick a weak password or reuse one from a site that got breached, because there's no password at all.
- **They sync.** Modern passkeys back up and sync across a user's devices through their platform (iCloud Keychain, Google Password Manager) or a password manager, so losing one phone doesn't lock them out.

**The easy path:** Don't implement WebAuthn (the underlying standard) by hand. The providers this guide already recommends — Clerk, Auth0, Supabase Auth, and others — support passkeys with a configuration toggle. Turn it on and let them handle the cryptography and the account-recovery edge cases.

**If you configure WebAuthn yourself (or review what the AI generated), these settings matter:**
- **RP ID** is your registrable domain (`example.com`), which lets the passkey work on every subdomain. It can never change without invalidating every credential, so choose it once.
- **`userVerification: "required"`** for passwordless sign-in — the device must check biometrics or PIN, not just presence. `"preferred"` is fine when the passkey is a second factor.
- **`attestation: "none"`** unless you have a compliance reason to know the authenticator model. Requesting attestation adds privacy prompts and complexity for no benefit to a typical app.
- **Allow multiple credentials per account** (phone, laptop, security key) and show them in settings with names and last-used dates, so losing one device isn't a lockout.
- **Conditional UI** (`mediation: "conditional"`, `autocomplete="username webauthn"`) surfaces passkeys in the browser's autofill on the username field — it's the difference between "what's a passkey?" and one-tap sign-in.
- Store the credential's sign counter and reject a decreasing value (cloned authenticator), and keep a non-passkey recovery path that's as strong as the passkey (not an SMS code).

## Email Magic Links and One-Time Codes

A "magic link" logs a user in by emailing them a link they click; a one-time code (OTP) emails or texts a short code they type in. Both skip passwords entirely.

**The tradeoffs:**
- **Upside:** There's no password to leak, reset, or reuse. The account's security rides on the user's email inbox, which they already protect.
- **Downside:** Your login now depends entirely on email getting delivered promptly. If your messages land in spam or arrive ten minutes late, users simply can't log in. If you use this method, treat email deliverability as a core part of your auth system — see `guides/operations/email-deliverability.md`.

**Non-negotiable rules if you build this:**
- **Single-use.** A link or code must stop working the moment it's used once. Otherwise a forwarded or logged link is a permanent key to the account.
- **Short-lived.** Expire links and codes quickly (5–15 minutes). A link that works for days is a link that leaks.
- **Rate-limited.** Limit how often codes can be requested and how many wrong guesses are allowed, or an attacker can brute-force a short numeric code.
- **Stored hashed, compared in constant time.** Same rules as password-reset tokens.

## Social Login, OAuth, and OIDC (Sign in with Google, etc.)

"Sign in with Google/Apple/GitHub" is genuinely a good option — you offload passwords and account security to a provider that does it well. OAuth 2.0 is the authorization framework; OpenID Connect (OIDC) is the identity layer on top that gives you a signed ID token saying who the user is. As with everything else here, **use a provider (Auth0, Clerk, Supabase, Cognito) to wire it up** rather than hand-rolling the dance. But even through a provider, there are pitfalls a vibe coder hits, and getting them wrong creates real account-takeover holes:

- **Follow RFC 9700 (OAuth 2.0 Security Best Current Practice, January 2025) and OAuth 2.1.** In practice that means: authorization-code flow with PKCE for *every* client (web, SPA, mobile, CLI), no implicit flow, no resource-owner password grant, exact redirect URI matching, and sender-constrained or rotated refresh tokens.
- **Allowlist your redirect URIs exactly.** After login, the provider sends the user back to a URL you specify. Register only the exact URLs you control and nothing else — no wildcards, no "close enough." A loose redirect URI lets an attacker redirect the login (and its code) to a site they control.
- **Always use the `state` parameter.** `state` is a random value your app sends into the login flow and checks when the user comes back. It ties the response to the request that started it. Without it, an attacker can trick a victim into completing a login the attacker began — logging the victim into the attacker's account (login CSRF), or the reverse. Providers handle this for you; don't disable it. With OIDC, also send and verify `nonce`.
- **Use the authorization-code flow with PKCE, not the implicit flow.** The implicit flow hands the token straight to the browser and is deprecated. Authorization-code-with-PKCE is the current standard and what every reputable provider defaults to — keep that default. AI tools routinely generate the deprecated pattern from older training data, so check what yours produced.
- **Never put tokens in URLs or query strings.** URLs get logged everywhere — server logs, proxies, browser history, analytics tools. (This is the core reason the implicit flow is dead.)
- **Validate every token you accept** (RFC 8725, JWT Best Current Practices): issuer (`iss` — did it come from the provider you expect?), audience (`aud` — was it issued for YOUR app?), expiry (`exp`), and signature. **Pin the algorithm you accept** in your verifier — reject `alg: none`, and never let the token choose between HMAC and RSA/ECDSA (a token that says `HS256` verified against your RSA *public* key as the HMAC secret is a classic bypass). Resolve `kid` only against the issuer's published JWKS, cache it, and check `typ` so an ID token can't be replayed as an access token. Skipping audience validation means a token issued for someone else's app can be replayed against yours.
- **Rotate refresh tokens for public clients.** Browsers and mobile apps can't keep a client secret, so each refresh must issue a new refresh token and invalidate the old one; if an old one is ever presented again, revoke the whole family — someone stole it.
- **Sender-constrain tokens when a stolen bearer token is your main worry.** DPoP (RFC 9449) binds a token to a key the client proves it holds on every request, so a copied token is useless elsewhere. Mutual TLS is the server-to-server equivalent.
- **CLIs, TVs, and agent tools use the Device Authorization flow (RFC 8628):** the tool shows a short code and URL, the user approves in a real browser, and the tool polls for the token. Don't ask users to paste passwords into a terminal.
- **Services acting on behalf of a user use token exchange (RFC 8693):** exchange the user's token for a narrower, audience-specific token for the downstream service instead of forwarding the original everywhere.
- **Handle account linking and duplicate emails carefully.** The same person may sign in with Google today and email/password tomorrow. If both carry the same email, don't silently create two separate accounts, and don't let a new sign-in method attach to an existing account without proof. Before linking a new provider to an existing account, verify the person actually controls that email (or require them to log in with the existing method first). Getting this wrong lets one login method hijack an account created with another.
- **Never trust `email_verified: false`.** Providers tell you whether they've confirmed the user owns the email. If that flag is false (or missing), treat the email as unverified — never use it to match or link to an existing account, or an attacker can register an unverified address to steal someone else's account.

## Sessions vs. Tokens — The Short Version

There are two ways to remember that a user is logged in: a **server-side session** (a random ID in a cookie, the real state on your server) or a **JWT** (a signed, self-contained token the client presents). For most web apps, **server-side sessions are the better default** — they're simpler and instantly revocable. Use JWTs when you have a concrete reason (API consumed by mobile or third parties, several backend services), keep access tokens to **15 minutes to 1 hour**, and pair them with rotated refresh tokens.

Session hygiene that applies either way:

- **Regenerate the session ID on login and on any privilege change** (session fixation). If the ID from the anonymous visit survives login, an attacker who planted that ID — via a link or a subdomain cookie — now owns the authenticated session.
- **Expire sessions.** Defaults: 30 minutes idle, 24 hours absolute. Low-risk consumer apps may extend these, but write the decision down.
- **"Log out everywhere."** Users and support must be able to revoke every session and refresh token for an account in one action, and it should happen automatically on password change and MFA reset. With JWTs this needs a server-side revocation list or a per-user token version claim checked on each request.

The full comparison, cookie flags, and where tokens should (and shouldn't) live in the browser are in `guides/security/state-management.md` — read that before choosing.

## Common Authentication Mistakes

**Insecure Direct Object Reference (IDOR):** Your API checks that a user is logged in but not that they're accessing their own data. Example: User A calls `/api/users/123/orders` and gets User B's orders because the API didn't verify that user A is user 123. Always filter by the authenticated user's identity.

**Client-side-only access control:** Hiding an "Admin" button in the UI but not protecting the admin API endpoints. Anyone who inspects network requests can call those endpoints directly.

**Not invalidating sessions on security events:** When a user changes their password, all existing sessions should be invalidated. Otherwise, an attacker who stole a session continues to have access even after the password change.

**Leaking information in auth responses:** "Invalid password" tells an attacker the username exists. Use generic messages: "Invalid email or password" for both cases — and make both paths take the same time.

**No throttling on login:** Without it, an attacker can try millions of password combinations. Throttle per IP and per account with progressive delays; lock out only as a last resort and notify the owner (see "Login Throttling Without Locking Users Out" above).

**Comparing secrets with `==`:** String equality returns as soon as the first byte differs, so an attacker can learn a token or HMAC byte by byte from response timing. Use `crypto.timingSafeEqual`, `hmac.compare_digest`, or your library's constant-time compare for API keys, signatures, reset tokens, and OTPs.

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
- **Authenticator apps (TOTP)** — the six-digit codes from apps like Google Authenticator or 1Password. Widely supported, works offline, no phone number needed. A solid default. Two details libraries get wrong: **a code is single-use** — store the last accepted time-step per user and refuse it again, or a phished code can be replayed within its 30-second window — and accept **at most one step of clock skew** each way, not a wide window.
- **SMS codes** — last resort only. Attackers take over phone numbers through SIM-swapping (convincing the carrier to transfer the number to their SIM), and then receive the victim's codes. Better than nothing, but don't offer it as the primary option if you can avoid it.

### Recovery and Lockout

- **Generate recovery codes at enrollment.** A set of one-time-use codes the user stores somewhere safe. Without them, a lost phone means a locked-out user. Store them hashed, like passwords.
- **Don't let support become the bypass.** Attackers who can't beat MFA call support pretending to be locked out. Define a strict identity-verification procedure for MFA resets, and log every reset. An MFA system that support will disable over one email is theater.
- **Step-up for sensitive actions.** Even within an authenticated session, re-prompt for the password or MFA before email/password changes, payout changes, or data exports. A stolen session cookie shouldn't be enough to take over the account.

**Implementation:** Use a library or service for TOTP and WebAuthn — auth providers (Auth0, Clerk, Supabase Auth, etc.) have MFA built in. Don't build your own MFA implementation.
