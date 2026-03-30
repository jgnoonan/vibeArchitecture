# Glossary

Plain-English definitions of architectural terms. Each entry includes a brief "why you should care" note.

---

**Agent (AI):** A program that uses a language model (like ChatGPT or Claude) to make decisions and take actions — calling tools, querying databases, sending messages. Unlike a simple chatbot, an agent acts on your behalf rather than just responding. *Why you should care: If your application uses AI to do things (not just answer questions), you're building an agent, and it needs guardrails.*

**Agent orchestration:** Coordinating multiple AI agents to work together on a task — deciding who does what, passing information between agents, and assembling the final result. *Why you should care: Multi-agent systems can be powerful but also complex. Without clear orchestration, agents duplicate work, lose context, or loop forever.*

**Accessibility (a11y):** Building your application so that people with disabilities can use it — including people using screen readers, keyboard-only navigation, voice control, or high-contrast settings. *Why you should care: About 15% of people have a disability. It's also a legal requirement for public applications in most jurisdictions.*

**ADR (Architecture Decision Record):** A short document that records an important technical decision — what you decided, why, and what other options you considered. *Why you should care: Six months from now, nobody will remember why you chose PostgreSQL over MongoDB. An ADR preserves that reasoning so decisions don't get revisited or accidentally reversed.*

**API (Application Programming Interface):** A defined way for software to talk to other software. When your frontend shows data from your backend, it uses an API. *Why you should care: You're probably building one whether you realize it or not.*

**ARIA (Accessible Rich Internet Applications):** A set of HTML attributes that add accessibility information to custom components for screen readers. The first rule of ARIA: don't use it if a native HTML element does the job. *Why you should care: ARIA is sometimes needed for custom widgets, but incorrect ARIA is worse than no ARIA — it misleads assistive technology.*

**Authentication:** Proving who you are. Logging in with a username and password is authentication. *Why you should care: Without it, anyone can pretend to be anyone.*

**Authorization:** Determining what you're allowed to do after authentication. An admin can delete users; a regular user can't. *Why you should care: Authentication without authorization means every logged-in user has full access to everything.*

**Atomic operation:** An operation that completes entirely or not at all — nothing can interrupt it halfway. Like flipping a light switch: it's either on or off, never stuck between. *Why you should care: When multiple threads update a counter or flag, atomic operations prevent two updates from colliding and producing a wrong result.*

**Auto-scaling:** Automatically adding or removing servers based on demand — more during busy periods, fewer during quiet ones. *Why you should care: It keeps your app responsive during traffic spikes without paying for idle servers at 3 AM.*

**BAA (Business Associate Agreement):** A legal contract required under HIPAA between a healthcare provider and any vendor that handles protected health information (PHI). *Why you should care: If your application processes health data in the US, your cloud provider and any third-party service that touches that data must sign a BAA. Using a service without a BAA is a compliance violation.*

**Backpressure:** A mechanism that slows down producers when consumers can't keep up. Like a valve that reduces flow when the pipe is full. *Why you should care: Without it, a sudden surge of work can overwhelm your system and crash it.*

**Blue-green deployment:** Running two identical environments and switching traffic between them for zero-downtime deployments. *Why you should care: It lets you update your app without users experiencing downtime.*

**Bulkhead:** Isolating components so one failure doesn't bring everything down, like watertight compartments in a ship. *Why you should care: Without isolation, one slow database query can make your entire application unresponsive.*

**Cache:** A fast storage layer that keeps copies of frequently-accessed data. Like keeping important phone numbers on a sticky note instead of looking them up in a directory every time. *Why you should care: Caching can make your app 10-100x faster for common operations.*

**Cache invalidation:** The process of updating or removing cached data when the original data changes. *Why you should care: Stale cache means users see outdated information. Getting this wrong is one of the hardest problems in software.*

**Canary deployment:** Sending a small percentage of traffic to a new version to test it before rolling out to everyone. *Why you should care: It catches bugs before they affect all your users.*

**CDN (Content Delivery Network):** A network of servers around the world that serve your static files from the location closest to the user. *Why you should care: It makes your site load faster for users who are far from your server.*

**CI/CD (Continuous Integration / Continuous Deployment):** Automated processes that test your code and deploy it whenever you push changes. *Why you should care: It catches bugs before they reach users and eliminates manual deployment mistakes.*

