# System Design Rules

> Applies to: Business tier and above (loaded for experienced developers, or when architecture complexity is detected in an existing codebase).
> For detailed explanations: see `guides/system-design/`

## Start with a Monolith

- The default architecture for every project is a single deployable unit (monolith). This is not a compromise — it's the right choice until you have evidence that it isn't.
- A well-structured monolith is faster to develop, simpler to deploy, easier to debug, and cheaper to operate than a distributed system. You trade none of these benefits until you have a concrete problem that requires it.
- "But we might need to scale" is not a reason to start with services. A single PostgreSQL instance handles thousands of concurrent users. A single application server handles thousands of requests per second. You are almost certainly not starting at a scale that demands distribution.

## Structure the Monolith for Future Flexibility

- Organize code by domain (users, payments, inventory, notifications), not by technical layer (controllers, services, repositories). Domain-oriented structure makes future extraction straightforward. Layer-oriented structure tangles domains together.
- Define clear boundaries between domains within the codebase. Domains communicate through explicit interfaces (function calls, internal APIs), not by reaching into each other's internals. If Module A needs data from Module B, it calls a function on Module B — it doesn't query Module B's database tables directly.
- Each domain owns its data. Avoid shared database tables that multiple domains write to. A shared `users` table that payments, notifications, and analytics all update is a future decomposition nightmare.
- Keep business logic out of API handlers and controllers. Handlers parse the request and call domain logic. Domain logic doesn't know about HTTP, request objects, or response formats. This separation makes it possible to extract a domain into a service without rewriting its core logic.

## When to Consider Decomposition

Do NOT decompose proactively. Decompose reactively, when you have measurable evidence of a specific problem. The checklist:

- [ ] **Multiple teams (3+) are blocked on each other.** Deployments require coordination across teams. Merge conflicts are frequent in shared code. One team's changes regularly break another team's features.
- [ ] **Parts of the system have radically different scaling profiles.** Image processing needs 10x the compute of user authentication. A real-time feed handles 100x the traffic of account management. You're scaling the entire monolith for the needs of one component.
- [ ] **A regulatory or security boundary requires strict isolation.** PCI scope reduction (keeping credit card processing in a separate, tightly controlled service). HIPAA-covered data that must be isolated from the rest of the system.
- [ ] **A specific seam is causing measurable delivery friction.** Not theoretical friction — actual incidents, actual delays, actual developer frustration that shows up in cycle time metrics.

**If 0–1 are true:** Stay monolith. Improve the internal structure instead.
**If 2+ are true:** Service decomposition deserves serious evaluation. Proceed with the Strangler Fig approach (see guides).

## If Decomposing: Rules for Services

- Service boundaries follow domain boundaries, not technical layers. A "database service" or "auth service" that every other service calls is a distributed monolith with network latency added. A "payments service" that owns everything about payments is a real service.
- Each service owns its data store. No shared databases between services. If Service A needs data from Service B, it asks Service B through an API — it does not query Service B's database. Shared databases are the #1 cause of distributed monoliths.
- Prefer asynchronous communication (message queues, events) over synchronous calls (HTTP, gRPC) between services when possible. Synchronous calls create tight coupling — if the called service is down, the caller fails. Asynchronous communication decouples availability.
- Use synchronous communication only when the caller genuinely needs an immediate response (user is waiting for a result). For everything else (notifications, analytics, audit logging, non-critical updates), use async.
- Every service must be independently deployable. If deploying Service A requires simultaneously deploying Service B, they are not separate services — they are a distributed monolith.
- Design for failure at every service boundary. Every call to another service can fail, time out, or return unexpected results. Apply the reliability rules (timeouts, retries, circuit breakers) to every inter-service call.

## Communication Patterns

- **Synchronous (HTTP/REST, gRPC):** Caller waits for a response. Simple to implement, easy to reason about. Use for queries and operations where the user is waiting. Downside: caller is blocked if the service is slow or down.
- **Asynchronous (message queues, events):** Caller sends a message and moves on. The receiving service processes it when ready. Use for operations that don't need an immediate response. Downside: harder to debug, eventual consistency requires careful handling.
- **Events vs. commands:** An event says "this happened" (OrderPlaced, UserRegistered). A command says "do this" (SendEmail, ProcessPayment). Events are better for decoupling — the publisher doesn't know or care who listens. Commands create a direct dependency on the receiver.
- Avoid chains of synchronous calls: Service A calls B, which calls C, which calls D. Latency adds up. If any service in the chain fails, the entire operation fails. If you find yourself building call chains, reconsider your service boundaries.

## Data Ownership

- Every piece of data has exactly one authoritative source (the "system of record"). Other services may cache copies, but there is one canonical source of truth.
- When data needs to be shared across services, use events to propagate changes. The owning service publishes "UserAddressUpdated"; interested services update their local copy. Accept that copies will be briefly stale (eventual consistency).
- Avoid distributed transactions (two-phase commit) across services. They are fragile, slow, and complex. Use sagas (a sequence of local transactions with compensating actions for rollback) for multi-service operations. See the glossary for saga pattern details.
