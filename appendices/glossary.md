# Glossary

Plain-English definitions of architectural terms. Each entry includes a brief "why you should care" note.

---

**API (Application Programming Interface):** A defined way for software to talk to other software. When your frontend shows data from your backend, it uses an API. *Why you should care: You're probably building one whether you realize it or not.*

**Authentication:** Proving who you are. Logging in with a username and password is authentication. *Why you should care: Without it, anyone can pretend to be anyone.*

**Authorization:** Determining what you're allowed to do after authentication. An admin can delete users; a regular user can't. *Why you should care: Authentication without authorization means every logged-in user has full access to everything.*

**Backpressure:** A mechanism that slows down producers when consumers can't keep up. Like a valve that reduces flow when the pipe is full. *Why you should care: Without it, a sudden surge of work can overwhelm your system and crash it.*

**Blue-green deployment:** Running two identical environments and switching traffic between them for zero-downtime deployments. *Why you should care: It lets you update your app without users experiencing downtime.*

**Bulkhead:** Isolating components so one failure doesn't bring everything down, like watertight compartments in a ship. *Why you should care: Without isolation, one slow database query can make your entire application unresponsive.*

**Cache:** A fast storage layer that keeps copies of frequently-accessed data. Like keeping important phone numbers on a sticky note instead of looking them up in a directory every time. *Why you should care: Caching can make your app 10-100x faster for common operations.*

**Cache invalidation:** The process of updating or removing cached data when the original data changes. *Why you should care: Stale cache means users see outdated information. Getting this wrong is one of the hardest problems in software.*

**Canary deployment:** Sending a small percentage of traffic to a new version to test it before rolling out to everyone. *Why you should care: It catches bugs before they affect all your users.*

**CDN (Content Delivery Network):** A network of servers around the world that serve your static files from the location closest to the user. *Why you should care: It makes your site load faster for users who are far from your server.*

**CI/CD (Continuous Integration / Continuous Deployment):** Automated processes that test your code and deploy it whenever you push changes. *Why you should care: It catches bugs before they reach users and eliminates manual deployment mistakes.*

**Circuit breaker:** A pattern that stops calling a failing service, giving it time to recover. Like an electrical breaker that trips to prevent a fire. *Why you should care: Without it, a failing external service can take your entire application down.*

**Connection pooling:** Maintaining a set of reusable database connections instead of creating a new one for each request. *Why you should care: Creating connections is slow. Pooling makes database operations significantly faster.*

**CORS (Cross-Origin Resource Sharing):** A browser security mechanism that controls which websites can make requests to your API. *Why you should care: Misconfigured CORS either blocks legitimate requests or allows malicious ones.*

**CQRS (Command Query Responsibility Segregation):** Separating the read side and write side of your application into different models. *Why you should care: You probably don't need it for most applications, but you might encounter it in recommendations. Use it only if you have very different read and write patterns at significant scale.*

**CRUD:** Create, Read, Update, Delete — the four basic operations for data. *Why you should care: Most web applications are fundamentally CRUD operations. Understanding this simplifies your design.*

**DDoS (Distributed Denial of Service):** An attack that overwhelms your servers with traffic to make them unavailable. *Why you should care: Rate limiting and CDNs help protect against this.*

**Encryption at rest:** Encrypting data while it's stored on disk. *Why you should care: If someone steals the hard drive or gains access to the raw storage, they can't read the data.*

**Encryption in transit:** Encrypting data while it's moving between systems (HTTPS/TLS). *Why you should care: Without it, anyone on the network path can read the data being transferred.*

**Eventual consistency:** A model where updates propagate gradually, and different parts of the system may briefly show different values. *Why you should care: When using caches or multiple databases, data might be briefly out of sync. Your UI needs to handle this gracefully.*

**Feature flag:** A configuration switch that enables or disables a feature without deploying new code. *Why you should care: You can deploy code to production safely and enable features gradually or disable them instantly if problems arise.*

