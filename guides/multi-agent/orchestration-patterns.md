# Agent Orchestration: How Multiple Agents Work Together

> For the compact rules, see `rules/multi-agent.md`.

## What Is a Multi-Agent System?

A multi-agent system is an application where multiple AI agents — each with its own instructions, tools, and responsibilities — work together to accomplish tasks that would be too complex for a single agent.

**Analogy:** Think of a restaurant kitchen. The head chef doesn't do everything alone. One person handles the grill, another preps vegetables, another plates desserts. Each person has a clear role, specific tools (a grill, a knife, a piping bag), and they coordinate through the head chef's direction. That's a multi-agent system.

In software terms: you have multiple AI "workers," each given a specific prompt, a specific set of tools (database access, web search, email sending), and a specific job. Something coordinates them — deciding who works on what, passing information between them, and assembling the final result.

## Start with One Agent

This might sound counterintuitive in a guide about multi-agent systems, but: **start with a single agent.**

Most tasks that seem like they need multiple agents can be handled by one well-prompted agent with the right tools. A single agent that can search the web, read documents, and write emails doesn't need to be three agents.

Split into multiple agents only when you have evidence:

- **The single agent's prompt is getting unwieldy.** If your system prompt is 3,000 words trying to cover research, analysis, writing, and review, the agent starts losing focus. Each task deserves clear, focused instructions.
- **Different tasks need different models.** Classification might work fine with a fast, cheap model. Creative writing might need a more capable one. Running everything through the expensive model wastes money.
- **Different tasks need different tool access.** A research agent needs web search. A database agent needs SQL access. Giving both to one agent creates unnecessary security risk.
- **You need parallel execution.** A single agent works sequentially. If you need to research three topics simultaneously, three agents can do that.
- **Failure isolation.** If the email-sending step fails, it shouldn't destroy the research that was already completed. Separate agents can fail independently.

If none of these apply, keep it as one agent. You can always split later.

## Common Orchestration Patterns

### Sequential Pipeline

The simplest multi-agent pattern. Agents work one after another, like a production line.

```
User Request → Agent A (Research) → Agent B (Analyze) → Agent C (Write) → Result
```

Each agent receives the output of the previous agent as input. Agent B doesn't start until Agent A finishes.

**When to use:** The work has a natural order — you can't analyze before you research, you can't write before you analyze. Each step builds on the previous one.

**Watch out for:** A failure in any step breaks the entire pipeline. Build in checkpoints — save intermediate results so you can resume from where it failed instead of starting over.

### Parallel Fan-Out / Fan-In

Multiple agents work simultaneously on different parts of the same task, and their results are combined.

```
                  ┌→ Agent A (Research Topic 1) ─┐
User Request ─────┼→ Agent B (Research Topic 2) ─┼→ Combiner → Result
                  └→ Agent C (Research Topic 3) ─┘
```

**When to use:** The sub-tasks are independent — one agent's work doesn't depend on another's. Research on three different competitors, analysis of multiple documents, generating content in multiple languages.

**Watch out for:** You need a strategy for combining results. A simple concatenation often produces a disjointed mess. Use a "combiner" agent or a synthesis step that merges results into a coherent whole. Also, the pipeline is only as fast as the slowest agent — one slow sub-task holds up everything.

### Router / Dispatcher

A routing agent examines the incoming request and sends it to the right specialist agent.

```
                  ┌→ Agent A (Billing questions)
User Request → Router ┼→ Agent B (Technical support)
                  └→ Agent C (General inquiry)
```

**When to use:** Different types of requests need fundamentally different handling. A customer support system where billing issues, technical problems, and general questions need different tools and approaches.

