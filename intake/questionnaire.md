# Project Intake Questionnaire

## Instructions for the AI Agent

Walk the user through these questions to understand their project and determine the appropriate tier of architectural guidance.

### How to conduct this conversation

1. **Explain what's happening first.** Say something like: *"Before we start building, I'd like to ask a few questions about your project. This helps me give you the right level of guidance — not too much for a simple project, not too little for something critical. It takes about 5 minutes."*
2. **Ask one or two questions at a time.** Do not present all questions at once.
3. **Use the wording below** (or natural variations). The questions are written in plain English deliberately.
4. **Adapt based on answers.** Follow the skip logic noted in each question.
5. **Be conversational, not interrogative.** This should feel like a helpful chat, not a form.
6. **After all questions**, determine the tier using the logic at the end of this document.
7. **Generate PROJECT_PROFILE.md** using the template, then confirm it with the user.

---

## The Questions

### Q0: What's your background?

*Ask:* "One more thing before we dive in — what's your background with building software?"
- **I'm new to this** — AI does most of the coding, I describe what I want
- **I've built a few things** — I can read code and make changes, but I'm still learning
- **I'm an experienced developer** — I have a software engineering background

Record as `experience_level` in the profile:
- "New to this" → `beginner`
- "Built a few things" → `intermediate`
- "Experienced developer" → `experienced`

**This does NOT change which rules apply.** All three levels get the full framework for their tier. It adjusts:
- **Communication style:** For `beginner` and `intermediate`, use plain language and explain every technical concept. For `experienced`, use concise technical language — standard terminology without definitions, skip analogies, surface tradeoffs at a deeper level.
- **Question depth:** For `experienced` users at Business tier or above, ask the additional architecture questions (Q11–Q14) after tier determination.
- **System design rules:** For `experienced` users at Business tier or above, load `rules/system-design.md`.

---

### Q1: What are you building?

*Ask:* "Tell me about what you want to build. Just describe it in your own words — what will it do, and what problem does it solve?"

Purpose: Establishes context. Also helps identify if an existing product might be a better fit.

**After the user answers:** If the project sounds like something well-served by an existing product (standard blog, e-commerce store, CMS, landing page, portfolio site), mention it once, gently:

*"That sounds similar to what [product] does out of the box. Have you looked into that? Using an existing product can save a lot of time. Building your own is totally fine — just want to make sure you know the option exists."*

If they want to proceed with building, move on. Never push back more than once.

---

### Q2: Who will use this?

*Ask:* "Who is this for?"
- **Just me** — personal project, learning, experimenting
- **People I know** — friends, family, coworkers, a small group
- **Anyone on the internet** — public sign-up, open access
- **Paying customers** — people pay for this, or a business depends on it

This is the primary tier determinant:
- "Just me" → **Personal**
- "People I know" → **Shared**
- "Anyone on the internet" → **Public**
- "Paying customers" → **Business**

**If "Just me":** Skip Q7 and Q8.

---

### Q3: Will people need to log in?

*Ask:* "Will users need to create an account or log in?"
- **No** — anyone can use it without an account
- **Yes** — users will sign up and log in

If No and tier is Personal or Shared: simplifies security guidance significantly.

---

### Q4: What information will you store?

