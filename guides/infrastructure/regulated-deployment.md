# Regulated Deployment: When Compliance Shapes Where and How You Deploy

> For the compact rules, see `rules/infrastructure.md` and `rules/compliance.md`.

## Why Deployment Is Different for Regulated Apps

For most applications, picking a hosting platform is a straightforward decision — choose something that fits your stack and budget. For Regulated-tier applications, the choice is constrained by law.

You can't just deploy a healthcare app to whichever cloud platform has the nicest free tier. You can't store EU customer data on a server in Virginia because it was cheaper. You can't have a single developer push code straight to production when auditors will ask who approved the change.

Compliance requirements don't just affect your application code — they determine where your infrastructure lives, how deployments happen, and who is allowed to touch production.

## How Compliance Constrains Your Hosting Choice

### HIPAA (Healthcare Data)

If your application handles Protected Health Information (PHI), your hosting provider must sign a **Business Associate Agreement (BAA)**. This is a legal contract that makes them partially responsible for protecting the data.

**Who offers BAAs:**
- **AWS** — Extensive HIPAA-eligible services. You must configure them correctly and sign the BAA through your account. Not all AWS services are HIPAA-eligible — check the [AWS HIPAA Eligible Services list](https://aws.amazon.com/compliance/hipaa-eligible-services-reference/).
- **Google Cloud (GCP)** — BAA available. Similar to AWS, only specific services are covered.
- **Microsoft Azure** — BAA available. Strong healthcare-specific offerings.
- **Supabase** — Offers BAA on their Pro plan and above. Good option if you're already using Supabase.

**Who typically does NOT offer BAAs:**
- Most PaaS platforms (Railway, Render, Fly.io) do not currently offer BAAs. Check their current compliance pages before assuming.
- Vercel does not offer a BAA. If your frontend is on Vercel but your backend handles PHI elsewhere, that may be acceptable — but verify with a compliance professional.

**The practical impact:** If you need HIPAA compliance, you're likely deploying on AWS, GCP, or Azure — or a platform that explicitly offers a BAA. This is not a suggestion; it's a legal requirement. Using a service without a BAA to process PHI is a compliance violation regardless of how secure the service actually is.

### PCI-DSS (Payment Card Data)

If you handle credit card numbers directly (not through Stripe/Square):

- Your hosting environment must support **network segmentation** — the ability to isolate your cardholder data environment (CDE) from the rest of your infrastructure.
- You'll need a hosting provider that supports or has completed PCI-DSS compliance.
- AWS, GCP, and Azure all support PCI-DSS compliant deployments.

**The honest advice from `rules/compliance.md` still applies:** Use Stripe, Square, or another PCI-compliant payment processor so you never touch card data directly. This reduces your PCI scope from "massive infrastructure project" to "verify Stripe is configured correctly."

### SOC 2 (SaaS / Service Organizations)

SOC 2 doesn't dictate a specific hosting provider, but it requires you to **demonstrate controls** around your infrastructure:

- Change management — every production change is reviewed and approved
- Access control — documented and restricted access to production
- Monitoring — you detect and respond to security events
- Vendor management — you've assessed your hosting provider's security

Most major cloud providers and many PaaS platforms publish their own SOC 2 reports, which you can reference in your compliance documentation. If your hosting provider doesn't have a SOC 2 report, auditors will ask why you chose them.

### GDPR (EU Data Protection)

GDPR doesn't mandate a specific hosting provider, but it has **data residency implications:**

- You must know where personal data is physically stored and processed
- Transferring EU personal data outside the EU requires specific legal mechanisms (Standard Contractual Clauses, adequacy decisions)
- The simplest approach: host EU user data in an EU region

## Data Residency

Data residency means your data must physically exist in specific geographic locations. This isn't about where your users are — it's about where the servers storing their data are located.

### When Data Residency Matters

- **GDPR:** EU personal data should stay in the EU unless you have a legal basis for transfer. While transfer mechanisms exist, hosting in an EU region avoids the complexity entirely.
- **Healthcare regulations:** Some countries require health data to stay within national borders.
- **Financial regulations:** Certain jurisdictions require financial records to be stored domestically.
- **Government contracts:** Often require data to stay within the country's borders.

### How to Implement Data Residency

**Choose the right region at setup time.** Every major cloud provider lets you select a region. Pick one that satisfies your regulatory requirements:
- EU data → EU region (eu-west-1, europe-west1, West Europe)
- US healthcare data → US region
- Country-specific requirements → region in that country (if available)

**Check where managed services replicate data.** Some managed services replicate data across regions for redundancy. Verify that replication doesn't send data outside your required geography. Most providers let you configure replication regions.

**Watch for hidden data flows:**
- **CDN caches** — If you use a CDN, cached content may be stored at edge locations worldwide. For sensitive data served through a CDN, restrict cache locations to compliant regions.
- **Backups** — Verify that automated backups are stored in a compliant region. Cross-region backup replication is a common default that may violate data residency requirements.
- **Logging and monitoring services** — Log data that contains personal information inherits the same residency requirements. Check where your logging service stores data.
- **Third-party services** — Every service that processes your data (email providers, analytics, error tracking) is a potential data residency concern. Know where they store data.

**Document your data flow.** Create a diagram showing where data enters your system, where it's stored, where it's processed, and where it exits. This is a requirement for most compliance frameworks and makes data residency auditing straightforward.

## Deployment Audit Trails

For Regulated applications, every production deployment must be traceable. Auditors will ask: who deployed this change, what was changed, when, and who approved it.

### What to Log for Every Deployment

- **Who triggered it** — the person or automated system that initiated the deploy
- **What was deployed** — the git commit hash, branch, and a summary of changes
- **When it happened** — timestamp
- **Approval status** — who reviewed and approved the changes before deployment
- **Success or failure** — did the deployment complete, and were there any errors
- **Rollback events** — if a deployment was rolled back, log that too with the reason

### CI/CD as Your Audit Trail

The best way to create deployment audit trails is to make your CI/CD pipeline the only way to deploy to production. When no one can deploy manually:

- Every deploy is automatically logged by the CI/CD system
- Every deploy is tied to a git commit (traceable to specific code changes)
- Every deploy went through whatever approval gates you've configured
- The audit trail is generated as a side effect of the process, not as an extra step someone might forget

**GitHub Actions, GitLab CI, and similar platforms** automatically log every pipeline run with timestamps, triggers, and outcomes. This log becomes your deployment audit trail.

**Never deploy to production by running a command from your laptop.** In a Regulated environment, manual deploys are unauditable. Even if you log them manually, auditors will question why the process allows bypassing the pipeline.

## Separation of Duties in Deployment

The principle: the person who writes a change should not be the sole person who puts it into production. This prevents a single compromised or malicious actor from introducing and deploying harmful changes.

### How to Implement With Small Teams

You don't need a dedicated release management team. For small teams (even two people), separation of duties means:

1. **Required pull request reviews.** Configure your repository so that no code merges to the main branch without at least one approval from someone other than the author. GitHub, GitLab, and Bitbucket all support this as a branch protection rule.

2. **Automated deployment from the main branch.** Once code is merged (reviewed and approved), the CI/CD pipeline deploys automatically. The developer wrote the code. A colleague approved it. The pipeline deployed it. That's three actors — sufficient separation for most compliance frameworks.

3. **No direct pushes to main.** Protect the main branch so that all changes go through pull requests. This is a repository setting, not a policy you hope people follow.

### For Larger Teams

- **Deployment approvals in CI/CD.** Some pipelines support manual approval gates — the pipeline builds and tests, then waits for an authorized person to approve before deploying to production.
- **Environment-specific access.** Developers can deploy to staging freely. Production deployment requires additional approval or a restricted set of authorized deployers.
- **Emergency procedures.** Document a break-glass process for urgent production fixes that bypasses normal approval. The process must still be audited — log who invoked it, why, and what was changed. Review every break-glass event afterward.

## Environment Isolation

Regulated environments require strict separation between production and non-production:

### Production Data Never Leaves Production

- Development and staging databases must not contain real regulated data (real patient records, real credit card numbers, real personal information).
- Use **synthetic data** (generated fake data that resembles real data in structure) or **anonymized data** (real data with identifying information removed) for non-production environments.
- If you need to debug a production issue with realistic data, do it in a secured environment with production-level access controls — not on a developer's laptop.

### Separate Everything

- **Separate credentials.** Production and development use different API keys, database passwords, and service accounts. There should be zero chance that a development action touches production data.
- **Separate access controls.** Not everyone who can access the development environment should have access to production. Production access should be limited and logged.
- **Separate networks.** Production infrastructure should be in a different network (VPC, security group) from development infrastructure. A misconfigured dev server should not be a path into production.

### Evidence for Auditors

Auditors will ask you to demonstrate that environments are isolated. Be prepared to show:
- Different credentials per environment (not the values — the fact that they're different)
- Access control lists showing who can reach production vs. development
- Network diagrams showing separation
- Your process for generating test data without using real regulated data

## Backup and Recovery Under Compliance

Backups of regulated data inherit all the compliance requirements of the original data.

### Backup Requirements

- **Encrypt backups.** If the data must be encrypted at rest, the backup must be encrypted at rest. This includes database dumps, file backups, and any exported data.
- **Store backups in compliant locations.** If data residency requires data in the EU, backups must also be in the EU. Cross-region backup replication can violate this.
- **Retention periods.** Different regulations mandate different retention:
  - HIPAA: 6 years
  - SOC 2: Typically 1 year (varies by trust service criteria)
  - PCI-DSS: 1 year
  - GDPR: Only as long as necessary for the processing purpose — which means you may need to delete backups when a user exercises their right to erasure (this is genuinely hard; plan for it)
- **Access control on backups.** Who can access backup files? Who can restore them? Log access to backups the same way you log access to production data.

### Tested Recovery

A backup you've never restored is not a backup — it's a hope. For Regulated applications, this is doubly true because auditors will ask.

- **Test restores regularly.** At least quarterly, restore a backup to a separate environment and verify the data is intact and the application works.
- **Document the test.** Record when you tested, what you tested, and the result. This becomes evidence for auditors.
- **Measure your recovery time.** How long does it take to go from "production is down" to "restored from backup and serving traffic"? This is your actual RTO — compare it to what you promised.

## Choosing a Platform: The Decision Framework

```
Is this HIPAA (healthcare data)?
  → Does the platform offer a BAA?
    → No → You cannot use this platform for PHI. Full stop.
    → Yes → Proceed to other checks.

Is this PCI-DSS (direct card handling)?
  → Use Stripe/Square instead if at all possible.
  → If you must handle cards: does the platform support network segmentation?
    → No → Find one that does.

Does data residency apply?
  → Can you select and restrict the deployment region?
    → No → Find a platform that supports region selection.

Does SOC 2 apply?
  → Does the platform publish a SOC 2 report?
    → No → You'll need to justify this choice to auditors.

For all Regulated deployments:
  → Does the platform support CI/CD integration (no manual deploys)?
  → Can you configure access controls and audit logging?
  → Does the platform support encrypted backups in compliant regions?
```

For most Regulated applications, the practical answer is **AWS, GCP, or Azure** — they support all major compliance frameworks, offer BAAs, provide region selection, and have extensive documentation for compliance configurations. The PaaS platforms are catching up but aren't there yet for most Regulated use cases.

That said, if your Regulated requirement is "only" GDPR and you're on a platform that lets you select an EU region and has a DPA (Data Processing Agreement), that may be sufficient. GDPR is less prescriptive about infrastructure than HIPAA or PCI-DSS.

**When in doubt, consult a compliance professional before choosing your hosting platform.** The cost of expert advice is a fraction of the cost of migrating platforms after an auditor flags a problem.