**Circuit breaker:** A pattern that stops calling a failing service, giving it time to recover. Like an electrical breaker that trips to prevent a fire. *Why you should care: Without it, a failing external service can take your entire application down.*

**Concurrency:** Multiple operations happening at the same time (or interleaved), potentially accessing the same resources. *Why you should care: Almost every web application handles concurrent requests. If two users update the same data at the same instant, you need a strategy for that or one update silently disappears.*

**Connection pooling:** Maintaining a set of reusable database connections instead of creating a new one for each request. *Why you should care: Creating connections is slow. Pooling makes database operations significantly faster.*

**Content-Security-Policy (CSP):** A security header that tells browsers which sources of content (scripts, images, styles) are allowed to load on your page. *Why you should care: CSP is one of the strongest defenses against XSS attacks. If a malicious script is injected, CSP can prevent the browser from executing it.*

**Context window:** The maximum amount of text (measured in tokens) that an AI model can process in a single conversation. Everything — your instructions, the conversation history, and the model's response — must fit within this window. *Why you should care: If your agent's context fills up, it starts forgetting earlier instructions or information. Managing context is a core challenge in agent systems.*

**Dead letter queue (DLQ):** A holding area for messages that failed to process after multiple attempts. Instead of retrying forever, the failed message is moved aside for investigation. *Why you should care: Without a DLQ, one bad message can block your entire queue and prevent any other work from being processed.*

**CORS (Cross-Origin Resource Sharing):** A browser security mechanism that controls which websites can make requests to your API. *Why you should care: Misconfigured CORS either blocks legitimate requests or allows malicious ones.*

**CQRS (Command Query Responsibility Segregation):** Separating the read side and write side of your application into different models. *Why you should care: You probably don't need it for most applications, but you might encounter it in recommendations. Use it only if you have very different read and write patterns at significant scale.*

**CRUD:** Create, Read, Update, Delete — the four basic operations for data. *Why you should care: Most web applications are fundamentally CRUD operations. Understanding this simplifies your design.*

**Deadlock:** Two or more operations each waiting for the other to finish, so none of them ever do. Thread A holds Lock 1 and wants Lock 2; Thread B holds Lock 2 and wants Lock 1 — both wait forever. *Why you should care: Deadlocks freeze your application with no error message. They're hard to diagnose because nothing crashes — everything just stops.*

**DDoS (Distributed Denial of Service):** An attack that overwhelms your servers with traffic to make them unavailable. *Why you should care: Rate limiting and CDNs help protect against this.*

**Defense in depth:** Layering multiple security controls so that if one fails, others still protect you. Like a castle with a moat, walls, and locked doors — an attacker has to get past all of them. *Why you should care: No single security measure is perfect. Layers mean a single failure doesn't expose everything.*

**Expand-and-contract pattern:** A database migration strategy where you add a new column, migrate data, update the code to use it, and then remove the old column — rather than renaming or changing a column in one step. *Why you should care: It lets you change your database schema without downtime or breaking running code. Each step is safe to deploy independently.*

**Exponential backoff:** A retry strategy where you wait progressively longer between attempts — 1 second, then 2, then 4, then 8. *Why you should care: When a service is overwhelmed or recovering, retrying immediately makes it worse. Backing off gives it time to recover.*

**Encryption at rest:** Encrypting data while it's stored on disk. *Why you should care: If someone steals the hard drive or gains access to the raw storage, they can't read the data.*

**Encryption in transit:** Encrypting data while it's moving between systems (HTTPS/TLS). *Why you should care: Without it, anyone on the network path can read the data being transferred.*

**Eventual consistency:** A model where updates propagate gradually, and different parts of the system may briefly show different values. *Why you should care: When using caches or multiple databases, data might be briefly out of sync. Your UI needs to handle this gracefully.*

**Feature flag:** A configuration switch that enables or disables a feature without deploying new code. *Why you should care: You can deploy code to production safely and enable features gradually or disable them instantly if problems arise.*

**Foreign key:** A database column that references a row in another table, with the database enforcing that the reference is valid. *Why you should care: Without foreign keys, your database can accumulate broken references that cause mysterious bugs.*

