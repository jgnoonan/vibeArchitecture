# vibeArchitecture

Architectural guidance for AI-assisted development. This file is the entry point — read it first, follow the instructions below.

## Step 1: Check for a Project Profile

Look for `PROJECT_PROFILE.md` in this directory.

- **If it has NOT been filled in** (still contains `[To be filled in]` placeholders): STOP. Do not write any code. Read `intake/questionnaire.md` and conduct the intake conversation with the user first. The conversation will produce a completed `PROJECT_PROFILE.md`.
- **If it HAS been filled in**: Proceed to Step 2.

## Step 2: Load the Appropriate Rules

Read `rules/_index.md` to determine which rule files apply based on the project's tier (recorded in `PROJECT_PROFILE.md`). Load those rule files. They are compact and designed to fit within context limits — load all that apply for the tier.

## Step 3: Build with the Rules Active

As you help the user build their project:

- Follow the loaded rules for every piece of code you write or suggest
- When a rule prevents something the user asks for, explain WHY in plain language
- When you're unsure about an architectural decision, say so — don't guess
- Surface the relevant checklist at the right time:
  - `checklists/before-you-build.md` when starting a new project
  - `checklists/before-you-deploy.md` when deployment or "going live" is discussed

## Step 4: Explain When Asked

If the user or you need deeper context on any rule, consult the detailed guide in `guides/` for that topic. These contain full reasoning, tradeoffs, and alternatives. Only load them when needed — not preemptively.

## How to Communicate

- **Use plain language.** The user may not have a software engineering background. Assume they are smart but not technical.
- **No jargon without explanation.** If a technical term is unavoidable, immediately explain it in everyday language. Example: "This needs an index — think of it like the index in the back of a book that helps you find things quickly instead of reading every page."
- **Explain consequences, not rules.** Instead of "this violates the principle of least privilege," say "this gives the app more access than it needs — if someone breaks in, they can reach everything instead of just one small part."
- **Be honest about tradeoffs.** Don't pretend there's always one right answer. When real tradeoffs exist, explain them and make a recommendation.

## Non-Negotiable Principles

These apply to EVERY project, regardless of tier:

1. **Never store secrets in your code.** API keys, passwords, and tokens must never appear in files committed to a repository. If a secret is committed even once, consider it compromised.
2. **Never trust information from users.** Anything a user types, uploads, or sends could be malicious. Always validate and sanitize before using it.
3. **Assume things will break.** Every network call can fail. Every external service will go down eventually. Handle failure gracefully instead of crashing.
4. **Make it work, make it right, then make it fast.** Get functionality working first. Clean up and fix the design. Only optimize speed after measuring an actual bottleneck.
5. **Document your big decisions.** When choosing a database, hosting provider, or significant library, write down what you chose and why.
6. **If you don't understand why something exists, don't remove it.** Ask first. It may be preventing a problem that took hours to discover.

## Module Index

| Directory | Purpose | When to Consult |
|-----------|---------|-----------------|
| `intake/` | Project intake questionnaire | Before any code is written |
| `rules/` | Compact architectural rules by tier | Every session — loaded based on project tier |
| `guides/` | Detailed explanations and tradeoffs | When the user asks "why?" or deeper context is needed |
| `checklists/` | Plain-English action items | At project milestones (start, pre-deploy, incidents) |
| `appendices/` | Anti-patterns, glossary, resources | Reference material as needed |
