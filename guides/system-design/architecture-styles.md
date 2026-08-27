# Architecture Styles: Monolith, Modular Monolith, and Services

> For the compact rules, see `rules/system-design.md`.

## Why This Matters

The single most expensive architectural decision you'll make is how you split (or don't split) your system into deployable pieces. Get it wrong early and you'll spend months untangling it. The good news: the right starting point is almost always the simplest one.

## The Spectrum

Architecture style isn't binary. It's a spectrum with three practical stops:

**Monolith** — one codebase, one deployable unit. All your code runs in the same process. A function call from your order handler to your inventory logic is just... a function call.

**Modular monolith** — still one deployable unit, but internally organized into clearly separated modules with explicit boundaries. The payments module can't reach into the inventory module's database tables. Modules communicate through defined interfaces. You get most of the organizational benefits of services without the operational complexity.

**Services (microservices)** — separate deployable units that communicate over the network. Each service has its own codebase, its own database, its own deployment pipeline. A call from order processing to inventory management is now an HTTP request or a message on a queue.

Each step to the right adds operational complexity: network communication, distributed debugging, deployment coordination, eventual consistency, and failure modes that don't exist in a monolith. You trade simplicity for independence and scalability — but only when you actually need them.

## Why Monolith First

A monolith is not a dirty word. It's the most productive architecture for the vast majority of projects, including large ones. Here's why:

**Development speed.** Calling a function is simpler than calling an API. Refactoring across modules is a code change, not a coordinated multi-service deployment. You can rename a concept across your entire system in an afternoon.

**Debugging.** A stack trace in a monolith shows you exactly what happened, start to finish. In a distributed system, a single user request might touch five services, and the bug is in the interaction between service 2 and service 4. Good luck finding that at 2 AM.

**Deployment.** One thing to deploy, one thing to monitor, one thing to roll back. No need to coordinate version compatibility across services.

**Cost.** One server (or a few) is cheaper than a dozen. No service mesh, no API gateway, no distributed tracing infrastructure, no message queue.

**Consistency.** Database transactions work. If you debit one account and credit another in the same transaction, both happen or neither does. In a distributed system, you need sagas, compensating transactions, and eventual consistency — all of which are dramatically harder to get right.

Shopify runs on a monolith. Stack Overflow runs on a monolith. Basecamp runs on a monolith. These are not small applications.

## The Decision Matrix

Don't decompose proactively. Decompose when you have evidence. These are the same four signals as the checklist in `rules/system-design.md`; count how many are true:

| Signal | Score |
|--------|-------|
| Multiple teams (3+) blocked on coordinating deployments | +1 |
| Parts of the system have radically different scaling needs | +1 |
| Regulatory/security boundary requires strict isolation (PCI, HIPAA) | +1 |
| A specific seam causes measurable delivery friction (not theoretical) | +1 |

**Score 0–1:** Stay a monolith. Improve internal structure if needed.
**Score 2+:** Service decomposition deserves serious evaluation — but **modular monolith first**: define hard boundaries between modules, prove them for a few months, then extract the one seam that is actually hurting using the Strangler Fig pattern. Don't design services from scratch, and don't extract a boundary that hasn't shipped and been proven inside the monolith.

A precondition, not a signal: the monolith has shipped and its domain boundaries are known. If you're still discovering what the domains are, no score justifies services.

### Signals That Are NOT on the Matrix

These are commonly cited reasons for microservices that are actually not good reasons:

- **"We might need to scale."** Scale the monolith first. Vertical scaling (bigger server) is trivial. Horizontal scaling (multiple instances behind a load balancer) works for stateless monoliths. You won't hit the limit for a long time.
- **"Different teams want different tech stacks."** Organizational preference is not an architectural requirement. The operational cost of running five languages in production is enormous. Standardize where possible.
- **"Netflix/Google/Amazon uses microservices."** They also have thousands of engineers and dedicated platform teams. This is cargo cult architecture.
- **"It's the modern way."** Kubernetes, service meshes, and distributed tracing are not indicators of good architecture. They're tools for specific problems at specific scales.

## The Strangler Fig Pattern

Named after a tropical vine that gradually grows around a host tree: you don't rewrite the monolith, you gradually replace it piece by piece.

### How It Works

1. **Identify a boundary.** Pick a module in your monolith that has a clear, well-defined interface. Ideally one that's already organized as a distinct domain (payments, notifications, image processing).

2. **Build the new service alongside the monolith.** The new service implements the same functionality. It gets its own database. It's deployed independently.

3. **Route traffic.** Put a routing layer (API gateway, load balancer, or even a simple proxy) in front of both. Start sending a small percentage of traffic for that domain to the new service.

4. **Verify.** Compare the results. Does the new service produce the same outcomes? Monitor error rates, latency, and correctness.

5. **Increase traffic gradually.** 10%, then 25%, then 50%, then 100%. At any point, you can route traffic back to the monolith if something goes wrong.

6. **Remove the old code.** Once 100% of traffic is handled by the new service and it's stable, remove the corresponding code from the monolith.

7. **Repeat.** Pick the next boundary.

