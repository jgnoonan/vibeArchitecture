# Integration Testing: Making Sure the Pieces Work Together

> For the compact rules, see `rules/testing.md`.

## What Is Integration Testing?

Unit tests check that individual functions work correctly in isolation. Integration tests check that those functions work correctly when they talk to real systems — your database, your API, external services.

Think of it this way: you can test that each gear in a clock works perfectly on its own, but you also need to test that they mesh together and the clock tells the right time.

## Testing Database Operations

Your application saves and retrieves data constantly. Integration tests verify that this actually works — that your queries return the right data, your migrations create the right tables, and your constraints catch invalid data.

### Use a Separate Test Database

Never run tests against your production database or even your development database. Tests create, modify, and delete data. You want a dedicated test database that can be wiped and rebuilt without anyone caring.

Most frameworks handle this automatically. Ask your AI: *"Is my test suite configured to use a separate test database? If not, set it up."*

### Test Containers

For more robust testing, "test containers" spin up a real database in a temporary Docker container just for your tests. When the tests finish, the container is destroyed. This gives you a completely fresh, isolated database every time.

This is the gold standard for integration testing, but it requires Docker to be installed. If you're not using Docker yet, a dedicated test database is perfectly fine.

### What to Test Against the Database

- **Saving and reading data:** Create a record, read it back, verify the fields match.
- **Constraints:** Try to save invalid data (missing required fields, duplicate unique values, invalid foreign keys). Verify the database rejects it.
- **Queries with conditions:** If you have a function that finds "all orders for this customer in the last 30 days," test it with various data combinations — including no matching records.
- **Migrations:** After running migrations, verify the schema is what you expect. This catches migration bugs before they hit production.

## Testing External Services

Your application probably talks to external services — payment processors, email providers, authentication services, third-party APIs. Testing against these real services in an automated test suite is problematic:

- They're slow (network calls take time)
- They're unreliable (the service might be down)
- They cost money (every API call to Stripe is real)
- They have side effects (you don't want to send real emails or charge real credit cards in a test)

### Mock External Services

A "mock" replaces a real service with a fake that you control. When your code calls the payment service, the mock intercepts the call and returns a response you've configured — without ever talking to the real service.

For example, instead of calling Stripe's API, your test tells the mock: "When someone tries to charge $50, return a success response." Then you test that your code handles the success correctly. In another test: "When someone tries to charge $50, return a card-declined error." Then you verify your code handles the failure correctly.

This lets you test every scenario — success, failure, timeout, unexpected responses — quickly and reliably.

### The Rule: Never Call Real External Services in Automated Tests

This is important enough to state as a rule. Automated tests that call real external services will:
- Fail randomly when the service is slow or down
- Run up bills on paid APIs
- Send real notifications to real people
- Create real records in external systems

Mock everything external. Test your code's behavior, not the external service's availability.

### When to Test Against Real Services

There is one exception: before a major release, it's valuable to manually verify that your integration with real services still works. APIs change, authentication tokens expire, endpoints get deprecated. A manual smoke test against the real service (in a sandbox or staging environment) catches these.

But this is manual verification, not part of your automated test suite.

## API Testing

If your application exposes an API (endpoints that other code calls), test those endpoints as a client would use them:

- **Send valid requests, check correct responses.** The right status code (200, 201), the right data format, the right content.
- **Send invalid requests, check proper rejection.** Missing fields should return 400, not 500. Unauthorized access should return 401 or 403, not a crash.
- **Test authentication.** Requests without credentials should be rejected. Requests with valid credentials should succeed. Requests with expired credentials should be rejected.
- **Test edge cases.** What happens with an empty list? A very large payload? Special characters in string fields? Pagination at the boundary (page 1, last page, page beyond the end)?

Most testing frameworks have built-in HTTP client tools that make API testing straightforward. Ask your AI: *"Help me write integration tests for my API endpoints."*

## Organizing Integration Tests

Integration tests are slower than unit tests because they use real databases, make HTTP calls, and set up more complex scenarios. Keep them organized:

- **Separate integration tests from unit tests.** Most test runners support tags or directory-based separation. This lets you run fast unit tests constantly and slower integration tests before deployment.
- **Clean up after each test.** Reset the database, clear any state. Tests should not leave artifacts that affect other tests.
- **Group related tests.** All tests for the user API in one file, all tests for the payment flow in another. This makes failures easy to locate.

## When to Write Integration Tests

Not everything needs an integration test. Focus on:

- **Database operations with business logic.** "Find the most popular products this week" involves queries, date logic, and sorting — test it against a real database.
- **API endpoints that your users or other services depend on.** If it's a public interface, test it.
- **Workflows that span multiple components.** "User creates an account, gets a welcome email, and appears in the admin dashboard" involves auth, email, and data — test the flow.
- **Anything that broke before.** If a bug made it to production, write an integration test that catches it. This prevents the same bug from happening twice.
