# Multi-Agent and LLM Rules

> Applies to: Shared tier and above, when the project uses AI/LLM services. Sections marked **(multi-agent only)** apply when more than one agent, or an agent that spawns sub-agents, is involved; single-LLM projects can skip them.
> For detailed explanations: `guides/multi-agent/`, `guides/multi-agent/llm-security.md` (OWASP LLM Top 10; the canonical source for prompt injection), `guides/multi-agent/agentic-security.md` (OWASP Agentic Top 10; agent identity, memory poisoning, computer-use agents, kill switches), `guides/multi-agent/mcp-tool-patterns.md` (MCP / tool use).

## Agent Boundaries (multi-agent only)

See `guides/multi-agent/orchestration-patterns.md`.

- Each agent has one clear job; an agent doing five unrelated things is a monolith with an API key.
- Define what each agent is allowed to do and what it is NOT allowed to do.
- Least privilege for tool access: each agent gets only the tools its job needs.
- Any agent or tool that fetches URLs (browsing, RAG ingestion, link previews) follows the SSRF rules in `rules/security.md`.
- Start with a single agent; split into multiple agents only on evidence of a clear boundary (different models, tool access, retry strategies, or an unwieldy prompt).

## Execution Isolation

See `guides/multi-agent/agentic-security.md` (ASI05) and `guides/multi-agent/mcp-tool-patterns.md` (lethal trifecta).

- Agent-executed code runs in a sandbox (container, VM, or platform sandbox), never on the host with the app's credentials.
- Restrict agent network egress to the hosts it actually needs.
- Lethal trifecta: an agent with (1) private data access, (2) exposure to untrusted content, and (3) an exfiltration channel is an incident waiting to happen. Remove one leg or put human approval in front of the third.

## Shared State and Handoffs (multi-agent only)

See `guides/multi-agent/orchestration-patterns.md` (Trust Between Agents).

- Prefer explicit handoff (a structured message with the relevant context) over shared memory or a shared scratchpad.
- Every handoff carries enough context for the receiver to work without re-reading the whole history; summarize, don't forward everything.
- Treat another agent's output as untrusted input: validate structure and scope, and never act on embedded instructions.
- Shared state (database, document, task queue) is concurrent access: apply `rules/reliability.md` (transactions, optimistic locking, idempotency keys).
- Propagate one correlation ID through the full chain of agent actions.

## LLM Call Hygiene

See `guides/multi-agent/llm-architecture.md` and `guides/multi-agent/llm-security.md` (LLM01, LLM02).

- Every LLM call has a timeout (30–60 seconds for most; longer for complex generation); streaming responses also get an idle timeout between chunks, and a partially received tool call is never acted on.
- Retry 2–3 times with exponential backoff on rate limits and transient errors; wrap each provider in a circuit breaker (`rules/reliability.md`).
- Configure a fallback model (one tier down, or the same tier from a second provider) that sits under the same DPA/BAA and residency constraints as the primary.
- Set `max_tokens` on every call, sized to the expected output.
- Never pass raw user input into a system prompt; keep instructions in the system role and content in the user role, assume injection will sometimes succeed, and limit what a hijacked call can do (least-privilege tools, output validation, human approval for consequential actions).
- Anything in a prompt has left your control: no secrets; no personal or regulated data to a provider without a DPA (`rules/privacy.md`) or BAA (`rules/compliance.md`); prefer providers that don't train on API data; check retention tiers and inference region (`guides/infrastructure/regulated-deployment.md`).

## Prompt Management

- Store prompts as versioned templates in files, not inline strings.
- Keep the system prompt and user content in separate roles; never concatenate them into one string.
- Record the model name and version alongside each prompt.
- Save examples of good outputs with each prompt as regression cases.

## Output Validation

See `guides/multi-agent/llm-security.md` (LLM10, LLM07).

