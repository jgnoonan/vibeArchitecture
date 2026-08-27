# Data Rules

> Applies to: Shared tier and above.
> For detailed explanations: see `guides/data/`

## Database Choice

- Default to PostgreSQL unless you have a specific reason for something else. It handles most use cases, is well-documented, and every major cloud provider offers a managed version.
- For simpler projects on a single server, SQLite is fine. Know its limits: one writer at a time, no network access from multiple machines. Hosted/replicated SQLite now exists (Turso/libSQL, LiteFS, Cloudflare D1) and removes the single-machine limit, but not the single-writer model.
- Use a managed database (where the hosting provider handles backups, updates, and failover) over self-hosting whenever possible. The operational burden of running a database yourself is significant.

## Schema Design

- Use a migration tool to manage all schema changes. Never modify database structure by hand in production. Migrations give you a versioned, repeatable, reviewable history of every structural change.
- Define foreign keys between related tables. They enforce relationships at the database level — if a bug tries to create an order for a nonexistent user, the database catches it.
- Add NOT NULL constraints to columns that must always have a value. Don't rely on application code alone to enforce this.
- Add UNIQUE constraints where duplicates shouldn't exist (email addresses, usernames, external IDs).
- Use CHECK constraints for value validation (status must be one of a defined set, quantity must be positive, etc.).
- Pick consistent naming conventions and use them everywhere. Recommended: `snake_case` for tables and columns, plural table names (`users`, `orders`).
- Default primary key: UUIDv7 (RFC 9562; native `uuidv7()` in Postgres 18, libraries elsewhere). It is time-ordered, so it indexes like a sequence; random UUIDv4 keys fragment B-tree indexes. Auto-increment integers remain fine for internal-only tables.
- Store timestamps as `timestamptz` (in Postgres) in UTC and convert at display time. The one exception is a *future local-time* event ("9 AM on March 3 in Europe/Berlin"): store the local wall time plus the IANA zone name, because the UTC offset can change before the event happens.
- Never store money in floating-point. Use `NUMERIC`, or an integer count of minor units with the currency code stored alongside — and honor the currency's exponent (USD 2, JPY 0, KWD 3). See `guides/data/schema-design.md`.

## Multi-Tenancy

- If one database serves many customers, every tenant-owned table carries a `tenant_id` and every query filters on it — sourced from the authenticated session, never from the request (see `rules/security.md`). Add `tenant_id` to composite indexes and unique constraints.
- Enforce isolation in the database, not only in application code: Postgres Row-Level Security policies keyed on a session variable turn a forgotten `WHERE tenant_id` into an empty result instead of a data leak.
- Shared database with `tenant_id` is the default. Move a tenant to its own schema or database only for a contractual, regulatory, or noisy-neighbor reason. See `guides/data/schema-design.md`.

## Indexes

- Add indexes on columns you frequently filter, sort, or join on. Without them, the database scans every row to answer a query — fine with 100 rows, catastrophic with 100,000.
- Don't index every column. Each index slows down inserts and updates and uses storage. Add them based on actual query patterns.
- For queries filtering on multiple columns together, use a composite index. Column order matters: put equality-filtered columns (`=`) before range-filtered columns (`>`, `<`, `BETWEEN`, `ORDER BY`), because the index is only usable up to the first range column. The index also serves queries on any left prefix of its columns; for two equality predicates either order works.
- Use partial indexes for low-cardinality or status columns (`CREATE INDEX ... WHERE status = 'pending'`). A full index on a 3-value column is mostly useless; an index over only the rows you actually query is small and fast.
- Verify indexes are working. Use your database's EXPLAIN or query plan tool to confirm queries use the indexes you've added.

## Data Integrity

- Use transactions for any operation involving multiple related writes. If step 3 of 5 fails, steps 1 and 2 must be rolled back — not left in a half-finished state.
- Keep transactions short. Long-running transactions lock data and slow down every other operation waiting for that data.
- Validate data in your application AND in the database. Application validation provides good user-facing error messages. Database constraints catch bugs your application code misses.
- Be deliberate about NULL. Only allow it when "no value" is meaningful and expected. Unintentional NULLs cause subtle bugs that are hard to track down.

## Backups

- Automate backups. A backup process that depends on someone remembering to run it will eventually be forgotten.
- Test your restores. Run a test restore at least once, then quarterly. A backup you've never restored from is a backup you don't know works.
- Enable point-in-time recovery if your database supports it (most managed databases do). This lets you restore to any moment, not just the last backup.
- Store backups in a different location than the database. If the server is lost, the backups must survive.

## Sensitive Data

- Enable encryption at rest. Most managed databases offer this — turn it on.
- Know where sensitive data lives. Track which tables and columns contain personal, financial, or other protected information.
- Don't log sensitive data. Query logs, application logs, and error reports must not contain passwords, credit card numbers, SSNs, or health information.
- When deleting sensitive data, confirm it's actually gone — not just soft-deleted and still queryable, not sitting in retained backups indefinitely. A soft-delete flag does NOT satisfy a user's deletion request. If you store personal data about real people, see `rules/privacy.md` for data-subject deletion and retention obligations.
- At Business tier, consider envelope encryption via your platform's KMS for high-sensitivity fields you must store (government IDs, third-party access tokens). Whole-database encryption at rest protects against stolen disks; field-level encryption also protects against leaked backups and over-broad query access. See `rules/compliance.md` for the full Regulated-tier treatment.

## Migrations

- Treat applied migrations as immutable. Never edit or delete a migration that has already run somewhere — write a new migration to fix a mistake.
- In production, prefer to **roll forward**, not down. Recovering by writing a new corrective migration is safer than running a `down` against live data (down-migrations that drop columns/tables destroy data). Write reversible `down` logic for local and CI use, but don't rely on reverting production.
- Make schema changes backward-compatible when possible. The expand-and-contract pattern: add the new column → deploy code that writes to both old and new → migrate existing data → deploy code that reads only the new column → drop the old column. This is what lets you deploy without downtime.
- Test migrations against realistic data volumes. A migration that takes 2 seconds on a test database can lock a production table for 20 minutes.
- Use the non-blocking form of every DDL statement in production (Postgres): `CREATE INDEX CONCURRENTLY`; `ADD CONSTRAINT ... NOT VALID` then `VALIDATE CONSTRAINT`; add `NOT NULL` via a `CHECK (col IS NOT NULL) NOT VALID` + validate, then `SET NOT NULL` (Postgres 12+ skips the rescan); and set `lock_timeout` (e.g., 5 seconds) so a migration that can't get its lock fails fast instead of queueing behind — and blocking — live traffic. See `guides/data/schema-design.md`.
- Run migrations as a separate deploy step, never at application startup; guard DDL that a later migration renames or drops (conditional checks / DO-blocks) so re-runs are safe; add a "migrate twice" CI test (full chain, then again, fail on any error). See `guides/data/schema-design.md` (Migration Runners and Re-runs).
- If more than one application instance can start at once, wrap the migration run in a database advisory lock (or your platform's equivalent). Two instances racing the same migration corrupt state or crash-loop together.
