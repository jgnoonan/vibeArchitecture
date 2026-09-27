-- Fixtures for data.yaml (generic SQL rules).
CREATE TABLE orders (
  id uuid PRIMARY KEY,
  -- # ruleid: va-money-as-float-sql
  total_price double precision NOT NULL,
  -- # ok: va-money-as-float-sql
  total_cents bigint NOT NULL,
  -- # ok: va-money-as-float-sql
  subtotal numeric(12,2) NOT NULL,
  -- # ruleid: va-timestamp-without-time-zone
  created_at timestamp NOT NULL DEFAULT now(),
  -- # ok: va-timestamp-without-time-zone
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- # ok: va-timestamp-without-time-zone
  shipped_at timestamp with time zone
);
-- # ruleid: va-migration-blocking-index
CREATE INDEX orders_created_idx ON orders (created_at);
-- # ok: va-migration-blocking-index
CREATE INDEX CONCURRENTLY orders_updated_idx ON orders (updated_at);
-- # ruleid: va-migration-destructive-ddl
ALTER TABLE orders DROP COLUMN legacy_total;
-- # ok: va-migration-destructive-ddl
ALTER TABLE orders ADD COLUMN currency text NOT NULL DEFAULT 'USD';
