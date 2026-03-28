# Testing AI Systems: When the Output Is Different Every Time

> For the compact rules, see `rules/multi-agent.md` (Testing section).
> For general testing guidance, see `rules/testing.md` and `guides/testing/testing-strategy.md`.

## The Fundamental Challenge

Normal software testing follows a simple pattern: given input X, expect output Y. If the output isn't Y, the test fails and you have a bug.

AI-powered software doesn't work this way. Ask an LLM to summarize an article and you'll get a different summary every time. Ask it to classify a support ticket and it might say "billing" on one run and "Billing" on another. Ask it to write a marketing email and you'll get a completely different email each attempt.

This doesn't mean you can't test AI systems. It means you need different testing strategies — ones that check for correctness at a higher level than exact string matching.

## What You CAN Test Deterministically

Even in non-deterministic systems, many things are predictable and testable with traditional methods:

### Tool Calls

When an agent decides to call a tool (search the web, query a database, send an email), you can test:
- Did it call the right tool?
- Did it pass the correct arguments?
- Did it handle the tool's response appropriately?

These are deterministic — either the agent called `search_database(customer_id=123)` or it didn't.

### Routing Decisions

If a router agent classifies a request and sends it to the appropriate specialist:
- Given a billing complaint, does it route to the billing agent?
- Given a technical question, does it route to the tech support agent?
- Given an ambiguous request, does it handle it reasonably?

Run the same 50 test inputs and check that routing accuracy stays above a threshold (e.g., 95%). Individual runs may vary, but the aggregate should be stable.

### Output Structure

If you expect JSON with specific fields:
- Does it parse as valid JSON?
- Are all required fields present?
- Are field types correct (string, number, array)?
- Are enum fields within the allowed values?

Structure validation is fully deterministic and should be tested like any other code.

### Guardrail Enforcement

Your guardrails should be tested adversarially:
- Send a prompt injection attempt. Does the agent resist it?
- Ask the agent to perform an action outside its scope. Does it refuse?
- Send input containing PII. Does the output handle it appropriately?
- Send a request that would exceed token budget limits. Does the budget control kick in?

These tests don't check the content of the response — they check that the safety boundaries hold.

### Cost and Performance

- Does a pipeline run complete within the expected token budget?
- Does each agent respond within the expected latency?
- Does the total pipeline cost stay within bounds?

These are measurable numbers, not subjective quality assessments.

## Testing Output Quality

For the non-deterministic parts — the actual content the AI produces — you need evaluation strategies that assess quality rather than exact matches.

### Rubric-Based Evaluation

Define specific, measurable criteria for what "good output" means for each agent:

**Example — Summarization agent rubric:**
- Does the summary mention all three key points from the source? (yes/no)
- Is the summary under 200 words? (yes/no)
- Does the summary contain information NOT in the source (hallucination)? (yes/no)
- Is the tone professional? (yes/no)

Score: 4/4 = great, 3/4 = acceptable, below 3 = needs attention.

The rubric turns subjective "is this good?" into objective, checkable criteria. Different people (or AI judges) evaluating the same output against the same rubric will mostly agree.

### LLM-as-Judge

Use a separate AI model to evaluate the output of the model being tested. This scales better than human evaluation and can run in your test suite.

**How to implement:**

1. Run your agent with a test input and capture the output
2. Send the input and output to a judge model with a rubric: *"Evaluate this summary against the original text. Score 1-5 on: accuracy, completeness, conciseness. Respond with JSON."*
3. Parse the judge's scores
4. Assert that scores meet minimum thresholds

