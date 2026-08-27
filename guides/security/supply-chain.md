# Supply Chain Security

> This guide explains dependency and build-pipeline security. Read it when setting up a new project, before launch, or when the user asks about Dependabot, secret scanning, or "npm audit."

For the compact rules, see `rules/universal.md` (Dependencies section).

---

## What Supply Chain Risk Means

Your app depends on hundreds of packages you didn't write. A compromised dependency, a typosquatted package name, or a leaked CI secret can compromise your app without touching your source code. AI-generated projects often pull in packages without vetting them.

Recent examples, so this isn't abstract:

- **xz-utils (March 2024).** A multi-year social-engineering campaign got a backdoor into a core Linux compression library, one step from every SSH server on the internet. Caught by luck, by a developer investigating a half-second login delay.
- **polyfill.io (June 2024).** A CDN domain serving a script embedded on 100,000+ sites changed hands; the new owner served malware to visitors. Any script you load from someone else's domain is code you've delegated.
- **tj-actions/changed-files (March 2025).** A popular GitHub Action was compromised and its version tags moved to a malicious commit, dumping CI secrets into build logs for every workflow that referenced it by tag.
- **Shai-Hulud (September 2025).** A self-propagating npm worm: installing an infected package ran a postinstall script that stole npm and cloud tokens, then used the npm tokens to publish the worm into every package the victim maintained. It spread through hundreds of packages in days.

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

## Install Hygiene: Cooldowns and No Scripts

Most malicious package versions are caught and unpublished within a day or two. You avoid nearly all of them by simply not installing anything that new:

- **Minimum release age.** pnpm's `minimumReleaseAge` setting (e.g. `10080` minutes = 7 days) refuses to resolve versions younger than the cutoff; Renovate and Dependabot have equivalent `minimumReleaseAge` / cooldown options for update PRs. Set one.
- **`--ignore-scripts` by default.** Lifecycle scripts (`preinstall`, `postinstall`) run arbitrary code with your user's permissions on install — that's how Shai-Hulud harvested tokens. Set `ignore-scripts=true` in `.npmrc` (pnpm blocks them by default and lets you allowlist specific packages that genuinely need a build step). Run the few you need explicitly.
- **Don't run installs with long-lived credentials in the environment.** A stolen token that's not there can't be stolen. Use short-lived, scoped tokens in CI and keep publishing tokens off developer laptops.

---

## CI/CD Pipeline Hygiene

- Pin GitHub Actions to a full commit SHA with a version comment (`uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`), not a tag. Tags are mutable — the tj-actions/changed-files compromise (March 2025) worked by moving existing version tags to a malicious commit. Dependabot and Renovate will keep SHA pins updated for you.
- Set `permissions:` on every workflow to the minimum (`contents: read` by default) so a compromised step can't push code or read more secrets than it needs
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

**If you publish packages:** use **npm trusted publishing** — the registry accepts publishes only from your configured CI workflow, authenticated with a short-lived OIDC token, so there is no long-lived npm token to steal (this is the control that would have stopped Shai-Hulud from spreading). Trusted publishing generates provenance automatically; on other setups, `npm publish --provenance` on GitHub Actions or Sigstore signing for containers and binaries lets consumers verify the artifact was built from your source by your CI. PyPI, RubyGems, and crates.io offer the same OIDC-based trusted publishing.

**SLSA v1.1** (Supply-chain Levels for Software Artifacts) is the maturity frame for all of this: Build L1 is documented, scripted builds with provenance; L2 adds a hosted build platform that signs the provenance; L3 adds a hardened, isolated builder. You don't need to chase levels — but when a customer security questionnaire asks about supply-chain maturity, SLSA is the vocabulary it will use. The companion US-government frame is **NIST SSDF v1.1 (SP 800-218)**, which federal procurement references, with **SP 800-218A** adding a profile for generative-AI and model development; an SSDF v1.2 draft was published in December 2025.

---

## What Good Looks Like at Each Tier

| Tier | Minimum |
|------|---------|
| Personal | Lock file committed, `.env` in `.gitignore` |
| Shared | + `npm audit` / equivalent before deploy |
| Public | + Dependabot or equivalent, secret scanning and SAST (CodeQL or Semgrep) in CI |
| Business | + SHA-pinned CI actions, minimum release age on installs, image scanning if containerized, SBOM generated at build, trusted publishing if you publish |
| Regulated | + documented SBOM process, approved dependency allowlist |
