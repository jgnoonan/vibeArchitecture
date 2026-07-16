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

## Scanning Your Own Code (SAST)

Dependency scanning (above) checks third-party code for known vulnerabilities. Static analysis — SAST — checks YOUR code for vulnerable patterns: SQL injection, hardcoded secrets, path traversal, mass assignment, unsafe deserialization. They are different checks; you want both.

For AI-generated code, SAST is arguably higher-value than for human code. AI repeats the same plausible-looking mistakes across projects, and SAST rules are written to catch exactly those patterns.

- **CodeQL** — free for public GitHub repos. Enable "Code scanning" in the repository's Security tab; the default setup covers most languages.
- **Semgrep** — fast, open source, works anywhere. Run `semgrep scan --config auto` locally, or add the CI integration.

Treat new high-severity findings as merge blockers at Public tier and above. Triage existing findings once — don't let a wall of old warnings train you to ignore new ones.

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
- **Prefer keyless, OIDC-federated deploys over stored cloud keys.** GitHub Actions (and GitLab CI, Bitbucket Pipelines) can authenticate to AWS, GCP, or Azure with short-lived OIDC tokens: the CI job proves its identity to the cloud provider and assumes a role — no long-lived secret stored anywhere. Long-lived cloud keys sitting in CI secrets are among the most-stolen credentials; a leaked one works for anyone, from anywhere, until you notice.

---

## Container and Base Images

If you use Docker: pin base image digests or specific version tags, not `latest`. Scan images with Trivy or your registry's scanner before deploy.

---

## SBOM and Artifact Provenance (Business Tier and Above)

An **SBOM** (Software Bill of Materials) is a machine-readable inventory of everything in your build — every package, every version. When the next major vulnerability lands, an SBOM answers "are we affected?" in seconds instead of days. Two standard formats exist: **CycloneDX** and **SPDX**. Generating one is cheap:

- `npm sbom` (built into npm) for Node projects
- **syft** for everything else: containers, directories, most language ecosystems

Regulated environments often require an SBOM for audits, and EU regulation is extending the requirement to ordinary products — see the Cyber Resilience Act note in `rules/compliance.md`.

**If you publish packages:** enable provenance so consumers can verify your artifact was built from your source by your CI — `npm publish --provenance` on GitHub Actions, or Sigstore signing for containers and binaries. This defends against the compromised-maintainer-laptop class of attack.

**SLSA** (Supply-chain Levels for Software Artifacts) is the maturity frame for all of this: level 1 is documented, scripted builds; higher levels add tamper-resistant, verifiable build pipelines. You don't need to chase levels — but when a customer security questionnaire asks about supply-chain maturity, SLSA is the vocabulary it will use.

---

## What Good Looks Like at Each Tier

| Tier | Minimum |
|------|---------|
| Personal | Lock file committed, `.env` in `.gitignore` |
| Shared | + `npm audit` / equivalent before deploy |
| Public | + Dependabot or equivalent, secret scanning and SAST (CodeQL or Semgrep) in CI |
| Business | + pinned CI actions, image scanning if containerized, SBOM generated at build |
| Regulated | + documented SBOM process, approved dependency allowlist |
