# Standards Mapping

> Where vibeArchitecture rules line up with recognized industry standards. Use this when a team, customer, or auditor asks "what does this framework actually cover?" — or to spot gaps mechanically as standards evolve.
>
> **This mapping is indicative, not a certification claim.** Following these rules does not make an application "OWASP compliant" or "NIST certified" — no such certifications exist for the framework itself. It shows which recognized risks each rule addresses.

## OWASP Top 10 (2025)

| Risk | Where vibeArchitecture covers it |
|------|----------------------------------|
| A01 Broken Access Control (incl. BOLA/IDOR, BFLA) | `rules/security.md` (Authorization; mass assignment rules in Input Validation), `rules/api.md` (Authentication and Authorization) |
| A02 Security Misconfiguration (SSRF folded in) | `rules/security.md` (HTTPS and Transport Security; Server-Side Requests), `rules/infrastructure.md` (IaC scanning, Network Security), `guides/security/input-validation.md` (SSRF) |
| A03 Software Supply Chain Failures | `rules/universal.md` (Dependencies), `rules/security.md` (Dependency Security), `guides/security/supply-chain.md`, `rules/compliance.md` (EU CRA — SBOM) |
| A04 Cryptographic Failures | `rules/security.md` (Cryptography; Authentication — password hashing; HTTPS), `guides/security/cryptography.md`, `rules/data.md` (Sensitive Data), `rules/compliance.md` (Data Protection) |
| A05 Injection | `rules/security.md` (Input Validation), `guides/security/input-validation.md`; for LLMs, `guides/multi-agent/llm-security.md` (LLM01) |
| A06 Insecure Design | `rules/system-design.md`, `guides/security/threat-modeling.md`, `checklists/before-you-build.md` |
| A07 Authentication Failures | `rules/security.md` (Authentication — MFA, OAuth/OIDC), `guides/security/authentication.md` |
| A08 Software or Data Integrity Failures | `rules/universal.md` (Dependencies — pinning, secret scanning), `guides/security/supply-chain.md` (provenance, SBOM), `rules/security.md` (Subresource Integrity), `rules/compliance.md` (PCI DSS 6.4.3/11.6.1) |
| A09 Security Logging and Alerting Failures | `rules/observability.md`, `rules/compliance.md` (Audit Trails) |
| A10 Mishandling of Exceptional Conditions | `rules/security.md` (fail-closed guards), `rules/universal.md` (Error Handling), `appendices/anti-patterns.md` (The Fail-Open Guard) |

## OWASP ASVS v5 (by chapter theme)

| ASVS theme | Where vibeArchitecture covers it |
|------------|----------------------------------|
| Encoding, sanitization, and injection | `rules/security.md` (Input Validation), `guides/security/input-validation.md` |
| Validation and business logic | `rules/security.md` (Input Validation), `rules/data.md` (Data Integrity), `rules/api.md` |
| File handling | `rules/security.md` (File Uploads) |
| Authentication | `rules/security.md` (Authentication), `guides/security/authentication.md` |
| Session management and tokens | `rules/security.md` (Authentication), `guides/security/state-management.md` |
| OAuth and OIDC | `rules/security.md` (Authentication), `guides/security/authentication.md` (Social Login, OAuth, and OIDC) |
| Authorization | `rules/security.md` (Authorization) |
| Cryptography and data protection | `rules/data.md` (Sensitive Data), `rules/compliance.md` (Data Protection) |
| Secure communication | `rules/security.md` (HTTPS and Transport Security) |
| Configuration | `rules/infrastructure.md`, `rules/universal.md` (Secrets and Configuration) |
| Logging and error handling | `rules/observability.md`, `rules/universal.md` (Error Handling) |

## OWASP MASVS v2 (Mobile Application Security Verification Standard)

The mobile analog of ASVS. Verify with the companion MASTG (Mobile Application Security Testing Guide).

