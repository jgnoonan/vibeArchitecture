# Standards Mapping

> Where vibeArchitecture rules line up with recognized industry standards. Use this when a team, customer, or auditor asks "what does this framework actually cover?" — or to spot gaps mechanically as standards evolve.
>
> **This mapping is indicative, not a certification claim.** Following these rules does not make an application "OWASP compliant" or "NIST certified" — no such certifications exist for the framework itself. It shows which recognized risks each rule addresses.

## OWASP Top 10 (2021)

| Risk | Where vibeArchitecture covers it |
|------|----------------------------------|
| A01 Broken Access Control | `rules/security.md` (Authorization; mass assignment rules in Input Validation) |
| A02 Cryptographic Failures | `rules/security.md` (Authentication — password hashing; HTTPS), `rules/data.md` (Sensitive Data), `rules/compliance.md` (Data Protection) |
| A03 Injection | `rules/security.md` (Input Validation), `guides/security/input-validation.md` |
| A04 Insecure Design | `rules/system-design.md`, `guides/security/threat-modeling.md`, `checklists/before-you-build.md` |
| A05 Security Misconfiguration | `rules/security.md` (HTTPS and Transport Security), `rules/infrastructure.md` (IaC scanning, Network Security) |
| A06 Vulnerable and Outdated Components | `rules/universal.md` (Dependencies), `rules/security.md` (Dependency Security), `guides/security/supply-chain.md` |
| A07 Identification and Authentication Failures | `rules/security.md` (Authentication — MFA, OAuth/OIDC), `guides/security/authentication.md` |
| A08 Software and Data Integrity Failures | `rules/universal.md` (Dependencies — pinning, secret scanning), `guides/security/supply-chain.md` (provenance, SBOM), `rules/security.md` (Subresource Integrity) |
| A09 Security Logging and Monitoring Failures | `rules/observability.md`, `rules/compliance.md` (Audit Trails) |
| A10 Server-Side Request Forgery | `rules/security.md` (Server-Side Requests), `guides/security/input-validation.md` (SSRF) |

## OWASP ASVS v5 (by chapter theme)

| ASVS theme | Where vibeArchitecture covers it |
|------------|----------------------------------|
| Encoding, sanitization, and injection | `rules/security.md` (Input Validation), `guides/security/input-validation.md` |
| Validation and business logic | `rules/security.md` (Input Validation), `rules/data.md` (Data Integrity), `rules/api.md` |
| File handling | `rules/security.md` (File Uploads) |
| Authentication | `rules/security.md` (Authentication), `guides/security/authentication.md` |
| Session management and tokens | `rules/security.md` (Authentication), `guides/security/state-management.md` |
| OAuth and OIDC | `rules/security.md` (Authentication), `guides/security/authentication.md` (OAuth/OIDC section) |
| Authorization | `rules/security.md` (Authorization) |
| Cryptography and data protection | `rules/data.md` (Sensitive Data), `rules/compliance.md` (Data Protection) |
| Secure communication | `rules/security.md` (HTTPS and Transport Security) |
| Configuration | `rules/infrastructure.md`, `rules/universal.md` (Secrets and Configuration) |
| Logging and error handling | `rules/observability.md`, `rules/universal.md` (Error Handling) |

## OWASP LLM Top 10 (2025)

`guides/multi-agent/llm-security.md` maps these risks in detail; the rules live in `rules/multi-agent.md`.

| Risk | Where vibeArchitecture covers it |
|------|----------------------------------|
| Prompt Injection | `rules/multi-agent.md` (LLM Call Hygiene, Execution Isolation), `guides/multi-agent/llm-security.md` |
| Sensitive Information Disclosure | `rules/multi-agent.md` (Output Validation), `guides/multi-agent/llm-security.md` |
| Supply Chain | `guides/security/supply-chain.md`, `guides/multi-agent/llm-security.md` |
| Data and Model Poisoning | `guides/multi-agent/llm-security.md` |
| Improper Output Handling | `rules/multi-agent.md` (Output Validation) |
| Excessive Agency | `rules/multi-agent.md` (Agent Boundaries, Execution Isolation), `guides/multi-agent/mcp-tool-patterns.md` (lethal trifecta, human-in-the-loop) |
| System Prompt Leakage | `rules/multi-agent.md` (Prompt Management), `guides/multi-agent/llm-security.md` |
| Vector and Embedding Weaknesses | `guides/multi-agent/llm-security.md` (RAG access controls) |
| Misinformation | `rules/multi-agent.md` (Output Validation), `guides/multi-agent/llm-security.md` (overreliance) |
| Unbounded Consumption | `rules/multi-agent.md` (Cost Controls) |

## NIST SSDF (SP 800-218, by practice group)

| Practice group | Where vibeArchitecture covers it |
|----------------|----------------------------------|
| PO — Prepare the Organization | Intake questionnaire and tier system, `PROJECT_PROFILE.template.md`, `appendices/adr-template.md` |
| PS — Protect the Software | `rules/universal.md` (Version Control — branch protection, secret scanning), `guides/security/supply-chain.md` (provenance, SBOM, keyless deploys) |
| PW — Produce Well-Secured Software | `rules/security.md`, `rules/data.md`, `rules/universal.md` (Code Scanning), `guides/security/threat-modeling.md`, `rules/testing.md` |
| RV — Respond to Vulnerabilities | `rules/universal.md` (Dependencies — prompt updates), `rules/observability.md` (Incident Preparedness), `guides/reliability/incident-response.md`, `rules/compliance.md` (EU CRA — coordinated disclosure) |

## Keeping This Current

When a standard revises (OWASP updates roughly every four years; the LLM Top 10 faster), walk each row: does the referenced rules section still address the risk? Rows with no rules reference are the gap list for the next framework release.
