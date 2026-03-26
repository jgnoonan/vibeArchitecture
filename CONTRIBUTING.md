# Contributing to vibeArchitecture

Thank you for your interest in improving vibeArchitecture. This framework exists to help people build better software with AI, and community contributions make it stronger.

## How to Contribute

### Reporting Issues

- **Incorrect or outdated advice** — If a rule, guide, or recommendation is wrong, misleading, or outdated, open an issue describing the problem and suggesting a correction.
- **Missing topics** — If there's an important architectural concern not covered, open an issue describing what's missing and why it matters.
- **Language clarity** — If something uses jargon without explanation or is confusing to a non-technical reader, that's a bug. Report it.
- **Broken links or formatting** — Small fixes matter. Report them or submit a PR directly.

### Submitting Changes

1. Fork the repository
2. Create a branch for your change (`git checkout -b improve-security-guide`)
3. Make your changes
4. Submit a pull request with a clear description of what you changed and why

### What Makes a Good Pull Request

- **One topic per PR.** A PR that fixes a typo in the glossary and rewrites the caching guide should be two separate PRs.
- **Explain the "why."** Don't just say what you changed — explain why the change improves the framework.
- **Respect the audience.** This framework is written for people who may not have a software engineering background. Technical accuracy matters, but so does accessibility.

## Writing Standards

All content in vibeArchitecture follows these principles:

### For User-Facing Content (checklists, intake, tier definitions)

- **Zero jargon.** Every term should be understandable by someone who has never worked in software engineering.
- **Conversational tone.** Write as if you're explaining something to a smart friend over coffee.
- **Actionable.** Every item should tell the reader what to do or decide, not just what to know.

### For AI-Facing Content (rules)

- **Compact.** Rules files are loaded into AI context windows. Every line counts. No filler, no repetition, no lengthy introductions.
- **Direct.** State the rule, then state the consequence of breaking it. One to three lines per rule.
- **Technical terms are acceptable** since the AI understands them, but include instructions to explain in plain language when communicating with the user.

### For Guides (detailed explanations)

- **Explain the "why."** These exist to answer "why does this rule exist?" Lead with the reasoning, not the instruction.
- **Use analogies.** Good analogies make abstract concepts concrete. The textbook-index analogy for database indexes, the ship-bulkhead analogy for isolation — these help non-technical readers build mental models.
- **Include tradeoffs.** Don't pretend there's always one right answer. When there are real tradeoffs, present them honestly and make a recommendation.
- **Examples matter.** Show what bad code looks like and what good code looks like. Code examples should be language-agnostic or use the most commonly understood language for the concept.

### For All Content

- **Opinionated with escape hatches.** State the default clearly. Then briefly note when the default doesn't apply.
- **No padding.** If a sentence doesn't add information, cut it.
- **Token budget awareness.** Rules files should stay under 120 lines. Guides should stay under 300 lines. If a topic needs more space, consider splitting it into two files.

## Structure Conventions

- **Rules files** go in `rules/` and are named for their domain: `security.md`, `data.md`, etc.
- **Guide files** go in `guides/{domain}/` and are named for their specific topic: `guides/security/authentication.md`.
- **Each rules file references its corresponding guides** with a note at the top: `> For detailed explanations: see guides/{domain}/`
- **Each guide starts with a note** explaining when to read it: `> This guide explains... Read it when...`

## Tier System

When adding or modifying rules, respect the tier system:

- **Universal** — applies to all projects, no exceptions
- **Shared** — adds security and data integrity basics
- **Public** — adds API hardening and deployment awareness
- **Business** — adds reliability, infrastructure, observability, performance
- **Regulated** — adds compliance-specific requirements

If a rule only matters for projects with paying customers, it belongs in Business tier or above — not in Universal. Overloading lower tiers with unnecessary rules defeats the purpose of the tiering system.

## Questions?

Open an issue with the "question" label. We're happy to discuss contributions before you invest time writing them.
