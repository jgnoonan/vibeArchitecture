# Rules Index

Read the project tier from `PROJECT_PROFILE.md`. Load ALL rule files listed for that tier. Each tier includes everything from lower tiers.

## Personal

- `rules/universal.md`

## Shared

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`

## Public

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/api.md`

## Business

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/api.md`
- `rules/reliability.md`
- `rules/infrastructure.md`
- `rules/observability.md`
- `rules/performance.md`

## Regulated

- `rules/universal.md`
- `rules/security.md`
- `rules/data.md`
- `rules/api.md`
- `rules/reliability.md`
- `rules/infrastructure.md`
- `rules/observability.md`
- `rules/performance.md`
- `rules/compliance.md`

## Enforcement

- When a rule conflicts with what the user asks for, explain the rule and the consequence of ignoring it in plain language.
- If the user insists on overriding a rule after understanding the risk, document the decision and the accepted risk in a code comment or project note.
- For detailed explanations of any rule, consult the corresponding file in `guides/`.
