# Caching — Why and How

> This guide explains caching concepts, strategies, and pitfalls. Read it when you need to improve performance or when you want to understand cache invalidation.

## What Caching Does

Caching stores the result of an expensive operation so that subsequent requests for the same thing can be served quickly without repeating the work. The "expensive operation" might be a database query, an API call, a computation, or rendering a page.

**The tradeoff:** Cached data might be stale (out of date). Every caching decision balances speed against freshness.

## Cache Layers

Your application can cache at several levels. Each layer serves a different purpose:

### Browser Cache

The user's browser stores files locally. When the browser needs a file it already has, it uses the local copy instead of requesting it again.

**Controlled by HTTP headers:**
- `Cache-Control: max-age=3600` — cache this for 1 hour
- `Cache-Control: no-cache` — always check with the server before using the cached version
- `Cache-Control: no-store` — never cache this (use for sensitive data)
- `ETag` — a fingerprint of the content. The browser asks "has this changed?" and the server either says "no, use your cached copy" (304) or sends the new version.

**Best for:** Static assets (JavaScript, CSS, images), API responses that don't change frequently.

**The filename trick:** Use content-hashed filenames (`app.a1b2c3.js`) with long cache durations. When the content changes, the filename changes, so the browser automatically fetches the new version. Old versions are never served stale.

### CDN (Content Delivery Network)

A CDN is a network of servers around the world that cache your content. When a user in Tokyo requests a file, the CDN serves it from a server in Tokyo instead of your server in Virginia. Faster for the user, less load on your server.

**Best for:** Static files (images, CSS, JavaScript, fonts), public API responses that are the same for all users.

**Popular CDNs:** Cloudflare (free tier), AWS CloudFront, Vercel Edge Network (automatic for Vercel deployments), Fastly.

### Application Cache

Your application stores frequently-accessed data in a fast in-memory store like Redis or Memcached. Instead of querying the database for every request, the application checks the cache first.

**Example workflow:**
1. Request comes in for user profile
2. Check Redis: is this user's profile cached?
3. If yes (cache hit): return the cached data immediately
4. If no (cache miss): query the database, store the result in Redis, return it

**Best for:** Database query results that are read frequently and change infrequently (product catalogs, user profiles, configuration), computed values that are expensive to calculate (leaderboards, aggregated statistics).

**Tools:** Redis (most popular, also useful for sessions and queues), Memcached (simpler, pure caching).

### Database Query Cache

Some databases cache query results internally. This is the least controllable layer — the database manages it automatically. Generally, it's more effective to cache at the application level where you have explicit control.

## Cache Invalidation — The Hard Part

> "There are only two hard things in Computer Science: cache invalidation and naming things." — Phil Karlton

When the underlying data changes, the cache must be updated or the cached version becomes stale. This is cache invalidation, and it's genuinely difficult because you need to know when data changed and which cached entries are affected.

### TTL-Based (Time-to-Live)

The simplest strategy: every cached entry has an expiration time. After that time, it's removed and the next request fetches fresh data.

```
Cache user profile with TTL of 5 minutes
```

**Advantages:** Simple to implement. No coordination needed between the write path and the cache.

**Disadvantages:** Data can be stale for up to the TTL duration. Users might see an old name for 5 minutes after changing it.

**When to use:** When slightly stale data is acceptable. Product listings, leaderboards, aggregate statistics, configuration that changes rarely.

### Event-Based (Active Invalidation)

When data changes, explicitly delete or update the cached version.

```
User updates their profile →
  Update database →
  Delete cached profile →
  Next read will fetch fresh data from database and re-cache it
```

**Advantages:** Data is never stale for more than the brief moment between the database write and the cache delete.

**Disadvantages:** More complex. Every write path that affects cached data must know to invalidate the cache. If you miss one, the cache serves stale data.

**When to use:** When freshness matters. User-facing profile data, inventory counts, pricing.

### Cache Versioning

Instead of invalidating a specific key, change the cache key itself:

```
Cache key: "products_v3"
When products change, increment to "products_v4"
```

The old cached data is simply never accessed again and eventually expires. This avoids the complexity of deleting specific entries.

## Cache Stampede (Thundering Herd)

### The Problem

A popular cache entry expires. At that exact moment, 1,000 users request it. All 1,000 get a cache miss. All 1,000 hit the database simultaneously. The database chokes under the sudden load.

### Solutions

**Lock-based recomputation:** The first request to find a cache miss acquires a lock and recomputes the value. All other requests wait for the lock to release, then read the new cached value. Only one database query is made instead of 1,000.

**Probabilistic early refresh:** Instead of all instances expiring at the same time, randomly refresh a few seconds before the actual expiration. This spreads the recomputation load.

**Background refresh:** A background job refreshes popular cache entries before they expire. The cache never goes empty for high-traffic data.

**Stale-while-revalidate:** Serve the stale cached data immediately while refreshing the cache in the background. The user gets a fast response (possibly slightly stale), and the cache is refreshed for the next request.

## What to Cache (and What Not To)

### Good Cache Candidates

- **Expensive computations:** Aggregated statistics, complex reports, search results
- **Frequently read, rarely changed data:** Product catalogs, user profiles, configuration settings, permission lists
- **External API responses:** Weather data, exchange rates, third-party service responses (respect their cache headers)
- **Rendered content:** Generated HTML pages, pre-computed API responses

### Bad Cache Candidates

- **Rapidly changing data:** Real-time stock prices, live chat messages, sensor readings. By the time you cache it, it's already stale.
- **User-specific sensitive data** (without careful design): Caching one user's data and accidentally serving it to another is a serious security vulnerability. If you cache user-specific data, ensure the cache key includes the user ID and access is verified.
- **Write-heavy data:** If data changes more often than it's read, caching just adds overhead.
- **Data that must be real-time accurate:** Current account balances, inventory counts for the last item in stock, authentication status. For these, the cost of serving stale data exceeds the cost of querying.

## Practical Tips

### Cache Key Design

Use clear, namespaced, predictable cache keys:
- Good: `user:123:profile`, `products:category:electronics:page:1`
- Bad: `data`, `stuff`, `temp123`

Include version information in keys when your data format changes: `user:123:profile:v2`

### Monitor Your Cache

Track:
- **Hit rate:** What percentage of requests are served from cache? Below 80%, your cache might not be covering the right data.
- **Miss rate:** A sudden spike in misses might indicate mass expiration or a problem.
- **Eviction rate:** If entries are being evicted before their TTL, your cache is too small.
- **Memory usage:** Ensure your cache isn't running out of memory.

### Start Simple

1. Begin with HTTP cache headers for static assets — zero infrastructure, immediate benefit
2. Add a CDN if your users are geographically distributed
3. Add Redis/application caching for specific slow queries you've identified through profiling
4. Don't cache everything "just in case" — cache what you've measured to be slow
