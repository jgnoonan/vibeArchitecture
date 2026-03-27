# Compliance Rules

> Applies to: Regulated tier only.
> This file covers architectural implications of common regulations. It is NOT legal advice. Consult a qualified professional for your specific regulatory obligations.

## General Principles

- Compliance requirements shape architecture. They are not bolt-on features — they must be designed in from the start. Retrofitting compliance into an existing system is dramatically more expensive.
- When in doubt about a regulatory requirement, do the more secure thing. It's cheaper to relax an overly strict control than to tighten an insufficient one.
- Document your compliance decisions. Auditors want to see not just what you did, but why you chose that approach.

## Audit Trails

- Log every action that creates, modifies, or deletes data: who did it, what they did, when, and from where (IP address, client identifier).
- Audit logs must be append-only. They cannot be modified or deleted by the application or by administrators. Use a separate storage mechanism with write-only access if possible.
- Include enough context to reconstruct what happened: the before and after state of changed records, the user's identity, and the authorization that permitted the action.
- Set retention periods based on your regulatory requirements (HIPAA: 6 years, SOC 2: typically 1 year, PCI-DSS: 1 year, GDPR: as long as necessary for the processing purpose).
- Audit logs themselves may contain sensitive data. Protect them with the same security controls as the data they describe.

## Access Control

- Implement the principle of least privilege: every user, service, and process gets the minimum access needed to perform its function. No more.
- Separate duties where required: the person who deploys code should not be the same person who approves the deployment. The person who manages encryption keys should not be the same person who accesses encrypted data.
- Maintain an access control inventory: who has access to what, and why. Review quarterly at minimum.
- Implement break-glass procedures for emergency access: a documented, audited process for granting temporary elevated access during incidents, with automatic expiration.
- All access grants and revocations must be logged in the audit trail.

## Data Protection

- Encrypt sensitive data at rest using industry-standard algorithms (AES-256). Use your cloud provider's key management service (KMS) for key storage.
- Encrypt all data in transit with TLS 1.2 or higher. Disable older TLS versions.
- Classify your data by sensitivity level. Not all data needs the same protection. A user's display name and their SSN have different requirements.
- Implement data masking or redaction for non-production environments. Development and staging databases should not contain real sensitive data. Use anonymized or synthetic data instead.
- Know where every copy of sensitive data exists: production database, backups, logs, caches, analytics pipelines, third-party services. Each copy must meet the same protection requirements.

## HIPAA (Healthcare Data)

If your application handles Protected Health Information (PHI):

- Use only HIPAA-eligible services. Major cloud providers offer HIPAA-eligible configurations, but you must sign a Business Associate Agreement (BAA) and use only the covered services.
- Apply the "minimum necessary" standard: access, use, and disclose only the minimum PHI needed for the specific purpose.
- Implement access logging for all PHI access — not just modifications, but reads.
- Encrypt PHI at rest and in transit. This is not optional.
- Maintain a risk assessment documenting threats and mitigations. This is a required document.
- Have a breach notification plan: notify affected individuals within 60 days, notify HHS, and notify media if the breach affects 500+ individuals.

## PCI-DSS (Payment Card Data)

If your application handles credit card numbers:

- **Strongly prefer not handling card data at all.** Use Stripe, Square, Braintree, or another PCI-compliant payment processor. They handle card data so you don't have to. This reduces your PCI scope dramatically.
- If you must handle card data: segment the cardholder data environment (CDE) from the rest of your network. Different security zones, restricted access, additional monitoring.
- Never store CVV/CVC codes, full magnetic stripe data, or PINs. Ever. Even encrypted.
- If storing card numbers: encrypt them, restrict access, log all access, and maintain a key management process.
- Conduct vulnerability scans quarterly and penetration tests annually.

## GDPR (EU Data Protection)

If your application processes personal data of EU residents:

- Implement mechanisms for data subject rights:
  - **Right to access:** Export all data held about a user in a standard format (JSON, CSV).
  - **Right to erasure:** Delete all personal data for a user. Design your schema so this is possible — foreign keys, cascading deletes, and awareness of where data lives (including backups and logs).
  - **Right to rectification:** Allow users to correct their data.
  - **Right to data portability:** Export data in a machine-readable format.
- Collect only what you need. Every data point collected must have a stated purpose.
- Obtain clear, affirmative consent for data processing beyond what's necessary for the service. Pre-checked boxes don't count.
- Maintain a Record of Processing Activities (ROPA) documenting what data you process, why, and how.
- Implement data protection by design: privacy considerations in architecture decisions, not as an afterthought.
- Appoint a Data Protection Officer (DPO) if required (large-scale processing of sensitive data).

## SOC 2 (SaaS / Service Organizations)

If your customers require SOC 2 compliance:

- Implement change management: all code and infrastructure changes go through a review and approval process before production deployment.
- Maintain evidence of controls: automated logging of deployments, access changes, security events, and incident responses. Auditors need documentation.
- Implement monitoring and alerting for security events: failed login attempts, privilege escalations, unusual access patterns.
- Maintain an incident response plan and demonstrate that it's been tested.
- Implement vendor management: assess the security of third-party services you depend on.

## FedRAMP (US Government)

If your application will be used by US federal government agencies, FedRAMP (Federal Risk and Authorization Management Program) applies. This is a fundamentally different level of compliance that is beyond the scope of this framework. FedRAMP requires hundreds of NIST 800-53 security controls, a third-party assessment organization, dedicated compliance staff, and typically costs $500K+ and takes months to years to complete. If FedRAMP is in your future, stop and engage a compliance firm that specializes in federal authorization before making any architectural decisions.

## Compliance Documentation

- Maintain a data flow diagram showing how data moves through your system: where it enters, where it's stored, where it's processed, and where it exits.
- Document your security controls: what they are, how they work, and how they're tested.
- Keep Architecture Decision Records (ADRs) for compliance-relevant decisions.
- Store compliance documentation in version control alongside your code. It should evolve with the system.