**Guardrails (AI):** Rules and constraints that limit what an AI agent can do — preventing it from taking dangerous actions, producing harmful content, or exceeding its scope. *Why you should care: An AI agent without guardrails can leak data, run up costs, or take actions you never intended. Guardrails are the safety boundaries.*

**Hallucination (AI):** When an AI model generates information that sounds confident and plausible but is factually wrong — inventing statistics, citing nonexistent sources, or fabricating details. *Why you should care: If your agent makes decisions based on hallucinated facts (wrong prices, nonexistent API endpoints, fabricated customer data), those decisions will be wrong too.*

**Horizontal scaling:** Adding more servers to handle more load.

**HSTS (HTTP Strict Transport Security):** A security header that tells browsers to always use HTTPS for your site, even if someone types the HTTP address. *Why you should care: Without HSTS, an attacker could intercept the initial HTTP request before the redirect to HTTPS and steal session cookies or inject content.* *Why you should care: It removes the ceiling on capacity, but requires your application to be stateless.*

**IDOR (Insecure Direct Object Reference):** A vulnerability where changing an ID in a URL or request lets you access another user's data. Example: changing `/api/orders/123` to `/api/orders/124` and seeing someone else's order. *Why you should care: It's one of the most common web vulnerabilities. Every endpoint that uses an ID must verify the requesting user is authorized to access that specific resource.*

**Idempotency:** An operation that produces the same result whether you execute it once or multiple times. *Why you should care: Networks are unreliable. Requests get retried. If creating an order isn't idempotent, a retry might create a duplicate order.*

**Infrastructure as Code (IaC):** Defining your servers, databases, and networking in configuration files instead of setting them up manually through a dashboard. *Why you should care: It makes your infrastructure reproducible, version-controlled, and reviewable — just like your application code.*

**Integration test:** A test that verifies multiple components work together correctly

**Jitter:** Adding a small random delay to retry timing so that many clients retrying at the same time don't all hit the server at the exact same instant. *Why you should care: Without jitter, a service that just recovered from being overwhelmed gets slammed by all the retrying clients at once, causing it to fail again — a "thundering herd."* — for example, that your code can actually save and retrieve data from the database. *Why you should care: Unit tests check individual pieces; integration tests catch problems in how those pieces connect.*

**Index (database):** A data structure that speeds up queries by allowing the database to find rows without scanning the entire table. *Why you should care: A missing index on a large table can make a query 1000x slower.*

**JWT (JSON Web Token):** A self-contained token used for authentication that carries information (claims) and is cryptographically signed. *Why you should care: Common for API authentication. Important to understand the tradeoffs vs. sessions.*

**LLM-as-Judge:** Using a separate AI model to evaluate the quality of another AI model's output. *Why you should care: It's the most scalable way to measure whether your agents are producing good results. A human can't review every output, but an AI judge can score them automatically.*

**Load balancer:** A system that distributes incoming requests across multiple servers. *Why you should care: It enables horizontal scaling and provides redundancy if one server fails.*

**Magic bytes:** The first few bytes of a file that identify its actual type, regardless of the file extension. A file named `photo.jpg` might actually be a `.exe` if its magic bytes say so. *Why you should care: When accepting file uploads, checking the extension alone isn't enough. Validating magic bytes prevents users from uploading disguised malicious files.*

**Managed service:** Infrastructure that a cloud provider operates for you — updates, backups, scaling, and maintenance are handled automatically. *Why you should care: It lets you focus on building your application instead of maintaining servers.*

**Message queue:** A system that holds messages (descriptions of work) until a worker is ready to process them. Like a to-do list that multiple workers can pull from. *Why you should care: Queues let you handle slow tasks (emails, image processing) in the background instead of making users wait.*

**Microservices:** An architecture where your application is split into small, independently deployable services that communicate over the network. Each service has its own codebase and database. *Why you should care: Microservices solve real problems at scale but add enormous complexity. Most applications should start as a monolith and decompose only when there's evidence it's necessary.*

**Migration (database):** A version-controlled script that changes the database schema. *Why you should care: Without migrations, database changes are manual, unreproducible, and can't be rolled back.*

**Modular monolith:** A monolith with strictly enforced internal boundaries between modules. Modules communicate through explicit interfaces, not by reaching into each other's internals. *Why you should care: You get most of the organizational benefits of microservices without the operational complexity. It's also the best preparation for future decomposition.*

