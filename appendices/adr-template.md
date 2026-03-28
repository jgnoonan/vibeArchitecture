# Architecture Decision Records (ADRs)

## What Is an ADR?

An Architecture Decision Record is a short document that captures an important technical decision — what you decided, why, and what other options you considered.

Think of it like a journal entry for your project's big choices. Six months from now, when you (or someone else) wonders "why did we use PostgreSQL instead of MongoDB?" or "why is the API built this way?", the ADR has the answer.

Without ADRs, decisions live in someone's head, in a forgotten Slack message, or nowhere at all. When that knowledge is lost, teams waste time revisiting decisions that were already made — or worse, reversing a good decision because nobody remembers why it was made.

## When to Write One

Write an ADR when you're making a decision that:

- Would take more than 15 minutes to explain to someone new to the project
- Involves choosing between multiple reasonable options
- Would be hard to reverse later (database choice, hosting platform, authentication approach)
- Affects how other parts of the system will be built

You don't need an ADR for every small choice. "Which CSS framework?" probably doesn't need one. "Which database?" definitely does.

## The Template

Copy this template for each decision. Keep it short — one page is ideal.

---

### ADR-[number]: [Title of the Decision]

**Date:** [When the decision was made]

**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

#### Context

What is the situation? What problem are you solving? What constraints exist?

Write this so someone unfamiliar with the project can understand it. Two to three sentences is usually enough.

#### Decision

What did you decide? State it clearly in one or two sentences.

#### Alternatives Considered

What other options did you evaluate? For each, briefly note why it wasn't chosen.

- **Option A:** [What it was] — [Why not]
- **Option B:** [What it was] — [Why not]

#### Consequences

What are the results of this decision — both positive and negative? Be honest about the tradeoffs.

- **Positive:** [What gets better]
- **Negative:** [What gets harder or what you give up]

---

## Examples

### ADR-001: Use PostgreSQL for the Primary Database

**Date:** 2026-03-15

**Status:** Accepted

#### Context

We need a database for our web application. The app stores user accounts, orders, and product data. We expect relational data with foreign key relationships. The team has limited database administration experience.

#### Decision

Use PostgreSQL as the primary database, hosted on a managed service (e.g., Supabase, Neon, or AWS RDS).

#### Alternatives Considered

- **MongoDB** — Document database. Would avoid rigid schemas, but our data is clearly relational. Joins and transactions are harder in MongoDB.
- **MySQL** — Solid relational database. PostgreSQL has better support for JSON columns, full-text search, and modern features we may need.
- **SQLite** — No server needed. Great for local development but doesn't support concurrent writes well enough for a multi-user web app.

#### Consequences

- **Positive:** Strong relational support, excellent ecosystem, easy to find help and hosting, good free tier on managed services.
- **Negative:** Requires managing a database server (mitigated by using a managed service). More structured than a document store — schema changes require migrations.

---

### ADR-002: Use Clerk for Authentication

**Date:** 2026-03-16

**Status:** Accepted

#### Context

Users need to sign up and log in. We need password management, email verification, and potentially social login. Building authentication from scratch is error-prone and time-consuming.

#### Decision

Use Clerk as the authentication provider.

#### Alternatives Considered

- **Build our own** — Full control but high risk. Auth is deceptively hard to get right (password hashing, session management, CSRF, rate limiting, account recovery).
- **Auth0** — Feature-rich but more complex to configure. Pricing gets expensive at scale.
- **Firebase Auth** — Good option, but ties us to the Google ecosystem. We want to avoid deep cloud vendor lock-in.
- **NextAuth/Auth.js** — Self-hosted, open source. Good option but requires more setup and maintenance. We may switch to this later if Clerk's pricing becomes a concern.

#### Consequences

- **Positive:** Fast to implement, handles security best practices, good developer experience, pre-built UI components.
- **Negative:** Monthly cost after free tier (manageable for our scale). Vendor dependency — if Clerk goes down, our auth goes down. If we outgrow Clerk, migration will take effort.

---

## Where to Store ADRs

Keep ADRs in your project repository. A common approach:

```
docs/
  adr/
    001-use-postgresql.md
    002-use-clerk-for-auth.md
    003-deploy-on-railway.md
```

Or just keep them in a single `docs/decisions.md` file if you prefer simplicity. The format matters less than the habit of writing them.

## Tips

- **Short is better than long.** A 10-line ADR that exists is infinitely more valuable than a 5-page ADR you never write.
- **Write them at decision time.** Don't try to reconstruct decisions months later — the reasoning will be fuzzy.
- **It's okay to change your mind.** Mark the old ADR as "Superseded by ADR-XXX" and write a new one explaining why the decision changed. The history is valuable.
- **Ask your AI to help.** After making a decision together, say: *"Write an ADR for the decision we just made about [topic]."* The AI was part of the conversation and can draft it quickly.
