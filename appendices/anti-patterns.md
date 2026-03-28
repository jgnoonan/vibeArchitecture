# Anti-Patterns — A Gallery of Things That Go Wrong

> Common mistakes found in AI-generated code and vibe-coded projects. For each: what it looks like, why it's bad, and what to do instead.

---

## Security Anti-Patterns

### Hardcoded Secrets

**What it looks like:**
```javascript
const API_KEY = "sk_live_abc123def456";
const DB_PASSWORD = "supersecret123";
```

**Why it's bad:** Anyone who can see your code (team members, GitHub users, attackers who breach your repo) has your credentials. Bots actively scan GitHub for API keys and exploit them within minutes.

**Do this instead:** Use environment variables loaded from a `.env` file (which is in `.gitignore`). See `guides/security/secrets-management.md`.

---

### API Keys in Frontend Code

**What it looks like:** A secret API key embedded in JavaScript that runs in the browser.

**Why it's bad:** Every user can view browser source code. Your secret key is not secret — it's published to the world.

**Do this instead:** Keep secret keys on the server. If the frontend needs to call an external service, route it through your backend API.

---

### SQL String Concatenation

**What it looks like:**
```python
query = "SELECT * FROM users WHERE email = '" + user_input + "'"
```

**Why it's bad:** A user can enter `'; DROP TABLE users; --` and delete your entire database. This is SQL injection, and it's been the #1 web vulnerability for over two decades.

**Do this instead:** Use parameterized queries: `"SELECT * FROM users WHERE email = ?"` with the input as a parameter. Or use an ORM.

---

### JWT in localStorage

**What it looks like:** Storing an authentication token in the browser's localStorage.

**Why it's bad:** Any JavaScript running on your page can read localStorage — including scripts injected through an XSS vulnerability. An attacker steals the token and has full access to the user's account.

**Do this instead:** Use httpOnly cookies. The browser sends them automatically, and JavaScript can't access them.

---

### CORS Wildcard with Credentials

**What it looks like:** `Access-Control-Allow-Origin: *` on an API that uses cookies or tokens.

**Why it's bad:** Any website can make authenticated requests to your API on behalf of your users.

**Do this instead:** List specific allowed origins. Never use `*` with credentials.

---

## Data Anti-Patterns

### No Foreign Keys

**What it looks like:** Tables reference each other by ID, but no foreign key constraints exist in the database.

**Why it's bad:** Data integrity depends entirely on application code being bug-free. Spoiler: it won't be. You'll end up with orders referencing deleted customers, comments on nonexistent posts, and orphaned records everywhere.

**Do this instead:** Define foreign keys. Let the database enforce relationships.

---

### No Database Migrations

**What it looks like:** Schema changes made by running SQL commands directly against the database, or by modifying the database through a GUI tool.

**Why it's bad:** No record of what changed or when. Can't reproduce the schema in another environment. Can't roll back. Other developers don't know about the changes. Deployment doesn't include schema updates.

**Do this instead:** Use migration tools (Prisma Migrate, Alembic, Knex migrations, Flyway, etc.). Every schema change is a versioned, committed, reproducible script.

---

### The Giant JSON Column

**What it looks like:** Storing complex structured data as a single JSON blob instead of in properly designed relational tables.

**Why it's bad:** You can't query efficiently inside JSON (or at all, depending on the database). No referential integrity. No constraints. No indexing on nested fields. Reporting becomes nightmarish.

**When it's actually OK:** Storing truly flexible metadata, user preferences, or configuration that varies per record and doesn't need to be queried directly.

**Do this instead:** Design relational tables for structured data. Use JSON columns only for genuinely unstructured or highly variable data.

---

### No Data Validation at the Database Level

**What it looks like:** All validation is in application code. The database accepts anything.

**Why it's bad:** Application bugs can write invalid data. Direct database access (migrations, scripts, admin tools) bypasses application validation. Over time, the database fills with inconsistent data.

**Do this instead:** Use NOT NULL, UNIQUE, CHECK, and FOREIGN KEY constraints. Application validation AND database constraints — belt and suspenders.

---

## Infrastructure Anti-Patterns

### ClickOps

**What it looks like:** Creating and configuring cloud resources by clicking through the web console.

**Why it's bad:** Not reproducible, not reviewable, not auditable. You can't deploy a second environment. You can't roll back. You can't explain what changed or when.

**Do this instead:** Define infrastructure in code (Terraform, Pulumi, CDK) or at minimum use your platform's configuration files.

---

### No Backup Strategy

**What it looks like:** The database exists and data is being stored, but nobody has thought about backups.

**Why it's bad:** When (not if) data is lost — accidental deletion, corruption, ransomware, hardware failure — there is no recovery. The business loses everything.

**Do this instead:** Enable automated backups. Test a restore. Know your recovery time.

---

### Running Databases on Compute Instances

**What it looks like:** Installing PostgreSQL or MySQL directly on an EC2 instance or VPS.

**Why it's bad:** You're now responsible for backups, updates, failover, security patching, performance tuning, disk management, and replication. That's a full-time job.

**Do this instead:** Use a managed database (RDS, Cloud SQL, PlanetScale, Supabase, etc.). Let the provider handle operations.

---

### Production Debug Mode

**What it looks like:** The application is deployed with `DEBUG=true`, `NODE_ENV=development`, or equivalent.

**Why it's bad:** Debug mode shows detailed error messages (with file paths, stack traces, database queries) to every user. This is a roadmap for attackers. It also disables performance optimizations and may expose debug endpoints.

**Do this instead:** Set production mode in your deployment environment variables. Test that error pages show user-friendly messages.

---

## Design Anti-Patterns

### Premature Microservices

**What it looks like:** A two-person team building an application with 8 separate services, a message queue, an API gateway, and a service mesh.

**Why it's bad:** Microservices solve problems of large teams working on large systems. For small teams, they add enormous complexity: network communication, distributed debugging, deployment coordination, data consistency. You've traded simple in-process function calls for unreliable network requests.

**Do this instead:** Start with a monolith. Decompose into services only when you have a specific problem that requires it (independent scaling, independent deployment by separate teams).

---

### Cargo Cult Architecture

**What it looks like:** Using Kafka for 10 messages per minute. Running Kubernetes for 2 containers. Implementing CQRS for a CRUD app. Choosing the technology because Netflix/Google/Amazon uses it.

**Why it's bad:** Technologies built for planet-scale problems add enormous complexity to normal-scale applications. You pay the operational cost without the benefits.

**Do this instead:** Choose boring technology. PostgreSQL, a simple queue (SQS, Redis), a basic deployment platform. Use the advanced stuff when you've outgrown the simple stuff.

---

### No Error Handling

**What it looks like:** The happy path works great. Any unexpected input, network failure, or edge case crashes the application or shows a raw error page.

**Why it's bad:** In production, the unhappy path happens constantly. Users enter unexpected data. Services go down. Networks hiccup. An application without error handling is an application that's always partially broken.

**Do this instead:** Wrap external calls in try/catch. Validate input at boundaries. Return helpful error messages. Log the technical details. Show the user a friendly error page.

---

### Trusting the Client

**What it looks like:** Security checks only in the frontend. Hiding admin buttons but not protecting admin API endpoints. Relying on JavaScript to validate input without server-side validation.

**Why it's bad:** Anyone can bypass the frontend by making direct API calls. Every browser has developer tools that let users modify requests. Client-side security is UX, not security.

**Do this instead:** All security checks on the server. Client-side validation is for user convenience only.

---

## Concurrency Anti-Patterns

### Ignoring Concurrent Access

**What it looks like:** Two users buy the last item in stock. The code reads "1 in stock," processes both purchases, and writes "0 in stock." You've sold an item you don't have.

**Why it's bad:** Code that works perfectly with one user at a time silently produces wrong results under real-world load. These bugs are intermittent and extremely hard to reproduce — they depend on exact timing.

**Do this instead:** Use database transactions with proper locking (`SELECT ... FOR UPDATE`) or optimistic concurrency (version numbers on rows). Any time two operations can touch the same data simultaneously, you need a concurrency strategy.

---

### Writing to Files Without Locking

**What it looks like:** Multiple processes or AI agents write to the same configuration file, log file, or data file without coordination. Intermittent data corruption, missing entries, or garbled content.

**Why it's bad:** Operating systems don't lock files for you. Two processes writing to the same file at the same time can interleave their writes, producing corrupted data. A crash mid-write can leave a half-written file.

**Do this instead:** Use file locks, write to a temporary file and rename atomically, or use a database for shared state instead of files. If you must share files, coordinate through a single writer process.

---

### Holding Locks During External Calls

**What it looks like:** Acquire a lock, call an API that takes 5 seconds, release the lock. Every other thread that needs that lock waits 5 seconds.

**Why it's bad:** The lock duration is now controlled by the external service, not your code. If the API is slow or hangs, the lock is held indefinitely. Everything that depends on that resource freezes.

**Do this instead:** Fetch data from the external service first (no lock). Then acquire the lock, update the shared resource with the fetched data, and release immediately. Minimize the time any lock is held.

---

### Non-Idempotent Retries

**What it looks like:** A payment request times out. Did it go through? The code retries. Now the customer is charged twice.

**Why it's bad:** Network timeouts don't tell you whether the operation succeeded or failed — only that you didn't get a response in time. Blindly retrying a non-idempotent operation can duplicate it.

**Do this instead:** Assign a unique idempotency key to each operation. Include it in the request. The receiving system checks if it's already processed that key and returns the original result instead of processing again. All payment APIs support this — use it.

---

### Global Mutable State

**What it looks like:** A module-level variable (like a counter, cache, or config object) that gets read and written by every request handler without synchronization.

**Why it's bad:** Web frameworks handle requests concurrently. Multiple threads writing to a shared variable without locks produces incorrect values, corrupted data structures, or crashes. The bugs are timing-dependent and appear randomly.

**Do this instead:** Use thread-safe data structures (concurrent maps, atomic counters), request-scoped state, or proper synchronization (mutexes). Better yet, keep state in a database or cache service designed for concurrent access.
