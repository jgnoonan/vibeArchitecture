# Secrets Management — Why and How

> This guide explains the reasoning behind the secrets rules. Read it when you want to understand why these practices matter, not just what to do.

## What's a Secret?

A "secret" is any piece of information that, if exposed, would let someone access your systems, impersonate your application, or read private data. This includes:

- **API keys** — credentials that let your app talk to services (Stripe, OpenAI, Twilio, etc.)
- **Database passwords** — the credentials your app uses to connect to its database
- **Tokens** — authentication tokens, session secrets, JWT signing keys
- **Connection strings** — URLs that include credentials (often for databases)
- **Private keys** — SSH keys, TLS certificates, encryption keys
- **OAuth client secrets** — the "password" part of your app's identity with login providers

## Why This Matters So Much

When a secret is exposed, the damage is immediate and often automated:

- **Leaked AWS keys** are found by bots scanning GitHub within minutes. They spin up cryptocurrency miners on your account. People have woken up to $50,000 cloud bills.
- **Leaked database credentials** give attackers direct access to all your data — every user's email, password hash, personal information, payment details.
- **Leaked API keys** for paid services get used immediately. A leaked OpenAI key can rack up thousands in charges before you notice.

This isn't theoretical. It happens every day. GitHub reports that millions of secrets are committed to repositories each year.

## The Git History Problem

Here's what catches most people: **removing a secret from your code doesn't remove it from git history.** Git stores every version of every file. If a password appeared in any commit — even if you deleted it in the next commit — it's still there. Anyone who clones the repository can find it.

This means:
- If a secret was ever committed, even for a moment, treat it as compromised
- Rotate (change) the secret immediately
- Tools like `git-secrets`, `truffleHog`, and `gitleaks` can scan history for leaked secrets

## The Right Way: Environment Variables

The standard approach that works for projects of any size:

1. **Create a `.env` file** in your project root. This is a plain text file with key-value pairs:
   ```
   DATABASE_URL=postgresql://user:password@host:5432/mydb
   STRIPE_SECRET_KEY=sk_live_abc123...
   SESSION_SECRET=a-long-random-string
   ```

2. **Add `.env` to `.gitignore` BEFORE creating the file.** This is critical — if you create the file first and your editor auto-commits, the secret is already in git history.

3. **Create a `.env.example` file** (this one IS committed) showing what variables are needed:
   ```
   DATABASE_URL=your_database_url_here
   STRIPE_SECRET_KEY=your_stripe_secret_key_here
   SESSION_SECRET=generate_a_random_string_here
   ```

4. **Use a library to load the `.env` file** in your application:
   - Node.js: `dotenv`
   - Python: `python-dotenv`
   - Ruby: `dotenv`
   - Most frameworks have this built in

## Client-Exposed Variables Are Not Secret

Frontend frameworks ship any variable with a special prefix straight into the browser bundle or app binary: `NEXT_PUBLIC_` (Next.js), `VITE_` (Vite), `EXPO_PUBLIC_` (Expo), `REACT_APP_` (Create React App), `PUBLIC_` (SvelteKit/Astro). That is the prefix's *purpose* — it marks values that are safe to publish, like a public analytics ID. A variable named `NEXT_PUBLIC_STRIPE_SECRET_KEY` is a secret printed on a billboard. Anything a server must keep private stays unprefixed and is only read in server code (API routes, server components, edge functions).

## AI Coding Tools Are a Leak Surface

Every AI assistant you use keeps a record of what it saw. Chat transcripts persist on the provider's side and in local history; MCP server configs (`.mcp.json`, `claude_desktop_config.json`, `.cursor/mcp.json`) commonly hold API keys as plain strings; `.claude/`, `.cursor/`, `.aider*`, and agent run logs capture file contents and command output — including the `.env` an agent just `cat`-ed to "check the config."

- Reference secrets by environment variable name in MCP configs (`"env": {"API_KEY": "${API_KEY}"}`) rather than pasting the value.
- Add tool directories and logs to `.gitignore` and to your secret scanner's paths, and don't commit MCP config that contains literal keys.
- Never paste a live key into a prompt. If one slips, treat it as leaked and rotate it — the transcript outlives the conversation.
- Give agents scoped, revocable credentials (a test-mode key, a token limited to one repo) rather than your personal master keys.