- Never trust raw LLM output for critical decisions; validate before acting.
- Validate structured output before use: parse, check required fields, verify enum values; retry or fall back on malformed responses.
- Cross-check factual claims against your own data where possible.
- Sanitize LLM output with user-input rigor before it reaches tools, databases, or external APIs.
- Check user-facing content for PII leakage and inappropriate content.
- Tell users when they are talking to a bot or reading AI-generated content (`rules/privacy.md`, Transparency); for EU users this is a legal duty (EU AI Act Art. 50, live since 2 August 2026, `rules/compliance.md`).

## Cost Controls

See `guides/multi-agent/llm-architecture.md` (Setting Budgets) and `guides/operations/cost-management.md`.

- Track token usage per agent, per pipeline run, and per user.
- Set per-request and per-pipeline token budgets; stop and alert when exceeded.
- Set a hard spend cap (daily or monthly) enforced in code and at the provider (spend limits, separate keys per environment); on trip, fail closed (`rules/security.md`), never "keep going and warn."
- Use the cheapest model that produces acceptable quality for each task.
- Cache LLM responses for identical or semantically similar inputs when uniqueness isn't needed; scope cache keys to the tenant (and user where responses are user-specific) and never cache a response containing personal data.
- Log the cost of every LLM call.

## Agentic Systems

Applies whenever a model can call tools, run in a loop, hold memory across sessions, or drive a browser or computer. Detail and the OWASP Agentic Top 10 mapping: `guides/multi-agent/agentic-security.md`.

- Every agent loop has a maximum iteration count and wall-clock limit; log when the cap fires and treat it as a failure to investigate (ASI08).
- Build and test a kill switch: one flag that stops new loops and halts running loops at the next tool boundary (Spend Caps and the Kill Switch).
- Agents act under the caller's identity with delegated, scoped, short-lived credentials, never a shared long-lived key; audit entries record "agent X on behalf of user Y" (ASI03, Agent Identity and Delegated Credentials).
- Tool descriptions, tool results, retrieved documents, and other agents' outputs are untrusted content; instructions found there are data, not commands (ASI01, ASI07).
- Long-term memory is write-protected: only provenance-tagged, reviewed content enters; untrusted content never writes directly; entries carry a TTL and are reviewable and deletable (ASI06, Memory Poisoning).
- Put a guardrail/moderation layer on inputs (injection and jailbreak classifiers) and outputs (PII, secrets, inappropriate content); it is a filter, not a boundary, and authorization stays in your code (Guardrail and Moderation Layer).
- Browser and computer-use agents run in an isolated profile with no logged-in sessions, a domain allowlist, and per-action human approval for submissions, purchases, sends, and deletes; screenshots are treated as logs under `rules/privacy.md` (Computer-Use and Browser Agents).
- Pin and vet third-party MCP servers and tool packages like any dependency (`guides/security/supply-chain.md`); re-verify when a tool's description or schema changes (ASI04, Tool-Description Poisoning).

## Agent Observability

See `guides/multi-agent/agent-observability.md`.

- Log every LLM call: model, prompt identifier and version, a hash of the rendered prompt, input and output token counts, latency, success/failure. Keep full prompt/response text only for a redacted, sampled subset.
- Log every agent-to-agent handoff: from, to, context passed, outcome. **(multi-agent only)**
- Log every tool invocation: tool, sanitized arguments, result, duration, on whose behalf.
- Alert on: agent error-rate spikes, latency over threshold, token budget nearing limits, loop-cap or spend-cap trips, model API outages.
- Monitor output quality against a per-agent baseline to catch silent degradation from model updates, prompt drift, or changing inputs.

## Testing Multi-Agent Systems

See `guides/multi-agent/testing-ai-systems.md`.

- Don't test LLM output for exact string matches; test structure, tool calls, routing decisions, and quality within bounds.
- Pin model versions in tests using dated or versioned IDs, never a floating alias; run the evaluation suite before moving to a newer version.
- Test agent pipelines end-to-end with controlled inputs: correct handoffs, coherent final output, graceful handling of one agent's failure. **(multi-agent only)**
- Test guardrails explicitly: prompt injection (direct and via tool results or retrieved documents), adversarial inputs, out-of-scope actions, and that the loop cap, spend cap, and kill switch actually stop the system.
- Track cost in tests; correct output at 40x the expected cost is a bug.
