# Supply Chain Security

> This guide explains dependency and build-pipeline security. Read it when setting up a new project, before launch, or when the user asks about Dependabot, secret scanning, or "npm audit."

For the compact rules, see `rules/universal.md` (Dependencies section).

---

## What Supply Chain Risk Means

Your app depends on hundreds of packages you didn't write. A compromised dependency, a typosquatted package name, or a leaked CI secret can compromise your app without touching your source code. AI-generated projects often pull in packages without vetting them.

---

## Lock Files (Non-Negotiable)

Commit your lock file (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `Gemfile.lock`). Without it, a fresh install on CI or a teammate's machine may resolve different versions — including one with a known vulnerability.

---

## Automated Vulnerability Scanning

Enable dependency scanning on your repository:

- **GitHub:** Dependabot alerts and security updates (free for public repos)
- **npm:** `npm audit` in CI — fail on critical/high in production branches
- **Python:** `pip-audit` or `safety check`
- **Rust:** `cargo audit`

Scan on every PR, not just periodically. A vulnerability disclosed Tuesday shouldn't wait until Friday's manual check.

---

## Secret Scanning

Secrets committed to git live forever in history. Enable:

- **GitHub push protection** and secret scanning (if available on your plan)
- **gitleaks** or **truffleHog** in CI on every push

If a secret is found: rotate it immediately. Removing it from the latest commit is not enough.

---

## Evaluate Before Adding a Dependency

Before `npm install some-new-lib`, ask:

1. Is it maintained? Last commit in the past year?
2. How many dependents? Obscure packages are higher typosquat risk.
3. Could you write this in 20 lines instead?
4. Does it pull in a huge dependency tree for one function?

AI assistants love adding dependencies. Push back when the cost outweighs the benefit.

---

## CI/CD Pipeline Hygiene

- Pin action versions in GitHub Actions (`uses: actions/checkout@v4`, not `@main`)
- Limit who can approve workflow runs on fork PRs (prevent secret exfiltration)
- Store CI secrets in the platform's secret manager — never in workflow YAML
- Use least-privilege tokens for deployment (scoped to one environment)

---

## Container and Base Images

If you use Docker: pin base image digests or specific version tags, not `latest`. Scan images with Trivy or your registry's scanner before deploy.

---

## What Good Looks Like at Each Tier

| Tier | Minimum |
|------|---------|
| Personal | Lock file committed, `.env` in `.gitignore` |
| Shared | + `npm audit` / equivalent before deploy |
| Public | + Dependabot or equivalent, secret scanning in CI |
| Business | + pinned CI actions, image scanning if containerized |
| Regulated | + documented SBOM process, approved dependency allowlist |

An SBOM (Software Bill of Materials) is a list of everything in your build. Regulated environments often require one for audits. Tools like Syft or your package manager's export can generate it.