| MASVS group | Where vibeArchitecture covers it |
|-------------|----------------------------------|
| MASVS-STORAGE (sensitive data at rest) | `rules/mobile.md` (Secure Storage), `guides/security/mobile-security.md` |
| MASVS-CRYPTO (cryptography) | `rules/security.md` (Cryptography), `guides/security/cryptography.md` |
| MASVS-AUTH (authentication and session) | `rules/mobile.md` (Authentication), `rules/security.md` (Authentication) |
| MASVS-NETWORK (secure communication) | `rules/mobile.md` (Network Security), `rules/security.md` (HTTPS and Transport Security) |
| MASVS-PLATFORM (platform interaction, IPC, deep links, WebViews) | `rules/mobile.md` (Authentication — deep links and WebViews; Push Notifications), `guides/security/mobile-security.md` |
| MASVS-CODE (code quality and build) | `rules/universal.md` (Code Quality, Code Scanning), `rules/mobile.md` (Common AI-Generated Mistakes) |
| MASVS-RESILIENCE (anti-tampering) | Not covered — relevant mainly to apps defending against on-device reverse engineering (DRM, fintech hardening); adopt MASTG guidance directly if required |
| MASVS-PRIVACY (user privacy) | `rules/privacy.md` (including the metadata section), `rules/mobile.md` (App Store and Privacy, Push Notifications) |

## OWASP Top 10 for LLM Applications (2026)

`guides/multi-agent/llm-security.md` maps these risks in detail; the rules live in `rules/multi-agent.md`.

| Risk | Where vibeArchitecture covers it |
|------|----------------------------------|
| LLM01 Prompt Injection | `rules/multi-agent.md` (LLM Call Hygiene, Execution Isolation), `guides/multi-agent/llm-security.md` (LLM01) |
| LLM02 Sensitive Information Disclosure | `rules/multi-agent.md` (Output Validation, Cost Controls — cache scoping), `guides/multi-agent/llm-security.md` (LLM02) |
| LLM03 Excessive Agency | `rules/multi-agent.md` (Agent Boundaries, Execution Isolation, Agentic Systems), `guides/multi-agent/llm-security.md` (LLM03), `guides/multi-agent/mcp-tool-patterns.md` (lethal trifecta, human-in-the-loop) |
| LLM04 Supply Chain | `guides/security/supply-chain.md`, `guides/multi-agent/llm-security.md` (LLM04), `guides/multi-agent/mcp-tool-patterns.md` (Tool-Description Poisoning) |
| LLM05 Data and Model Poisoning | `guides/multi-agent/llm-security.md` (LLM05), `guides/multi-agent/agentic-security.md` (Memory Poisoning) |
| LLM06 Unbounded Consumption | `rules/multi-agent.md` (Cost Controls, Agentic Systems), `guides/multi-agent/llm-security.md` (LLM06) |
| LLM07 Misinformation | `rules/multi-agent.md` (Output Validation), `guides/multi-agent/llm-security.md` (LLM07) |
| LLM08 Hidden Context Exposure | `rules/multi-agent.md` (Prompt Management), `guides/multi-agent/llm-security.md` (LLM08) |
| LLM09 Vector and Embedding Weaknesses | `guides/multi-agent/llm-security.md` (LLM09) |
| LLM10 Improper Output Handling | `rules/multi-agent.md` (Output Validation), `guides/multi-agent/llm-security.md` (LLM10) |

## OWASP Top 10 for Agentic Applications (2026)

`guides/multi-agent/agentic-security.md` maps these in detail; compact rules in `rules/multi-agent.md` (Agentic Systems).