**Monolith:** An application built and deployed as a single unit. All code runs in the same process. *Why you should care: This is the right default for most applications. It's simpler to develop, deploy, debug, and operate than a distributed system.*

**Mutex (mutual exclusion):** A lock that only one thread can hold at a time. Like a bathroom door lock — if someone's inside, everyone else waits. *Why you should care: Mutexes are the most basic tool for preventing race conditions when multiple threads access shared data.*

**N+1 query problem:** A performance bug where loading a list of N items triggers N additional queries for related data, instead of loading everything in 1-2 queries. *Why you should care: It's the #1 cause of slow pages in web applications.*

**ORM (Object-Relational Mapping):** A library that lets you interact with the database using your programming language instead of writing SQL directly. Examples: Prisma, SQLAlchemy, Sequelize, Active Record. *Why you should care: ORMs speed up development but can hide performance problems. Understand what queries they generate.*

**Optimistic concurrency:** An approach where you proceed without locking, then check if anyone else changed the data before you save. If they did, you retry. *Why you should care: It's faster than locking when conflicts are rare, which they usually are.*

**Parameterized query:** A database query where user input is passed as separate parameters rather than concatenated into the query string. Prevents SQL injection. *Why you should care: This single practice prevents one of the most dangerous and common web vulnerabilities.*

**PII (Personally Identifiable Information):** Any data that can identify a specific person — name, email, phone number, address, IP address, government ID. *Why you should care: PII triggers privacy regulations (GDPR, CCPA). Collecting, storing, or leaking PII without proper handling can result in legal penalties and loss of user trust.*

**Pessimistic concurrency:** An approach where you lock the data before reading it, preventing anyone else from changing it until you're done. *Why you should care: It's the safe choice when conflicts are frequent or the stakes are high (money, inventory).*

**Prompt injection:** An attack where a user crafts input that tricks an AI model into ignoring its instructions and doing something unintended — the AI equivalent of SQL injection. *Why you should care: If your agent processes user input, a malicious user could override your instructions and make the agent leak data, bypass restrictions, or take unauthorized actions.*

