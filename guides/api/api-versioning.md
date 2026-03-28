# API Versioning: Changing Your API Without Breaking Everything

> For the compact rules, see `rules/api.md`.

## Why Versioning Matters

Imagine you run a restaurant and you change the menu. Easy — print new menus. Now imagine 500 delivery apps have your old menu hardcoded into their systems. You change the name of a dish and suddenly orders are failing everywhere.

That's what happens when you change an API that other software depends on. If your API has clients (mobile apps, other services, third-party integrations), changing it carelessly will break those clients. API versioning is how you make changes without breaking existing users.

## Do You Need Versioning?

**You probably DON'T need formal versioning if:**
- You control all the clients (your own frontend talks to your own backend, and they deploy together)
- Nobody else calls your API
- You can update all clients immediately when the API changes

**You probably DO need versioning if:**
- Mobile apps call your API (you can't force users to update their app immediately)
- Third parties integrate with your API
- Multiple separate applications depend on your API
- Your frontend and backend deploy independently

If you're unsure, design your API to be versionable (it's easy) even if you don't actively use versions yet.

## Versioning Strategies

There are three common approaches. Each has tradeoffs.

### 1. URL Path Versioning (Recommended for Most Projects)

Put the version in the URL:
```
/api/v1/users
/api/v2/users
```

**Pros:**
- Obvious and visible — anyone looking at the URL knows which version they're using
- Easy to implement in any framework (route `/api/v1/*` to one set of handlers, `/api/v2/*` to another)
- Easy to test (just change the URL)
- Easy for your AI to implement

**Cons:**
- Technically, the URL represents a resource, not a version of a resource (purists object)
- Can lead to a lot of duplicated code if you have many versions

**This is the right choice for most applications.** It's the simplest, most widely understood approach.

### 2. Header Versioning

The version is sent in a request header:
```
GET /api/users
Accept: application/vnd.myapp.v2+json
```

**Pros:**
- URLs stay clean
- Technically more "correct" according to REST principles

**Cons:**
- Invisible — you can't tell the version from looking at the URL
- Harder to test (you need to set headers, not just change a URL)
- Harder for clients to implement correctly
- Less obvious to newcomers

Use this if you have a strong opinion about REST purity. Otherwise, use URL versioning.

### 3. Query Parameter Versioning

The version is a query parameter:
```
/api/users?version=2
```

**Pros:**
- Easy to implement
- URL base stays the same

**Cons:**
- Easy to forget (what happens if the version parameter is missing?)
- Looks less clean than path versioning
- Can conflict with other query parameters

Not recommended — it combines the disadvantages of both other approaches.

## When to Create a New Version

Not every change needs a new version. Here's the key distinction:

### Breaking Changes (REQUIRE a new version)

A change is "breaking" if existing clients would fail or get wrong results:

- **Removing a field** from a response. Clients expect it to be there.
- **Renaming a field.** `user_name` becomes `username` — clients looking for `user_name` get nothing.
- **Changing a field's type.** `age` was a number, now it's a string. Clients parsing it as a number will crash.
- **Removing an endpoint.** Clients calling it get 404.
- **Adding a required field** to a request. Existing clients don't send it, so their requests fail.
- **Changing error formats.** Clients that parse error responses break.

### Non-Breaking Changes (DO NOT require a new version)

- **Adding a new field** to a response. Existing clients ignore fields they don't recognize.
- **Adding a new optional field** to a request. Existing clients don't send it, and the API uses a default.
- **Adding a new endpoint.** Existing clients don't call it, so nothing breaks.
- **Improving performance.** The response is the same, just faster.
- **Fixing a bug.** If the API was returning wrong data, fixing it is correct — even if some client was relying on the wrong behavior (edge case; use judgment).

**The rule of thumb:** If existing clients can keep working without any changes on their end, it's non-breaking. If they'd need to update their code, it's breaking.

## How to Manage Multiple Versions

Running two (or more) versions of your API simultaneously:

### Keep It Minimal

Every version you maintain is code you have to update, test, and debug. Limit yourself to **at most two active versions** — the current one and the previous one.

### Deprecation Process

When you release v2:

1. **Announce the deprecation** of v1. Tell your API consumers (in documentation, in response headers, via email) that v1 will stop working on a specific date. Give them generous notice — 6 months minimum for external APIs, 3 months for internal ones.

2. **Add deprecation warnings.** Include a response header like `Deprecation: true` or `Sunset: 2027-01-01` in v1 responses. Well-built clients can detect this and alert their developers.

3. **Monitor v1 usage.** Before shutting it down, check who's still calling it. Reach out to active users if possible.

4. **Shut down v1** on the announced date. Return `410 Gone` with a message directing clients to v2.

### Code Organization

Avoid copy-pasting your entire API for each version. Instead:

- **Shared logic:** Business logic, database operations, and validations should be version-independent. They don't change when the API format changes.
- **Version-specific layers:** Each version has its own request parsing and response formatting. v1 returns `user_name`, v2 returns `username` — but both call the same internal function.
- **Routing:** Route `/api/v1/*` to v1 handlers and `/api/v2/*` to v2 handlers. The handlers are thin wrappers around shared logic.

## Practical Tips

**Start at v1, not v0.** Calling your first version `v1` is conventional and signals stability.

**Don't version internal APIs unnecessarily.** If your frontend and backend deploy together, you can change both at the same time. Versioning adds overhead you don't need.

**Changelog your API changes.** Keep a simple list of what changed in each version. Your consumers need this, and it helps you track what's different between versions.

**Ask your AI to help plan the migration:**
> *"I need to rename the `user_name` field to `username` in my API. Help me create a v2 that makes this change while keeping v1 working."*
