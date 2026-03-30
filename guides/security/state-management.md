# State Management: Where Your App Remembers Things

> For the compact rules, see `rules/security.md` (session management) and `rules/reliability.md` (stateless design).

## What Is "State"?

State is any information your application remembers between requests. When a user logs in, the app needs to remember they're logged in. When they add items to a shopping cart, the app needs to remember what's in the cart. When they set a preference for dark mode, the app needs to remember that choice.

The question isn't whether your app has state — it does. The question is where that state lives and how it's managed. Get this wrong and you'll have security vulnerabilities, scaling problems, or mysterious bugs where users see each other's data.

## The Big Decision: Sessions vs. JWTs

When a user logs in, you need to remember who they are for subsequent requests. There are two main approaches, and this is one of the most debated topics in web development. Here's the honest comparison.

### Server-Side Sessions

**How it works:** When a user logs in, the server creates a session (a record that says "this user is authenticated") and stores it — typically in a database or Redis. The server sends the user a cookie containing only a session ID (a random string). On every subsequent request, the browser sends that cookie, the server looks up the session ID, and retrieves the user's information.

**The session ID is meaningless on its own.** It's just a random string. The actual data (who the user is, what permissions they have) lives on the server.

**Advantages:**
- **Easy to revoke.** Want to log someone out immediately? Delete their session from the server. Done. This matters for security — if an account is compromised, you can kill all active sessions instantly.
- **Small cookies.** The cookie contains only a random ID, not user data. It's tiny.
- **Server controls the data.** The user can't see or tamper with their session data because it lives on the server.
- **Simple to implement.** Most web frameworks have session support built in.

**Disadvantages:**
- **Requires server-side storage.** Every active session takes space in your database or Redis. For most applications this is trivial, but at very large scale it's a consideration.
- **Scaling requires shared storage.** If you run multiple application servers, they all need access to the same session store. Otherwise, a user's request might hit a server that doesn't have their session. A shared Redis instance solves this easily.

### JWTs (JSON Web Tokens)

**How it works:** When a user logs in, the server creates a JWT — a token that contains the user's information (ID, email, permissions) and is cryptographically signed. The server sends this token to the client. On subsequent requests, the client sends the token back. The server verifies the signature to confirm the token hasn't been tampered with, then reads the user information directly from the token.

**The token is self-contained.** The server doesn't need to look anything up — all the information is in the token itself.

**Advantages:**
- **No server-side storage needed.** The server doesn't store sessions. It just verifies the token's signature. This makes scaling simpler — any server can validate any token without shared state.
- **Works well across services.** If you have multiple backend services, they can all verify the same JWT without needing a shared session store.
- **Good for APIs consumed by third parties.** External clients can authenticate with a token without needing cookies.

**Disadvantages:**
- **Hard to revoke.** This is the biggest problem. A JWT is valid until it expires. If a user's account is compromised and you need to log them out immediately, you can't — the token is still valid. Workarounds exist (token blocklists, short expiry times) but they add the complexity that JWTs were supposed to eliminate.
- **Larger than session cookies.** A JWT carrying user data can be 1–2KB. Not huge, but it's sent with every request.
- **Token contents are readable.** JWTs are signed but not encrypted by default. Anyone can decode the token and read the contents. Never put sensitive data (passwords, secrets, detailed permissions) in a JWT.
- **Complex to implement correctly.** Token rotation, refresh tokens, secure storage on the client, handling expiration — there are many ways to get this wrong.

### Which Should I Use?

**For most web applications: server-side sessions.**

Sessions are simpler, more secure (easy revocation), and the "scaling problem" is solved by a single Redis instance that costs a few dollars a month. Most applications will never outgrow this.

**Consider JWTs when:**
- You're building an API consumed by mobile apps or third-party clients (not a browser-based web app)
- You have multiple independent backend services that need to verify authentication without a shared database
- You're building a system where statelessness is a hard requirement

**The common mistake:** Choosing JWTs "because they're modern" or "because I don't want to manage sessions." JWTs are not simpler — they shift the complexity to token management, refresh flows, and the revocation problem. For a browser-based web app with one backend, sessions are the better default.

## Client-Side Storage

Your application may also need to store data on the user's device — preferences, cached data, offline state. The browser provides several options, each with different security implications.

### Cookies

**What they are:** Small pieces of data that the browser automatically sends with every request to your server.

