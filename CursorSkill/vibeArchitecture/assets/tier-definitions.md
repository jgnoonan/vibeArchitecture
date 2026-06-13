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
- Basic security practices (input validation, secure password storage)
- Data integrity (protecting against accidental data loss or corruption)
- Backup strategy

**What you don't need to worry about:**
- Rate limiting and abuse prevention
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
- Basic monitoring (know when things break before users tell you)
- Deployment strategy (update without downtime)

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

**Who it's for:** Projects handling healthcare data (HIPAA), payment card data (PCI-DSS), personal data of EU citizens (GDPR), or other legally regulated information.

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
