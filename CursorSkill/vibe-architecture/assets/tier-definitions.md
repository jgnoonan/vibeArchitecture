# Project Tiers

## How Tiers Work

Your project's tier determines how much architectural guidance the AI applies. Think of it like building codes — a garden shed has different requirements than a hospital. Neither is wrong; they just need different levels of care.

Each tier includes everything from the tiers below it.

---

## Personal

**Who it's for:** Just you. Learning, experiments, personal tools, prototypes.

**What the AI enforces:**
- Basic code hygiene (version control, don't commit secrets)
- Simple error handling
- Data backup awareness

**What you don't need to worry about:**
- User authentication
- Scaling
- High availability
- Compliance

**Typical hosting cost:** Free to $5/month

---

## Shared

**Who it's for:** A known group — friends, family, coworkers, classmates. People who can tell you when something breaks.

**What the AI adds on top of Personal:**
- User authentication (accounts and login) if needed
- Basic security practices (input validation, secure password storage, login rate limiting, multi-factor authentication for admin accounts)
- Data integrity (protecting against accidental data loss or corruption)
- Backup strategy
- Basic tests for the code that handles money, permissions, and core workflows

**What you don't need to worry about:**
- Abuse-scale rate limiting and bot defenses (basic login throttling is still on)
- Complex deployment strategies
- Performance at scale

**Typical hosting cost:** $5–25/month

---

## Public

**Who it's for:** Strangers on the internet. Anyone can sign up and use it.

**What the AI adds on top of Shared:**
- API security (rate limiting, abuse prevention)
- Hardened input validation (assume some users are malicious)
- Error handling that doesn't leak internal details
- HTTPS enforcement
- Accessibility (semantic HTML, keyboard navigation, labels) — a legal requirement for public apps in many places
- Consistent API design

**Why it's different from Shared:** When strangers use your app, you must assume some will try to break it — out of curiosity, malice, or accident. You can't call them up when something goes wrong.

**Typical hosting cost:** $20–100/month

---

## Business

**Who it's for:** Paying customers, or a business depends on this working. Downtime or data loss has real financial consequences.

**What the AI adds on top of Public:**
- Reliability patterns (handling failures gracefully)
- Infrastructure as code (reproducible, automated deployments)
- Structured logging and monitoring (find problems fast)
- Performance awareness (response times, database optimization)
- Tested backup and recovery procedures
- Deployment safety (rollback plans, staged rollouts)

**Why it's different from Public:** When people pay for your product, they expect it to work. When it doesn't, you lose money, trust, and potentially face legal liability.

**Typical hosting cost:** $100–500+/month

---

## Regulated

**Who it's for:** Projects handling healthcare data (HIPAA), payment card data (PCI-DSS), biometric data, government IDs, children's data (COPPA / GDPR-K), or other legally regulated information — or any project where downtime is critical *and* sensitive data is involved. Ordinary personal data about EU, UK, or California users does **not** make a project Regulated; that's the privacy overlay below.

**What the AI adds on top of Business:**
- Compliance-specific architectural rules
- Audit trails (who did what, when, from where)
- Data encryption requirements beyond standard practices
- Access control and separation of duties
- Data retention and deletion policies
- Enhanced documentation requirements

**Why it's different from Business:** Regulatory violations carry fines, lawsuits, and in some cases criminal liability. The rules exist because the consequences of failure are severe.

**Typical hosting cost:** $200–1,000+/month

**Important:** The AI applies architectural best practices for regulated environments, but cannot provide legal advice. Consult a compliance specialist or attorney for your specific regulatory obligations.

---

## Privacy: an overlay, not a tier

Some obligations are triggered by **who your users are**, not by how big or serious your app is. If your app stores personal data about other people (names, emails, phone numbers, location) — or any of your users are in the EU, UK, or California — privacy laws like GDPR and CCPA apply even to a small Public-tier app.

When this is the case, the AI applies a **privacy overlay** on top of your tier (the `rules/privacy.md` rules): users can export their data, delete it on request (a hidden "soft delete" flag doesn't count), and consent to non-essential tracking. This is separate from becoming "Regulated" — you get the data-subject-rights basics without the full compliance program.

**Health, biometric, or children's data escalates the whole tier to Regulated; payment or government-ID data to at least Business; "critical" downtime impact to at least Business (Regulated when combined with sensitive data)** — exactly as in `questionnaire.md`. The overlay is for ordinary personal data.