**Foreign key:** A database column that references a row in another table, with the database enforcing that the reference is valid. *Why you should care: Without foreign keys, your database can accumulate broken references that cause mysterious bugs.*

**Horizontal scaling:** Adding more servers to handle more load. *Why you should care: It removes the ceiling on capacity, but requires your application to be stateless.*

**Idempotency:** An operation that produces the same result whether you execute it once or multiple times. *Why you should care: Networks are unreliable. Requests get retried. If creating an order isn't idempotent, a retry might create a duplicate order.*

**Index (database):** A data structure that speeds up queries by allowing the database to find rows without scanning the entire table. *Why you should care: A missing index on a large table can make a query 1000x slower.*

**JWT (JSON Web Token):** A self-contained token used for authentication that carries information (claims) and is cryptographically signed. *Why you should care: Common for API authentication. Important to understand the tradeoffs vs. sessions.*

**Load balancer:** A system that distributes incoming requests across multiple servers. *Why you should care: It enables horizontal scaling and provides redundancy if one server fails.*

**Migration (database):** A version-controlled script that changes the database schema. *Why you should care: Without migrations, database changes are manual, unreproducible, and can't be rolled back.*

**N+1 query problem:** A performance bug where loading a list of N items triggers N additional queries for related data, instead of loading everything in 1-2 queries. *Why you should care: It's the #1 cause of slow pages in web applications.*

**ORM (Object-Relational Mapping):** A library that lets you interact with the database using your programming language instead of writing SQL directly. Examples: Prisma, SQLAlchemy, Sequelize, Active Record. *Why you should care: ORMs speed up development but can hide performance problems. Understand what queries they generate.*

**Parameterized query:** A database query where user input is passed as separate parameters rather than concatenated into the query string. Prevents SQL injection. *Why you should care: This single practice prevents one of the most dangerous and common web vulnerabilities.*

**Rate limiting:** Restricting how many requests a client can make in a given time period. *Why you should care: Without it, one abusive user or bot can overwhelm your server or run up your cloud bill.*

**RTO (Recovery Time Objective):** How quickly you need to recover after an outage. *Why you should care: It determines your backup, failover, and deployment strategy.*

**RPO (Recovery Point Objective):** How much data you can afford to lose, measured in time. An RPO of 1 hour means you can lose up to 1 hour of data. *Why you should care: It determines your backup frequency.*

**Saga pattern:** A way to manage multi-step operations across services where each step can be compensated (undone) if a later step fails. *Why you should care: For complex workflows (like checkout: reserve inventory, charge payment, send confirmation), you need a strategy for partial failures.*

**SLA/SLO/SLI:** Service Level Agreement (contractual promise), Service Level Objective (internal target), Service Level Indicator (actual measurement). *Why you should care: These define what "reliable enough" means for your application and drive architecture decisions.*

**Soft delete:** Marking a record as deleted (usually with a timestamp) instead of physically removing it. *Why you should care: It allows recovery of accidentally deleted data and maintains referential integrity with related records.*

**Stateless (application design):** The application doesn't store any data in its own process between requests. All state lives in external services (database, cache). *Why you should care: Stateless applications can scale horizontally — you can run multiple copies behind a load balancer.*

**TLS (Transport Layer Security):** The protocol that provides HTTPS — encrypted communication between browsers and servers. *Why you should care: Without TLS, data (including passwords) travels in plain text that anyone on the network can read.*

**Transaction (database):** A group of database operations that either all succeed or all fail together. *Why you should care: Without transactions, a crash in the middle of a multi-step operation leaves your data in a half-finished, inconsistent state.*

**Vertical scaling:** Using a bigger server (more CPU, more memory) to handle more load. *Why you should care: It's the simplest scaling strategy and is often the right first step before adding complexity with horizontal scaling.*

**XSS (Cross-Site Scripting):** An attack where malicious JavaScript is injected into a web page and runs in other users' browsers. *Why you should care: It can steal user sessions, redirect users to malicious sites, and modify page content.*
