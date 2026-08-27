# Compliance Rules

> Applies to: Regulated tier. Exception: the EU AI Act section applies at Public tier and above whenever EU users interact with an AI feature. For everyday privacy obligations (GDPR/CCPA data-subject rights) below Regulated tier, see `rules/privacy.md`.
> Deployment detail (BAAs, residency) and full timelines, thresholds, and reporting clocks: `guides/infrastructure/regulated-deployment.md` (Regulatory Timelines, checked August 2026).
> This file covers architectural implications of common regulations. It is NOT legal advice. Consult a qualified professional for your specific regulatory obligations. Dates were checked in August 2026; regulations move — verify before relying on any of them.

## General Principles

- Compliance requirements shape architecture; design them in from the start rather than retrofitting.
- When in doubt about a requirement, do the more secure thing.
- Document compliance decisions: what you did and why.

## Audit Trails

- Log every create, modify, and delete: who, what, when, from where (IP, client identifier). When an AI agent acts, log the agent *and* the user it acted for.
- Audit logs are append-only, unmodifiable by the application or administrators; use separate write-only storage where possible.
- Include enough context to reconstruct the event: before/after state, identity, and the authorization that permitted it.
- Set retention by regime: HIPAA 6 years for required documentation (audit-log retention is set by your risk analysis, commonly 6 years); SOC 2 typically 1 year; PCI DSS 1 year with 3 months immediately available; GDPR as long as necessary for the purpose.
- Protect audit logs with the same controls as the data they describe.

## Access Control

- Least privilege for every user, service, and process.
- Separate duties where required: deployer ≠ approver; key manager ≠ data accessor.
- Maintain an access inventory (who, what, why); review at least quarterly.
- Implement documented, audited break-glass emergency access with automatic expiration.
- Log all access grants and revocations in the audit trail.

## Data Protection

- Encrypt sensitive data at rest (AES-256) with keys in your cloud KMS.
- Encrypt all data in transit with TLS 1.2+; disable older versions.
- Classify data by sensitivity and protect each class accordingly.
- Mask or synthesize data for non-production environments; no real sensitive data in dev or staging.
- Know every copy of sensitive data (production, backups, logs, caches, analytics, third parties, AI-provider retention); each copy meets the same requirements.

## HIPAA (Healthcare Data)

If your application handles Protected Health Information (PHI):

- Use only HIPAA-eligible services under a signed Business Associate Agreement (BAA). Platform specifics: `guides/infrastructure/regulated-deployment.md`.
- Apply the "minimum necessary" standard to every access, use, and disclosure.
- Log all PHI access, reads included.
- Encrypt PHI at rest and in transit.
- Maintain a risk analysis (required document; it drives audit-log retention and control choices).
- Keep required documentation (policies, procedures, risk analyses, BAAs) 6 years from creation or last effective date.
- Breach notification: individuals within 60 days of discovery; HHS within 60 days if ≥500 individuals (otherwise annual log); media when >500 residents of a state are affected.
- The HIPAA Security Rule NPRM (January 2025) would make MFA, encryption, asset inventory, annual audits, and 72-hour restore mandatory; proposed, not final — build to it now anyway. Status: `guides/infrastructure/regulated-deployment.md`.

## PCI DSS (Payment Card Data)

If your application handles card numbers, PCI DSS v4.0.1 applies (all v4.0 requirements mandatory since 31 March 2025):

- **Strongly prefer not handling card data at all.** Use Stripe, Square, Braintree, or another PCI-compliant processor.
- Even iframe/redirect merchants (SAQ A) must meet 6.4.3 (inventory, authorize, integrity-check every payment-page script) and 11.6.1 (detect unauthorized changes to payment-page headers and content).
- If you must handle card data: segment the cardholder data environment (CDE) from the rest of the network.
- Never store CVV/CVC, full magnetic stripe data, or PINs, even encrypted.
- If storing card numbers: encrypt, restrict access, log all access, maintain a key-management process.
- Vulnerability scans quarterly; penetration tests annually.

## GDPR (EU Data Protection)

If your application processes personal data of EU residents:

- Implement data-subject rights: access (JSON/CSV export), erasure (schema designed so full deletion is possible, including backups and logs), rectification, portability, and automated-decision rights (Art. 22, `rules/privacy.md`).
- Collect only what you need; every data point has a stated purpose.
- Obtain clear, affirmative consent for processing beyond what the service needs (no pre-checked boxes). Lawful bases, consent rules, and DPIA triggers: `rules/privacy.md` (Lawful Basis).
- Maintain a Record of Processing Activities (ROPA).
- Data protection by design in architecture decisions.
- Appoint a DPO if required (large-scale processing of sensitive data).
- Cross-border transfers need a mechanism: adequacy decision, EU-US Data Privacy Framework, or Standard Contractual Clauses (`guides/infrastructure/regulated-deployment.md`).
- The Digital Omnibus GDPR amendments are proposed, not law; track, don't build to them yet.

## Children's Data (COPPA and equivalents)