**Prompt template:** A reusable set of instructions for an AI model, stored as a file and versioned like code. Variables (like the user's message or data to process) are inserted at runtime. *Why you should care: Prompts control your AI's behavior. Scattering them as inline strings across your codebase makes them impossible to manage, review, or test.*

**Race condition:** A bug where the outcome depends on the unpredictable timing of two or more operations. Like two people editing the same document — whoever saves last wins, and the other person's changes vanish. *Why you should care: Race conditions work fine in testing (single user) and fail mysteriously in production (many users). They're among the hardest bugs to find and fix.*

**Rate limiting:** Restricting how many requests a client can make in a given time period. *Why you should care: Without it, one abusive user or bot can overwhelm your server or run up your cloud bill.*

**RTO (Recovery Time Objective):** How quickly you need to recover after an outage. *Why you should care: It determines your backup, failover, and deployment strategy.*

**Postmortem:** A structured review after an incident — what happened, why, and how to prevent it from happening again. The focus is on improving the system, not blaming people. *Why you should care: Without postmortems, you fix the symptom but not the cause, and the same incident happens again.*

**Read replica:** A copy of your database that handles read queries while the primary database handles writes. *Why you should care: If your app reads much more than it writes (most do), replicas can dramatically improve performance.*

**RPO (Recovery Point Objective):** How much data you can afford to lose, measured in time. An RPO of 1 hour means you can lose up to 1 hour of data. *Why you should care: It determines your backup frequency.*

**Runbook:** A step-by-step guide for handling a specific type of incident, written when you're calm so you can follow it when things are on fire at 2 AM. *Why you should care: Under stress, people forget steps. A runbook makes incident response faster and more reliable.*

**Saga pattern:** A way to manage multi-step operations across services where each step can be compensated (undone) if a later step fails. *Why you should care: For complex workflows (like checkout: reserve inventory, charge payment, send confirmation), you need a strategy for partial failures.*

**SLA/SLO/SLI:** Service Level Agreement (contractual promise), Service Level Objective (internal target), Service Level Indicator (actual measurement). *Why you should care: These define what "reliable enough" means for your application and drive architecture decisions.*

**Screen reader:** Software that reads screen content aloud for people who are blind or have low vision. Common screen readers: VoiceOver (macOS/iOS), NVDA (Windows, free), TalkBack (Android). *Why you should care: Screen readers rely on semantic HTML to understand your page. If your code uses `<div>` for everything, the screen reader can't tell a button from a paragraph.*

**Semantic HTML:** Using HTML elements for their intended purpose — `<button>` for buttons, `<nav>` for navigation, `<h1>` for main headings — rather than styling generic `<div>` elements to look like them. *Why you should care: It's the foundation of accessibility, helps SEO, and makes your code more readable. AI agents frequently generate non-semantic HTML.*

**Sharding:** Splitting your database across multiple servers, with different data on each (e.g., users A–M on Server 1, users N–Z on Server 2). *Why you should care: Sharding is a last-resort scaling strategy. It adds enormous complexity and should only be considered after you've exhausted query optimization, connection pooling, caching, and read replicas.*

**Soft delete:** Marking a record as deleted (usually with a timestamp) instead of physically removing it. *Why you should care: It allows recovery of accidentally deleted data and maintains referential integrity with related records.*

**Stateless (application design):** The application doesn't store any data in its own process between requests. All state lives in external services (database, cache). *Why you should care: Stateless applications can scale horizontally — you can run multiple copies behind a load balancer.*

**Strangler Fig pattern:** A migration strategy where you gradually replace parts of an old system with new services, routing traffic incrementally until the old code can be removed. *Why you should care: It's the safest way to migrate from a monolith to services — no big-bang rewrite, no risky cutovers.*

**Structured output (AI):** Constraining an AI model to respond in a specific format (usually JSON with a defined schema) rather than free-form text. *Why you should care: When your code needs to parse the AI's response, structured output prevents malformed responses that crash your application.*

**Test pyramid:** A model for balancing different types of tests — many fast unit tests at the base, fewer integration tests in the middle, a handful of slow end-to-end tests at the top. *Why you should care: It keeps your test suite fast and maintainable while still catching bugs at every level.*

**Threat modeling:** Systematically thinking about what could go wrong with your application's security — who might attack it, how, and what you can do about it. *Why you should care: 30 minutes of structured thinking about threats can prevent months of incident response.*

**TLS (Transport Layer Security):** The protocol that provides HTTPS — encrypted communication between browsers and servers. *Why you should care: Without TLS, data (including passwords) travels in plain text that anyone on the network can read.*

**Token (AI):** The basic unit AI models use to process text — roughly a word or part of a word. AI services charge by the number of tokens processed (both input and output). *Why you should care: Tokens are how AI costs are measured. A long prompt or a verbose response costs more. Managing token usage is managing your AI budget.*

**Tool use / Function calling (AI):** A capability where an AI model can request to call specific functions or tools (search the web, query a database, send an email) rather than just generating text. The application executes the tool and returns the result to the model. *Why you should care: This is how AI agents interact with the real world. It's powerful but requires careful access control — an agent should only have access to the tools it actually needs.*

**Transaction (database):** A group of database operations that either all succeed or all fail together. *Why you should care: Without transactions, a crash in the middle of a multi-step operation leaves your data in a half-finished, inconsistent state.*

**Vertical scaling:** Using a bigger server (more CPU, more memory) to handle more load. *Why you should care: It's the simplest scaling strategy and is often the right first step before adding complexity with horizontal scaling.*

**Unit test:** A test that checks one small piece of your code in isolation — does this function return the right answer? Runs fast, no database or network needed. *Why you should care: Unit tests tell you exactly what broke and run in milliseconds, making them the fastest feedback loop for catching bugs.*

**Vendor lock-in:** When your application becomes so dependent on one cloud provider's specific services that switching to another would require significant rewriting. *Why you should care: Some lock-in is fine and the productivity tradeoff is worth it, but understanding the risk helps you make deliberate choices.*

**WCAG (Web Content Accessibility Guidelines):** The international standard for web accessibility. Level A is the minimum, Level AA is what most laws require and most organizations target, Level AAA is the highest. *Why you should care: WCAG AA is the benchmark. When someone says "is this accessible?" they usually mean "does it meet WCAG 2.1 Level AA?"*

**XSS (Cross-Site Scripting):** An attack where malicious JavaScript is injected into a web page and runs in other users' browsers. *Why you should care: It can steal user sessions, redirect users to malicious sites, and modify page content.*
