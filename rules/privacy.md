# Privacy Rules (Data-Subject Rights)

> Applies to: Shared tier and above, whenever the app stores personal data about **real people other than the builder** (names, emails, phone numbers, location, or anything that identifies a person).
> This overlay makes basic privacy obligations (GDPR, UK GDPR, CCPA/CPRA, and similar laws) reachable without full Regulated tier. Regulated projects load `rules/compliance.md` on top of this.
> For detailed explanations: see `guides/data/data-lifecycle.md`. This is architectural guidance, not legal advice — consult a professional for your specific obligations.

## Why this applies to "ordinary" apps

Most privacy laws are triggered by **who your users are**, not by how big or serious your app is. If you have EU/UK users, GDPR applies. If you have California users past its thresholds, CCPA/CPRA applies. A hobby-scale Public app with real signups almost always falls under at least one of these. You don't need to be "Regulated" to owe users these basics.

## Collect Less

- Collect only the personal data you actually use. Every field you store is a field you must protect, disclose, and be able to delete. If you don't need someone's phone number, don't ask for it.
- Have a stated purpose for each piece of personal data you collect. "We might want it later" is not a purpose.
- Don't quietly repurpose data. Data collected to run the service shouldn't later be sold, used to train models, or shared with third parties without a new basis and (usually) consent.

## Data-Subject Rights (build these in early)

Design the schema so these are possible from day one — retrofitting them is painful.

- **Right to access / export:** A user can get a copy of the personal data you hold about them, in a portable format (JSON or CSV). Provide a way to produce this — even a manual admin process is acceptable at small scale, but know how to do it.
- **Right to deletion / erasure:** A user can request that their personal data be deleted. Your schema must make this achievable — know every table, log, cache, backup, and third-party service (analytics, email provider, AI provider) that holds their data. See the soft-delete note below.
- **Right to rectification:** A user can correct wrong data about themselves.
- **Right to object / withdraw consent:** If processing relies on consent (marketing email, non-essential tracking), withdrawing it must be as easy as giving it.

## Soft Delete vs. Real Deletion

- The universal "prefer soft delete" default (`rules/universal.md`) is about protecting against *accidental* loss. It does **not** satisfy a deletion request. A record marked `deleted = true` but still holding the person's email is **not** erased.
- When a user exercises deletion, personal data must actually go away (or be irreversibly anonymized). Keep only what you have a lawful reason to retain (e.g. a transaction record for tax/accounting) and strip the rest.
- Reconcile the two: soft-delete for undo windows and referential integrity, then a real purge/anonymize step that runs on erasure requests and on retention expiry.

## Lawful Basis

- Every purpose you process personal data for needs a lawful basis. GDPR has six, and consent is only one of them — often the wrong one. **Contract** and **legitimate interest** usually cover core service functionality (account data, order processing, transactional email, fraud prevention).
- Reserve **consent** for what genuinely needs it — marketing, non-essential tracking — because consent can be withdrawn at any time, and anything built on it must be able to stop.
- Don't show consent banners for processing that doesn't require consent. A banner asking permission for strictly necessary cookies is noise that trains users to click through everything.
- High-risk processing — large-scale profiling, sensitive data (health, biometrics), systematic monitoring — triggers a Data Protection Impact Assessment (DPIA). Document it before building, not after.

## Consent & Tracking

- Non-essential cookies and tracking (analytics, ad pixels, session replay) require consent in the EU/UK **before** they load — not a pre-checked box, not "by using this site you agree."
- Essential cookies (login/session, CSRF, load balancing) don't need consent. Don't hide tracking cookies among them.
- Record consent: what the user agreed to, and when. If you can't show consent was given, you don't have it.

## Third Parties & Data Sharing

- Every third party you send personal data to (email provider, analytics, error tracking, an LLM/AI API) is a processor acting on your behalf. Use reputable ones that offer a Data Processing Agreement (DPA), and don't send them more than they need.
- **Do not send personal or regulated data to an AI/LLM provider that isn't covered by an appropriate agreement** (DPA, or a BAA for health data). Assume anything you put in a prompt has left your control. See `rules/multi-agent.md` and `guides/multi-agent/llm-security.md`.
- Know where data leaves your region. If users are in the EU/UK, cross-border transfer of their data has extra rules.

## If You Claim Privacy, Audit the Metadata

- Encrypting content is not the same as protecting privacy. The failures that contradict a privacy claim almost always live in the *metadata* plane: cleartext names and messages in invitation records, personal data copied into push-notification payloads, identifiers and social-graph pairs printed in server logs, and database columns that quietly reconstruct who knows whom.
- If your marketing says "private" or "end-to-end encrypted," review the system against a stronger threat model: an honest-but-curious, compromised, or subpoenaed **operator** — you, your hosting provider, your database. What could that operator read or infer? Logs, push payloads, analytics events, and retained columns are all part of the claim.
- Push notifications transit Apple's and Google's servers — treat their payloads as data shared with a third party. Prefer opaque wake signals; fetch the actual content on-device over your own encrypted channel.
- Delete transition paths, don't deprecate them. If a cleartext column or legacy endpoint contradicts the privacy model, removing it structurally is the only state in which it cannot return.

## Transparency & Retention

- Publish a privacy notice that honestly matches what you actually collect, why, who you share it with, and how long you keep it. The framework can't write legal text, but the notice must not contradict the code.
- Define a retention period for each category of personal data and delete/anonymize past it. "Keep everything forever" is a liability, not a feature.
- If you have a data breach involving personal data, most regimes require prompt notification (GDPR: authorities within 72 hours where feasible). Have a rough plan before you need it; `checklists/something-broke.md` is the starting point.

## When to escalate to Regulated

If you handle **health data, payment card data, government IDs, biometric data, or children's data**, this overlay is not enough — the project is Regulated. Load `rules/compliance.md` for audit trails, encryption standards, and regulation-specific requirements (HIPAA, PCI-DSS, GDPR special categories, SOC 2).