### Why This Works

- **Zero big-bang risk.** You never do a risky cutover. Traffic shifts gradually and reverses instantly.
- **The monolith stays functional.** During the entire migration (which may take months), the existing system keeps working. Users don't notice.
- **Boundaries are proven, not guessed.** You're extracting a module that already works — you know its interface, its data requirements, and its edge cases. You're not designing a service from imagination.
- **You can stop at any point.** Extracted two services and the rest of the monolith is fine? Stop. Not every module needs to become a service.

## Event Sourcing and CQRS: Don't, by Default

**Event sourcing** stores every change as an immutable event (`OrderPlaced`, `ItemAdded`, `OrderShipped`) and derives current state by replaying them. **CQRS** splits the write model from the read model, often with the read side rebuilt from those events. They're frequently pitched together as "the scalable architecture."

For most applications they're a tax with no refund. You lose the simplest fact about a database — the row *is* the truth — and gain: projections that must be rebuilt when they drift, schema versioning for events you can never delete, eventual consistency between the thing you just wrote and the thing you read back, and debugging that starts with "replay 40,000 events." Reporting, ad-hoc queries, GDPR erasure (you can't delete an immutable log without crypto-shredding), and onboarding all get harder.

What people actually want is usually one of: an **audit log** (append an `audit_events` row in the same transaction as the write — done), **undo** (soft deletes and versioned rows), or a **fast read path** (a materialized view or a denormalized table refreshed by the outbox below). Reach for real event sourcing only when replayability is the product — ledgers, trading systems, collaborative editing with full history — and you can name the requirement.

## The Transactional Outbox: Fixing the Dual-Write Problem

The moment you have both a database and a queue (or an event bus, a search index, a webhook), you hit the **dual-write problem**: your code writes the order to Postgres, then publishes `OrderPlaced` to the queue. If the process dies between the two, the order exists and nobody hears about it. If you publish first and the transaction then rolls back, consumers act on an order that doesn't exist. Wrapping both in a try/catch doesn't help — there's no transaction that spans a database and a queue.

The **transactional outbox** pattern fixes it with one table:

1. In the same database transaction as the business write, insert a row into `outbox` (`id`, `event_type`, `payload`, `created_at`, `published_at NULL`). Now the order and its event commit or roll back together.
2. A relay publishes unpublished outbox rows to the queue and marks them published. The relay is either a small polling worker (`SELECT ... WHERE published_at IS NULL ORDER BY id LIMIT 100 FOR UPDATE SKIP LOCKED`) or change data capture (Debezium reading the write-ahead log).
3. Consumers dedupe on the outbox row's ID, because the relay can publish twice if it crashes after sending but before marking — this is at-least-once delivery, the same idempotency requirement as everywhere else (`guides/reliability/concurrency.md`).

If your queue *is* Postgres (pg-boss, Graphile Worker, Solid Queue, Oban, River — see `guides/system-design/async-patterns.md`), you get the outbox for free: enqueueing the job in the same transaction as the write is the whole pattern. That's a strong reason to keep the queue in the database until you have a reason not to.

## The Distributed Monolith Anti-Pattern

The worst outcome: you've split into services but gained none of the benefits. Signs you've built a distributed monolith:

- **Shared database.** Multiple services read and write to the same database tables. Changing a column requires coordinating across teams. You've added network latency without gaining independence.
- **Lock-step deployments.** Service A can't be deployed without simultaneously deploying Service B. If they must be deployed together, they're not separate services.
- **Synchronous call chains.** Every user request triggers a chain of synchronous calls: A → B → C → D. Latency adds up. If any service is down, the whole request fails. You've replaced simple function calls with fragile network calls.
- **Shared libraries with business logic.** A "common" library that contains domain logic and must be versioned across all services simultaneously. Changes to the library trigger redeployments of everything.

If you recognize these patterns, you don't have microservices — you have a monolith with network overhead. The fix is usually to merge services back together and re-extract with better boundaries.

## Architecture Style by Tier

| Tier | Default Style | When to Reconsider |
|------|--------------|-------------------|
| Personal | Monolith | Never |
| Shared | Monolith | Never |
| Public | Monolith | Rarely — only if scaling a specific component is proven necessary |
| Business | Monolith, evaluate with Q11–Q14 | When 2+ signals are true — modular monolith first |
| Regulated | Monolith, evaluate with Q11–Q14 | When compliance requires isolation (PCI scope reduction) or the decision matrix scores 2+ |

## Common Questions

**"Can I use containers with a monolith?"**
Absolutely. Containerizing a monolith is great for deployment consistency. Containers ≠ microservices.

**"What about serverless functions?"**
Serverless works well for specific, isolated tasks (image resizing, webhook processing, scheduled jobs). Using serverless for an entire application usually creates a distributed monolith with cold-start latency and vendor lock-in.

**"We already have services. Should we merge them back?"**
If you're experiencing distributed monolith symptoms and the services don't have independent teams, independent deployment, or independent scaling needs — yes, seriously consider it. Merging services back into a monolith is a valid and sometimes courageous engineering decision.
