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

## Leveling Up: Secrets Managers

For production applications (Business tier and above), `.env` files have limitations:
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