| Risk | Where vibeArchitecture covers it |
|------|----------------------------------|
| ASI01 Agent Goal Hijack | `guides/multi-agent/agentic-security.md` (ASI01), `guides/multi-agent/llm-security.md` (LLM01) |
| ASI02 Tool Misuse & Exploitation | `guides/multi-agent/agentic-security.md` (ASI02), `guides/multi-agent/mcp-tool-patterns.md` (Validate Before Execute) |
| ASI03 Identity & Privilege Abuse | `guides/multi-agent/agentic-security.md` (Agent Identity and Delegated Credentials), `guides/multi-agent/mcp-tool-patterns.md` (Agent Identity) |
| ASI04 Agentic Supply Chain Vulnerabilities | `guides/multi-agent/agentic-security.md` (ASI04), `guides/multi-agent/mcp-tool-patterns.md` (Tool-Description Poisoning), `guides/security/supply-chain.md` |
| ASI05 Unexpected Code Execution (RCE) | `rules/multi-agent.md` (Execution Isolation), `guides/multi-agent/agentic-security.md` (ASI05) |
| ASI06 Memory & Context Poisoning | `guides/multi-agent/agentic-security.md` (Memory Poisoning) |
| ASI07 Insecure Inter-Agent Communication | `guides/multi-agent/orchestration-patterns.md` (Trust Between Agents), `guides/multi-agent/agentic-security.md` (ASI07) |
| ASI08 Cascading Failures | `rules/multi-agent.md` (Agentic Systems — loop caps, kill switch), `rules/reliability.md` (Circuit Breakers), `guides/multi-agent/agentic-security.md` (Spend Caps and the Kill Switch) |
| ASI09 Human-Agent Trust Exploitation | `guides/multi-agent/agentic-security.md` (ASI09), `rules/privacy.md` (Transparency & Retention) |
| ASI10 Rogue Agents | `guides/multi-agent/agentic-security.md` (ASI10), `rules/multi-agent.md` (Agent Observability) |

## NIST AI RMF 1.0 and AI 600-1 (Generative AI Profile)

| Function | Where vibeArchitecture covers it |
|----------|----------------------------------|
| Govern | `rules/compliance.md` (AI Governance References, EU AI Act, US AI and State Laws), `appendices/adr-template.md`, `appendices/assurance-register-template.md` |
| Map | `guides/security/threat-modeling.md`, `guides/multi-agent/agentic-security.md` (lethal trifecta, ASI mapping) |
| Measure | `guides/multi-agent/testing-ai-systems.md`, `guides/multi-agent/agent-observability.md` (Quality Measurement) |
| Manage | `rules/multi-agent.md` (Cost Controls, Agentic Systems), `guides/multi-agent/agentic-security.md` (Spend Caps and the Kill Switch) |
| AI 600-1 GenAI risks (confabulation, information integrity, data privacy, human-AI configuration) | `guides/multi-agent/llm-security.md` (LLM02, LLM09), `rules/privacy.md` (Transparency & Retention, Third Parties & Data Sharing) |

## ISO/IEC 42001 (AI Management System)

| Theme | Where vibeArchitecture covers it |
|-------|----------------------------------|
| AI policy, roles, and risk assessment | `rules/compliance.md` (AI Governance References), `appendices/assurance-register-template.md` |
| AI system lifecycle and data management | `rules/multi-agent.md` (Prompt Management, Testing Multi-Agent Systems), `rules/privacy.md` |
| Third-party and supplier relationships | `rules/privacy.md` (Third Parties & Data Sharing), `guides/infrastructure/regulated-deployment.md` (AI model APIs) |
| Transparency and impact on individuals | `rules/privacy.md` (Transparency & Retention, Data-Subject Rights — automated decisions), `rules/compliance.md` (EU AI Act) |

## NIST SSDF (SP 800-218 v1.1 and SP 800-218A; v1.2 in draft)

SP 800-218A adds practices for AI model development and use; v1.2 (draft) is expected to fold them in — check the current version.

| Practice group | Where vibeArchitecture covers it |
|----------------|----------------------------------|
| PO — Prepare the Organization | Intake questionnaire and tier system, `PROJECT_PROFILE.template.md`, `appendices/adr-template.md` |
| PS — Protect the Software | `rules/universal.md` (Version Control — branch protection, secret scanning), `guides/security/supply-chain.md` (provenance, SBOM, keyless deploys) |
| PW — Produce Well-Secured Software | `rules/security.md`, `rules/data.md`, `rules/universal.md` (Code Scanning), `guides/security/threat-modeling.md`, `rules/testing.md` |
| RV — Respond to Vulnerabilities | `rules/universal.md` (Dependencies — prompt updates), `rules/observability.md` (Incident Preparedness), `guides/reliability/incident-response.md`, `rules/compliance.md` (EU CRA — coordinated disclosure and reporting deadlines) |
| 800-218A — AI model and data practices | `rules/multi-agent.md` (Prompt Management, Testing Multi-Agent Systems), `guides/multi-agent/llm-security.md` (LLM04, LLM07) |

