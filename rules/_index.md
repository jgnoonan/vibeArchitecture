# Rules Index

Read the project tier from `PROJECT_PROFILE.md`. Load ALL rule files listed for that tier. Each tier includes everything from lower tiers.

## Personal

- `rules/universal.md`

## Shared

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/privacy.md` *(load when the app stores personal data about other people, or any users are in the EU / UK / California)*
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*
- `rules/mobile.md` *(load when building native mobile apps — iOS, Android, React Native, or Flutter)*

## Public

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/api.md`
- `rules/accessibility.md`
- `rules/privacy.md` *(load when the app stores personal data about other people, or any users are in the EU / UK / California)*
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*
- `rules/mobile.md` *(load when building native mobile apps — iOS, Android, React Native, or Flutter)*
- `rules/compliance.md` *(load when EU users interact with an AI feature — only the EU AI Act section applies below Regulated tier)*

## Business

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/api.md`
- `rules/accessibility.md`
- `rules/reliability.md`
- `rules/infrastructure.md`
- `rules/observability.md`
- `rules/performance.md`
- `rules/privacy.md` *(load when the app stores personal data about other people, or any users are in the EU / UK / California)*
- `rules/system-design.md` *(load when experience_level is `experienced`, or when architecture complexity is detected in an existing codebase)*
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*
- `rules/mobile.md` *(load when building native mobile apps — iOS, Android, React Native, or Flutter)*
- `rules/compliance.md` *(load when EU users interact with an AI feature — only the EU AI Act section applies below Regulated tier)*

## Regulated

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/api.md`
- `rules/accessibility.md`
- `rules/reliability.md`
- `rules/infrastructure.md`
- `rules/observability.md`
- `rules/performance.md`
- `rules/privacy.md`
- `rules/system-design.md` *(load when experience_level is `experienced`, or when architecture complexity is detected in an existing codebase)*
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*
- `rules/mobile.md` *(load when building native mobile apps — iOS, Android, React Native, or Flutter)*
- `rules/compliance.md`

## Enforcement

- When a rule conflicts with what the user asks for, explain the rule and the consequence of ignoring it in plain language.
- If the user insists on overriding a rule after understanding the risk, document the decision and the accepted risk in a code comment or project note.
- For detailed explanations of any rule, consult the corresponding file in `guides/`.
- For operations guides (cost management, day-2 operations, email deliverability, internationalization) see `guides/operations/` — not tier-gated rules, but consult them at Public tier and above when the topic comes up.