**Use for:** Session IDs, authentication tokens, small server-relevant data.

**Security settings (always set these):**
- `HttpOnly` — JavaScript can't read the cookie. Prevents XSS attacks from stealing session cookies. **Always set this for session cookies.**
- `Secure` — Cookie is only sent over HTTPS. Prevents interception on insecure connections. **Always set this in production.**
- `SameSite=Lax` or `SameSite=Strict` — Prevents the browser from sending the cookie with cross-site requests. Protects against CSRF attacks. **Always set this.**
- Short `Max-Age` or `Expires` — Don't let session cookies live forever. A few hours to a few days is appropriate for most applications.

### localStorage

**What it is:** A key-value store in the browser that persists until explicitly cleared. About 5MB per domain.

**Use for:** User preferences (dark mode, language), non-sensitive cached data, UI state.

**Never use for:** Authentication tokens, session data, or anything sensitive. JavaScript (including injected scripts from XSS vulnerabilities) can read everything in localStorage. If an attacker injects a script, they can steal anything stored there.

### sessionStorage

**What it is:** Like localStorage, but cleared when the browser tab is closed.

**Use for:** Temporary data that should not persist between sessions — form drafts, temporary filters, wizard progress.

**Same security limitations as localStorage** — readable by any JavaScript on the page.

### IndexedDB

**What it is:** A more capable client-side database for larger amounts of structured data.

**Use for:** Offline-capable applications that need to store significant data locally, cached API responses.

**Same security limitations** — accessible to JavaScript on the page.

### The Rule

**Sensitive data (tokens, personal info, financial data) goes in `HttpOnly` cookies — never in localStorage, sessionStorage, or IndexedDB.** Cookies with `HttpOnly` are the only client-side storage that JavaScript can't access, which makes them the only storage safe from XSS attacks.

## Stateless Application Design

"Stateless" means your application server doesn't store any data in its own memory between requests. Every request is self-contained — the server has everything it needs to process it from the request itself plus external data stores.

### Why It Matters

If your application stores state in memory (sessions in a variable, cached data in an object, uploaded files in a temp directory), that state only exists on one server. Run two servers behind a load balancer and a user's second request might hit the other server — which doesn't have their session, their cached data, or their uploaded file.

**Stateless design means:**
- Sessions → stored in Redis or a database (not in server memory)
- Uploaded files → stored in cloud storage like S3 (not on the server's disk)
- Cached data → stored in Redis or Memcached (not in a server-side variable)
- Background jobs → managed by a job queue (not by an in-memory timer)

### When It Matters

- **Single server (Personal/Shared tier):** Statelessness is nice to have but not critical. Your one server has all the state.
- **Multiple servers (Public tier and above):** Statelessness is required for horizontal scaling. If you can't run two copies of your app behind a load balancer, you can't scale horizontally.
- **Containerized deployments:** Containers can be stopped and restarted at any time. Any state in the container's memory or filesystem is lost. External state stores are essential.

### How to Check

Ask your AI: *"Is this application stateless? Could I run two instances behind a load balancer without users experiencing issues?"*

If the answer is no, the AI should identify what state is stored locally and help you move it to an external store.

## Common Mistakes

**Storing JWTs in localStorage.** If your site has any XSS vulnerability, an attacker's script can read the token and impersonate the user. Use `HttpOnly` cookies instead.

**Not setting `HttpOnly` on session cookies.** Without this flag, any JavaScript on your page can read the session cookie — including injected scripts from XSS attacks.

**Using JWTs with long expiration times.** A JWT that's valid for 30 days means a stolen token is usable for 30 days. Use short expiration (15 minutes to 1 hour) with refresh tokens, or just use server-side sessions.

**Keeping sessions alive forever.** Sessions should expire — both when idle (no activity for 30 minutes) and absolutely (no session lives longer than 24 hours, regardless of activity). This limits the window of exposure if a session is stolen.

**Storing application state in server memory.** Works perfectly on one server, breaks mysteriously when you add a second. The bug manifests as users randomly losing their session, seeing empty carts, or getting logged out — but only sometimes.

**Mixing concerns in cookies.** Don't put user preferences (dark mode) in the same cookie as authentication data. Authentication cookies should be `HttpOnly` (JavaScript can't read them). Preference cookies need to be readable by JavaScript to apply the preference. Use separate cookies.
