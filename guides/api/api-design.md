# API Design — Why and How

> This guide explains the reasoning behind API design rules. Read it when designing your API or when you want to understand why conventions exist.

## What Is an API?

An API (Application Programming Interface) is how different pieces of software talk to each other. When your frontend shows a list of products, it asks the backend API for that list. When a mobile app creates a new user account, it sends the data to the backend API.

Think of it as a restaurant menu: the menu lists what's available and how to order it. The API defines what data is available and how to request or change it.

## REST — The Standard Approach

REST (Representational State Transfer) is the most common API style for web applications. It uses standard web concepts that are already built into every browser and programming language:

### Resources and URLs

Everything in your API is a **resource** — something that has a name and can be accessed with a URL:
- `/users` — the collection of all users
- `/users/123` — a specific user
- `/users/123/orders` — that user's orders
- `/orders/456` — a specific order

Resources are **nouns** (things), not verbs (actions). Use `/users`, not `/getUsers` or `/createUser`.

### HTTP Methods (Verbs)

The action is expressed through the HTTP method:
- **GET** — retrieve data (read-only, no side effects)
- **POST** — create a new resource
- **PUT** — replace an entire resource with new data
- **PATCH** — update specific fields of a resource
- **DELETE** — remove a resource

This means "get all users" is `GET /users` and "create a user" is `POST /users`. The URL stays the same; the method changes.

### Why This Matters

This isn't arbitrary convention — it has practical benefits:
- **Cacheability:** GET requests can be cached automatically. Browsers, CDNs, and proxies know GET doesn't change anything.
- **Safety:** GET requests can be retried safely. If a GET request times out, the client can try again without worrying about side effects.
- **Predictability:** If you know the pattern, you can guess the URL for any resource without reading documentation.

## Status Codes — Speaking the Same Language

HTTP status codes tell the client what happened. Using them correctly means clients can handle responses automatically without parsing error messages.

### The Important Ones

**Success (2xx):**
- `200 OK` — the request worked, here's the result
- `201 Created` — the request worked and a new resource was created (include the new resource or its location in the response)
- `204 No Content` — the request worked but there's nothing to return (common for DELETE)

**Client Errors (4xx) — the client did something wrong:**
- `400 Bad Request` — the data sent was invalid (malformed JSON, missing required fields)
- `401 Unauthorized` — authentication is required and wasn't provided, or credentials are invalid
- `403 Forbidden` — authentication succeeded but this user doesn't have permission
- `404 Not Found` — the requested resource doesn't exist
- `409 Conflict` — the request conflicts with existing data (duplicate email, version conflict)
- `422 Unprocessable Entity` — the format is valid but the data fails business rules
- `429 Too Many Requests` — rate limit exceeded

**Server Errors (5xx) — something broke on your end:**
- `500 Internal Server Error` — an unexpected error occurred
- `502 Bad Gateway` — your server got an invalid response from an upstream service
- `503 Service Unavailable` — your server is overloaded or down for maintenance

### The Golden Rule

Never return `200 OK` with an error message in the body. If something went wrong, use the appropriate error status code. Clients depend on status codes for automated error handling.

## Error Responses

Every error response should follow the same format across your entire API. This is critical — a developer using your API shouldn't have to guess what an error response looks like.

A practical format:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The email address is not valid",
    "details": [
      { "field": "email", "message": "Must be a valid email address" },
      { "field": "name", "message": "Must not be empty" }
    ]
  }
}
```

Include:
- A machine-readable error code (for programmatic handling)
- A human-readable message (for developers debugging)
- Field-level details for validation errors (so the UI can show errors next to the right field)

Never include: stack traces, database error messages, internal file paths, SQL queries. These are security leaks and belong in your logs, not in API responses.

## Pagination

Any endpoint returning a list must support pagination. Without it, a table with 100,000 rows will produce a response that's either gigantic (slow to send, slow to process) or will time out entirely.

### Cursor-Based Pagination (Recommended)

The response includes a cursor (an opaque token representing the current position):
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true
  }
}
```

The client requests the next page with: `GET /items?cursor=eyJpZCI6MTAwfQ==`

**Advantages:** Fast regardless of how deep you paginate, consistent results even when data changes between requests.

### Offset-Based Pagination (Simpler but Limited)

The client specifies page number and size: `GET /items?page=5&limit=20`

**Advantages:** Simpler to understand and implement.
**Disadvantages:** Becomes slow on large datasets (the database must skip past all the earlier rows), and inserting or deleting records between page requests causes items to shift (skipped or shown twice).

### Recommendation

Use cursor-based for any dataset that might grow large. Offset-based is acceptable for small, relatively static datasets.

## Idempotency

An idempotent operation produces the same result whether you execute it once or multiple times. This matters because networks are unreliable — requests can be sent twice, or a client might not get the response and retry.

- **GET, PUT, DELETE** are naturally idempotent. Getting a user twice returns the same user. Deleting a user twice deletes them and then does nothing. Updating with the same data results in the same state.
- **POST** is NOT naturally idempotent. Creating a user twice could create two users. For important POST operations (payments, order creation), use an **idempotency key**: the client generates a unique ID and sends it with the request. If the server sees the same ID twice, it returns the first response instead of processing again.

## GraphQL — When REST Isn't Enough

GraphQL is an alternative to REST where the client specifies exactly what data it wants. Instead of multiple REST endpoints, there's one endpoint that accepts queries.

**Good for:** Mobile apps that need to minimize data transfer, complex nested data structures, UIs that need different subsets of the same data on different screens.

**Not worth the complexity for:** Simple CRUD applications, small teams without GraphQL experience, projects that are primarily server-rendered.

If you're unsure, start with REST. You can always add GraphQL later for specific use cases.
