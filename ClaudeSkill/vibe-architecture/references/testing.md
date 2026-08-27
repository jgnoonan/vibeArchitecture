# Testing Rules

> Applies to: Shared tier and above.
> For detailed explanations: see `guides/testing/`

## Why Testing Matters

- Untested code is code you hope works. Tested code is code you know works. The difference matters most when real people depend on your application.
- Tests catch bugs before your users do. A bug found in testing costs minutes to fix. A bug found in production costs hours, reputation, and sometimes data.
- Tests make change safe. When you have tests, you can refactor, add features, and update dependencies with confidence. Without tests, every change is a gamble.

## What to Test

- **Business logic — always.** The rules and calculations that make your application do what it does. If a function decides pricing, calculates a score, validates eligibility, or processes a transaction, it needs tests.
- **Input validation — always.** Test that bad input is rejected and good input is accepted. Test boundary values (empty strings, zero, negative numbers, very long strings, special characters).
- **Error handling paths — always.** Test what happens when things go wrong: network failures, missing data, invalid states, permission denied. The unhappy path is where most production bugs live.
- **Security-relevant code — always.** Authentication, authorization, access control, data sanitization. If getting it wrong exposes user data, test it.
- **Database operations — for Shared tier and above.** Test that data is saved correctly, retrieved correctly, and that constraints work as expected.
- **API endpoints — for Public tier and above.** Test that your API returns the right status codes, correct data, and proper error responses.

## What NOT to Test

- Framework internals. Trust that React renders components, that Express routes requests, that Django processes forms. Test your code, not theirs.
- Trivial code with no logic. A function that returns a constant or a simple getter with no conditions doesn't need its own test.
- Visual layout details (unless you have visual regression tools). Pixel-perfect positioning changes constantly and creates brittle tests.

## Test Expectations by Tier

- **Shared:** Have tests for critical business logic. Running tests manually before deploying is acceptable.
- **Public:** Have tests for business logic and API endpoints. Tests should run automatically before deployment (CI pipeline).
- **Business:** Comprehensive test suite covering business logic, API endpoints, error handling, and database operations. Tests must run in CI. No deployment without passing tests. Add an automated accessibility gate in CI for user-facing UI (`@axe-core/playwright`, `jest-axe` / `vitest-axe`) that fails on new WCAG violations. Before launch, run a basic load test (k6, Locust) against a staging environment — verify the app survives expected peak concurrency and that rate limits behave under load.
- **Regulated:** Everything in Business, plus tests for compliance-relevant code paths (audit logging, access control, data handling). Document test coverage for auditors.

## When AI Writes Tests

AI-generated tests need careful review. Watch for:

- **Tests that test the implementation, not the behavior.** A test that checks "function X calls function Y" is brittle. A test that checks "when I place an order, the inventory decreases" is valuable. Tests should verify what the code does, not how it does it.
- **Tautological tests.** Tests that always pass because they test nothing meaningful. Example: asserting that a mock returns the value you told it to return.
- **Missing edge cases.** AI tends to test the happy path thoroughly but miss boundary conditions, error cases, and unusual inputs that require domain knowledge.
- **Unrealistic test data.** Test data should reflect real-world conditions. Testing with a single record when production has millions misses performance bugs.

Ask the AI to specifically generate tests for error cases and edge cases — it usually won't unless prompted.

## Silently Skipped Tests Read as Green

- A test suite that skips itself when infrastructure is missing — no database configured, no API key present, no network — looks exactly like a passing suite. Locally *and* in a misconfigured CI job, "all tests pass" can mean "the only meaningful tests never ran."
- Make skips loud: print a prominent skip count and reason, or fail outright when a suite that should run can't. Somewhere — locally against a real database, or in a CI job with the service available — the infrastructure-dependent tier must actually execute, and you must be able to tell that it did.
- After any schema, query, or storage-layer change, explicitly confirm the database-backed tests ran. This is the change class where the skipped tier hides real breakage.

## Reviewing an AI-Built Codebase

- Tests catch the bugs you thought to write tests for. At Business tier and above (or before any launch you care about), also run structured **adversarial review**: separate review passes, each hunting one failure class — authorization, concurrency, data durability, failure handling, privacy/metadata, accessibility — rather than one generic "find bugs" pass.
- Verify findings before believing them. AI reviewers produce plausible-sounding defects that don't survive being traced end-to-end against the source; expect a double-digit percentage of raw claims to dissolve under verification. An unverified finding list erodes trust and wastes fix time.
- A review is closed when every finding — LOW severity included — is fixed or explicitly closed with a written rationale. Findings that silently expire come back.
- For solo developers this substitutes for the pull-request review a team would have: no second human sees the code, so the adversarial pass is the second reviewer. See `guides/testing/adversarial-review.md` for the full method.

## Test Data

- Use factories or fixtures to generate test data. Hard-coded test data scattered across files becomes unmaintainable.
- Each test should set up its own data and clean up after itself. Tests must not depend on each other or on shared mutable state.
- Use an isolated test database. Never run tests against production data. Never run tests against a shared development database. [Testcontainers](https://testcontainers.com/) (Java, Go, Node, Python, .NET, and more) spins up a throwaway real database per test run when Docker is available.
- Keep test data realistic in shape and volume. If your production table has 100,000 rows, at least some tests should work with more than 5 rows.