**Tips:**
- Use a more capable model as judge than the model being tested
- Provide a specific rubric, not an open-ended "rate this"
- Run multiple judgments and average (reduces noise from the judge's own non-determinism)
- Periodically validate the judge against human ratings — make sure they correlate

### Comparison Testing

Instead of evaluating outputs in isolation, compare them:

- **A/B prompt testing:** Run the same inputs through Prompt v1 and Prompt v2. Have a judge (or human) rate which is better. This is more reliable than absolute scoring because relative comparisons are easier than absolute judgments.
- **Regression testing:** Before deploying a prompt change, run your test inputs through both the old and new prompts. Are the new outputs at least as good? If quality drops on more than X% of inputs, don't deploy.
- **Model comparison:** When evaluating whether to switch models (cheaper model, newer version), run both against your test suite and compare.

### Snapshot Testing

Save a collection of representative outputs that you've reviewed and confirmed are good. When you change a prompt or update a model:

1. Run the same inputs through the updated system
2. Compare new outputs to saved snapshots
3. Flag significant differences for review

This isn't exact-match comparison — it's a signal that something changed. A human (or LLM judge) reviews the flagged differences and decides if the new output is acceptable.

For a simple implementation: save outputs as files, diff against the previous version, and review anything that changed substantially.

## Building Your Test Suite

### The Evaluation Dataset

Build a collection of test inputs that cover:

- **Typical cases** — the bread-and-butter inputs your agents handle every day
- **Edge cases** — unusual inputs, very short or very long text, special characters, multiple languages
- **Adversarial inputs** — prompt injection attempts, off-topic requests, inputs designed to break the system
- **Known difficult cases** — inputs that caused problems in the past (regression prevention)

Start small — 20–50 carefully chosen test cases are more valuable than 1,000 random ones. Grow the dataset over time, especially by adding cases that caused real-world failures.

### Organizing Tests

Separate your AI tests into categories:

**Fast tests (run on every change):**
- Output structure validation
- Tool call verification
- Guardrail enforcement
- Cost/token budget checks

These are deterministic, fast, and cheap. Run them in your CI pipeline.

**Evaluation tests (run before deployment):**
- Quality scoring against evaluation dataset
- LLM-as-Judge assessments
- Regression comparison against previous outputs

These involve LLM calls (the judge), so they cost money and take time. Run them before deploying prompt changes or model upgrades, not on every code commit.

**Human review (periodic):**
- Sample real production outputs for human rating
- Review flagged outputs from automated quality monitoring

Do this weekly or after any significant change.

### Pin Model Versions in Tests

If your tests pass with `claude-sonnet-4-20250514` and you upgrade to a newer version, the tests might fail — not because your code changed, but because the model behaves differently.

Pin model versions in your test configuration so test results are stable. When you want to evaluate a model upgrade, explicitly run the evaluation suite against both versions and compare.

## Integration Testing for Agent Pipelines

Testing individual agents is important, but the pipeline as a whole can fail in ways that individual tests don't catch:

- Agent A produces output that Agent B can't parse
- The handoff loses critical context
- The total pipeline takes too long or costs too much
- A failure in Agent C isn't handled properly, and Agent D proceeds with garbage input

**Pipeline integration tests should verify:**

1. **Happy path end-to-end.** A realistic input goes through all agents and produces a reasonable final output.
2. **Agent failure handling.** When you simulate Agent B failing (mock it to return an error), does the pipeline handle it gracefully? Does it retry? Fall back? Alert?
3. **Context preservation.** Does important information from the user's original request survive all the way through the pipeline? Or does it get lost in summarization between agents?
4. **Cost bounds.** Does the full pipeline run stay within the expected token budget?
5. **Timeout behavior.** If one agent is slow (simulate with a delay), does the pipeline time out and handle it, or hang indefinitely?

## Getting Started

If you have no AI testing today:

1. **Start with structure validation.** For every agent that produces structured output, add a test that verifies the output parses correctly and has the required fields. This catches the most common failures.

2. **Build a small evaluation dataset.** Pick 20 representative inputs for your most important agent. Run them, review the outputs, and save the good ones as your baseline.

3. **Add guardrail tests.** Write 5–10 adversarial inputs (prompt injections, out-of-scope requests) and verify your guardrails catch them.

4. **Add cost assertions.** In your pipeline tests, assert that total tokens stay under a budget. This prevents runaway costs from sneaking into production.

5. **Review real outputs weekly.** Look at 20–50 outputs from production. Note any that are bad. Add the inputs that caused bad outputs to your evaluation dataset.

Ask your AI: *"Help me set up an evaluation framework for testing [this agent's] output quality. I need a test dataset, a rubric, and an LLM-as-judge evaluation."*