## SLSA v1.1 (Supply-chain Levels for Software Artifacts)

| Level | Where vibeArchitecture covers it |
|-------|----------------------------------|
| Build L1 — provenance exists | `guides/security/supply-chain.md` (SBOM and Artifact Provenance) |
| Build L2 — hosted build, signed provenance | `guides/security/supply-chain.md` (CI/CD Pipeline Hygiene; keyless signing) |
| Build L3 — hardened build platform | Not prescribed; `guides/security/supply-chain.md` (What Good Looks Like at Each Tier) points to it for Regulated tier |

## CIS Controls v8.1 (selected controls)

| Control | Where vibeArchitecture covers it |
|---------|----------------------------------|
| 1–2 Inventory of assets and software | `guides/security/supply-chain.md` (SBOM), `rules/compliance.md` (HIPAA NPRM — asset inventory) |
| 3 Data protection | `rules/data.md` (Sensitive Data), `rules/compliance.md` (Data Protection), `rules/privacy.md` |
| 4 Secure configuration | `rules/infrastructure.md`, `rules/security.md` (HTTPS and Transport Security) |
| 5–6 Account and access control management | `rules/security.md` (Authentication, Authorization), `rules/compliance.md` (Access Control) |
| 7 Continuous vulnerability management | `rules/universal.md` (Dependencies, Code Scanning), `guides/security/supply-chain.md` |
| 8 Audit log management | `rules/observability.md`, `rules/compliance.md` (Audit Trails) |
| 11 Data recovery | `rules/data.md` (Backups), `rules/reliability.md` (Disaster Recovery) |
| 16 Application software security | `rules/security.md`, `rules/testing.md`, `guides/security/threat-modeling.md` |
| 17 Incident response management | `rules/observability.md` (Incident Preparedness), `guides/reliability/incident-response.md`, `checklists/something-broke.md` |

## GDPR and CCPA/CPRA (privacy regimes)

| Obligation | Where vibeArchitecture covers it |
|------------|----------------------------------|
| Data minimization and purpose limitation | `rules/privacy.md` (Collect Less) |
| Data-subject rights (access, erasure, rectification, portability, objection) | `rules/privacy.md` (Data-Subject Rights, Soft Delete vs. Real Deletion), `rules/compliance.md` (GDPR) |
| Automated decision-making (GDPR Art. 22, CCPA ADMT) | `rules/privacy.md` (Data-Subject Rights), `rules/compliance.md` (US AI and State Laws) |
| Lawful basis, consent, DPIA | `rules/privacy.md` (Lawful Basis, Consent & Tracking) |
| Opt-out signals (Global Privacy Control) | `rules/privacy.md` (Consent & Tracking) |
| Processors and international transfers | `rules/privacy.md` (Third Parties & Data Sharing), `guides/infrastructure/regulated-deployment.md` (GDPR Transfer Mechanisms, AI model APIs) |
| Breach notification | `rules/privacy.md` (Transparency & Retention), `rules/compliance.md` (HIPAA for health data) |
| Children's data | `rules/compliance.md` (Children's Data — COPPA) |

## EU Cyber Resilience Act

| Obligation | Where vibeArchitecture covers it |
|------------|----------------------------------|
| Secure-by-default, vulnerability handling, SBOM | `guides/security/supply-chain.md` (SBOM and Artifact Provenance), `rules/security.md` |
| Coordinated vulnerability disclosure | `rules/compliance.md` (EU CRA), `guides/reliability/incident-response.md` |
| 24 h / 72 h / 14-day reporting (from 11 Sep 2026) | `rules/compliance.md` (EU CRA), `rules/observability.md` (Incident Preparedness) |
| Security updates over the support period | `rules/universal.md` (Dependencies), `rules/mobile.md` (Updates and Compatibility) |

## Keeping This Current

When a standard revises (OWASP updates roughly every four years; the LLM and Agentic Top 10 lists yearly), walk each row: does the referenced rules section still address the risk? Rows with no rules reference are the gap list for the next framework release.
