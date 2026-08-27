# Regulated Deployment: When Compliance Shapes Where and How You Deploy

> For the compact rules, see `rules/infrastructure.md` and `rules/compliance.md`.

## Why Deployment Is Different for Regulated Apps

For most applications, picking a hosting platform is a straightforward decision — choose something that fits your stack and budget. For Regulated-tier applications, the choice is constrained by law.

You can't just deploy a healthcare app to whichever cloud platform has the nicest free tier. You can't store EU customer data on a server in Virginia because it was cheaper. You can't have a single developer push code straight to production when auditors will ask who approved the change.

Compliance requirements don't just affect your application code — they determine where your infrastructure lives, how deployments happen, and who is allowed to touch production.

## How Compliance Constrains Your Hosting Choice

The obligations themselves — audit trails, encryption, retention, breach notification — are in `rules/compliance.md`; this guide only covers what they mean for *where and how you deploy*. In one line each:

- **HIPAA:** the platform must sign a BAA, and only its HIPAA-eligible services are usable for PHI.
- **PCI DSS:** if you touch card data, the platform must support network segmentation of the cardholder data environment (and, as `rules/compliance.md` says, you should be using a processor so you don't).
- **SOC 2:** no platform requirement, but the platform should publish its own SOC 2 report or you'll be asked why you chose it.
- **GDPR:** you must know where personal data is stored and processed, and cross-border transfers need a legal mechanism.

### Who Signs a BAA (check current plans — this changes)

Platform offerings move every year; every line below is "as last checked" and must be re-verified on the platform's compliance page before you commit.

- **AWS, Google Cloud, Microsoft Azure** — BAA available through your account. Only specific services are covered: for AWS, check the [HIPAA Eligible Services list](https://aws.amazon.com/compliance/hipaa-eligible-services-reference/); GCP and Azure publish equivalents.
- **Supabase** — BAA on the Team plan and above (not Pro). Enable the HIPAA add-on and review their shared-responsibility list.
- **Render** — BAA available on Organization/Enterprise plans.
- **Vercel** — BAA available on Enterprise. If only your frontend is on Vercel and no PHI passes through it, you may not need one there — but "no PHI in the frontend" is a claim you must be able to prove (logs, edge functions, analytics).
- **Fly.io** — BAA available on enterprise arrangements; not self-serve.
- **Railway and most other small PaaS** — historically no BAA. Check.

**The practical impact:** a BAA is a legal requirement, not a preference. Using a service without one to process PHI is a violation regardless of how secure the service is. Plans that include a BAA are typically the most expensive tier, which is a real cost input to the platform decision.

### GDPR Transfer Mechanisms

Transferring EU personal data outside the EU/EEA requires one of:

- an **adequacy decision** for the destination country (the UK, Switzerland, Japan, and others);
- the **EU-US Data Privacy Framework** (2023) — for US recipients that have self-certified; check the recipient's certification and scope, and note the framework has been challenged in court before;
- **Standard Contractual Clauses (SCCs)** plus a transfer impact assessment.

The simplest approach is still to host EU user data in an EU region and avoid the question.

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
- **AI model APIs** — Every prompt is a data transfer to the provider. Three things to check: (1) **Inference region** — most major providers now offer EU (and some other regional) inference endpoints or region-pinned deployments via the cloud marketplaces; use them for EU personal data, and make sure your *fallback* model is pinned the same way. (2) **Retention** — providers typically keep API inputs/outputs for a period (often around 30 days) for abuse monitoring; regulated workloads usually need a **zero-data-retention** tier or contractual ZDR, which is a separate agreement from the DPA. (3) **Training** — confirm in writing that API traffic is not used for training. Rules: `rules/multi-agent.md` (LLM Call Hygiene).

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

## Regulatory Timelines (checked August 2026)

The compact rules in `rules/compliance.md` keep one operative date per regime. This section holds the full phase-in tables, thresholds, and reporting clocks behind those lines. Everything here was checked in August 2026; regulations move, so verify before relying on any date. None of this is legal advice.

### Audit-Log and Documentation Retention

- **HIPAA:** the 6-year rule applies to required *documentation* (policies, procedures, risk analyses, BAAs), measured from creation or last effective date. Audit-log retention is not fixed by the rule; it is set by your own risk analysis, and many organizations choose 6 years to match.
- **SOC 2:** typically 1 year of evidence.
- **PCI DSS:** 1 year, with the most recent 3 months immediately available for analysis.
- **GDPR:** as long as necessary for the processing purpose, then delete.

### HIPAA

- **Breach notification.** Individuals: without unreasonable delay and no later than 60 days after discovery. HHS: within 60 days if the breach affects 500 or more individuals; smaller breaches are logged and reported annually, within 60 days of the calendar year end. Media: notify prominent outlets when a breach affects more than 500 residents of a single state or jurisdiction.
- **Security Rule NPRM (January 2025).** Proposes making most "addressable" safeguards mandatory: MFA, encryption at rest and in transit, a technology asset inventory and network map, annual compliance audits, and the ability to restore systems within 72 hours. As of August 2026 it is proposed, not final; check current status. Building to it now is the cheap option, because every item is already good practice.

### PCI DSS v4.0.1

- v4.0.1 is the current version. v4.0's future-dated requirements became mandatory on 31 March 2025.
- Requirements 6.4.3 and 11.6.1 apply even to SAQ A merchants using a processor's iframe or redirect: 6.4.3 requires an inventory of every script on payment pages, written authorization for each, and integrity checking; 11.6.1 requires a mechanism that detects unauthorized changes to payment-page HTTP headers and content. The drop-in iframe reduces scope; it does not remove these two.

### GDPR

- **Transfer mechanisms:** adequacy decision, the EU-US Data Privacy Framework (for certified US recipients), or Standard Contractual Clauses; see GDPR Transfer Mechanisms above.
- **Digital Omnibus package.** The Commission's proposal would amend the GDPR on pseudonymized-data scope, a legitimate-interest basis for AI training, and cookie rules. Proposed, not law: track it, don't build to it.

### COPPA (amended rule)

- Effective 23 June 2025; compliance deadline 22 April 2026, so fully in force.
- Verifiable parental consent before collecting personal information, and a **separate** consent for disclosing it to third parties or using it for targeted advertising. A single bundled consent no longer suffices.
- A written, published data retention policy (what, why, how long); retain only as long as reasonably necessary for the stated purpose.
- A written information security program with a named coordinator, risk assessments, and safeguards proportionate to the data.
- Biometric identifiers (face, voice, fingerprint) and government IDs are personal information under the rule.
- Outside the US: GDPR sets the digital consent age at 16 (member states may lower it to 13); the UK Age Appropriate Design Code applies to services likely to be accessed by under-18s.

### EU AI Act

The Act phases in. The Digital Omnibus on AI (published in the Official Journal 24 July 2026, in force 27 July 2026) shifted the high-risk dates.

| Obligation | Date | Notes |
|---|---|---|
| Prohibited practices (Art. 5) | 2 February 2025 | Emotion recognition in workplaces and schools, social scoring, manipulative techniques exploiting vulnerabilities, untargeted facial-image scraping. |
| AI-literacy duty (Art. 4) | 2 February 2025 | Providers and deployers ensure staff operating AI systems have sufficient AI literacy. For a small team: document what your AI features do, their limits, and who is responsible. |
| General-purpose AI model obligations | 2 August 2025 | Fall mainly on model providers; if you fine-tune and redistribute a model, check whether you've become a GPAI provider. |
| Transparency (Art. 50) | 2 August 2026 (live) | Users told they are interacting with AI unless obvious from context; AI-generated or manipulated content (synthetic text published to inform the public, images, audio, video, deepfakes) disclosed as such, machine-readably where feasible (content credentials/watermarks: `guides/multi-agent/llm-security.md`, LLM09). |
| High-risk, stand-alone (Annex III) | 2 December 2027 (deferred) | Hiring, credit scoring, education access, essential services, law enforcement, and similar. Risk management, data governance, human oversight, logging, documentation, registration. |
| High-risk embedded in regulated products (Annex I) | 2 August 2028 (deferred) | Medical devices, machinery, vehicles. |

Roles: **providers** (who build or substantially modify an AI system) carry heavier obligations than **deployers** (who use one). Building a product on a model API typically makes you a deployer of the model but can make you a provider of your overall system.

### US State AI Laws

There is no federal AI statute; watch for federal preemption efforts.

| Law | Operative date | Scope |
|---|---|---|
| Colorado AI Act (SB 24-205) | 30 June 2026 | Duty of care for developers and deployers of "high-risk" AI making consequential decisions (employment, credit, housing, healthcare, education, insurance, legal). Impact assessments, notice to affected consumers, appeal path for adverse decisions. |
| Texas TRAIGA | 1 January 2026 | Prohibits specific harmful uses (manipulation to self-harm, unlawful discrimination, certain biometric uses); requires disclosure when consumers interact with AI in healthcare and government contexts; includes a regulatory sandbox. |
| California SB 243 (companion chatbots) | 1 January 2026 | Chatbots that simulate companionship must disclose they are AI, run self-harm protocols, and for minors remind users to take breaks and avoid sexual content. Annual reporting from July 2027. |
| California AI Transparency Act (SB 942, amended by AB 853, signed 13 October 2025) | 2 August 2026 (in force) | Applies to covered generative-AI providers with more than 1 million monthly users: latent (embedded) and manifest (visible) disclosures on AI-generated content plus a free public detection tool. Hosting-platform obligations begin 1 January 2027. |
| CCPA ADMT regulations | Adopted September 2025; phasing in through 2027 | Pre-use notice, opt-out, and access to the logic of automated decision-making technology. See `rules/privacy.md` (Data-Subject Rights). |
| Illinois, Utah, New York City, others | Various | Narrower AI hiring and disclosure laws. If you do automated employment decisions, assume one applies. |

### EU Cyber Resilience Act

| Milestone | Date |
|---|---|
| In force | 10 December 2024 |
| Reporting obligations (apply to products already on the market) | 11 September 2026 |
| Full application | 11 December 2027 |

Reporting clocks for an actively exploited vulnerability or a severe incident affecting product security: **24-hour** early warning, **72-hour** notification, **14-day** final report, submitted through the ENISA single reporting platform to your national CSIRT. Have the runbook and contact path ready before September (`guides/reliability/incident-response.md`). Full application adds secure-by-default requirements, an SBOM (`guides/security/supply-chain.md`), a coordinated vulnerability disclosure process, security updates for the support period (at least 5 years unless the product's life is shorter), conformity assessment (self-assessment for most products; third-party for "important" and "critical" classes), and CE marking.

### FedRAMP

FedRAMP (Federal Risk and Authorization Management Program) applies when US federal agencies use your application. It requires hundreds of NIST 800-53 controls, a third-party assessment organization (3PAO), dedicated compliance staff, and typically costs $500K+ and takes months to years. Engage a compliance firm that specializes in federal authorization before making architectural decisions.

### AI Governance Frameworks

- **NIST AI RMF 1.0** (Govern / Map / Measure / Manage) and **NIST AI 600-1**, the Generative AI Profile: the practical checklist of GenAI-specific risks (confabulation, data privacy, information integrity, human-AI configuration) with suggested actions.
- **ISO/IEC 42001**: the certifiable AI management system standard (the AI analog of ISO 27001), relevant when enterprise customers ask for evidence of AI governance.
