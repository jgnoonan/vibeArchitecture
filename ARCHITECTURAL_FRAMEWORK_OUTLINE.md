# vibeArchitecture: A Software Architecture Framework for AI-Assisted Development

**GitHub:** [github.com/jgnoonan/vibeArchitecture](https://github.com/jgnoonan/vibeArchitecture)

## Project Vision

A modular, stack-agnostic set of markdown files that can be dropped into any software project to provide AI coding agents (Claude Code, Cursor, Copilot, Codex, etc.) with the architectural guidance that vibe coders don't know they're missing — until production breaks at 2 AM.

**Target audience:** Developers using AI coding agents who can describe what they want but lack the 10–40 years of battle scars that teach you *why* systems fail.

**Design philosophy:** Opinionated defaults with explained tradeoffs. Every rule includes the *why*, because an AI agent that understands the reasoning can apply the principle to novel situations — not just pattern-match against a checklist.

---

## File Structure Overview

```
vibeArchitecture/
├── ARCHITECT.md                  # Root entry point — the AI reads this first
├── 00-before-you-build/
│   ├── decision-framework.md     # Architectural decision-making process
│   ├── requirements-checklist.md # What to nail down before writing code
│   └── adr-template.md          # Architecture Decision Record template
├── 01-system-design/
│   ├── system-design.md          # Monolith vs. services, boundaries, coupling
│   ├── state-management.md       # Stateless design, session handling, caching
│   └── async-patterns.md         # Queues, events, pub/sub — when and why
├── 02-security/
│   ├── security-architecture.md  # Threat modeling, defense in depth
│   ├── authn-authz.md            # Authentication & authorization patterns
│   ├── secrets-management.md     # Secrets, keys, tokens — lifecycle & storage
│   └── input-validation.md       # Trust boundaries, injection prevention
├── 03-data/
│   ├── data-architecture.md      # Schema design, normalization, migrations
│   ├── data-integrity.md         # Transactions, consistency, constraints
│   └── data-lifecycle.md         # Retention, backup, archival, GDPR/CCPA
├── 04-api-design/
│   ├── api-design.md             # REST, GraphQL, gRPC — principles & choices
│   ├── api-versioning.md         # Breaking changes, deprecation, contracts
│   └── api-security.md           # Rate limiting, throttling, abuse prevention
├── 05-reliability/
│   ├── reliability.md            # Failure modes, graceful degradation
│   ├── high-availability.md      # Redundancy, failover, RTO/RPO
│   └── resilience-patterns.md    # Circuit breakers, retries, bulkheads, timeouts
├── 06-infrastructure/
│   ├── infrastructure.md         # IaC principles, environments, drift
│   ├── deployment.md             # CI/CD, blue-green, canary, rollback
│   ├── containerization.md       # Docker, orchestration, image hygiene
│   └── cloud-fundamentals.md     # Shared responsibility, regions, cost awareness
├── 07-observability/
│   ├── observability.md          # The three pillars: logs, metrics, traces
│   ├── logging.md                # Structured logging, correlation IDs, levels
│   ├── monitoring-alerting.md    # What to monitor, alert fatigue, dashboards
│   └── incident-response.md      # Runbooks, postmortems, on-call
├── 08-performance/
│   ├── performance.md            # Profiling-first, premature optimization
│   ├── scaling-strategies.md     # Vertical vs. horizontal, auto-scaling
│   ├── caching.md                # Cache layers, invalidation, stampede
│   └── database-performance.md   # Indexing, query plans, connection pooling
├── 09-testing/
│   ├── testing-strategy.md       # Test pyramid, what to test, what not to
│   ├── integration-testing.md    # Contract tests, test containers, fixtures
│   └── chaos-engineering.md      # Failure injection, game days (when ready)
├── 10-operations/
│   ├── operational-readiness.md  # Production readiness checklist
│   ├── cost-management.md        # Cloud cost awareness, right-sizing
│   └── compliance.md             # Regulatory awareness, audit trails
└── appendices/
    ├── anti-patterns.md          # Gallery of horrors with explanations
    ├── glossary.md               # Terms vibe coders may not know
    └── further-reading.md        # Curated resources for deeper learning
```

---

## ARCHITECT.md — Root Entry Point

**Purpose:** The single file the AI agent reads first. It does NOT contain all the rules — it provides orientation and tells the agent which modules to consult for the current task.

### Contents

1. **Framework purpose & philosophy** — One paragraph on why this exists
2. **How to use this framework** — Instructions for the AI agent:
   - Read this file at session start
   - Before implementing any feature, consult the relevant module(s)
   - When making architectural decisions, use the ADR template
   - When in doubt, ask the human — don't guess on architecture
3. **Project profile** (to be filled in per-project):
   - Application type (web app, API, mobile backend, CLI tool, etc.)
   - Expected scale (users, requests/sec, data volume)
   - Compliance requirements (HIPAA, SOC2, PCI-DSS, GDPR, none)
   - Availability target (best-effort, 99.9%, 99.99%)
   - Team size and experience level
   - Budget constraints
4. **Module index** — Brief description of each module with guidance on when to consult it
5. **Non-negotiable principles** — The 5–7 rules that apply to EVERY decision:
   - Never store secrets in code or environment files committed to version control
   - Never trust user input — validate and sanitize at every boundary
   - Design for failure — assume every external call can fail
   - Make it work, make it right, make it fast — in that order
   - Every architectural decision gets documented (ADR)
   - If you don't understand why a pattern exists, don't remove it — ask
   - Security is not a feature — it's a property of the system

---

## Module Outlines

### 00 — Before You Build

#### decision-framework.md
- **The cost of decisions** — Reversible vs. irreversible decisions (one-way doors vs. two-way doors)
- **Decision inputs** — What information you need before choosing
  - Expected load profile (read-heavy? write-heavy? bursty?)
  - Data sensitivity and regulatory requirements
  - Team capability and operational maturity
  - Time-to-market constraints vs. long-term maintainability
  - Budget — cloud costs, licensing, headcount
- **Tradeoff matrices** — Structured way to compare options
- **When to choose boring technology** — The innovation tokens concept
  - You get approximately three innovation tokens per project
  - Everything else should be proven, well-documented, well-understood
  - The database your team knows beats the database that benchmarks faster
- **When to build vs. buy vs. open-source**
  - Decision tree with cost, control, compliance, and capability axes
- **The "what happens when" exercise** — Thinking through failure scenarios before committing

#### requirements-checklist.md
- **Functional requirements that affect architecture:**
  - Multi-tenancy requirements
  - Offline/disconnected operation
  - Real-time vs. eventual consistency needs
  - File upload/processing requirements
  - Search requirements (full-text, faceted, geo)
  - Notification requirements (email, push, SMS, webhooks)
  - Internationalization and localization
- **Non-functional requirements (quality attributes):**
  - Performance targets (response time, throughput)
  - Availability targets with business justification
  - Scalability expectations (users, data growth, geographic)
  - Security and compliance mandates
  - Data retention and sovereignty requirements
  - Accessibility requirements (WCAG level)
  - Disaster recovery objectives (RTO/RPO)
- **Operational requirements:**
  - Deployment frequency targets
  - Monitoring and alerting needs
  - On-call and support model
  - Backup and restore SLAs
- **Each item includes:** Why it matters, what happens if you skip it, and a "good enough for now" minimum

#### adr-template.md
- Lightweight Architecture Decision Record format
- Fields: Context, Decision, Status, Consequences, Alternatives Considered
- Examples of well-written ADRs at different scales
- When to write one (any decision that would take >15 minutes to explain to a new team member)

---

### 01 — System Design

#### system-design.md
- **Start with a monolith** — Why, when, and the conditions for decomposition
  - The distributed monolith anti-pattern
  - Service boundaries should follow domain boundaries, not technical layers
  - You earn microservices — you don't start with them
- **Separation of concerns at the system level**
  - Presentation, business logic, data access — why this still matters
  - The difference between logical separation and physical separation
- **Coupling and cohesion**
  - Types of coupling: data, stamp, control, content, temporal
  - Why temporal coupling is the silent killer in distributed systems
  - How to identify hidden coupling in your design
- **Bounded contexts and domain boundaries**
  - Not a full DDD course — practical boundary identification
  - The "can this team deploy independently?" test
- **Communication patterns between components**
  - Synchronous: HTTP/REST, gRPC — when and tradeoffs
  - Asynchronous: Message queues, event streams — when and tradeoffs
  - The critical difference between commands, events, and queries
- **Data ownership** — Each piece of data has exactly one authoritative source

#### state-management.md
- **Stateless application design** — Why and how
  - What "stateless" actually means (and doesn't mean)
  - Moving state out of the application process
  - Session management patterns (server-side sessions, JWTs, trade-offs)
- **Caching as a state management decision**
  - Cache-aside, read-through, write-through, write-behind
  - Cache invalidation — why it's hard and strategies that work
  - The thundering herd / cache stampede problem
- **Client-side state**
  - What belongs in the browser vs. what belongs on the server
  - Local storage, session storage, cookies — security implications of each

#### async-patterns.md
- **When to go asynchronous** — Decision criteria
  - Long-running operations (>500ms is a good threshold)
  - Operations that can fail independently
  - Operations where the user doesn't need an immediate result
  - Fan-out / fan-in patterns
- **Message queues vs. event streams** — They solve different problems
  - Queues: work distribution, task processing, load leveling
  - Event streams: event sourcing, change data capture, audit logs
  - When you actually need Kafka vs. when SQS/RabbitMQ is plenty
- **Idempotency** — Why every async handler must be idempotent
  - Idempotency keys and deduplication strategies
  - At-least-once vs. exactly-once delivery (spoiler: exactly-once is a spectrum)
- **Dead letter queues and poison messages**
- **Saga pattern** — Coordinating multi-step workflows without distributed transactions
- **Backpressure** — What happens when producers outpace consumers

---

### 02 — Security

#### security-architecture.md
- **Threat modeling for people who don't do threat modeling**
  - STRIDE in 15 minutes — good enough to catch the big stuff
  - "What would a malicious user do?" exercise for each feature
  - The attack surface concept — every endpoint, every input, every integration
- **Defense in depth** — No single layer is sufficient
  - Network level (firewalls, VPCs, security groups)
  - Application level (input validation, output encoding)
  - Data level (encryption at rest and in transit)
  - Identity level (authentication, authorization, least privilege)
- **The principle of least privilege** — Applied everywhere
  - Database users should not have admin rights
  - Application service accounts should have minimal permissions
  - API keys should be scoped to what they need
  - IAM roles > IAM users for cloud resources
- **Supply chain security**
  - Dependency scanning (Dependabot, Snyk, etc.)
  - Lock files and reproducible builds
  - Evaluating third-party libraries (maintenance, popularity, license)
- **Security headers and transport security**
  - HTTPS everywhere — no exceptions
  - HSTS, CSP, X-Frame-Options, X-Content-Type-Options
  - CORS — what it actually does and common misconfigurations

#### authn-authz.md
- **Authentication patterns**
  - Username/password (bcrypt, argon2 — never MD5/SHA for passwords)
  - OAuth 2.0 / OIDC — when to use, when to delegate to an identity provider
  - API key authentication — appropriate uses and limitations
  - Multi-factor authentication — when to require it
  - Session-based vs. token-based — honest tradeoff comparison
- **Authorization patterns**
  - RBAC (Role-Based Access Control) — simple and usually sufficient
  - ABAC (Attribute-Based Access Control) — when RBAC isn't enough
  - Resource-level permissions — "can THIS user access THIS record?"
  - The authorization check belongs in the business logic layer, not just the API layer
- **Common mistakes**
  - Checking authentication but not authorization
  - Client-side-only access control
  - Insecure direct object references (IDOR)
  - Overly broad JWT claims
  - Not invalidating sessions on password change/logout

#### secrets-management.md
- **What constitutes a secret** — API keys, passwords, tokens, certificates, connection strings, encryption keys
- **Where secrets must NEVER be:**
  - Source code (even in "private" repos)
  - Environment files committed to version control
  - Client-side code / browser-accessible locations
  - Log output
  - Error messages returned to users
  - URL parameters
- **Where secrets should live:**
  - Cloud-native secret managers (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)
  - HashiCorp Vault for multi-cloud or on-prem
  - CI/CD secret storage (GitHub Secrets, etc.) — for deployment only
  - `.env` files in `.gitignore` for LOCAL development only
- **Secret rotation** — Why and how to design for it from day one
- **The "git history" problem** — Once a secret is committed, it's compromised forever

#### input-validation.md
- **Trust boundaries** — Where untrusted data enters your system
  - User input (forms, APIs, file uploads)
  - Data from external services and APIs
  - Data from your own database (it may have been corrupted)
  - URL parameters, headers, cookies
- **Validation strategy**
  - Validate at the boundary, sanitize for the context
  - Allowlists over denylists
  - Type checking, range checking, format checking, business rule checking
- **Injection attacks** — The big ones, explained simply
  - SQL injection — parameterized queries, always
  - XSS (Cross-Site Scripting) — output encoding for the context
  - Command injection — never construct shell commands from user input
  - Path traversal — never use user input to construct file paths directly
  - SSRF (Server-Side Request Forgery) — validate URLs, use allowlists
- **File upload security**
  - Validate file type by content (magic bytes), not extension
  - Size limits
  - Malware scanning
  - Store outside web root, serve through application

---

### 03 — Data

#### data-architecture.md
- **Choose the right database for the job**
  - Relational (PostgreSQL, MySQL) — when and why (most of the time)
  - Document (MongoDB, DynamoDB) — actual good use cases vs. hype
  - Key-value (Redis, Memcached) — caching, sessions, ephemeral data
  - Search (Elasticsearch, OpenSearch) — full-text search, analytics
  - The "polyglot persistence" trap — more databases = more operational burden
  - **Default to PostgreSQL unless you have a specific reason not to**
- **Schema design fundamentals**
  - Normalization — why it matters, when to denormalize deliberately
  - Primary keys — UUIDs vs. auto-increment, tradeoffs
  - Foreign keys — use them; they're your safety net
  - Indexes — what they are, when to add them, when they hurt
  - Naming conventions — be consistent, be descriptive
- **Migrations**
  - Always use migration tools (never manual DDL in production)
  - Forward-only migrations — no manual rollbacks
  - Backward-compatible schema changes (expand-and-contract pattern)
  - Test migrations against production-like data volumes

#### data-integrity.md
- **Transactions** — ACID properties explained practically
  - When you need transactions (any multi-step write operation)
  - Transaction isolation levels — what they protect against
  - Keep transactions short — long transactions kill concurrency
- **Constraints** — Let the database enforce your rules
  - NOT NULL, UNIQUE, CHECK, FOREIGN KEY — use them all
  - The database is the last line of defense for data integrity
  - Application-level validation AND database constraints — belt and suspenders
- **Consistency patterns**
  - Strong consistency — when you must have it (financial transactions, inventory)
  - Eventual consistency — when it's acceptable and how to handle it in the UI
  - Conflict resolution strategies (last-write-wins, merge, manual resolution)
- **Soft deletes vs. hard deletes**
  - When each is appropriate
  - Implementation patterns and indexing considerations

#### data-lifecycle.md
- **Backup strategy** — 3-2-1 rule (3 copies, 2 media types, 1 off-site)
  - Automated backups — never rely on manual processes
  - Test your restores — an untested backup is not a backup
  - Point-in-time recovery capability
- **Data retention policies**
  - Define retention periods before you start collecting data
  - Automated purging/archival
  - Legal hold considerations
- **Privacy and compliance**
  - GDPR right to erasure — design for it from day one
  - CCPA data access requests
  - HIPAA — if you're in healthcare, this shapes everything
  - Data residency / sovereignty requirements
  - PII identification and classification
- **Data encryption**
  - At rest — database encryption, volume encryption
  - In transit — TLS everywhere
  - Application-level encryption — when you need it beyond infrastructure encryption

---

### 04 — API Design

#### api-design.md
- **API-first design** — Design the contract before the implementation
  - OpenAPI / Swagger for REST
  - Schema-first for GraphQL
  - Protobuf definitions for gRPC
- **REST fundamentals done right**
  - Resources are nouns, HTTP methods are verbs
  - Consistent URL patterns and naming conventions
  - Proper HTTP status codes (not everything is 200 or 500)
  - Pagination — cursor-based over offset-based for large datasets
  - Filtering, sorting, field selection — keep it consistent
  - HATEOAS — when it's worth it and when it isn't
- **GraphQL — honest assessment**
  - Good for: complex, nested data; mobile clients with bandwidth constraints
  - Bad for: simple CRUD; teams without GraphQL operational experience
  - The N+1 query problem in GraphQL (DataLoader pattern)
  - Query complexity limits — prevent abuse
- **Error handling in APIs**
  - Consistent error response format across all endpoints
  - Meaningful error codes and messages for developers
  - Never expose internal details (stack traces, SQL errors) to clients
  - Distinguish between client errors (4xx) and server errors (5xx)
- **Idempotency in APIs**
  - GET, PUT, DELETE should be idempotent by nature
  - POST — use idempotency keys for safe retries

#### api-versioning.md
- **Why you need a versioning strategy from day one**
- **Versioning approaches** — URL path, header, query param — tradeoffs
- **Breaking vs. non-breaking changes** — Clear definitions
- **Deprecation policy** — How to sunset old versions gracefully
- **Contract testing** — Preventing accidental breaking changes

#### api-security.md
- **Authentication for APIs** — API keys, OAuth 2.0, JWT validation
- **Rate limiting and throttling**
  - Why: abuse prevention, fair usage, cost control
  - Implementation patterns (token bucket, sliding window)
  - Communicating limits to clients (429 status, Retry-After header)
- **Input validation at the API boundary** — Schema validation, size limits
- **CORS configuration** — Common mistakes and correct patterns
- **Request/response logging** — What to log and what to redact (PII, secrets)

---

### 05 — Reliability

#### reliability.md
- **Failure is not exceptional — it's expected**
  - Every network call can fail
  - Every external service will have downtime
  - Every database will eventually become slow or unavailable
  - Design for "what happens when X breaks?" not "X will always work"
- **Failure modes and their mitigation**
  - Transient failures — retry with backoff
  - Persistent failures — circuit breakers and fallbacks
  - Cascading failures — bulkheads and isolation
  - Data corruption — validation and checksums
  - Capacity exhaustion — backpressure and load shedding
- **Graceful degradation** — The system should get worse gracefully, not catastrophically
  - Feature flags for non-critical features
  - Read-only mode when writes fail
  - Cached/stale data is often better than an error page
  - Static fallback pages
- **Dependency management**
  - Classify dependencies: hard (system can't function without) vs. soft (nice to have)
  - Hard dependencies need the strongest resilience patterns
  - Soft dependencies should fail silently with fallbacks

#### high-availability.md
- **SLA/SLO/SLI** — What they mean and why you define them before building
  - SLA: contractual commitment to customers
  - SLO: internal target (should be stricter than SLA)
  - SLI: the actual measurements
  - The nines table — what 99.9% vs 99.99% actually means in downtime
- **Redundancy patterns**
  - Active-active vs. active-passive
  - Multi-AZ deployments
  - Multi-region — when it's justified (hint: rarely for startups)
  - Database replication (read replicas, failover clusters)
- **Failover strategies**
  - Automated failover vs. manual
  - Health checks — shallow vs. deep
  - DNS failover considerations
- **Recovery objectives**
  - RTO (Recovery Time Objective) — How fast can you recover?
  - RPO (Recovery Point Objective) — How much data can you afford to lose?
  - These drive your backup, replication, and failover design
- **When you DON'T need high availability**
  - Internal tools, batch processing, dev/staging environments
  - The cost of HA is real — don't gold-plate

#### resilience-patterns.md
- **Retry with exponential backoff and jitter**
  - Why jitter matters (thundering herd)
  - Maximum retry limits
  - Which errors are retryable (5xx, timeouts) vs. not (4xx)
- **Circuit breaker pattern**
  - Closed → Open → Half-Open state machine
  - When to use: any call to an external service
  - Configuration: failure threshold, timeout, half-open probe count
- **Bulkhead pattern**
  - Isolate failures so one slow dependency doesn't bring everything down
  - Thread pool isolation, connection pool isolation
  - Separate pools for critical vs. non-critical operations
- **Timeout everywhere**
  - Connection timeouts, read timeouts, overall operation timeouts
  - No unbounded waits — ever
  - Timeout budgets — propagating deadlines through call chains
- **Fallback strategies**
  - Return cached data
  - Return default values
  - Degrade to simpler functionality
  - Queue for later processing

---

### 06 — Infrastructure

#### infrastructure.md
- **Infrastructure as Code — non-negotiable**
  - Terraform, Pulumi, CloudFormation, CDK — pick one, be consistent
  - The principle: if it's not in code, it doesn't exist
  - No manual changes in production — ever (ClickOps is a slur)
  - State management (Terraform state) — remote state, locking
- **Environment parity**
  - Dev, staging, production should differ in scale, not in kind
  - Same IaC templates for all environments, parameterized
  - Environment-specific configuration via variables, not code branches
- **Infrastructure drift detection**
  - Regular plan/diff runs
  - Alerting on drift
- **Network architecture basics**
  - VPCs, subnets, security groups — defense in depth
  - Public vs. private subnets — databases are NEVER public
  - NAT gateways — when you need them
  - VPN/bastion hosts for administrative access

#### deployment.md
- **CI/CD is not optional**
  - Automated builds, automated tests, automated deployments
  - The deployment pipeline: build → test → stage → production
  - Every deployment should be reproducible from a specific commit
- **Deployment strategies**
  - Rolling deployment — good default for most applications
  - Blue-green — zero-downtime with instant rollback
  - Canary — gradual rollout with monitoring gates
  - Feature flags — deploy code without exposing features
  - When to use each
- **Rollback strategy**
  - Every deployment must have a rollback plan
  - Database migration rollback considerations
  - The "forward fix" vs. "rollback" decision
- **Deployment safety**
  - Deployment windows vs. continuous deployment — team maturity matters
  - Smoke tests post-deployment
  - Automated health checks before declaring deployment successful
  - Break-glass procedures for emergency deployments

#### containerization.md
- **Docker fundamentals for the architecture-aware**
  - One process per container (usually)
  - Multi-stage builds — minimize image size and attack surface
  - Don't run as root in containers
  - Pin base image versions (never use `latest` in production)
  - `.dockerignore` — keep secrets and unnecessary files out of images
- **Container orchestration — when you need it**
  - Single container: Docker Compose is fine
  - Small scale: ECS/Fargate, Cloud Run, App Runner
  - Large scale: Kubernetes — but understand the operational cost
  - You probably don't need Kubernetes (yet)
- **Image hygiene**
  - Vulnerability scanning (Trivy, Snyk Container)
  - Regular base image updates
  - Image signing and verification for production

#### cloud-fundamentals.md
- **The shared responsibility model** — What the cloud provider secures vs. what you secure
- **Regions and availability zones** — Why they matter
- **Cost awareness from day one**
  - Understand your cloud bill — review it monthly
  - Reserved instances / savings plans for predictable workloads
  - Spot/preemptible instances for fault-tolerant workloads
  - Tag everything for cost allocation
  - Set billing alerts before you get a surprise
- **Cloud-native vs. cloud-agnostic** — An honest tradeoff discussion
  - Cloud-native services reduce operational burden but increase lock-in
  - For startups: embrace cloud-native, switch later if needed
  - For enterprises: evaluate lock-in risk against operational savings
- **Managed services vs. self-hosted**
  - Default to managed (RDS over self-hosted PostgreSQL, etc.)
  - Self-host only when managed doesn't meet requirements

---

### 07 — Observability

#### observability.md
- **Why observability matters** — You can't fix what you can't see
- **The three pillars: Logs, Metrics, Traces**
  - Logs tell you WHAT happened
  - Metrics tell you HOW MUCH / HOW OFTEN
  - Traces tell you WHERE in the call chain
  - You need all three — they're complementary, not alternatives
- **Observability-driven development** — Instrument as you build, not after
- **Correlation IDs** — Thread a unique ID through every request across all services
  - Generate at the edge (API gateway, load balancer)
  - Pass through every service call
  - Include in every log entry
  - This single practice will save you more debugging time than almost anything else

#### logging.md
- **Structured logging** — JSON, not free-form text
  - Every log entry should be machine-parseable
  - Standard fields: timestamp, level, service, correlation_id, message
  - Context fields: user_id, request_path, duration_ms
- **Log levels used correctly**
  - ERROR: Something broke that needs attention
  - WARN: Something unexpected but handled
  - INFO: Business-significant events (user created, order placed)
  - DEBUG: Technical details for troubleshooting (off in production by default)
- **What to log and what NOT to log**
  - DO: Request/response metadata, errors, business events, performance data
  - DON'T: Passwords, tokens, PII, full request/response bodies in production
  - Redaction patterns for sensitive data
- **Log aggregation** — Centralize logs from all services/instances
  - CloudWatch, ELK/OpenSearch, Datadog, Grafana Loki — pick one
  - Retention policies — how long to keep logs and at what cost

#### monitoring-alerting.md
- **The four golden signals** (per Google SRE)
  - Latency — response time distributions, not averages
  - Traffic — request rate
  - Errors — error rate by type
  - Saturation — resource utilization (CPU, memory, disk, connections)
- **Application metrics**
  - Business metrics: sign-ups, orders, revenue
  - Technical metrics: response times, queue depths, cache hit rates
  - Custom metrics for your domain
- **Alert design**
  - Alert on symptoms, not causes (alert on high error rate, not high CPU)
  - Every alert must be actionable — if you can't do anything about it, it's not an alert
  - Alert fatigue is real — fewer, better alerts
  - Severity levels: page (wake someone up), ticket (fix this week), inform (FYI)
- **Dashboards**
  - One "overview" dashboard per service
  - Business metrics dashboard for stakeholders
  - Don't build dashboards nobody looks at

#### incident-response.md
- **Runbooks** — Step-by-step guides for common incidents
  - Write them before you need them
  - Keep them next to the code (or linked from the monitoring system)
  - Test them periodically
- **Incident management basics**
  - Detect → Triage → Mitigate → Resolve → Learn
  - Mitigation first, root cause later
  - Communication during incidents (status page, stakeholder updates)
- **Postmortems / Retrospectives**
  - Blameless — focus on systems and processes, not people
  - What happened, why, what we'll change
  - Action items with owners and deadlines
  - Share broadly — incidents are learning opportunities

---

### 08 — Performance

#### performance.md
- **The first rule: Don't optimize prematurely**
  - Make it work, make it right, THEN make it fast
  - Profile first — never guess where the bottleneck is
  - Optimization without measurement is superstition
- **Performance budgets**
  - Define acceptable response times for each operation class
  - Page load targets (Core Web Vitals as a framework)
  - API response time targets (p50, p95, p99 — not averages)
- **Common performance killers**
  - N+1 queries — the #1 performance bug in web applications
  - Unbounded queries (SELECT * FROM big_table with no LIMIT)
  - Synchronous calls to external services in the request path
  - Missing database indexes
  - Over-serialization (loading and transforming data you don't need)

#### scaling-strategies.md
- **Vertical scaling** — Bigger machines
  - Simple, effective, has a ceiling
  - Good first step for most problems
- **Horizontal scaling** — More machines
  - Requires stateless application design
  - Load balancing strategies (round-robin, least-connections, session affinity)
  - Database scaling is harder than application scaling
- **Read replicas** — Scale reads independently of writes
- **Database sharding** — When you actually need it (hint: later than you think)
- **Auto-scaling**
  - Scale on the right metric (request count, queue depth, not just CPU)
  - Scaling policies — cooldown periods, minimum/maximum instances
  - Pre-warming for predictable traffic spikes

#### caching.md
- **The caching decision tree** — When to cache and when not to
- **Cache layers**
  - Browser cache (Cache-Control headers)
  - CDN (static assets, API responses)
  - Application cache (Redis, Memcached)
  - Database query cache
- **Cache invalidation strategies**
  - TTL-based (simple, good enough for most cases)
  - Event-based (more complex, more precise)
  - Cache versioning
- **Cache stampede / thundering herd**
  - The problem: cache expires, 1000 requests hit the database simultaneously
  - Solutions: lock-based recomputation, probabilistic early expiration, background refresh
- **What to cache — and what not to**
  - Cache: expensive computations, frequently read / rarely changed data
  - Don't cache: user-specific sensitive data (without careful design), rapidly changing data

#### database-performance.md
- **Indexing fundamentals**
  - How indexes work (B-tree, hash, GIN, GiST — when to use each)
  - Composite indexes — column order matters
  - Covering indexes — avoid table lookups
  - Index maintenance overhead (writes become slower)
  - The "EXPLAIN ANALYZE is your friend" principle
- **Query optimization**
  - Read the query plan before optimizing
  - Common anti-patterns: SELECT *, functions in WHERE clauses, implicit type conversions
  - Pagination: keyset/cursor over OFFSET for large tables
- **Connection pooling**
  - Why: database connections are expensive to create
  - Connection pool sizing (don't just set it to 100 and forget)
  - PgBouncer, ProxySQL, built-in pool managers
- **Write optimization**
  - Batch operations where possible
  - Avoid large transactions that hold locks
  - Consider write-ahead patterns for high-throughput writes

---

### 09 — Testing

#### testing-strategy.md
- **The test pyramid** — More unit tests, fewer E2E tests
  - Unit tests: Fast, isolated, test logic — the foundation
  - Integration tests: Test boundaries (database, APIs, message queues)
  - End-to-end tests: Test critical user journeys — the tip
- **What to test**
  - Business logic — always
  - Data validation — always
  - Error handling paths — often forgotten, always important
  - Edge cases and boundary conditions
  - Security-relevant code paths
- **What NOT to test**
  - Framework code (trust that React renders correctly)
  - Trivial getters/setters
  - Third-party library internals
  - Layout/visual details (unless you have visual regression tools)
- **Test data management**
  - Factories/fixtures over hard-coded data
  - Test databases — isolated, reset between runs
  - Never test against production data
- **When AI writes tests**
  - AI-generated tests need human review for correctness
  - Watch for: tests that test the implementation rather than the behavior
  - Watch for: tests that always pass (tautological tests)
  - Watch for: missing edge cases that require domain knowledge

#### integration-testing.md
- **Contract testing** — Verify API contracts between services
  - Pact, Spring Cloud Contract — prevent integration surprises
  - Consumer-driven contracts — the consumer defines expectations
- **Test containers** — Real databases and services in tests
  - Better than mocking for integration tests
  - Docker-based, ephemeral, isolated
- **External service testing**
  - Mock external APIs with tools like WireMock
  - Record-and-replay for complex integrations
  - Never call real external services in automated tests

#### chaos-engineering.md
- **Not for beginners** — Prerequisites before chaos engineering
  - Solid monitoring and alerting
  - Defined SLOs
  - Incident response process
  - Team maturity and buy-in
- **Starting small**
  - Game days: manually simulate failures with the team
  - Turn off a non-critical service — does the system degrade gracefully?
  - Introduce latency to a dependency — does the circuit breaker work?
- **Principles**
  - Run in production (eventually), but start in staging
  - Minimize blast radius
  - Have a hypothesis before experimenting
  - Automate the experiment for repeatability
- **Tools overview** — Chaos Monkey, Litmus, Gremlin (brief, not prescriptive)

---

### 10 — Operations

#### operational-readiness.md
- **Production readiness checklist** — Before any service goes live:
  - [ ] Health check endpoint exists and is monitored
  - [ ] Structured logging is in place with appropriate levels
  - [ ] Metrics are being collected (the four golden signals)
  - [ ] Alerts are configured for critical failure modes
  - [ ] Runbooks exist for known failure scenarios
  - [ ] Deployment is automated and tested
  - [ ] Rollback procedure is documented and tested
  - [ ] Backup and restore has been tested
  - [ ] Security review has been completed
  - [ ] Load testing has validated expected traffic levels
  - [ ] On-call rotation (or point of contact) is established
  - [ ] Dependencies are documented with their SLAs
  - [ ] Secrets are managed properly (not in code)
  - [ ] Error pages / fallback behavior is configured
  - [ ] HTTPS / TLS is configured and enforced
- **Progressive rollout** — Don't go from zero to 100% traffic overnight

#### cost-management.md
- **Cloud cost principles**
  - Track costs from day one — not after the first surprise bill
  - Right-size instances — monitor utilization, downsize the idle
  - Delete what you're not using (unused EBS volumes, old snapshots, idle load balancers)
  - Use cost allocation tags — know which team/project/feature costs what
- **Cost-aware architecture decisions**
  - Serverless vs. always-on — crossover points
  - Storage tiering (hot/warm/cold/archive)
  - Data transfer costs — the hidden cloud expense
  - Reserved capacity for predictable workloads
- **Cost monitoring and alerts**
  - Daily/weekly cost reports
  - Anomaly detection — catch unexpected spend spikes
  - Budget alerts before you hit limits

#### compliance.md
- **Regulatory awareness** — Not a legal guide, but architectural implications
  - HIPAA (healthcare): encryption, access logging, BAAs, minimum necessary
  - SOC 2 (SaaS): access controls, change management, monitoring
  - PCI-DSS (payments): network segmentation, encryption, key management
  - GDPR/CCPA (privacy): data inventory, consent management, right to erasure
- **Audit trails**
  - Who did what, when, from where
  - Immutable audit logs — append-only, tamper-evident
  - Retention requirements per regulation
- **Access control and separation of duties**
  - Principle of least privilege (again — it's that important)
  - Break-glass procedures for emergency access
  - Regular access reviews

---

### Appendices

#### anti-patterns.md
A curated gallery of common architectural mistakes seen in AI-generated code, organized by category:

- **Security anti-patterns**
  - Hardcoded secrets, API keys in frontend code, SQL string concatenation
  - JWT stored in localStorage, CORS wildcards in production, HTTP in production
- **Data anti-patterns**
  - No foreign keys, no indexes, no migrations
  - Storing everything in one giant JSON column
  - No data validation at the database level
  - Using MongoDB "because it's flexible" with no schema design at all
- **Infrastructure anti-patterns**
  - ClickOps (manual cloud console changes)
  - Monolithic "God" environment variables file
  - No backup strategy, no tested restores
  - Running databases on EC2 instead of managed services
- **Design anti-patterns**
  - Distributed monolith (microservices that can't deploy independently)
  - Premature microservices (for a team of two)
  - Cargo cult patterns (using Kafka for 10 messages per minute)
  - Résumé-driven development (choosing tech to learn it, not because it fits)
- **Each entry includes:** What it looks like, why it's bad, what to do instead

#### glossary.md
- Plain-English definitions of architectural terms
- Aimed at developers who are competent coders but haven't worked in large-scale systems
- Terms like: idempotency, eventual consistency, backpressure, circuit breaker, bulkhead, SLA/SLO/SLI, RTO/RPO, CQRS, saga pattern, sharding, connection pooling, etc.
- Each term includes a one-sentence "why you should care" note

#### further-reading.md
- **Books** (curated, not exhaustive):
  - *Designing Data-Intensive Applications* — Martin Kleppmann
  - *Release It!* — Michael Nygard
  - *Building Secure and Reliable Systems* — Google SRE team
  - *The Phoenix Project* — Gene Kim (for understanding DevOps culture)
  - *Fundamentals of Software Architecture* — Mark Richards & Neal Ford
- **Online resources:**
  - AWS Well-Architected Framework (useful even if not on AWS)
  - Google SRE Books (free online)
  - OWASP Top 10 and Cheat Sheet Series
  - The Twelve-Factor App (twelve-factor.net)
- **Community and newsletters:**
  - Curated list of high-signal, low-noise resources
  - Podcasts, blogs, and conferences worth following

---

## Implementation Plan

### Phase 1 — Foundation (MVP)
Write the core files that provide the most immediate value to vibe coders:
1. `ARCHITECT.md` (root entry point)
2. `security-architecture.md` + `secrets-management.md` + `input-validation.md` (security is the biggest gap)
3. `system-design.md` (monolith-first guidance)
4. `data-architecture.md` + `data-integrity.md` (database fundamentals)
5. `anti-patterns.md` (immediate "don't do this" value)
6. `operational-readiness.md` (the production checklist)

### Phase 2 — API & Reliability
7. `api-design.md` + `api-security.md`
8. `reliability.md` + `resilience-patterns.md`
9. `deployment.md`
10. `observability.md` + `logging.md`

### Phase 3 — Advanced Topics
11. `high-availability.md`
12. `performance.md` + `caching.md` + `database-performance.md`
13. `scaling-strategies.md`
14. `testing-strategy.md` + `integration-testing.md`
15. `cost-management.md`

### Phase 4 — Polish & Community
16. `glossary.md` + `further-reading.md`
17. Remaining files
18. vibeArchitecture GitHub repository: contributing guidelines, README, LICENSE
19. Example integrations (CLAUDE.md, .cursorrules, AGENTS.md wrappers that `@import` from vibeArchitecture/)
20. Community feedback and iteration

---

## Design Decisions for the Framework Itself

### Why markdown?
- Universal format readable by all AI coding agents
- Human-readable without special tooling
- Version-controllable in git
- Lightweight — no runtime dependencies

### Why modular files instead of one giant doc?
- AI agents have context window limits — load only what's relevant
- Teams can adopt incrementally (start with security, add more over time)
- Different team members can own different modules
- Reduces merge conflicts in team settings

### Why stack-agnostic?
- Principles transcend languages and frameworks
- A vibe coder using Next.js needs the same security awareness as one using Django
- Implementation-specific guidance belongs in project-level CLAUDE.md / .cursorrules

### Naming: `vibeArchitecture/` directory
- Speaks directly to the vibe coding community — the name signals what it's for
- Distinct from `.claude/`, `.cursor/`, `.github/` — this is tool-agnostic
- Won't conflict with existing AI coding agent configuration
- Clear purpose from the name
- The root `ARCHITECT.md` can be `@imported` from tool-specific config files
- Projects clone or copy the `vibeArchitecture/` directory into their project root
- Alternatively, install as a git submodule for easy updates from the upstream repo

---

## Open Questions

1. **Licensing** — MIT? Creative Commons? What encourages maximum adoption?
2. **Scope management** — How to keep each file concise enough for AI context windows while being comprehensive enough to be useful?
3. **Versioning** — How to version the framework itself as best practices evolve?
4. **Community governance** — If this becomes a community project, how are contributions reviewed for quality?
5. **Certification/badging** — Should projects be able to declare compliance level (e.g., "vibeArchitecture Level 1: Security Fundamentals")?
6. **Integration templates** — Pre-built wrappers for Claude Code, Cursor, Copilot that `@import` the relevant vibeArchitecture modules?
7. **Industry-specific extensions** — Healthcare (HIPAA), finance (PCI-DSS/SOX), government (FedRAMP) as optional add-on modules?
