# Data Rules

> Applies to: Shared tier and above.
> For detailed explanations: see `guides/data/`

## Database Choice

- Default to PostgreSQL unless you have a specific reason for something else. It handles most use cases, is well-documented, and every major cloud provider offers a managed version.
- For simpler projects on a single server, SQLite is fine. Know its limits: one writer at a time, no network access from multiple machines.
- Use a managed database (where the hosting provider handles backups, updates, and failover) over self-hosting whenever possible. The operational burden of running a database yourself is significant.

## Schema Design

- Use a migration tool to manage all schema changes. Never modify database structure by hand in production. Migrations give you a versioned, repeatable, reviewable history of every structural change.
- Define foreign keys between related tables. They enforce relationships at the database level — if a bug tries to create an order for a nonexistent user, the database catches it.
- Add NOT NULL constraints to columns that must always have a value. Don't rely on application code alone to enforce this.
- Add UNIQUE constraints where duplicates shouldn't exist (email addresses, usernames, external IDs).
- Use CHECK constraints for value validation (status must be one of a defined set, quantity must be positive, etc.).
- Pick consistent naming conventions and use them everywhere. Recommended: `snake_case` for tables and columns, plural table names (`users`, `orders`).

## Indexes

- Add indexes on columns you frequently filter, sort, or join on. Without them, the database scans every row to answer a query — fine with 100 rows, catastrophic with 100,000.
- Don't index every column. Each index slows down inserts and updates and uses storage. Add them based on actual query patterns.
- For queries filtering on multiple columns together, use a composite index. Column order matters — put the most selective (most unique values) column first.
- Verify indexes are working. Use your database's EXPLAIN or query plan tool to confirm queries use the indexes you've added.

## Data Integrity

- Use transactions for any operation involving multiple related writes. If step 3 of 5 fails, steps 1 and 2 must be rolled back — not left in a half-finished state.
- Keep transactions short. Long-running transactions lock data and slow down every other operation waiting for that data.
- Validate data in your application AND in the database. Application validation provides good user-facing error messages. Database constraints catch bugs your application code misses.
- Be deliberate about NULL. Only allow it when "no value" is meaningful and expected. Unintentional NULLs cause subtle bugs that are hard to track down.

## Backups

- Automate backups. A backup process that depends on someone remembering to run it will eventually be forgotten.
- Test your restores. Run a test restore at least once. A backup you've never restored from is a backup you don't know works.
- Enable point-in-time recovery if your database supports it (most managed databases do). This lets you restore to any moment, not just the last backup.
- Store backups in a different location than the database. If the server is lost, the backups must survive.

## Sensitive Data

- Enable encryption at rest. Most managed databases offer this — turn it on.
- Know where sensitive data lives. Track which tables and columns contain personal, financial, or other protected information.
- Don't log sensitive data. Query logs, application logs, and error reports must not contain passwords, credit card numbers, SSNs, or health information.
- When deleting sensitive data, confirm it's actually gone — not just soft-deleted and still queryable, not sitting in retained backups indefinitely.

## Migrations

- Migrations are forward-only. Write a new migration to fix a mistake. Never edit or delete a migration that has been applied.
- Make schema changes backward-compatible when possible. The expand-and-contract pattern: add the new column → deploy code that writes to both old and new → migrate existing data → deploy code that reads only the new column → drop the old column.
- Test migrations against realistic data volumes. A migration that takes 2 seconds on a test database can lock a production table for 20 minutes.
- Include both "up" (apply) and "down" (revert) logic in every migration, even if you hope never to revert.
