# Testing Strategy: Making Sure Your App Actually Works

> For the compact rules, see `rules/testing.md`.

## Why Test?

You've built something and it works on your machine. That's great — but "works on my machine" and "works reliably for real users" are very different things.

Testing is how you close that gap. A test is a small program that runs your code with specific inputs and checks that the output is what you expect. When you have tests, you can change your code and immediately know if you broke something. Without tests, you find out when a user reports it — or worse, when they quietly leave.

Think of tests like a safety net for a trapeze artist. The artist doesn't plan to fall, but the net means a mistake isn't a catastrophe.

## The Test Pyramid

Not all tests are created equal. There's a widely used model called the "test pyramid" that helps you decide what kind of tests to write and how many of each.

**Bottom of the pyramid — Unit tests (write the most of these):**
A unit test checks one small piece of your code in isolation. "Does this function calculate sales tax correctly?" "Does this validation reject an invalid email?" They run in milliseconds, don't need a database or network, and tell you exactly what broke.

**Middle of the pyramid — Integration tests (write a moderate number):**
An integration test checks that pieces work together. "When I save a user to the database, can I read them back?" "When I call this API endpoint, does it return the right data?" They're slower because they use real databases or services, but they catch problems that unit tests miss — like a mismatch between your code and your database schema.

**Top of the pyramid — End-to-end tests (write just a few):**
An end-to-end (E2E) test simulates a real user. "Can a user sign up, log in, create a project, and log out?" These are the slowest and most fragile, but they verify that the whole system works together. Write them for your most critical user journeys — the paths where failure would be most damaging.

The pyramid shape matters: lots of fast unit tests at the base, fewer integration tests in the middle, a handful of E2E tests at the top. If your pyramid is upside-down (mostly E2E tests, few unit tests), your test suite will be slow, flaky, and painful to maintain.

## What Should I Test First?

If you're starting from zero tests, don't try to test everything at once. Start with the code that matters most:

1. **The code that handles money.** Pricing calculations, payment processing, subscription logic. Getting this wrong costs real money.
2. **The code that controls access.** Login, permissions, "can this user see this data?" Getting this wrong exposes sensitive information.
3. **The code that validates input.** Form validation, API input checking. Getting this wrong lets bad data in.
4. **The code with complex logic.** Anything with multiple conditions, calculations, or state transitions. Simple code rarely has bugs; complex code almost always does.

You don't need 100% test coverage to get value. Even 20% coverage on the right code is dramatically better than 0%.

## Writing Good Tests

A good test has three parts (sometimes called "Arrange, Act, Assert"):

1. **Set up** — Create the conditions for the test (the input data, the starting state)
2. **Do the thing** — Call the function or action you're testing
3. **Check the result** — Verify the output is what you expected

Here's the pattern in plain language:

```
Given: a shopping cart with two items totaling $50
When: I apply a 10% discount code
Then: the total should be $45
```

### What makes a test bad?

**Testing implementation instead of behavior.** A test that checks "the function calls the database save method" is fragile — it breaks when you refactor the internals even if the behavior is unchanged. A test that checks "after saving, the user appears in the database" tests behavior and survives refactoring.

**Tests that depend on each other.** If Test B only passes when Test A runs first, you have a dependency. Tests should be independent — any test should pass when run alone, in any order.

**Tests that depend on timing.** "Wait 2 seconds, then check if the email was sent" is unreliable. The email might take 3 seconds on a slow day. Use deterministic checks instead of time-based waits.

**Tests with no assertions.** A test that runs code but never checks the result proves nothing. It passes even if the code is completely broken.

## When AI Writes Your Tests

If you're using AI to write tests (which is a great idea — it's one of the things AI does well), be aware of a few patterns:

**AI loves the happy path.** It will thoroughly test "user signs up successfully" but might skip "what happens when the email is already taken" or "what happens when the database is down." After the AI generates tests, ask it: *"Now write tests for the error cases and edge cases."*

**AI can write tests that test nothing.** A test that creates a mock, tells the mock to return a value, and then asserts the mock returned that value proves nothing about your code. Read through AI-generated tests and ask: "Would this test fail if my code had a bug?"

**AI mirrors your code structure.** If your code has a bug, AI might write a test that expects the buggy behavior. Tests should be written from the specification ("what should happen") not from the implementation ("what does happen").

**The best prompt for AI-generated tests:**
> *"Write tests for [this function/endpoint]. Include tests for: normal operation, invalid input, missing data, boundary values, and error conditions. Each test should have a clear name describing what it verifies."*

## Test Data

**Use realistic data, not just "test" and "1234".**
A test that creates a user named "test" with email "test@test.com" might pass, but it won't catch the bug where your code breaks on names with apostrophes (O'Brien) or emails with plus signs (user+tag@gmail.com).

**Each test creates its own data.**
Don't rely on data that another test created, or on data that's pre-loaded in the database. If that other test changes or the pre-loaded data is modified, your test breaks for reasons that have nothing to do with your code.

**Use a separate database for testing.**
Tests should never touch your real data. Most frameworks can be configured to use a separate test database that gets reset between test runs. If your AI set up the project, ask it: *"Is the test suite configured to use a separate test database?"*

## Running Tests

**Run tests before every deployment.**
The best setup: tests run automatically whenever you push code (this is called "continuous integration" or CI). Most hosting platforms and GitHub Actions can do this for free. Ask your AI: *"Set up a CI pipeline that runs tests before deployment."*

**Run tests locally before pushing.**
Don't wait for CI to tell you something is broken. Run the test suite on your machine first. It's faster and gives you a chance to fix problems before they're visible to anyone else.

**A failing test is not a nuisance — it's a gift.**
It means the test caught a problem before your users did. Fix the code, not the test (unless the test itself is wrong).

## How Much Testing Is Enough?

There's no magic number. But here are practical guidelines:

- **Personal projects:** Tests are optional but helpful for complex logic.
- **Shared projects:** Test the critical paths — anything where a bug would affect other people.
- **Public projects:** Test business logic, API endpoints, and input validation. Run tests in CI.
- **Business projects:** Comprehensive test suite. No deployment without passing tests. Test error handling and edge cases, not just the happy path.
- **Regulated projects:** Everything above, plus tests for compliance-relevant code. Document your test coverage for auditors.

The goal is not to reach a coverage number. The goal is confidence: "I can change this code and know quickly if I broke something."
