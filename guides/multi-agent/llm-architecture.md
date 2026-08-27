# LLM Architecture: Building Reliable AI-Powered Applications

> For the compact rules, see `rules/multi-agent.md`.

## Why This Matters

Calling an AI model is not like calling a normal API. Normal APIs are deterministic — same input, same output, every time. AI models are non-deterministic — same input, different output each time. They can hallucinate facts, ignore instructions, produce malformed output, or occasionally go completely off the rails.

Building a reliable application on top of AI requires treating LLM calls with the same caution you'd apply to any unreliable external service — plus handling the unique challenges that come with non-deterministic, natural-language outputs.

## Prompt Management

### Why Prompts Belong in Files

Prompts are the instructions that control your AI's behavior. They're as important as your application code — arguably more so, because a subtle prompt change can completely alter your app's behavior.

Yet many projects bury prompts as inline strings deep in function calls:

```
# Don't do this
response = client.chat(
    messages=[{"role": "system", "content": "You are a helpful assistant that classifies customer support tickets into categories: billing, technical, general. Respond with only the category name."}]
)
```

This is like hardcoding your database queries as string literals scattered across your codebase. It works until you need to change something, and then you're hunting through code to find every prompt.

**Store prompts in template files:**

```
# prompts/classify-ticket.md (or .txt, .yaml, .json)
You are a customer support classifier.

Given a support ticket, classify it into exactly one category:
- billing
- technical
- general

Respond with only the category name, nothing else.
```

Now your prompts are:
- **Version-controlled.** You can see what changed, when, and why.
- **Reviewable.** Prompt changes can be reviewed like code changes.
- **Separate from logic.** You can tweak the prompt without touching application code.
- **Testable.** You can run the same prompt against a set of test inputs and compare results.

### System Prompts vs. User Content

Every LLM call should have a clear separation:

- **System prompt:** Your instructions to the model. What role it plays, what format to use, what rules to follow. This comes from your code/templates.
- **User message:** The actual content to process. This comes from the user or from a previous agent's output.

Never mix them. Never build a single string that mashes your instructions together with user content. This separation is critical for preventing prompt injection (where user content tricks the model into ignoring your instructions).

### Prompt Versioning

When you change a prompt, you're changing your application's behavior. Treat prompt changes with the same care as code changes:

1. Save examples of the current prompt's good outputs (these become your regression tests)
2. Make the change
3. Run the same inputs through the new prompt
4. Compare the outputs — are they still good? Better? Worse?
5. Deploy the change

If you're using a framework that supports it, maintain prompt versions explicitly (v1, v2, v3) so you can roll back if a new prompt performs worse.

## Model Selection

### Right-Sizing Your Models

Not every task needs the most powerful model. Using the most capable model for everything is like hiring a surgeon to put on a band-aid — it works, but it's expensive and slow.

**Match the model to the task:**

| Task | Model tier | Why |
|------|-----------|-----|
| Classification, routing, labeling | Small/fast tier | Simple decision, doesn't need deep reasoning |
| Extraction, summarization, reformatting | Mid-tier | Needs comprehension but not creativity |
| Creative writing, complex reasoning, analysis, agentic multi-step work | Frontier tier | Quality matters, needs full capability |
| Simple templating, formatting | Consider not using an LLM at all | String templates are faster, cheaper, and deterministic |

