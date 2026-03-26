# Data Integrity — Why and How

> This guide explains why data integrity matters and how to protect it. Read it when you want to understand transactions, consistency, and why database constraints are essential.

## What Is Data Integrity?

Data integrity means your data is accurate, consistent, and trustworthy. When you look at a record, you can trust it reflects reality. When you update something, the update either happens completely or not at all — no half-finished operations leaving the database in a broken state.

The opposite of data integrity is corruption: orders referencing customers that don't exist, account balances that don't add up, duplicate records that shouldn't be there, and timestamps that make no sense. These problems are insidious because they often aren't noticed immediately. By the time you find them, you don't know how long the data has been wrong or how many decisions were made based on bad information.

## Transactions — All or Nothing

A transaction groups multiple database operations into a single unit that either completely succeeds or completely fails.

### Why You Need Them

Imagine transferring $100 between bank accounts:
1. Subtract $100 from Account A
2. Add $100 to Account B

If your application crashes between steps 1 and 2, $100 has vanished. Account A lost it, Account B never got it. A transaction ensures both steps happen together — if step 2 fails, step 1 is automatically undone.

This isn't just about banking. Any time you make multiple related changes, you need a transaction:
- Creating an order and reducing inventory
- Registering a user and creating their default settings
- Updating a record and writing an audit log entry

### The ACID Properties

Databases guarantee four properties for transactions (known as ACID):

- **Atomicity** — all operations in the transaction succeed, or none of them do. No partial results.
- **Consistency** — the transaction moves the database from one valid state to another. Constraints are enforced.
- **Isolation** — concurrent transactions don't interfere with each other. One transaction doesn't see another's incomplete work.
- **Durability** — once a transaction is committed (confirmed), the data survives even if the server crashes immediately after.

### Keep Transactions Short

While a transaction is active, it may lock the rows it's working on, preventing other operations from accessing them. A transaction that takes 30 seconds locks data for 30 seconds. Other users and processes wait, the application slows down, and timeouts cascade.

Rules of thumb:
- Do all your slow work (API calls, computations, file operations) BEFORE starting the transaction
- Inside the transaction: only database operations
- If a transaction takes more than a few seconds, redesign the approach

## Constraints — Your Last Line of Defense

Application code validates data before writing it to the database. But applications have bugs, APIs have edge cases, and developers make mistakes. Database constraints catch what code misses.

### NOT NULL

If a column should always have a value, mark it NOT NULL. Without this:
- A bug that fails to set a required field will silently create a row with NULL
- Code that reads the field will crash or behave unexpectedly
- Queries that filter on the field will miss NULL rows (NULL doesn't equal anything, not even itself)

### UNIQUE

Prevents duplicate values. Critical for:
- **Email addresses** — without UNIQUE, your system might create two accounts with the same email. Which one gets the password reset email?
- **Usernames** — if two users have the same username, which one is which?
- **External IDs** — if you store a Stripe customer ID, it must be unique to prevent billing confusion

### CHECK

Enforces rules on values. Examples:
- `CHECK (price > 0)` — prevents negative prices
- `CHECK (status IN ('active', 'inactive', 'suspended'))` — prevents invalid status values
- `CHECK (end_date >= start_date)` — prevents impossible date ranges
- `CHECK (quantity >= 0)` — prevents negative quantities

### Foreign Keys

Ensures references between tables are valid. If the `orders` table references `customer_id`, a foreign key guarantees that customer exists. Without it:
- Deleting a customer could leave orphaned orders pointing to nothing
- A bug could write an order with a nonexistent customer ID
- Queries joining the tables would silently drop rows with invalid references

## Soft Deletes vs. Hard Deletes

**Hard delete:** `DELETE FROM users WHERE id = 123` — the row is gone. Permanently.

**Soft delete:** `UPDATE users SET deleted_at = NOW() WHERE id = 123` — the row is marked as deleted but still exists.

### When to Use Soft Delete

- Data you might need to recover (user accounts, orders, content)
- Data subject to audit requirements (must show what existed and when it was removed)
- Data referenced by other records (deleting a user shouldn't break their historical orders)

### When to Use Hard Delete

- Temporary or ephemeral data (session records, temporary tokens)
- Data you're legally required to actually delete (GDPR right to erasure, in some interpretations)
- Data that accumulates volume with no retention value (old log entries, expired caches)

### Soft Delete Implementation Notes

- Add a `deleted_at` timestamp column (not a boolean — the timestamp tells you when)
- Add a default filter to all queries: `WHERE deleted_at IS NULL`
- Be aware: UNIQUE constraints on email/username need to account for soft-deleted rows. A common pattern is a partial unique index that only covers non-deleted rows
- Periodically hard-delete old soft-deleted records to manage table size

## Handling NULL

NULL means "no value" or "unknown." It's not the same as zero, empty string, or false. It has special behavior that causes bugs:

- `NULL = NULL` is not TRUE (it's NULL). You must use `IS NULL` instead of `= NULL`
- `NULL` in arithmetic produces NULL: `5 + NULL = NULL`
- Aggregate functions (COUNT, SUM, AVG) typically skip NULL values, which can give surprising results
- Sorting: NULLs may sort first or last depending on the database

**The rule:** Only allow NULL when "no value" is a meaningful, expected state. A user's middle name can legitimately be NULL. An order's total price should not be.

## Consistency Patterns

### Strong Consistency

Every read returns the most recently written value. After you update a record, the next read — from anywhere — sees the update.

**When you must have it:** Financial balances, inventory counts, anything where stale data causes incorrect decisions.

**The cost:** Stronger consistency typically means slower writes (the database must confirm the write is visible everywhere before acknowledging it).

### Eventual Consistency

After an update, different parts of the system may briefly see different values, but they all converge to the same value eventually (usually within milliseconds to seconds).

**When it's acceptable:** Social media feeds, analytics dashboards, recommendation systems, search indexes — anywhere a brief delay is tolerable.

**The cost:** Simpler to implement, better performance, but you must design your UI to handle the possibility that data is momentarily stale.

### Practical Advice

For most applications running a single database, you already have strong consistency. Eventual consistency becomes relevant when you introduce caching, read replicas, or multiple services with their own databases. Don't introduce complexity to solve a consistency problem you don't have.
