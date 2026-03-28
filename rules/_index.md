# Rules Index

Read the project tier from `PROJECT_PROFILE.md`. Load ALL rule files listed for that tier. Each tier includes everything from lower tiers.

## Personal

- `rules/universal.md`

## Shared

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*

## Public

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/api.md`
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*

## Business

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/api.md`
- `rules/reliability.md`
- `rules/infrastructure.md`
- `rules/observability.md`
- `rules/performance.md`
- `rules/system-design.md` *(load when experience_level is `experienced`, or when architecture complexity is detected in an existing codebase)*
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*

## Regulated

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/testing.md`
- `rules/api.md`
- `rules/reliability.md`
- `rules/infrastructure.md`
- `rules/observability.md`
- `rules/performance.md`
- `rules/system-design.md` *(load when experience_level is `experienced`, or when architecture complexity is detected in an existing codebase)*
- `rules/multi-agent.md` *(load when ai_usage is `single-llm` or `multi-agent`)*
- `rules/compliance.md`

## Enforcement

- When a rule conflicts with what the user asks for, explain the rule and the consequence of ignoring it in plain language.
- If the user insists on overriding a rule after understanding the risk, document the decision and the accepted risk in a code comment or project note.
- For detailed explanations of any rule, consult the corresponding file in `guides/`.
