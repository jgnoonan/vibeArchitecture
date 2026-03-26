# Performance Rules

> Applies to: Business tier and above.
> For detailed explanations: see `guides/performance/`

## First Principles

- **Do not optimize prematurely.** Make it work correctly, make the code clean, THEN make it fast. Optimizing before you've measured is guessing, and guessing wastes time on the wrong problems.
- **Always measure before optimizing.** Use profiling tools, query analyzers, and performance monitoring to identify the actual bottleneck. The bottleneck is almost never where you think it is.
- **Set performance budgets.** Define acceptable response times for each type of operation before building. Example: page loads under 2 seconds, API responses under 500ms at p95, background jobs complete within 5 minutes. Measure against these targets.

## Common Performance Killers

- **N+1 queries**: The #1 performance bug in web applications. Loading a list of 100 items, then making a separate database query for each item's related data = 101 queries instead of 2. Use eager loading, joins, or batch queries. Watch for this in every list/collection endpoint.
- **Unbounded queries**: `SELECT * FROM big_table` with no LIMIT will eventually return millions of rows. Every query that returns a list must have a limit. Every API endpoint that returns a list must paginate.
- **Missing indexes**: A query without an index scans every row. On a table with 10 rows, it's instant. On a table with 10 million rows, it takes minutes. See the data rules for indexing guidance.
- **Synchronous external calls in the request path**: If rendering a page requires calling 3 external APIs sequentially and each takes 500ms, the page takes 1.5+ seconds before your code even starts building the response. Parallelize calls that don't depend on each other, cache responses, or move them to background processing.
- **Loading data you don't use**: `SELECT *` when you need 3 columns, loading full objects when you need a count, deserializing large payloads to read one field. Query for only what you need.

## Database Performance

- Use your database's EXPLAIN / query plan tool to understand how queries execute. Learn to read the output — it shows whether indexes are used, how many rows are scanned, and where time is spent.
- Add indexes based on actual slow queries, not speculation. See what queries your application runs most and optimize those first.
- Use connection pooling. Database connections are expensive to create. A connection pool maintains a set of reusable connections instead of opening and closing them for every request. Most frameworks have built-in pooling; configure it intentionally (don't just accept defaults).
- Size your connection pool deliberately. A common mistake is setting it to 100 "just in case." A pool that's too large wastes database resources and can actually hurt performance. Start with 5–20 connections for most applications; increase based on measured need.
- Batch writes where possible. Inserting 1,000 rows one at a time is dramatically slower than a single batch insert.

## Caching

- Cache expensive computations and frequently-read, rarely-changed data. Don't cache data that changes constantly or is unique to every request.
- Use the simplest caching layer that solves the problem:
  - **HTTP cache headers** (Cache-Control, ETag) for static assets and API responses that don't change often. Free, automatic, no infrastructure needed.
  - **CDN** for static files (images, CSS, JavaScript). Serves files from locations close to users.
  - **Application cache** (Redis, Memcached) for computed data, session data, or frequently queried database results.
  - **Database query cache** as a last resort — it's usually more effective to cache at the application level.
- Set explicit expiration (TTL) on every cached value. A cache entry without an expiration is a stale data bug waiting to happen.
- Plan for cache invalidation from the start. When the underlying data changes, the cache must be updated or cleared. The two simplest strategies: TTL-based (accept slightly stale data, refresh periodically) or event-based (clear cache when data changes).
- Guard against cache stampede: when a popular cache entry expires, hundreds of simultaneous requests hit the database at once. Solutions: lock-based recomputation (one request refreshes, others wait), probabilistic early refresh (randomly refresh before actual expiration), or background refresh (refresh the cache before it expires).

## Scaling Awareness

- Design for horizontal scaling from the start: keep your application stateless (no data stored in the application process that would be lost if it restarts or if a request hits a different instance). Store sessions, caches, and uploads in external services.
- Vertical scaling (bigger server) is the simplest first response to performance problems. Often the right answer for small-to-medium applications.
- Horizontal scaling (more servers) requires stateless design and a load balancer. It has no ceiling but adds operational complexity.
- Database scaling is harder than application scaling. Use read replicas before sharding. Optimize queries before adding hardware. Most applications hit application limits before database limits.

## Frontend Performance (If Applicable)

- Optimize images: use modern formats (WebP, AVIF), resize to display dimensions, lazy-load below-the-fold images.
- Minimize JavaScript bundle size. Use code splitting to load only what's needed for the current page. Tree-shake unused imports.
- Set Cache-Control headers for static assets. Use content-hashed filenames (`app.a1b2c3.js`) so the cache is automatically invalidated on new deployments.
- Measure with real tools: Lighthouse, Core Web Vitals, WebPageTest. These show what actual users experience, not what your fast development machine shows.
