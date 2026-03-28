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

Don't decompose proactively. Decompose when you have evidence. Score your situation:

| Signal | Score |
|--------|-------|
| Multiple teams (3+) blocked on coordinating deployments | +1 |
| Parts of the system have radically different scaling needs | +1 |
| Regulatory/security boundary requires strict isolation (PCI, HIPAA) | +1 |
| A specific seam causes measurable delivery friction (not theoretical) | +1 |
| The monolith has shipped and the domain boundaries are proven | +1 |

**Score 0–1:** Monolith. Improve internal structure if needed.
**Score 2:** Modular monolith. Define hard boundaries between modules. This prepares for future extraction without paying the distributed-systems tax now.
**Score 3–5:** Services may be justified. But extract from a working monolith using the Strangler Fig pattern — don't design services from scratch.

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
| Business | Monolith, evaluate with Q11–Q14 | When the decision matrix scores 2+ |
| Regulated | Monolith, evaluate with Q11–Q14 | When compliance requires isolation (PCI scope reduction) or the decision matrix scores 2+ |

## Common Questions

**"Can I use containers with a monolith?"**
Absolutely. Containerizing a monolith is great for deployment consistency. Containers ≠ microservices.

**"What about serverless functions?"**
Serverless works well for specific, isolated tasks (image resizing, webhook processing, scheduled jobs). Using serverless for an entire application usually creates a distributed monolith with cold-start latency and vendor lock-in.

**"We already have services. Should we merge them back?"**
If you're experiencing distributed monolith symptoms and the services don't have independent teams, independent deployment, or independent scaling needs — yes, seriously consider it. Merging services back into a monolith is a valid and sometimes courageous engineering decision.