**Watch out for:** The router is a single point of failure. If it misclassifies, the wrong agent handles the request. Use a fast, cheap model for routing (it's a classification task, not a generation task), and include a fallback for uncertain classifications.

### Supervisor with Workers

A supervisor agent manages a team of worker agents. It decides what needs to be done, assigns tasks, reviews results, and decides what to do next.

```
User Request → Supervisor ─┬→ Worker A → Supervisor
                           ├→ Worker B → Supervisor
                           └→ Worker C → Supervisor
                           → Final Result
```

The supervisor has a loop: assign work, review results, decide if more work is needed or if the task is complete.

**When to use:** Complex tasks where the workflow can't be pre-determined. The supervisor adapts based on intermediate results — "the research wasn't detailed enough, send it back" or "we need a different approach, try this instead."

**Watch out for:** Runaway loops. A supervisor that keeps saying "not good enough" can cycle indefinitely. Always set a maximum number of iterations and a wall-clock limit (`rules/multi-agent.md`, Agentic Systems). Also, the supervisor consumes tokens on every review cycle — this pattern is more expensive than a fixed pipeline.

**Orchestrator hijack:** the supervisor reads every worker's output — so a worker that browsed a poisoned web page can carry an injected instruction straight into the agent that holds the most tools. Treat worker output as untrusted input (see Trust Between Agents below).

### Human-in-the-Loop

Not every step needs to be automated. Some decisions should involve a human — especially when the stakes are high.

```
Agent A (Draft) → Human Review → Agent B (Revise based on feedback) → Result
```

**When to use:** When the output has real consequences (sending emails to customers, publishing content, making financial decisions) or when quality requirements exceed what automated evaluation can guarantee.

**Implementation:** Store the agent's output in a review queue. Present it to the human with a simple approve/reject/edit interface. Only proceed when approved. This adds latency but dramatically reduces risk.

## The Framework Landscape

Several frameworks exist to help you build multi-agent systems. None of them are required — you can build multi-agent systems with direct API calls. But they handle common patterns so you don't reinvent them.

**Verify current maintenance status before adopting any of these.** This space moves fast: projects get merged, renamed, or put into maintenance mode within a year. Check the repository's recent commits and release notes, not just its star count.

### Provider SDKs (OpenAI Agents SDK, Claude Agent SDK, Google ADK)

**Approach:** Each major model provider now ships its own agent toolkit — an agent loop, tool calling, handoffs between agents, sessions, and guardrail hooks — tuned to that provider's models and features (prompt caching, structured output, computer use).

**Good for:** Teams committed to one provider who want the thinnest layer that still handles the loop, retries, and tool plumbing correctly.

**Consider when:** You'd otherwise write the agent loop yourself. Watch for lock-in: keep prompts, tool schemas, and evaluation data in your own files so a provider switch is a port, not a rewrite.

### LangGraph

**Approach:** Stateful graphs. You define agents as nodes and transitions as edges in a graph. State flows through the graph and agents can conditionally route to different next steps.

**Good for:** Complex workflows with conditional branching, loops, and dynamic routing. When the workflow isn't a simple pipeline.

**Consider when:** You need precise control over agent flow, state management, and conditional logic.

### CrewAI

**Approach:** Role-based teams. You define agents with roles ("Senior Researcher," "Content Writer"), goals, and tools. Agents collaborate on tasks with defined dependencies.

**Good for:** Projects where the agent roles map naturally to human job roles. Marketing teams, research teams, content production pipelines.

**Consider when:** You want a high-level abstraction and don't need fine-grained control over every agent interaction.

### Microsoft Agent Framework (successor to AutoGen and Semantic Kernel)

**Approach:** In October 2025 Microsoft folded AutoGen (conversational multi-agent) and Semantic Kernel (enterprise orchestration) into a single Agent Framework for .NET and Python. AutoGen is in maintenance mode; new work goes to the Agent Framework. It keeps AutoGen's conversation-style patterns (draft → review → revise, debate) and Semantic Kernel's workflow/graph style.

**Good for:** .NET shops, Azure-centric deployments, iterative-refinement or debate-style workflows.

**Consider when:** You're already on the Microsoft stack. If you find AutoGen tutorials, note they describe the older project.

### Pydantic AI

**Approach:** Type-first agents in Python. Tool schemas and outputs are Pydantic models, so structured output validation is built in rather than bolted on.

**Good for:** Python teams that already use Pydantic and want validation of every model output as a first-class feature.

### Vercel AI SDK and Mastra (TypeScript)

**Approach:** Vercel's AI SDK is the de-facto TypeScript layer for streaming, tool calling, and provider abstraction in web apps; Mastra builds agents, workflows, and memory on top of it.

**Good for:** Next.js / Node applications where the agent is part of a web product and streaming UI matters.

### Direct API Calls (No Framework)

**Approach:** Call the LLM API directly. Write your own orchestration logic.

**Good for:** Simple pipelines, when you want full control, when frameworks add more complexity than they save.

**Consider when:** You have 2–3 agents in a straightforward pipeline. The overhead of learning a framework may exceed the overhead of writing the orchestration yourself.

### How to Choose

| Situation | Recommendation |
|-----------|---------------|
| 1–2 agents, simple pipeline | Direct API calls |
| Single provider, want the loop handled | That provider's agent SDK |
| Role-based team, clear handoffs | CrewAI |
| Complex branching and state | LangGraph |
| Iterative refinement or debate, Microsoft stack | Microsoft Agent Framework |
| Python, validation-heavy | Pydantic AI |
| TypeScript web app | Vercel AI SDK (+ Mastra for workflows/memory) |
| Not sure yet | Start with direct API calls. Migrate to a framework when the orchestration logic gets painful to maintain. |

Don't pick a framework first and then design your agents around it. Design your agents first — their roles, tools, and interactions — and then pick the framework (or no framework) that fits.

### Agents Talking Across Systems (A2A)

When agents built by different teams or vendors need to cooperate, the Agent2Agent (A2A) protocol (started by Google, now under the Linux Foundation) standardizes discovery (an "agent card"), task exchange, and streaming between agents over HTTP. It is to agent-to-agent calls roughly what MCP is to agent-to-tool calls. Treat a remote agent as you would any third-party API — authenticated, rate-limited, and untrusted — and see Trust Between Agents below.

## Trust Between Agents

The same rules that protect you from a malicious user apply between your own agents:

- **Another agent's output is untrusted input.** Validate structure and scope before acting on it, exactly as you would a user message. A worker that read a poisoned document will faithfully pass the poison up the chain; if the orchestrator treats worker output as instructions, the attacker now controls the agent with the most tools. This is *orchestrator hijack via worker output*, and it's the multi-agent form of indirect prompt injection (`guides/multi-agent/llm-security.md`, LLM01).
- **Authenticate inter-agent messages.** When agents run as separate services (or over A2A), each message carries an identity you can verify — a signed token, mTLS, or at minimum a per-agent credential — and the correlation ID of the originating user request. An agent should be unable to forge a message that looks like it came from the supervisor.
- **Least privilege per hop.** An agent's credentials should be scoped to *its* job, delegated from the user's session, and short-lived. A compromised summarizer must not be able to call the payments tool just because the orchestrator can. See `guides/multi-agent/agentic-security.md` (Agent Identity and Delegated Credentials).
- **Don't let agents talk each other into loops.** Cap total iterations across the whole pipeline, not just per agent.

## Agent Communication and Context

### Minimizing Context Loss

Every time one agent hands off to another, some context is lost. Agent A understood the nuance of the user's request. Agent B only sees what Agent A wrote in the handoff message.

**Keep handoffs structured:**
Instead of passing free-form text between agents, use structured handoff messages:
- **Task:** What the next agent should do
- **Context:** Key information the next agent needs (not everything — just what's relevant)
- **Constraints:** Any limitations or requirements
- **Source:** Where this information came from (so the next agent can go deeper if needed)

### Context Summarization

In long pipelines, context grows with every step. By the time you reach Agent D, the accumulated context might exceed the model's context window or become so noisy that the agent loses focus.

Summarize between steps. After Agent B finishes, summarize its output and the relevant context before passing to Agent C. You lose some detail, but you gain focus and stay within token limits.

### Shared Memory (Use with Caution)

Some frameworks offer shared memory — a central store that all agents can read and write. This seems convenient but creates the same problems as shared mutable state in any concurrent system:

- Two agents writing to the same key at the same time (race condition)
- One agent reading stale data that another agent has already updated
- No clear ownership of who is responsible for what data

If you use shared memory, apply the concurrency rules from `rules/reliability.md`: use locks or transactions, define clear ownership (only one agent writes to a given key), and treat reads as potentially stale.

Prefer explicit handoffs over shared memory whenever possible.

## Common Mistakes

**Too many agents too soon.** Five agents doing work that one agent could handle. More agents means more complexity, more failure points, more cost, and harder debugging. Start simple.

**Agents with unclear boundaries.** If you can't explain in one sentence what an agent does, its scope is too broad. "Handles everything related to customers" is too broad. "Classifies incoming support tickets by category" is clear.

**No failure handling between agents.** Agent B assumes Agent A always succeeds. When Agent A fails or returns garbage, Agent B crashes or produces nonsense. Every handoff point needs error handling.

**Context overload.** Passing the entire conversation history to every agent in the pipeline. By Agent D, the context is 10,000 tokens of accumulated noise, and the agent can't find the actual instructions. Summarize and filter.

**No cost visibility.** A pipeline that works beautifully but costs more per run than you assumed, multiplied by real traffic, is a budget incident. `guides/multi-agent/llm-architecture.md` (Token Budget Management) walks through the arithmetic; the fix is the same either way — log costs from day one and enforce a hard cap.
