# Agentic Security (OWASP Top 10 for Agentic Applications)

> This guide covers the risks that appear once a model can *act*: call tools, run in a loop, remember across sessions, talk to other agents, or drive a browser. It maps to the OWASP Top 10 for Agentic Applications (2026 list, from the OWASP GenAI Security Project). Read it alongside `guides/multi-agent/llm-security.md` (the LLM Top 10, which covers prompt injection and the chatbot-level risks) and `guides/multi-agent/mcp-tool-patterns.md` (tool plumbing).

For compact rules, see `rules/multi-agent.md` (Agentic Systems).

Reference: [OWASP GenAI Security Project — Agentic Applications](https://genai.owasp.org). Entry names below are the official 2026 list names: ASI01 Agent Goal Hijack, ASI02 Tool Misuse & Exploitation, ASI03 Identity & Privilege Abuse, ASI04 Agentic Supply Chain Vulnerabilities, ASI05 Unexpected Code Execution (RCE), ASI06 Memory & Context Poisoning, ASI07 Insecure Inter-Agent Communication, ASI08 Cascading Failures, ASI09 Human-Agent Trust Exploitation, ASI10 Rogue Agents.

---

## Why Agents Need Their Own List

A chatbot that gets hijacked says something embarrassing. An agent that gets hijacked *does* something: sends the email, deletes the rows, buys the thing, and then tells the next agent to do the same. The blast radius is the union of every tool it holds, every credential it carries, and every agent that trusts it. The LLM Top 10 still applies; this list adds the failure modes that come from autonomy, persistence, and delegation.

---

## The Ten Risks

### ASI01: Agent Goal Hijack

**What it is:** The agent is steered to a different objective than the one the user gave it — through prompt injection (direct or indirect), a poisoned document, a manipulated tool result, or another agent's output. The agent still "works"; it just works for someone else.

**Rules:** Everything the model reads is untrusted except your own system prompt (`guides/multi-agent/llm-security.md`, LLM01). Pin the goal outside the model: the orchestrator holds the task definition and checks each proposed action against it ("the task was *summarize*; why is it calling *send_email*?"). Require human approval for actions outside the declared scope. Log the plan the agent formed, not just the actions it took, so drift is visible.

### ASI02: Tool Misuse & Exploitation

**What it is:** The agent uses a legitimate tool in a harmful way — the right tool with the wrong arguments, the wrong tool for the task, or a tool chain nobody anticipated (read the secrets file, then call the HTTP tool).

**Rules:** Validate every tool argument against a schema and an allowlist before execution. Give each agent only the tools its job needs; split read from write. Treat tool annotations as hints, not permissions. Rate-limit tool calls per run. Audit tool *combinations*: the lethal trifecta (`guides/multi-agent/mcp-tool-patterns.md`) is the canonical bad combination.

### ASI03: Identity & Privilege Abuse

**What it is:** The agent runs with more authority than the user it serves, or with a shared credential that every user's requests flow through. Once hijacked, it does anything that credential can do, and the audit log can't say who asked.

**Rules:** See Agent Identity and Delegated Credentials below. Short version: the agent acts *as the user*, with a delegated, scoped, short-lived token; never a god key. Downstream services enforce authorization on that token, not on the prompt.

### ASI04: Agentic Supply Chain Vulnerabilities

**What it is:** Compromised or malicious components in the agent stack — third-party MCP servers, tool packages, prompt libraries, agent frameworks, downloaded "skills," or model endpoints. Tool-description poisoning and rug-pulls (`guides/multi-agent/mcp-tool-patterns.md`) are the agent-specific forms.

**Rules:** Pin, checksum, and review every MCP server and tool package like any dependency (`guides/security/supply-chain.md`). Snapshot tool descriptions and schemas and alert on change. Don't co-load untrusted servers with sensitive tools. Keep an inventory of which agent uses which server at which version.

### ASI05: Unexpected Code Execution (RCE)

**What it is:** The agent writes and runs code, or a tool interprets its output as code (SQL, shell, `eval`, a templating engine) — and the code does something nobody intended.

**Rules:** All agent-executed code runs in a sandbox with its own credentials and restricted egress (`rules/multi-agent.md`, Execution Isolation). Never pass model output to `eval`, a shell, or a query builder without parsing and validation. Treat "the agent can run code" as a Regulated-grade decision: log every execution, cap runtime and resources, and wipe the sandbox between tasks.

### ASI06: Memory & Context Poisoning

**What it is:** Something untrusted gets written into the agent's persistent memory or shared context, and from then on every session starts already compromised. Unlike a one-off injection, a poisoned memory is permanent until someone finds it.

**Rules:** See Memory Poisoning below: provenance-tag every memory, no direct writes from untrusted content, TTLs, and human review for anything that changes behavior.

### ASI07: Insecure Inter-Agent Communication

**What it is:** Agents trust each other implicitly. A message that looks like it came from the supervisor is obeyed; a worker's output is executed as instructions; messages travel unauthenticated and unlogged. A poisoned worker becomes a poisoned pipeline (orchestrator hijack via worker output).

**Rules:** Treat another agent's output as untrusted input and validate structure and scope before acting on it. Authenticate inter-agent messages (signed tokens, mTLS, per-agent credentials) and carry the originating correlation ID on every hop. Scope each agent's credentials to its own job. See `guides/multi-agent/orchestration-patterns.md` (Trust Between Agents) and, for cross-organization agents, the A2A protocol notes there.

### ASI08: Cascading Failures

**What it is:** One agent's bad output, retry storm, or loop propagates through the system — supervisors retrying failed workers, workers re-fetching, every level burning tokens and calling tools until budgets or the provider give out.

**Rules:** Iteration caps and wall-clock limits on every loop, pipeline-wide as well as per agent. Circuit breakers around each model provider and each tool (`rules/reliability.md`). A hard spend cap and a kill switch (below). Idempotent tools so a retried action doesn't double-execute. Fail closed: when a guard trips, stop, don't "continue with warnings."

### ASI09: Human-Agent Trust Exploitation

**What it is:** People over-trust the agent's confident output, or the agent is manipulated into manipulating people — persuading a user to approve an action, phishing on the attacker's behalf, or drowning a reviewer in approval prompts until they click through everything.

**Rules:** Tell users they're talking to an agent and what it can do (`rules/privacy.md`, Transparency). Make approvals specific ("send this email to these three recipients," not "continue?") and rate-limit them so approval fatigue can't be engineered. Show the source and confidence of claims that drive decisions. Never let the agent be the sole authority for money, compliance, or safety decisions.

### ASI10: Rogue Agents

**What it is:** An agent that keeps running outside its intended scope, lifetime, or supervision — a forgotten background loop, a spawned sub-agent nobody tracks, an agent that has been hijacked and is now quietly working for someone else.

**Rules:** Every agent has an owner, a purpose, a lifetime, and a budget, recorded somewhere a human can read. Sub-agents inherit the parent's caps and correlation ID and cannot outlive the parent task. Monitor for agents that are running but not attributable to a live user request. The kill switch pauses all of them.

---

## Agent Identity and Delegated Credentials

The single highest-leverage control on this page.

- **Agents act as the user, not as themselves.** When user Y asks agent X to do something, every downstream call carries a credential that says "X on behalf of Y" and is limited to what Y may do. The downstream service authorizes against Y's permissions. If Y can't see invoice 42, neither can the agent, no matter what the prompt says.
- **Scoped, short-lived, audience-bound.** Minutes to hours of validity, only the scopes the task needs, bound to the specific service (OAuth resource indicators / token audience) so a token stolen from one tool can't be replayed at another.
- **No shared god key.** A long-lived, broadly scoped API key in the agent's environment is the difference between "an attacker made the agent leak one user's data" and "an attacker made the agent leak everyone's."
- **Attribution in every log line.** `agent=X principal=Y correlation_id=…`. "The agent did it" is never an acceptable audit answer.
- **Standard flows, not homegrown.** Interactive users: OAuth 2.1 authorization code. Headless/CLI agents: device authorization flow. Server-to-server on the user's behalf: token exchange for a narrower token. Details and RFCs: `guides/security/authentication.md`; MCP-specific wiring: `guides/multi-agent/mcp-tool-patterns.md`.

---

## Memory Poisoning

Long-term memory (vector stores of past interactions, "user preferences," learned facts, shared scratchpads) is the most durable place an attacker can plant an instruction.

- **Provenance-tag every memory.** Who or what wrote it, from which source, when, and at what trust level. A memory that came from a web page the agent browsed is not the same as one the user typed.
- **No untrusted writes to long-term memory.** Content from tool results, retrieved documents, web pages, and other agents may be *summarized for the current task* but never written into persistent memory without an explicit, reviewed step. If the agent "learns" from what it reads, that learning goes to a quarantine store first.
- **TTL by default.** Memories expire unless renewed. A preference from eight months ago is probably stale; a planted instruction from eight months ago is definitely dangerous.
- **Reviewable and deletable.** Users (and operators) can see what the agent remembers about them and delete it. This is also a privacy obligation (`rules/privacy.md`, Data-Subject Rights).
- **Segregate by tenant and user.** Shared memory across users is a cross-tenant leak waiting to happen (`guides/multi-agent/llm-security.md`, LLM08).
- **Treat memory as a dataset.** Version it, diff it, and run your injection tests against a seeded copy.

---

## Tool-Description Poisoning

Covered in detail in `guides/multi-agent/mcp-tool-patterns.md` (Tool-Description Poisoning and Other Supply-Chain Tricks). The essentials: tool descriptions are model-facing text with high trust, so they are a prime injection channel; pin and snapshot them; show them to a human at install; never co-load untrusted servers with sensitive tools.

---

## Computer-Use and Browser Agents

An agent that sees a screen and clicks is an agent whose "tool" is every website and every application on that machine. Treat it as the highest-risk configuration you run.

- **Isolated profile, no logged-in sessions.** A fresh browser profile or VM per task, with no saved passwords, cookies, or sessions from a real person. If the agent needs to be logged in somewhere, log it in with a delegated, scoped account for that task — not your account.
- **Domain allowlist.** The agent can navigate only to hosts the task requires. Everything else is blocked at the network layer, not by asking the model nicely. Apply the SSRF rules (`rules/security.md`) to the agent's browser too.
- **Screenshots are data.** They contain whatever was on screen — other people's names, account numbers, the contents of an open email. Redact or discard them under the same retention and privacy rules as logs; never ship them to a model provider not covered by your DPA; never store them longer than the task needs.
- **Per-action approval for consequential steps.** Form submissions, purchases, sends, deletes, permission changes, and anything involving payment details wait for a specific human confirmation. The agent may fill the form; a human clicks submit.
- **Everything on screen is untrusted content.** A web page can contain instructions aimed at the agent (visible or hidden). The agent must treat page content as data, and the orchestrator must check each proposed action against the task goal (ASI01).
- **Hard limits.** Wall-clock timeout per task, action count cap, and the kill switch.

---

## Spend Caps and the Kill Switch

- **Iteration cap** on every loop (supervisor cycles, retries, sub-agent spawns), and a **pipeline-wide** cap so agents can't pass the buck to each other forever. A supervisor that can say "not good enough" indefinitely, or two agents handing work back and forth, will loop until the money runs out. Pair the count with a wall-clock limit, log when either fires, and treat a cap trip as a failure to investigate, never as normal operation: a loop that routinely hits its cap is a loop whose exit condition is broken.
- **Hard spend cap**, enforced in code and at the provider (separate API keys per environment with spend limits). Alerts (`guides/multi-agent/llm-architecture.md`, Setting Budgets) warn you; the cap stops you. When it trips, the system fails closed — no new model calls — and a human resets it.
- **Kill switch:** one flag that pauses every agent. No new loops start; running loops stop at the next tool boundary; queued tasks stay queued. Wire it as a feature flag or admin endpoint, make it independent of the agents themselves, and **test it** — an untested kill switch is a hope. It is the whole-layer circuit breaker (`rules/reliability.md`, Circuit Breakers).

---

## Streaming

Streaming responses change two things:

- **Idle timeouts, not just total timeouts.** A stream that sends its first token in 200 ms and then stalls will pass a total-time check for a long time. Time out if no chunk arrives for N seconds.
- **Never act on a partial tool call.** Tool-call arguments arrive incrementally. Executing when you *think* you have enough — or on a stream that was cut off mid-argument — is how `delete_user(id=12` becomes `delete_user(id=1)`. Wait for the provider's end-of-tool-call signal, then validate the complete arguments.

---

## Guardrail and Moderation Layer

Put a classifier stage on both sides of the model:

- **Inputs:** prompt-injection and jailbreak detection, content policy, PII detection (so you can redact before it reaches a provider not cleared for it).
- **Outputs:** PII and secret leakage, harmful content, format/scope checks ("asked for a summary, got a shell command").

Use the provider's moderation endpoint or a dedicated small model. Two rules: it is a **filter, not a boundary** — authorization still happens in your code — and it must **fail closed**: if the guardrail service is down, the pipeline stops, it doesn't skip the check.

---

## Prompt Caching Cost Mechanics

Prompt caching makes agents affordable, and misusing it makes them expensive. The mechanics are similar across providers (check your provider's current pricing):

- **Cache writes cost a premium.** Storing a prefix typically costs 25% or more *above* the normal input price (more for longer-lived caches). **Cache reads are heavily discounted** — often around 90% off input price.
- So caching pays only when a prefix is reused several times inside the cache's lifetime (commonly minutes; extended lifetimes cost more to write). Cache a prefix that's used once and you paid extra for nothing.
- **Put breakpoints before the variable content.** Order the prompt as: system instructions → tool definitions → stable context → *breakpoint* → per-turn content. Anything that changes per call (timestamps, user names, "today is …") belongs after the breakpoint, or it invalidates the cache every time.
- **Tool definitions count.** A large tool list is exactly the kind of stable prefix that should be cached — and exactly the kind of thing that busts the cache when a description changes (which is also a supply-chain signal, see ASI04).
- **Log cache hits and misses** with the token counts. A sudden drop in cache hit rate is a cost regression and sometimes a sign that something upstream started injecting variable text into your prefix.

---

## Quick Checklist for Agentic Features

- [ ] Agents act with delegated, scoped, short-lived credentials; no shared god key; audit says "X on behalf of Y"
- [ ] Every loop has an iteration cap and wall-clock limit; pipeline-wide cap too
- [ ] Hard spend cap enforced in code and at the provider; fails closed
- [ ] Kill switch exists, is independent of the agents, and has been tested
- [ ] Other agents' outputs, tool results, and tool descriptions treated as untrusted
- [ ] Inter-agent messages authenticated and correlated
- [ ] Long-term memory: provenance-tagged, no untrusted direct writes, TTL, reviewable
- [ ] Third-party MCP servers pinned, vetted, and descriptions snapshotted
- [ ] Agent-executed code sandboxed with restricted egress
- [ ] Computer-use agents: isolated profile, domain allowlist, screenshot handling, per-action approval for submits/purchases
- [ ] Streaming: idle timeout; no action on partial tool calls
- [ ] Guardrail layer on inputs and outputs; fails closed
- [ ] Prompt cache breakpoints placed before variable content; hit rate logged