Every major provider ships models in roughly these three tiers (for example, Anthropic's Haiku / Sonnet / Opus families — example only; verify the current model list before choosing). Names and prices change every few months, so this guide talks in tiers, not model IDs.

Start with the cheapest model that produces acceptable quality. Move up only when you have evidence the cheaper model isn't good enough.

### Fallback Chains

AI model APIs go down. They hit rate limits. They have bad days. Your application needs a plan B:

```
Primary: mid-tier model, provider A
  ↓ (if unavailable or rate-limited)
Fallback: small/fast model from provider A, or the same tier from provider B
  ↓ (if also unavailable)
Fallback: Return cached response or graceful error
```

Implementation:
1. Try the primary model with a timeout
2. If it fails (timeout, rate limit, server error), try the fallback
3. If the fallback also fails, either return a cached response (if available and appropriate) or return a clear error to the user

**Timeouts come first.** Models can be slow or unresponsive, and a missing timeout means one stalled call blocks the whole pipeline (or, on a queue, every worker behind it). 30 to 60 seconds covers most calls; long-form generation gets more, but never "no limit." For streaming, add an idle timeout between chunks and never act on a partially received tool call (`guides/multi-agent/agentic-security.md`, Streaming). Retry transient errors and rate limits 2 or 3 times with exponential backoff, then fail over. The fallback is usually one tier down (frontier to mid-tier, mid-tier to small/fast) or the same tier from a second provider; degraded output beats no output. Set `max_tokens` on every call sized to the expected output, because an unbounded generation can run to thousands of tokens and blow both budget and latency target.

**The fallback must be legally interchangeable with the primary.** If your primary provider is under a DPA (or a BAA for health data) and serves from an EU endpoint, the fallback needs the same agreement and the same residency. A failover that quietly routes regulated data to an uncovered provider is a data breach with extra steps. Wrap each provider in a circuit breaker (`rules/reliability.md`) so a dead provider fails fast rather than eating your timeout budget on every request.

Don't fail silently. If you're serving degraded responses from a fallback model, log it and alert so you know something is wrong.

### Model Versioning

AI models get updated. The "Claude Sonnet" you tested against today may behave differently from the "Claude Sonnet" of next month. When possible:

- **Pin model versions in production.** Use the provider's dated or versioned model ID rather than a floating alias like "latest" (Anthropic, for example, publishes IDs such as `claude-haiku-4-5-20251001` alongside undated aliases — example only; verify the current model list). An alias can change under you overnight.
- **Test before upgrading.** Run your evaluation suite against the new version before switching production traffic
- **Keep model version in your configuration,** not hardcoded in source code, so you can change it without a code deploy

## Output Validation

### Why You Can't Trust LLM Output

LLMs are confident, articulate, and sometimes completely wrong. They will:

- Produce invalid JSON when you asked for JSON
- Invent fields you didn't request
- Omit fields you did request
- Return "I'd be happy to help!" instead of the structured data you asked for
- Hallucinate facts, URLs, statistics, and API endpoints
- Confidently format a phone number incorrectly

For non-critical uses (drafting an email, generating ideas), this is fine — a human reviews the output. For automated pipelines where the output triggers actions (sending emails, updating databases, making API calls), you must validate.

### Structural Validation

When you expect structured output:

1. **Use the model's structured output mode** if available (JSON mode, tool use / function calling). This constrains the output format at the model level.
2. **Parse the output.** Don't assume it's valid. Try to parse the JSON, catch the error, retry if it fails.
3. **Validate the schema.** The JSON might parse successfully but be missing required fields or have wrong types. Validate against a schema.
4. **Check enum values.** If you asked for a category from a specific list, verify the response is actually in that list.

### Factual Validation

When the LLM makes factual claims that your application acts on:

- **Cross-check against your data.** If the agent says "this customer's last order was #1234," verify that against the database.
- **Don't use LLM-generated URLs or links without checking.** They're frequently hallucinated.
- **Be skeptical of numbers and statistics.** LLMs are unreliable with precise figures.

### Retry Strategy for Bad Output

When validation fails:

1. **Retry with the same prompt** (the model is non-deterministic, so you might get valid output on the second try). 1–2 retries is reasonable.
2. **Retry with a more explicit prompt** ("Your previous response was invalid JSON. Please respond with ONLY valid JSON in this exact format: ...").
3. **Fall back to a more capable model.** If the cheap model keeps producing invalid output, try the expensive one.
4. **Fail gracefully.** After exhausting retries, don't crash. Log the failure, return an error to the user, and move on.

## Prompt Injection

Prompt injection — user input, or content the model reads, that overrides your instructions — is covered once, in `guides/multi-agent/llm-security.md` (LLM01). That guide is the canonical source; this section only says what the architecture must assume.

- Keep instructions in the system role and user content in the user role. This is a useful mitigation, not a fix.
- Injection also arrives *indirectly*: inside a retrieved document, a web page, an email, a tool result, or even a tool's own description. Anything the model reads is an input.
- Don't rely on keyword blocklists ("ignore previous instructions"). They are trivially bypassed and give false confidence.
- Design so that a successful injection can't do much: least-privilege tools, output validation before any action, and human approval for consequential or irreversible steps. See the lethal trifecta in `guides/multi-agent/mcp-tool-patterns.md`.

## Token Budget Management

### Understanding Costs

LLM calls are billed by tokens (roughly words). A typical pipeline might:

- Send a 500-token system prompt
- Include 2,000 tokens of context
- Receive a 500-token response

That's 3,000 tokens per call: 2,500 in, 500 out. At illustrative mid-tier prices of $3 per million input tokens and $15 per million output tokens, that's $0.0075 input + $0.0075 output = $0.015 per call. Sounds cheap — but a 5-agent pipeline (five calls per request) is $0.075 per request, and at 10,000 requests a day that's $750/day, or roughly $22,000 a month. Rerun this arithmetic with your provider's current price sheet; the shape of the surprise is the same at any price.

### Practical Cost Optimization

**Shorter prompts.** Every token in your prompt costs money on every call. A prompt that's 500 tokens instead of 1,000 saves 50% on input costs — multiplied by every call.

**Caching.** If you're processing the same document twice, cache the result. If 100 users ask similar questions, a semantic cache can return a cached response for similar (not just identical) queries.

**Prompt caching.** Most providers offer discounted pricing when the beginning of your prompt is identical across calls. The mechanics matter: writing a prefix into the cache usually costs a *premium* over normal input (25% or more, depending on provider and cache lifetime), and reading it back is heavily discounted (often around 90% off). So caching only pays when the same prefix is reused several times within the cache's lifetime. Structure prompts so the static system instructions and tool definitions come first, put the cache breakpoint immediately before the variable content, and don't churn the prefix with timestamps or per-user data. Details: `guides/multi-agent/agentic-security.md` (Prompt Caching Cost Mechanics).

**Summarization in pipelines.** Instead of passing the full output of Agent A (2,000 tokens) to Agent B, summarize it to 500 tokens. Agent B gets what it needs at a quarter of the cost.

**Batch processing.** If you have 100 items to classify, some providers offer batch APIs at reduced rates. Even without a batch API, grouping items into a single prompt ("classify these 10 items") is cheaper than 10 separate calls.

### Setting Budgets

1. **Per-call budget:** Set `max_tokens` on every call. A classification task that should return one word doesn't need a 4,000-token output budget.
2. **Per-pipeline budget:** Track cumulative tokens across all agents in a pipeline run. If a pipeline normally uses 10,000 tokens and suddenly uses 100,000, something is wrong (probably an infinite loop or runaway agent). Kill it.
3. **Per-user budget:** For user-facing applications, consider per-user rate limits to prevent abuse or runaway usage.
4. **Monthly budget:** Set alerts at 50%, 80%, and 100% of your monthly AI spend budget. Treat this with the same urgency as cloud infrastructure billing alerts. (This is the one place the 50/80/100 thresholds are spelled out; other guides link here.)
5. **Hard cap:** Alerts are not limits. Enforce a spend ceiling in code and at the provider (per-environment API keys with spend limits) so that when the cap is hit, calls stop. See `rules/multi-agent.md` (Cost Controls, Agentic Systems) and `guides/multi-agent/agentic-security.md` (Spend Caps and the Kill Switch).

## The Non-Determinism Problem

Traditional software: same input always produces the same output. You can test with exact string matching, regression tests are straightforward, and bugs are reproducible.

LLM-powered software: same input produces different output every time. Your classification agent might return "billing" on one run and "Billing" on another. Your writing agent might produce a great paragraph one time and a mediocre one the next.

**This changes how you build, test, and debug:**

- **Don't test for exact output.** Test for correct structure, correct category, correct tool calls, quality within bounds.
- **Retries may produce different results.** A failed LLM call that's retried might succeed with different (possibly better or worse) output. This is unlike retrying a database query, which returns the same data.
- **Bugs are hard to reproduce.** "The agent did something weird yesterday" might be impossible to reproduce because the model generates different responses even with identical inputs. Log enough to investigate: the prompt identifier and version, a hash of the rendered prompt, the model version, token counts, and the tool calls made — plus full prompt/response text for a redacted sample only. Logging every full prompt at volume is a cost and a privacy problem (`guides/multi-agent/agent-observability.md`, What NOT to Log).
- **Temperature matters.** A temperature of 0 makes the model more deterministic (but not fully deterministic). Use low temperature for classification and structured tasks. Higher temperature for creative tasks.
- **Set seeds when available.** Some providers offer a `seed` parameter that makes output more reproducible. Use it in testing.
