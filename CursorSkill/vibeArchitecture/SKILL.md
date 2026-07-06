---
name: vibeArchitecture
description: Apply architectural guardrails when building software. Runs an intake questionnaire to determine the project's tier, then enforces security, reliability, and best practice rules appropriate to the tier while writing code.
---

# vibeArchitecture

**Framework version:** 1.2.0

Architectural guardrails for AI-generated code. When the user asks you to build software, follow this skill's instructions to ensure the code is secure, reliable, and production-ready.

## When to Activate

Activate this skill when:
- The user asks you to build an app, website, API, or any software project
- The user asks you to write code for a new or existing project
- The user mentions "vibeArchitecture" by name
- The user asks about security, architecture, or deployment best practices for their project

## Step 1: Check for an Existing Project Profile

Look for a `PROJECT_PROFILE.md` in the project root or in the conversation context.

- **If it exists and is filled in** (tier and project basics resolved) **and `experience_level` is one of `beginner`, `intermediate`, or `experienced`:** Read the tier and apply the rules for that tier. Skip to Step 3.
- **If it exists and is filled in but `experience_level` is missing or invalid:** Do not write code yet. Ask once: *"How do you want explanations: short and technical, or step by step with more context?"* Map to `experienced` / `beginner` / `intermediate` respectively; if the user skips, default to `experienced` and note they can say *"explain like I'm new"* anytime. Update `PROJECT_PROFILE.md`, then go to Step 3.
- **If it does not exist or has placeholder text:** Proceed to Step 2.

## Step 2: Run the Intake Conversation

Before writing any code, ask the user these questions conversationally. Ask one or two at a time. Be natural, not interrogative.

Start with: "Before we start building, I'd like to ask a few quick questions about your project. This helps me apply the right level of protection. Takes about 2 minutes."

**Q0: "How do you like explanations: short and technical, or step by step with more context?"** (Or use the fuller background question from the full framework.) Record as `experience_level`: short and technical → `experienced`; step by step → `beginner`; in between → `intermediate`.

**Q1: "Tell me what you want to build."**
Get a one-sentence description.

**Q2: "Who is this for?"**
- Just me → **Personal** tier
- People I know (friends, family, team) → **Shared** tier
- Anyone on the internet → **Public** tier
- Paying customers → **Business** tier

**Q3: "What kind of information will it store?"**
- Names, emails, phone numbers, location → personal data about other people: apply the **Privacy overlay** (load `privacy.md`) — export, deletion, and consent obligations
- Passwords → note (system handles this even if user doesn't realize)
- Payment/financial data → upgrade to at least **Business**
- Health/medical data → upgrade to **Regulated**
- Biometric data (face, fingerprint) → upgrade to **Regulated**
- Government IDs → upgrade to at least **Business**
- Children's data → upgrade to at least **Business** (COPPA)
- Nothing sensitive → no change

Also ask: **"Will any users be in the EU, UK, or California?"** If yes, the Privacy overlay (`privacy.md`) is mandatory even at Public tier.

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
  Q3 has biometric data → Regulated
  Q3 has payment/financial data → at least Business
  Q3 has government IDs → at least Business
  Q3 has children's data → at least Business
  Q4 is "Critical" → at least Business
  Q4 is "Critical" + sensitive data → Regulated

Then apply the Privacy overlay (independent of tier — an add-on, not an upgrade):
  Stores personal data about other people, OR any EU/UK/California users
    → load privacy.md (data-subject rights: export, deletion, consent)
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
- **Experience level:** [beginner / intermediate / experienced]
- **Data sensitivity:** [from conversation]
- **AI usage:** [none / single-llm / multi-agent]
- **Platform:** [web / mobile-native / both / other]
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
- Load `privacy.md` when the app stores personal data about other people, or any users are in the EU / UK / California (data-subject-rights overlay — applies from Shared upward, independent of tier)
- Load `multi-agent.md` when ai_usage is `single-llm` or `multi-agent`
- Load `system-design.md` when tier is Business or Regulated AND `experience_level` is `experienced`, or when architecture complexity is detected in an existing codebase
- Load `mobile.md` when building native mobile apps (iOS, Android, React Native, or Flutter)

Read the relevant rule files from `references/` and follow them for every piece of code you write.

## Step 4: Build with Guardrails Active

As you help the user build:

- Follow the loaded rules for every piece of code you write
- When a rule prevents something the user asks for, explain WHY in plain language
- When you're unsure about an architectural decision, say so
- If the user asks "why?" about any rule, explain the reasoning. Use the detailed explanation files in `references/` for context. Use analogies when helpful.

## How to Communicate

Adjust depth using **`experience_level`** from the profile once set. **Beginner / intermediate:** plain language, explain jargon, consequences over rule names. **Experienced:** concise, technical terms OK, no analogies unless asked.

- **Use plain language** when `experience_level` is `beginner` or `intermediate`. Assume smart, not necessarily technical.
- **No jargon without explanation** for `beginner` / `intermediate`. Example: "This needs an index -- think of it like the index in the back of a book that helps you find things quickly instead of reading every page."
- **Explain consequences, not rules** for `beginner` / `intermediate`. Instead of "this violates least privilege," say "this gives the app more access than it needs -- if someone breaks in, they can reach everything instead of just one small part."
- **Experienced users:** lead with the answer; skip praise and filler.
- **Be honest about tradeoffs.** Don't pretend there's always one right answer.
- **Effort and cost estimates:** Default to **the user plus you (the AI)** — realistic solo/small-session timelines (e.g. a weekend of focused work, a few weeks of evenings). Do **not** open with traditional team estimates (months, multiple FTEs, tens of thousands in labor) unless they explicitly want a hiring, agency, or investor-style plan. If both views help, give **vibe-coding first**, then a **clearly labeled** traditional bracket. See `assets/project-profile-template.md` under **Cost Estimate** for the same guidance when filling the profile.

## What Never to Do

- NEVER skip capturing **tier** and **experience_level** before writing code. Full intake can be shortened only when the profile already has both; if tier exists but experience is missing, the one-question gate in Step 1 is mandatory.
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

## Installing in Cursor

This skill is the Cursor edition of vibeArchitecture. To install:

1. Copy the `CursorSkill/vibeArchitecture/` folder from the repo into `~/.cursor/skills/vibeArchitecture/` (personal) or `.cursor/skills/vibeArchitecture/` (project-scoped)
2. Alternatively, ZIP the `vibeArchitecture/` folder so the archive contains `vibeArchitecture/SKILL.md` at the top level and import via Cursor Settings > Rules > Agent Skills

When the full framework is also present in a project as `vibeArchitecture/`, prefer reading `vibeArchitecture/ARCHITECT.md` and `vibeArchitecture/guides/` for deeper context beyond the compact `references/` files in this skill.
