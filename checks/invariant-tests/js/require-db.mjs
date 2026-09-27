// Make database-backed tests fail loudly instead of skipping (VA TEST-021/TEST-022).
// `.va/check full` runs TEST_DB_CMD with VA_REQUIRE_DB=1. Call this from your DB test setup:
//   import { requireDb } from "./require-db.mjs";
//   const db = await requireDb(() => connect(process.env.DATABASE_URL));
// Without VA_REQUIRE_DB it returns null so local runs can skip; with it, a missing DB is a failure.
export async function requireDb(connect) {
  try {
    if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL is not set");
    return await connect();
  } catch (err) {
    if (process.env.VA_REQUIRE_DB === "1") {
      throw new Error(`database tests must run here but the database is unavailable: ${err.message}`);
    }
    console.warn(`\n  SKIPPING database tests: ${err.message}\n`);
    return null;
  }
}
