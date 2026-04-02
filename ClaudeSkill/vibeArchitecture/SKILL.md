---
name: vibeArchitecture
description: Apply architectural guardrails when building software. Runs an intake questionnaire to determine the project's tier, then enforces security, reliability, and best practice rules appropriate to the tier while writing code.
---

# vibeArchitecture

Architectural guardrails for AI-generated code. When the user asks you to build software, follow this skill's instructions to ensure the code is secure, reliable, and production-ready.

## When to Activate

Activate this skill when:
- The user asks you to build an app, website, API, or any software project
- The user asks you to write code for a new or existing project
- The user mentions "vibeArchitecture" by name
- The user asks about security, architecture, or deployment best practices for their project

## Step 1: Check for an Existing Project Profile

Look for a `PROJECT_PROFILE.md` in the project root or in the conversation context.

- **If it exists and is filled in:** Read the tier and apply the rules for that tier. Skip to Step 3.
- **If it does not exist or has placeholder text:** Proceed to Step 2.

## Step 2: Run the Intake Conversation

Before writing any code, ask the user these questions conversationally. Ask one or two at a time. Be natural, not interrogative.

Start with: "Before we start building, I'd like to ask a few quick questions about your project. This helps me apply the right level of protection. Takes about 2 minutes."

**Q1: "Tell me what you want to build."**
Get a one-sentence description.

**Q2: "Who is this for?"**
- Just me → **Personal** tier
- People I know (friends, family, team) → **Shared** tier
- Anyone on the internet → **Public** tier
- Paying customers → **Business** tier

**Q3: "What kind of information will it store?"**
- Names, emails, phone numbers → note privacy policy needed
- Passwords → note (system handles this even if user doesn't realize)
- Payment/financial data → upgrade to at least **Business**
- Health/medical data → upgrade to **Regulated**
- Government IDs → upgrade to at least **Business**
- Nothing sensitive → no change

**Q4: "What happens if it stops working?"** (Skip for Personal tier)
- No big deal → no change
- Serious / Critical → upgrade to at least **Business**

**Q5: "Are we starting from scratch or working with existing code?"**

**Q6: "Will your app call any AI services like ChatGPT or Claude?"**
- No → ai_usage: none
- Single AI calls → ai_usage: single-llm
- Multiple agents working together → ai_usage: multi-agent

### Tier Determination

```
Start with Q2 answer as the base tier.
Then check for upgrades (tier can only go UP):
  Q3 has health/medical data → Regulated
  Q3 has payment/financial data → at least Business
  Q3 has government IDs → at least Business
  Q4 is "Critical" → at least Business
  Q4 is "Critical" + sensitive data → Regulated
```

### After Determining the Tier

Tell the user their tier and what it means. Be encouraging:
"Based on your answers, this is a [tier] project. That means I'll apply [brief description] rules. Nothing scary -- just smart defaults."

Create a `PROJECT_PROFILE.md` with the answers:

```markdown
# Project Profile

- **Project name:** [from conversation]
- **Description:** [from conversation]
- **Date created:** [today's date]
- **Tier:** [Personal / Shared / Public / Business / Regulated]
- **Data sensitivity:** [from conversation]
- **AI usage:** [none / single-llm / multi-agent]
- **New or existing:** [new / existing]
```

## Step 3: Apply Rules by Tier

Load and follow the rules for the determined tier AND all tiers below it. The rules files are in the `references/` directory of this skill.

| Tier | Load These Rule Files |
|------|----------------------|
| **Personal** | `universal.md` |
| **Shared** | Above + `security.md`, `data.md`, `testing.md` |
| **Public** | Above + `api.md`, `accessibility.md` |
| **Business** | Above + `reliability.md`, `infrastructure.md`, `observability.md`, `performance.md` |
| **Regulated** | Above + `compliance.md` |

**Conditional rules:**
- Load `multi-agent.md` when ai_usage is `single-llm` or `multi-agent`

Read the relevant rule files from `references/` and follow them for every piece of code you write.

## Step 4: Build with Guardrails Active

As you help the user build:

- Follow the loaded rules for every piece of code you write
- When a rule prevents something the user asks for, explain WHY in plain language
- When you're unsure about an architectural decision, say so
- If the user asks "why?" about any rule, explain the reasoning. Use the detailed explanation files in `references/` for context. Use analogies when helpful.

## How to Communicate

- **Use plain language.** The user may have no coding background. Assume they are smart but not technical.
- **No jargon without explanation.** If a technical term is unavoidable, immediately explain it. Example: "This needs an index -- think of it like the index in the back of a book that helps you find things quickly instead of reading every page."
- **Explain consequences, not rules.** Instead of "this violates least privilege," say "this gives the app more access than it needs -- if someone breaks in, they can reach everything instead of just one small part."
- **Be honest about tradeoffs.** Don't pretend there's always one right answer.
- **Effort and cost estimates:** Default to **the user plus you (the AI)** — realistic solo/small-session timelines (e.g. a weekend of focused work, a few weeks of evenings). Do **not** open with traditional team estimates (months, multiple FTEs, tens of thousands in labor) unless they explicitly want a hiring, agency, or investor-style plan. If both views help, give **vibe-coding first**, then a **clearly labeled** traditional bracket. See `assets/project-profile-template.md` under **Cost Estimate** for the same guidance when filling the profile.

## What Never to Do

- NEVER skip the intake conversation, even if the user says "just build it"
- NEVER hardcode secrets in code, even in examples
- NEVER generate code without error handling
- NEVER use a div as a button or skip form labels
- NEVER build SQL by concatenating user input into query strings
- NEVER store passwords in plain text

## Reference Files

The `references/` directory contains the detailed rule files for each tier. Load them based on the tier determination above. Each file is compact (80-120 lines) and designed to be loaded into context efficiently.

The `assets/` directory contains:
- `tier-definitions.md` -- Detailed explanation of what each tier means
- `project-profile-template.md` -- Full template for the project profile

## More Information

vibeArchitecture is open source (MIT licensed). For the full framework with detailed guides, checklists, and IDE integrations: https://github.com/jgnoonan/vibeArchitecture
