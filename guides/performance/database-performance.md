# Database Performance — Why and How

> This guide explains database performance concepts and optimization strategies. Read it when queries are slow, when you're designing your schema, or when you want to understand indexing.

## The First Rule: Measure, Don't Guess

The bottleneck is almost never where you think it is. Before optimizing anything:

1. **Identify which queries are slow.** Most databases and ORMs can log slow queries. Enable this.
2. **Understand why they're slow.** Use EXPLAIN / query plan analysis (covered below).
3. **Fix the specific problem.** Don't add indexes everywhere hoping one will help.

## How Indexes Work

### The Analogy

Imagine a textbook with no index. To find every mention of "photosynthesis," you'd read every page. That's a **full table scan** — the database reads every row to find matches.

Now imagine the textbook has an index in the back: "Photosynthesis: pages 12, 47, 89, 156." You go directly to those pages. That's a **database index** — a separate data structure that tells the database exactly where to find matching rows.

### What Indexes Do

An index is a sorted copy of specific columns with pointers back to the full rows. When you query with a WHERE clause, the database checks the index first (fast lookup in a sorted structure) instead of scanning every row (slow for large tables).

### When to Add Indexes

Add an index when:
- A query filters on a column (WHERE clause) and the table has more than a few thousand rows
- A query sorts by a column (ORDER BY) and the table is large
- A query joins tables on a column
- You've verified with EXPLAIN that the query is doing a full table scan

### When NOT to Add Indexes

- **On every column "just in case."** Each index consumes storage and slows down INSERT, UPDATE, and DELETE operations because the index must be updated too.
- **On small tables.** A table with 100 rows doesn't need indexes — scanning 100 rows is nearly instant.
- **On columns that are rarely queried.** An index no query uses is pure overhead.
- **On columns with very few distinct values.** An index on a boolean column (true/false) or a status column with 3 possible values provides little benefit — the database still has to read a large percentage of the table.

### Composite Indexes

A composite index covers multiple columns. Column order matters.

For a query like `WHERE country = 'US' AND city = 'Denver'`:
- Index on `(country, city)` — effective. The database finds US first (narrowing the search), then Denver within US.
- Index on `(city, country)` — less effective. Finding Denver first narrows less (many countries have a Denver-equivalent).

**Rule of thumb:** Put the most selective column (the one with the most distinct values) first.

### Covering Indexes

A "covering index" includes all the columns a query needs. The database can answer the query entirely from the index without looking at the actual table row. This is the fastest possible query.

## EXPLAIN — Your Best Friend

Every major database has an EXPLAIN command that shows how it plans to execute a query.

### What to Look For

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123 AND status = 'active';
```

Key things in the output:
- **Seq Scan** (Sequential Scan): The database is reading every row. For large tables, this is usually the problem. Adding an index on the filtered columns typically fixes it.
- **Index Scan** or **Index Only Scan**: The database is using an index. This is what you want.
- **Rows:** How many rows the database estimated vs. actually processed. A large number here on a query you expect to return a few rows indicates a missing index.
- **Actual Time:** How long each step took. The slowest step is your bottleneck.

### A Practical Workflow

1. Find a slow query (from logs or user complaints)
2. Run EXPLAIN ANALYZE on it
3. Look for Seq Scans on large tables
4. Add an index on the columns being filtered
5. Run EXPLAIN ANALYZE again to confirm the index is used
6. Measure the query time improvement

## The N+1 Query Problem

The single most common performance bug in web applications.

### What It Looks Like

You want to display 50 blog posts with their authors:

```
Query 1: SELECT * FROM posts LIMIT 50        (1 query)
Query 2: SELECT * FROM users WHERE id = 1    (for post 1's author)
Query 3: SELECT * FROM users WHERE id = 2    (for post 2's author)
...
Query 51: SELECT * FROM users WHERE id = 50  (for post 50's author)
```

That's 51 queries to display one page. Each query has network overhead, parsing overhead, and execution time. With 50 posts, it's slow. With 500 posts, it's unusable.

### The Fix

**Eager loading / JOIN:**
```sql
SELECT posts.*, users.name as author_name
FROM posts
JOIN users ON posts.user_id = users.id
LIMIT 50;
```
One query instead of 51.

**Batch loading (WHERE IN):**
```sql
SELECT * FROM posts LIMIT 50;
SELECT * FROM users WHERE id IN (1, 2, 3, ..., 50);
```
Two queries instead of 51.

### How to Detect N+1 in ORMs

Most ORMs (Sequelize, SQLAlchemy, Active Record, Prisma) make N+1 easy to create accidentally because lazy loading is often the default. Tools to detect it:
- Enable query logging and count the queries per request
- Use N+1 detection libraries (e.g., `bullet` for Rails, `nplusone` for Python)
- Watch for patterns in your logs: many similar queries in rapid succession

## Connection Pooling

### Why It Matters

Creating a database connection is expensive — it involves network handshaking, authentication, and memory allocation. If every request opens and closes a connection, that overhead adds up fast.

A connection pool maintains a set of pre-established connections. When your code needs a database connection, it borrows one from the pool. When it's done, it returns it. No connection setup overhead.

### Pool Sizing

**Too small:** Requests queue up waiting for a connection. Latency increases under load.
**Too large:** Each connection consumes memory on the database server. Too many connections can actually degrade database performance.

**Starting point:** 5–20 connections for most web applications. Adjust based on:
- How many concurrent requests your app handles
- How long database operations typically take
- What your database can handle (PostgreSQL default max is 100)

**Formula (rough guideline):** pool_size = (number_of_app_instances × connections_per_instance) should be well under the database's max_connections setting.

### Tools

- **Built-in:** Most ORMs and database drivers have connection pooling built in. Configure it intentionally.
- **External pooler:** PgBouncer (for PostgreSQL) sits between your app and database, managing connections efficiently. Useful when you have many app instances or serverless functions.

## Common Query Anti-Patterns

### SELECT *

Retrieves all columns when you might only need two or three. Wastes network bandwidth, memory, and CPU time deserializing unused data.

**Fix:** List only the columns you need: `SELECT id, name, email FROM users`

### Functions in WHERE Clauses

```sql
SELECT * FROM orders WHERE YEAR(created_at) = 2024
```

This applies the YEAR() function to every row before comparing, which prevents index usage.

**Fix:** Use a range condition:
```sql
SELECT * FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'
```

### Missing LIMIT

```sql
SELECT * FROM logs WHERE level = 'error'
```

If there are a million error logs, this returns all of them.

**Fix:** Always include a LIMIT for queries that return lists: `LIMIT 100` or use pagination.

### Large IN Clauses

```sql
SELECT * FROM products WHERE id IN (1, 2, 3, ..., 10000)
```

Beyond a few hundred values, this becomes slow. Consider a temporary table or a JOIN instead.

## Write Performance

### Batch Inserts

Inserting 1,000 rows one at a time means 1,000 round trips to the database. A batch insert does it in one:

```sql
INSERT INTO items (name, price) VALUES
  ('Widget', 9.99),
  ('Gadget', 19.99),
  ('Doohickey', 4.99),
  ...;
```

Most ORMs support batch operations. Use them for bulk data loading.

### Transaction Size

Large transactions (updating millions of rows in one transaction) hold locks for a long time, blocking other operations. Break large updates into smaller batches:
- Update 1,000 rows at a time
- Commit after each batch
- Add a small delay between batches if the system is under load
