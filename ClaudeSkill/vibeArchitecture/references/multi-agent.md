# Multi-Agent and LLM Rules

> Applies to: Shared tier and above, when the project uses AI/LLM services.
> For detailed explanations: see `guides/multi-agent/`

## Agent Boundaries

- Each agent has one clear job. A "research agent" researches. A "writing agent" writes. A "review agent" reviews. If an agent is doing five unrelated things, it's not an agent — it's a monolith with an API key.
- Define what each agent is allowed to do and — equally important — what it is NOT allowed to do. An agent that can read customer data should not also be able to delete it unless that's explicitly its job.
- Apply the principle of least privilege to tool access. Give each agent only the tools it needs. A summarization agent doesn't need database write access. A classification agent doesn't need to send emails.
- Start with a single agent doing everything. Extract into multiple agents only when you have evidence of a clear boundary — different models needed, different tool access, different retry strategies, or the single agent's prompt is becoming unwieldy. This is the "monolith first" principle applied to agents.

## Shared State and Handoffs

- Prefer explicit handoff over shared memory. When Agent A finishes and Agent B needs to continue, pass a structured message with the relevant context — don't have both agents reading and writing to a shared scratchpad.
- Every handoff must include enough context for the receiving agent to do its job without re-reading the entire conversation history. Summarize, don't forward everything.
- If agents must share state (a database, a document, a task queue), treat it exactly like concurrent access to shared resources. The concurrency rules in `rules/reliability.md` apply: use transactions, optimistic locking, or idempotency keys.
- Track the full chain of agent actions with a correlation ID. When a user request triggers Agent A, which calls Agent B, which calls Agent C, all three should log the same correlation ID so you can trace the full pipeline.

## LLM Call Hygiene

- Every LLM API call must have a timeout. Models can be slow or unresponsive. A missing timeout means one stalled call blocks your entire pipeline. Set reasonable timeouts (30–60 seconds for most calls, longer for complex generation).
- Retry LLM calls with exponential backoff. Rate limits and transient errors are normal. Retry 2–3 times with increasing delays before failing.
- Configure a fallback model. If your primary model is unavailable or rate-limited, fall back to an alternative (e.g., Claude Sonnet → Claude Haiku, GPT-4o → GPT-4o-mini). Degraded output is better than no output.
- Set a token limit on every call. An unbounded generation can produce thousands of tokens, consume your budget, and blow your latency target. Set `max_tokens` appropriate to the expected output size.
- Never pass raw, unsanitized user input directly into a system prompt. This is prompt injection — the LLM equivalent of SQL injection. User content goes in the user message, clearly separated from your instructions.

## Prompt Management

- Store prompts as versioned templates in files, not as inline strings scattered across your codebase. When a prompt changes, you should be able to see what changed, when, and why — just like any other code change.
- Separate the system prompt (your instructions to the model) from user content (the input being processed). Never concatenate them into a single string.
- Include the model name and version in your prompt configuration. When you upgrade models, some prompts may need adjustment. Knowing which prompt was written for which model prevents silent quality degradation.
- When a prompt works well, save examples of its good outputs alongside it. These become your regression test cases.

## Output Validation

- Never trust raw LLM output for critical decisions. The model can hallucinate, misformat, or produce confidently wrong answers. Validate before acting.
- When you expect structured output (JSON, specific fields, categories), validate the structure before using it. Parse the JSON. Check required fields exist. Verify enum values are within the expected set. Handle malformed responses with a retry or fallback.
- For factual claims, cross-check against your own data when possible. If an agent says "the customer's order total is $142.50," verify that against the database — don't take the model's word for it.
- Before passing LLM output to tools, databases, or external APIs, sanitize it with the same rigor you'd apply to user input. An LLM can produce SQL, shell commands, or API calls that are subtly wrong or dangerous.
- For user-facing content, check for PII leakage (did the model accidentally include someone's email or phone number from its training data?) and inappropriate content.

## Cost Controls

- Track token usage per agent, per pipeline run, and per user. You need to know where your money is going before you can optimize.
- Set per-request and per-pipeline token budgets. If a single pipeline run exceeds the budget, stop and alert — don't let a runaway loop burn through your account.
- Use the cheapest model that produces acceptable quality for each task. Classification, routing, and simple extraction rarely need the most capable model. Save expensive models for tasks that actually need them.
- Cache LLM responses for identical or semantically similar inputs when the output doesn't need to be unique. Summarizing the same document twice should cost you once.
- Log the cost of every LLM call. This isn't optional for production systems. When your monthly bill spikes, you need to identify which agent, which pipeline, or which user is responsible.

## Agent Observability

- Log every LLM call: model used, prompt identifier (not the full prompt — that's too large), input token count, output token count, latency, and success/failure status.
- Log every agent-to-agent handoff: which agent handed off to which, what context was passed, and whether the receiving agent succeeded.
- Log every tool invocation: which tool, what arguments, what result, how long it took.
- Set up alerts for: error rate spikes on any agent, latency exceeding thresholds, token budget approaching limits, model API outages.
- Monitor output quality over time. Establish a baseline for each agent's quality metrics and detect when it degrades — model updates, prompt drift, or changing input patterns can all cause silent quality drops.

## Testing Multi-Agent Systems

- LLM outputs are non-deterministic. Don't test for exact string matches. Test for: correct structure, correct tool calls, correct routing decisions, quality within acceptable bounds.
- Pin model versions in tests. If your tests pass with `gpt-4o-2024-08-06` and you upgrade to a newer version, run the evaluation suite before deploying the change.
- Test agent pipelines end-to-end with controlled inputs. Verify that agents hand off correctly, that the final output is coherent, and that failure in one agent is handled gracefully.
- Test your guardrails explicitly. Attempt prompt injection, send adversarial inputs, request out-of-scope actions. Your guardrails should catch these — verify that they do.
- Track costs in tests. A pipeline that produces correct output but costs $2 per run instead of $0.05 is a bug.
