# Infrastructure Rules

> Applies to: Business tier and above.
> For detailed explanations: see `guides/infrastructure/`

## Infrastructure as Code

- Define all infrastructure in code (Terraform, Pulumi, CloudFormation, CDK, or your platform's config files). If it's not in code, it doesn't reliably exist — it can't be reviewed, versioned, or reproduced.
- Never make manual changes to production infrastructure through a web console or CLI. Manual changes create drift (the real state doesn't match the code) and can't be audited or rolled back.
- Store infrastructure code in version control alongside application code. Review infrastructure changes the same way you review code changes.
- For simpler projects: if you're using a platform like Railway, Vercel, or Fly.io, their configuration files (`fly.toml`, `vercel.json`, `railway.json`) serve as lightweight infrastructure as code. Use them.

## Environment Parity

- Development, staging, and production should differ in scale, not in kind. Same database type, same services, same configuration structure. Different credentials, different sizes.
- Use the same deployment process for all environments. If staging deploys differently than production, staging isn't testing what matters.
- Never hardcode environment-specific values (URLs, credentials, feature flags) in source code. Use environment variables or configuration files that differ per environment.
- If you can't afford a full staging environment, at least maintain a separate database for testing. Never test against production data with destructive operations.

## Deployment

- Automate deployments. A deployment that requires manual steps will eventually have a step forgotten, skipped, or done wrong.
- Every deployment must be reproducible from a specific git commit. You should be able to answer "what code is running in production right now?" at any moment.
- Deploy frequently in small increments rather than rarely in large batches. Small deployments are easier to test, easier to understand, and easier to roll back.
- Run automated tests before deployment. If tests fail, the deployment stops. No exceptions, no "we'll fix it after."

## Rollback

- Every deployment must have a rollback plan. Before deploying, know the answer to: "If this breaks production, how do I undo it, and how long will that take?"
- Practice rollbacks. A rollback plan you've never tested is a plan you can't trust under pressure.
- For database schema changes: ensure backward compatibility. The previous version of your code must still work with the new schema, because during a rollback, old code will run against the new database.
- Prefer "roll forward" (deploy a fix) for minor issues. Use rollback for serious problems where you need immediate recovery and don't have time to diagnose.

## Deployment Strategies

- **Rolling deployment** (default for most apps): new version gradually replaces old instances. Simple, low-risk for most changes.
- **Blue-green deployment**: run two identical environments, switch traffic from old (blue) to new (green). Instant rollback by switching back. Good when you need zero downtime and fast rollback.
- **Canary deployment**: send a small percentage of traffic to the new version, monitor for problems, gradually increase. Best for high-traffic applications where you want to catch issues before they affect everyone.
- **Feature flags**: deploy code to production but keep new features hidden behind a flag. Enable for a subset of users, then gradually roll out. Separates deployment from release.
- Start with rolling deployments. Move to blue-green or canary when your scale or risk warrants it.

## Containers (When Used)

- One process per container. Don't run your app, database, and background worker in the same container.
- Use multi-stage builds to keep images small. Build stage has compilers and dev tools; runtime stage has only what's needed to run.
- Don't run processes as root inside containers. Create and use a non-root user.
- Pin base image versions. Never use the `latest` tag in production — it can change underneath you without warning.
- Include a `.dockerignore` file. Keep `.env` files, `.git`, `node_modules`, and other unnecessary files out of the image.
- Scan container images for known vulnerabilities before deploying (Trivy, Snyk Container, or your CI platform's built-in scanner).

## Regulated Deployment

- For Regulated-tier projects, hosting platform choice is constrained by compliance requirements. HIPAA requires a signed BAA, PCI-DSS requires network segmentation capabilities, GDPR may require data residency in specific regions. See `guides/infrastructure/regulated-deployment.md` for the full decision framework.
- Every production deployment must be auditable: who deployed, what commit, when, who approved. Use CI/CD as the sole deployment path — no manual deploys to production.
- Separation of duties: the person who writes code must not be the sole person who deploys it. Require pull request reviews and automated deployment from the main branch.

## Network Security

- Databases must never be publicly accessible. Place them in a private network; connect through your application only.
- Restrict access to management interfaces (database admin panels, monitoring dashboards, deployment tools). Require VPN or IP allowlisting, not just a password.
- Use security groups or firewall rules to allow only the traffic that's needed. Default to deny all, then explicitly allow specific ports and sources.
- Separate your application into public-facing components (web server, API) and private components (database, cache, internal services). Only the public components should be reachable from the internet.