*Ask:* "What kind of information will your app store? Pick everything that applies."
- Names, email addresses, or phone numbers
- Passwords (for login — the system stores them even if users don't see them)
- Payment or financial information (credit cards, bank details, transactions)
- Health or medical information
- Government-issued IDs (SSN, driver's license, passport numbers)
- Location tracking or movement data
- None of the above — just non-personal stuff (todos, game scores, preferences)

**Tier upgrades based on answers:**
- Health/medical data → upgrade to **Regulated**
- Payment/financial data → upgrade to at least **Business**
- Government IDs → upgrade to at least **Business**
- Names/emails/phone → flag that a privacy policy is likely needed

---

### Q5: How will people use it?

*Ask:* "How will people access your app?"
- **Web browser** — a website or web app
- **Mobile app** — iOS, Android, or both
- **Desktop app** — installed on a computer
- **API** — other programs connect to it
- **Command-line tool** — run from a terminal
- **More than one of these**

Skip if Q2 was "Just me" and the project is clearly a local script or tool.

---

### Q6: Where will it run?

*Ask:* "Where will your app be hosted?"
- **Just on my computer** — not on the internet
- **In the cloud** — AWS, Google Cloud, Azure, Vercel, Railway, Fly.io, etc.
- **On a company's internal network** — not accessible from the public internet
- **Not sure yet**

If "Just on my computer" combined with "Just me" from Q2: almost certainly **Personal** tier.

If "Not sure yet": recommend cloud hosting for anything above Personal tier. Note the uncertainty in the profile.

---

### Q7: How many users do you expect?

*Ask:* "Roughly how many people will use this? A ballpark is fine."
- **Under 100**
- **Hundreds to a few thousand**
- **Tens of thousands or more**
- **No idea**

**Skip if Q2 was "Just me."**

If "No idea": that's fine. Design for hundreds initially, make it possible to scale later.

---

### Q8: What happens if it stops working?

*Ask:* "Imagine your app goes down completely. What's the impact?"
- **No big deal** — I'll fix it when I get to it
- **Annoying** — some people will be inconvenienced
- **Serious** — people can't do their work or important tasks
- **Critical** — money is lost, legal issues arise, or people could be harmed

**Skip if Q2 was "Just me."**

If "Critical": upgrade to at least **Business**. If combined with sensitive data from Q4, likely **Regulated**.

---

### Q9: What's your budget?

*Ask:* "Do you have a budget for hosting and cloud services?"
- **Free tier only** — $0/month
- **Small** — up to $25/month
- **Moderate** — up to $100/month
- **Flexible** — whatever it takes

**After answering, give a reality check based on the tier:**
- Personal: "Good news — you can do this for free or nearly free."
- Shared: "A small cloud setup typically runs $5–25/month."
- Public: "A public app usually costs $20–100/month depending on traffic and storage. Databases, file storage, and email services each add cost."
- Business: "A production business app typically runs $100–500+/month for infrastructure, depending on scale and reliability needs."
- Regulated: "Compliance requirements add cost — security tooling, audit logging, specialized hosting. $200–1,000+/month is common."

If their budget doesn't match typical costs for their tier, flag it honestly but constructively.

---

### Q10: New project or existing code?

*Ask:* "Are we starting from scratch, or adding to an existing project?"
- **Starting from scratch** — proceed to Q10.5, then Tier Determination Logic below.
- **Adding to existing code** — proceed to Q10.5, then Existing Project Analysis below, then Tier Determination.

---

### Q10.5: Does this project use AI or language models?

*Ask:* "Will your app call AI services like ChatGPT, Claude, or other language models? Or will it use multiple AI agents that work together?"
- **No AI** — the app doesn't call any AI/LLM services
- **Single AI calls** — the app calls an AI model for specific tasks (chatbot, summarization, classification, content generation)
- **Multiple agents** — the app has multiple AI agents that work together, pass tasks between each other, or coordinate on complex workflows

Record as `ai_usage` in the profile:
- "No AI" → `none`
- "Single AI calls" → `single-llm`
- "Multiple agents" → `multi-agent`

**If `single-llm` or `multi-agent`:** Load `rules/multi-agent.md` for the project. The LLM call hygiene, prompt management, output validation, and cost control rules apply even for single LLM integrations. The agent orchestration rules are most relevant for `multi-agent` projects.

**If `multi-agent`:** After tier determination, mention that detailed orchestration guidance is available:
*"Since you're building a multi-agent system, I'll apply additional rules for how your agents communicate, manage costs, and handle failures. There are detailed guides available when we get into the specifics of your agent architecture."*

---

## Existing Project Analysis

When the user has an existing codebase, analyze it BEFORE completing the questionnaire. Many answers can be detected automatically, saving the user from answering questions the code already answers. Ask the user only for information that can't be determined from the codebase.

### What to Analyze

Scan the project and look for the following. Summarize findings for the user in plain language.

**Tech stack and dependencies:**
- Package manifests (`package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, `go.mod`, `pom.xml`, etc.) — identify the language, framework, and key libraries
- Lock files — are they present? (They should be)

**Secrets and configuration:**
- `.gitignore` — does it exist? Does it include `.env`?
- `.env` files — do they exist? Are they in `.gitignore`?
- Scan source code for patterns that look like hardcoded secrets (API keys, connection strings, tokens). Flag any found as **critical**.
- `.env.example` — does one exist?

**Database:**
- Database configuration or ORM setup — what database is used?
- Migration files — are migrations being used?
- Schema files — are foreign keys, constraints, and indexes defined?

**Authentication and authorization:**
- Auth libraries or services in use (Auth0, Clerk, Firebase Auth, Passport, NextAuth, Devise, etc.)
- Session or JWT configuration
- Password hashing approach (if handling passwords directly)
- Role/permission patterns

**API design:**
- API routes or endpoints — REST, GraphQL, or other
- Error handling patterns — consistent error format?
- Input validation — present at API boundaries?
- Rate limiting — configured?
- CORS configuration

**Security:**
- HTTPS configuration
- Security headers
- Dependency vulnerability status (run `npm audit`, `pip-audit`, or equivalent if possible)

**Infrastructure and deployment:**
- Deployment configuration (`Dockerfile`, `docker-compose.yml`, `fly.toml`, `vercel.json`, `railway.json`, `Procfile`, CI/CD config files)
- Environment separation (separate configs for dev/staging/production)
- IaC files (Terraform, Pulumi, CDK, CloudFormation)

**Observability:**
- Logging setup — structured? What library?
- Monitoring or error tracking (Sentry, Datadog, etc.)
- Health check endpoints

**Testing:**
- Test files and test runner configuration
- Test coverage (if measurable)
- Types of tests present (unit, integration, e2e)

**AI and agent usage (signals for multi-agent rules):**
- AI/LLM SDK packages in dependencies (`openai`, `anthropic`, `@anthropic-ai/sdk`, `langchain`, `langgraph`, `crewai`, `autogen`, `llamaindex`, `ai` (Vercel AI SDK), `google-generativeai`, `cohere`, `replicate`)
- Multiple LLM client instantiations or multiple agent class definitions
- Tool/function definitions for LLM function calling
- Prompt files or prompt template directories
- Agent orchestration configuration (workflow definitions, agent role definitions)
- Multiple model configurations (suggesting different models for different tasks)

If AI/LLM packages are detected, pre-fill `ai_usage` accordingly:
- One LLM client with simple calls → `single-llm`
- Multiple agents, agent frameworks, or orchestration patterns → `multi-agent`
- No AI packages → `none` (still ask Q10.5 to confirm — they may be planning to add AI)

**Architecture complexity (signals for system design questions):**
- Multiple separate deployment configurations (multiple Dockerfiles, separate CI/CD pipelines for different parts)
- Monorepo with independent modules that have their own package manifests or build configs
- Multiple distinct databases or data stores serving different purposes
- Existing service-oriented or microservices architecture (multiple running services, API gateway, message queues)
- Large number of contributors or recent commit authors (suggests multiple teams)
- Distinct domain directories with minimal cross-references (payments, inventory, notifications operating independently)

If 2+ of these signals are detected AND the tier is Business or Regulated, surface the architecture questions (Q11–Q14) regardless of experience level. The codebase itself is indicating architectural complexity that needs to be addressed.

### How to Present Findings

After analysis, present a summary to the user:

*"I've looked through your existing codebase. Here's what I found:"*

- List the tech stack and key libraries
- Note what's working well (has migrations, uses an auth library, has tests, etc.)
- Flag concerns organized by severity:
  - **Critical** (fix immediately): hardcoded secrets, missing `.gitignore`, `.env` committed to git history
  - **Important** (fix soon): no input validation, missing database constraints, no error handling, outdated dependencies with known vulnerabilities
  - **Recommended** (improve over time): no tests, no structured logging, no health check endpoint, missing security headers

### Pre-Fill the Profile

Use the analysis to pre-fill answers to the questionnaire:
- **Q3 (accounts/login):** Detected from auth configuration
- **Q4 (data stored):** Inferred from database schema and models
- **Q5 (access method):** Detected from project type (web app, API, CLI, etc.)
- **Q6 (hosting):** Detected from deployment configuration
- **Q10:** Already answered — existing code

Then ask the user ONLY for the questions that can't be detected:
- **Q1 (what are you building):** Still valuable to hear in their words
- **Q2 (who will use this):** Can't be determined from code
- **Q7 (expected users):** Can't be determined from code
- **Q8 (downtime impact):** Can't be determined from code
- **Q9 (budget):** Can't be determined from code
- **Q10.5 (AI usage):** Confirm the detected AI usage level, or ask if not detected

### Gap Assessment

After determining the tier, compare the existing codebase against the tier's rules and produce a prioritized list of gaps:

*"Based on your project's tier, here are the areas where the codebase doesn't yet meet the recommended standards. I've organized them by priority:"*

1. **Critical gaps** — security vulnerabilities, exposed secrets, missing data protection. Address before doing anything else.
2. **Important gaps** — missing input validation, no backup strategy, no error handling, missing database constraints. Address before adding new features.
3. **Recommended improvements** — missing tests, no monitoring, no deployment automation. Address as part of ongoing development.

Note these gaps in the PROJECT_PROFILE.md under "Warnings and Flags."

Do NOT try to fix everything at once. Work through gaps incrementally, starting with critical items, alongside the user's feature work.

---

## Tier Determination Logic

```
Start with Q2 answer:
  "Just me"              → Personal
  "People I know"        → Shared
  "Anyone on the internet" → Public
  "Paying customers"     → Business

Then check for upgrades (tier can only go UP):
  Q4 has health/medical data            → Regulated
  Q4 has payment/financial data          → at least Business
  Q4 has government IDs                  → at least Business
  Q8 is "Critical"                       → at least Business
  Q8 is "Critical" + sensitive data (Q4) → Regulated
```

---

## Architecture Questions (Conditional)

**Ask these ONLY when both conditions are true:**
1. The user's `experience_level` is `experienced`
2. The determined tier is **Business** or **Regulated**

For `beginner` and `intermediate` users, or for Personal/Shared/Public tiers, skip this section entirely. The monolith default in `rules/system-design.md` is the right choice for them.

### Q11: How big is the development team?

*Ask:* "How many developers will be working on this codebase?"
- **Just me or 1–2 people**
- **A small team (3–5 people)**
- **A larger team (6+ people)**
- **Multiple teams working on different parts**

Record in the profile. This is a key input for architecture style decisions.

---

### Q12: Do different parts need to scale independently?

*Ask:* "Does your system have parts with very different resource needs? For example, image processing that's CPU-heavy while user authentication is lightweight — or a real-time feed that handles 100x the traffic of account management."
- **No** — it's fairly uniform
- **Yes** — there are clearly different scaling profiles
- **Not sure**

If "Not sure": default to uniform. Revisit when real traffic data exists.

---

### Q13: Do teams need to deploy independently?

*Ask:* "Do different teams need to ship their changes without waiting on other teams?"
- **No** — we coordinate releases
- **Yes** — we need independent deployment
- **Not applicable** — it's just one team

If "Yes" combined with "Multiple teams" from Q11: this is a strong signal for service decomposition.

---

### Q14: Are there hard domain boundaries?

*Ask:* "Does your system have clearly separate domains — areas that barely share data and could function independently? For example: payments, inventory management, and notifications."
- **No** — it's one cohesive application
- **Yes** — there are distinct domains with clear boundaries
- **Not sure yet**

---

### Architecture Style Determination

```
Default: Monolith (all projects start here)

Consider service decomposition if 2+ of these are true:
  Q11 = "Multiple teams"
  Q12 = "Yes" (independent scaling needs)
  Q13 = "Yes" (independent deployment needs)
  Q14 = "Yes" (clear domain boundaries)

If 0–1 are true: Monolith. Record as "Monolith" in the profile.
If 2 are true: Modular monolith with clear boundaries. Record as "Modular monolith."
  Flag: "Your project has some signals pointing toward services, but a
  well-structured monolith with clear internal boundaries is the right
  starting point. When the boundaries prove themselves, they become
  natural extraction points."
If 3–4 are true: Services may be justified. Record as "Services — evaluate."
  Flag: "Your team structure and scaling needs suggest services may be
  appropriate. But start with the boundaries clearly defined in a
  monolith or modular monolith. Extract services from proven boundaries
  — don't design them from scratch."
```

Even when the determination suggests services, the AI should emphasize the Strangler Fig approach: prove the boundaries in a monolith, then extract incrementally. See `guides/system-design/architecture-styles.md` for the detailed decision framework.

---

## After Determining the Tier

1. **Add `vibeArchitecture/` to the project's `.gitignore`.** The framework is a development tool — it should not be committed to the project's repository. Add a `vibeArchitecture/` line to the project's root `.gitignore` file. Create the file if it doesn't exist.

2. **Tell the user their tier and what it means.** Read from `tier-definitions.md`. Be encouraging, not intimidating. Example: *"Based on your answers, this is a Public-tier project. That means we'll apply security and data protection rules appropriate for an app that strangers on the internet will use. Nothing scary — just smart defaults."*

3. **Flag warnings where needed:**
   - Storing personal data at any tier: *"Since you're storing personal information, you'll likely need a privacy policy. I can't write legal documents, but it's worth looking into a template or getting professional advice."*
   - Health/financial data: *"This type of data has legal requirements around storage and handling. I'll apply the right architectural rules, but you should also consult someone who knows [HIPAA/PCI-DSS] requirements."*
   - Budget mismatch: *"Based on what you've described, hosting typically costs [range]. Your budget of [amount] might be tight. We can discuss options to work within it."*

4. **Generate PROJECT_PROFILE.md in the project root.** Save the completed profile in the project's root directory (next to the `vibeArchitecture/` folder), NOT inside `vibeArchitecture/`. The profile is project-specific data that should be committed to the project's repository. Use the template from `vibeArchitecture/PROJECT_PROFILE.md`.

5. **Confirm with the user:** *"Here's what I've captured. Does this look right? We can adjust anything."*

6. **Load the rules** from `rules/_index.md` for the determined tier and begin building.

7. **For Business and Regulated tiers:** Mention the production readiness checklist. *"When you're getting ready to launch, we'll go through a production readiness checklist together. It covers security, reliability, monitoring, and everything you need for a solid launch. We don't need it now — just know it's there for when you're ready."*