If your service is directed at US children under 13, or you have actual knowledge of child users, COPPA applies (children's data makes the project Regulated, `rules/privacy.md`). The amended rule is fully in force (compliance deadline 22 April 2026):

- Verifiable parental consent before collecting personal information, and **separate** consent for third-party disclosure or targeted advertising.
- A written, published data retention policy; no indefinite retention.
- A written information security program with a named coordinator, risk assessments, and proportionate safeguards.
- Biometric identifiers and government IDs count as personal information.
- Outside the US: GDPR digital consent age is 16 (member states may lower to 13); the UK Age Appropriate Design Code applies to services likely accessed by under-18s.

## EU AI Act (AI Systems Serving EU Users)

If EU users interact with an AI system in your application (full phase-in table in the guide):

- **Prohibited practices (in force since 2 February 2025):** no emotion recognition in workplaces/schools, social scoring, manipulative techniques exploiting vulnerabilities, or untargeted facial-image scraping for the EU market.
- **AI-literacy duty (Art. 4, since February 2025):** document what your AI features do, their limits, and who is responsible.
- **GPAI model obligations (since 2 August 2025):** mainly for model providers; fine-tuning and redistributing a model can make you one.
- **Transparency (Art. 50, LIVE since 2 August 2026):** tell users when they interact with AI unless obvious; disclose AI-generated or manipulated content (text published to inform the public, images, audio, video, deepfakes), machine-readably where feasible (`guides/multi-agent/llm-security.md`, LLM09).
- **High-risk stand-alone systems (Annex III, deferred to 2 December 2027):** hiring, credit, education access, essential services, law enforcement, and similar. If your feature touches one, stop and get professional advice; the deferral moves the deadline, not the work.
- **High-risk AI in regulated products (Annex I, deferred to 2 August 2028).**
- Know your role: **providers** (build or substantially modify) carry heavier obligations than **deployers** (use); building on a model API usually makes you a deployer of the model and possibly a provider of your system.

## US AI and State Laws

No federal AI statute yet; watch for preemption. If you serve US users with AI features, check at least:

- **Colorado AI Act (SB 24-205, effective 30 June 2026):** duty of care, impact assessments, consumer notice, and appeal path for high-risk AI in consequential decisions.
- **Texas TRAIGA (effective 1 January 2026):** prohibited harmful uses; disclosure when consumers interact with AI in healthcare and government contexts.
- **California SB 243 companion chatbots (effective 1 January 2026):** disclose AI, self-harm protocols, minor protections; annual reporting from July 2027.
- **California AI Transparency Act (SB 942, amended by AB 853; operative 2 August 2026, in force):** covered generative-AI providers with >1M monthly users provide latent and manifest disclosures and a free public detection tool; hosting-platform obligations from 1 January 2027.
- **CCPA ADMT regulations (adopted September 2025, phasing in through 2027):** pre-use notice, opt-out, access to the logic. See `rules/privacy.md` (Data-Subject Rights).
- Illinois, Utah, New York City, and others have narrower AI hiring/disclosure laws; if you automate employment decisions, assume one applies.

## AI Governance References

When asked "what framework do you follow for AI risk": **NIST AI RMF 1.0** (Govern / Map / Measure / Manage) with **NIST AI 600-1** (Generative AI Profile), and **ISO/IEC 42001** (certifiable AI management system) for enterprise evidence. Security mappings: `appendices/standards-mapping.md` (OWASP LLM Top 10 and Agentic Top 10).

## EU Cyber Resilience Act (Software Sold into the EU)

Applies to "products with digital elements" on the EU market, including installable software (desktop, mobile, libraries, firmware, on-prem); pure SaaS is largely out of scope unless it is a remote data-processing component of such a product. In force since 10 December 2024.

- **Reporting obligations from 11 September 2026**, including for products already on the market: actively exploited vulnerabilities and severe incidents need a 24-hour early warning, 72-hour notification, and 14-day final report via the ENISA platform to your national CSIRT. Runbook first (`guides/reliability/incident-response.md`).
- **Full application 11 December 2027:** secure-by-default, SBOM (`guides/security/supply-chain.md`), coordinated vulnerability disclosure, security updates for the support period (≥5 years unless product life is shorter), conformity assessment (self-assessment for most; third-party for "important"/"critical" classes), CE marking.

## SOC 2 (SaaS / Service Organizations)

If customers require SOC 2:

- Change management: all code and infrastructure changes go through review and approval before production.
- Maintain evidence of controls: automated logging of deployments, access changes, security events, incident responses.
- Monitor and alert on security events: failed logins, privilege escalations, unusual access patterns.
- Maintain and test an incident response plan.
- Vendor management: assess the security of third-party services, including AI providers.

## FedRAMP (US Government)

If US federal agencies will use your application, FedRAMP applies and is beyond this framework's scope (hundreds of NIST 800-53 controls, third-party assessment, typically $500K+ and months to years). Engage a specialist compliance firm before making architectural decisions.

## Deployment and Infrastructure

- Compliance constrains where and how you deploy: platform selection, data residency (including AI model APIs), deployment audit trails, and separation of duties are in `guides/infrastructure/regulated-deployment.md`.
- Your hosting platform must support your framework (HIPAA needs a BAA, PCI DSS needs segmentation, GDPR may need EU residency); verify before choosing.
- Backups inherit the data's compliance requirements: encryption, retention, access controls, residency.

## Compliance Documentation

- Maintain a data flow diagram: where data enters, is stored, processed, and exits, including every AI provider.
- Document security controls: what they are, how they work, how they're tested.
- Keep ADRs for compliance-relevant decisions.
- Store compliance documentation in version control alongside the code.