## Leveling Up: Secrets Managers

A secrets manager is preferred at Shared tier and required at Business tier and above. `.env` files have limitations:
- They sit on disk in plain text
- There's no access logging
- Rotation requires manual file editing and redeployment

**Secrets managers** solve these problems:
- **AWS Secrets Manager / Azure Key Vault / GCP Secret Manager** — cloud-native, integrates with your cloud platform, handles rotation
- **HashiCorp Vault** — works across clouds and on-premise, more complex but more flexible
- **Platform-specific** — Vercel, Railway, Fly.io, and Heroku all have built-in environment variable management through their dashboards

For most projects, your hosting platform's built-in secret management is sufficient. You don't need Vault on day one.

## Secret Rotation

"Rotation" means changing a secret on a regular schedule. Think of it like changing your locks periodically — even if you don't think anyone copied your key.

Design for rotation from the start:
- Your app should read secrets from environment variables on startup or per-request, not hardcode them
- Changing a secret should require only updating the environment variable and restarting the app — no code changes
- For critical secrets, consider a rotation schedule (every 90 days is common)

### Rotating Without an Outage: The Overlap Window

"Update the variable and restart the app" is fine for a database password, but it quietly breaks for secrets that are used to *sign* things — JWT signing keys, session secrets, and webhook-signing secrets. Here's the trap:

**The problem:** Those secrets aren't just used to open a lock; they're used to stamp a signature that gets checked later. Suppose you swap your JWT signing key in one move. Every token you already handed out was signed with the *old* key. The instant the app only knows the *new* key, every one of those in-flight tokens fails its signature check — and every logged-in user is kicked out at once. The same happens if you rotate a session secret (all sessions become invalid) or a webhook-signing secret (in-flight webhook deliveries suddenly look forged). A hard cutover turns a routine rotation into an outage.

**The fix: accept two secrets at once.** Instead of swapping in a single step, run an *overlap window* where both the old and new secret are valid:

1. **Add** the new secret alongside the old one (e.g. `SESSION_SECRET_NEW` next to `SESSION_SECRET`), and deploy so the app **accepts both** when verifying a signature.
2. **Sign with the new secret** going forward, but keep **verifying against both**. Now new tokens use the new key, and old tokens still check out against the old key.
3. **Wait** for the old tokens or sessions to age out — long enough that everything signed with the old secret has expired (past your longest token lifetime).
4. **Remove** the old secret. Nothing is relying on it anymore, so this final step is safe.

At no point is there a moment where a valid, unexpired token can't be verified. That's what makes it zero-downtime.

**This isn't exotic — providers build it in.** Stripe, for example, lets you have two active webhook-signing secrets at the same time precisely so you can roll to a new one without dropping deliveries mid-rotation. Many API providers issue the new key while the old key keeps working for a grace period. When a provider offers an overlap like this, use it; it exists for exactly this reason.

For how JWT signing keys and session secrets are used in the first place, see `guides/security/authentication.md`.

## Common Mistakes

| Mistake | Why It's Bad | What To Do Instead |
|---------|-------------|-------------------|
| API key in source code | Anyone with repo access has the key | Use environment variables |
| `.env` committed to git | Secret is in git history forever | Add `.env` to `.gitignore` first |
| Secrets in frontend code | Anyone can view browser source | Keep secrets server-side only |
| Same keys for dev and prod | Dev leak compromises production | Use different secrets per environment |
| Secrets in log output | Logs are often widely accessible | Redact secrets before logging |
| Secrets in error messages | Error pages can be seen by users | Never include secrets in user-visible output |
| Sharing secrets via chat/email | Creates a permanent record in an insecure channel | Use a secrets manager or encrypted sharing tool |
| Pasting a key into an AI chat or MCP config | Transcripts and config files persist and get committed | Reference by env var name; rotate anything pasted |
| Secret behind `NEXT_PUBLIC_` / `VITE_` / `EXPO_PUBLIC_` | The prefix ships the value to every client | Only public values get the prefix; secrets stay server-side |
