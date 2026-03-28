# Agent Observability: Knowing What Your AI Is Actually Doing

> For the compact rules, see `rules/multi-agent.md` (Agent Observability section).

## Why This Is Different from Normal Observability

In a traditional web application, monitoring is mostly about "is it up?" and "is it fast?" With AI agents, you have a new dimension: "is the output any good?"

A traditional API either returns the right data or throws an error. An AI agent can return a confident, well-formatted response that is completely wrong. It can silently degrade — producing slightly worse output over weeks as input patterns shift or models get updated — and you won't know unless you're measuring.

Agent observability means knowing three things at all times:
1. **Is it running?** (Same as traditional monitoring — uptime, errors, latency)
2. **Is it costing what I expect?** (Token usage, per-agent and per-pipeline costs)
3. **Is the output still good?** (Quality measurement — the hard new part)

## What to Log

### Every LLM Call

For every call to an AI model, log:

- **Timestamp** — when the call happened
- **Model** — which model and version (e.g., `claude-sonnet-4-20250514`, not just "Sonnet")
- **Prompt identifier** — a name or ID for the prompt template used (e.g., "classify-ticket-v3"), NOT the full prompt text (that's too large for high-volume logging)
- **Input tokens** — how many tokens went in
- **Output tokens** — how many tokens came out
- **Latency** — how long the call took (from request sent to response received)
- **Status** — success, error, timeout, rate-limited
- **Error details** — if it failed, why

This gives you the basics: how often you're calling models, how much it costs, how fast it is, and how often it fails.

### Agent-to-Agent Handoffs

When one agent passes work to another:

- **Correlation ID** — the ID that ties this entire request together, from the user's original request through every agent in the pipeline
- **Source agent** — who handed off
- **Destination agent** — who received
- **Handoff summary** — what was passed (a brief description, not the full payload)
- **Timestamp** — when the handoff happened

This lets you trace a single user request through your entire agent pipeline — invaluable when debugging "the system gave a weird answer."

### Tool Invocations

When an agent uses a tool (database query, web search, API call, file read):

- **Agent** — which agent invoked the tool
- **Tool** — which tool was called
- **Arguments** — what was passed to the tool (sanitize sensitive data)
- **Result summary** — success/failure, relevant metadata (rows returned, response status)
- **Latency** — how long the tool call took

Tool calls are where your agents interact with the real world. When something goes wrong, it's usually here.

### What NOT to Log

- **Full prompt text in production.** At high volume, logging every prompt creates enormous storage costs and potential privacy issues (prompts may contain user data). Log prompt identifiers instead, and keep full prompts in your template files where they can be reviewed.
- **Full LLM output in production.** Same issue. Log a summary or hash. Keep full outputs only for a sample (see Quality Measurement below).
- **Sensitive user data in plain text.** If your prompts include personal information, redact it before logging. Your observability system should not become a secondary database of customer data.

## Tracing Across Agents

When a user's request triggers a pipeline of 3–5 agents, you need to follow the thread. This is distributed tracing applied to agent systems.

**How it works:**

1. When a request enters your system, generate a unique **correlation ID** (a UUID or similar).
2. Pass this ID to every agent and every tool call in the pipeline.
3. Include it in every log entry.
4. When something goes wrong, search your logs by correlation ID and you see the entire journey: which agents ran, what they produced, where things went sideways.

**Analogy:** It's like a tracking number for a package. The package goes through multiple warehouses and trucks, but the tracking number lets you see every step of the journey.

Most AI frameworks support this natively (LangSmith for LangChain/LangGraph, CrewAI's built-in logging). If you're building without a framework, implement it yourself — it's as simple as passing an ID through your function calls.

## Cost Tracking

AI costs can surprise you. Unlike cloud infrastructure (where you provision a server and the cost is predictable), AI costs are directly proportional to usage — and usage patterns can shift quickly.

### What to Track

- **Cost per LLM call.** Input tokens × input price + output tokens × output price. Log this for every call.
- **Cost per agent.** Sum of all LLM calls for a given agent type over a time period. This tells you which agents are expensive.
- **Cost per pipeline run.** Total cost across all agents for a single user request or task. This is your "unit economics" — the cost to serve one request.
- **Cost per user.** If users trigger different numbers of pipelines, track per-user spending. One heavy user shouldn't blow your budget.
- **Daily/weekly/monthly totals.** For budgeting and trend analysis.

### Building a Cost Dashboard

At minimum, you want to see:

1. **Total spend today/this week/this month** — against your budget
2. **Spend by agent** — which agents cost the most?
3. **Spend by model** — are you using expensive models where cheap ones would work?
4. **Trend line** — is spending going up or down? A gradual increase might mean growing usage (good) or a pipeline getting less efficient (bad).

For small projects, this can be as simple as a spreadsheet updated from your logs. For larger projects, tools like LangSmith, Helicone, or custom dashboards built on your logging data.

### Setting Alerts

- **Budget threshold alerts.** Alert at 50%, 80%, and 100% of your monthly budget. At 100%, you need to decide: increase the budget or reduce usage.
- **Per-pipeline cost spike.** If a single pipeline run costs 10x the average, alert immediately. This likely indicates an infinite loop or runaway agent.
- **Sudden usage increase.** If daily call volume doubles without a corresponding increase in users, investigate. A bug might be causing duplicate calls.

## Quality Measurement

This is the genuinely hard part. How do you know if your AI's output is good?

### Automated Evaluation

**Structural checks (easiest):**
- Did the output parse as valid JSON?
- Are all required fields present?
- Are values within expected ranges or categories?
- Did the agent call the right tools?

These catch obvious failures but not subtle quality issues.

**LLM-as-Judge (moderate difficulty):**
Use a second AI model to evaluate the first model's output. "On a scale of 1–5, how well does this summary capture the key points of the original document?"

This works surprisingly well for relative comparisons (is output A better than output B?) but less well for absolute quality assessment. It's also not free — the judge model consumes tokens too.

Practical tips for LLM-as-Judge:
- Use a more capable model as the judge than the model being judged
- Provide a clear rubric (not "is this good?" but "does it include all three key points, avoid fabrication, and stay under 200 words?")
- Run the same evaluation multiple times and average scores to reduce randomness
- Validate the judge occasionally with human evaluation — make sure the judge and humans agree

**Task-specific metrics (when available):**
- Classification: accuracy, precision, recall against labeled test data
- Extraction: did it extract the correct values from the document?
- Summarization: does the summary contain the key points? (Can be checked programmatically if you know the key points)

### Human Evaluation (The Gold Standard)

No automated evaluation fully replaces human judgment. Build human review into your workflow:

- **Sample a percentage of outputs.** You don't need to review everything. Reviewing 1–5% of outputs gives you a meaningful quality signal.
- **Simple rating scale.** Good / Acceptable / Bad is enough for most purposes. Don't ask reviewers to fill out a 10-field rubric.
- **Track quality over time.** If the percentage of "Bad" ratings increases, investigate. A model update, a prompt change, or shifting input patterns might be the cause.
- **Use bad outputs to improve prompts.** When a human marks an output as "Bad," save it with an explanation. These become your improvement cases — update the prompt to handle them, then verify with regression testing.

### Quality Baselines

When your system is working well, establish baselines:

- Average quality score per agent (from LLM-as-Judge or human evaluation)
- Error rate (percentage of outputs that fail validation)
- Typical token usage per pipeline run

Then monitor for deviation. A 10% drop in quality scores is a signal to investigate, even if nothing looks broken at the infrastructure level.

## Getting Started

If your agent system has no observability today, start here:

1. **Log every LLM call** with model, tokens, latency, and status. This takes 15 minutes to add and gives you cost visibility immediately.
2. **Add a correlation ID** to your pipeline. Pass it through every agent. Include it in logs. This makes debugging possible.
3. **Set up billing alerts** with your AI provider. This takes 5 minutes and prevents surprise bills.
4. **Sample and review outputs.** Once a week, look at 20–50 outputs from your agents. Are they good? Are any surprising? This is the simplest quality measurement and often the most insightful.

Ask your AI: *"Help me add structured logging for all LLM calls in this project, including model, token count, latency, and a correlation ID."*
