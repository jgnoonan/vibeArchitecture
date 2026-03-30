# Search Architecture: Helping Users Find Things

> This is an architectural planning guide. Search decisions affect your database, infrastructure, performance, and cost. The performance rules (`rules/performance.md`) and data rules (`rules/data.md`) apply to search implementations.

## Why Search Is an Architectural Decision

Adding a search bar to your app seems simple. But behind that search bar lies a set of decisions that affect your database choice, your infrastructure, your costs, and how your application scales.

Get the search approach right early and it just works. Get it wrong and you'll face slow queries, irrelevant results, angry users, and eventually a painful migration.

## Levels of Search

Not every application needs a search engine. Match your approach to your actual needs.

### Level 1: Simple Filtering (Database WHERE Clause)

**What it is:** Filtering records by exact or partial matches using your existing database.

```sql
SELECT * FROM products WHERE name LIKE '%wireless headphones%'
```

**Good for:**
- Small datasets (under 100,000 records)
- Exact matches and simple contains-style searches
- Filtering by known fields (status, category, date range)
- Admin panels and internal tools

**Limitations:**
- `LIKE '%term%'` can't use indexes efficiently — it scans every row
- No relevance ranking (results aren't sorted by how well they match)
- No typo tolerance ("headphons" returns nothing)
- No understanding of synonyms ("wireless" doesn't match "Bluetooth")
- Gets slow as data grows

**When to use:** Your app has simple search needs, a modest dataset, and users search by known values. Most internal tools and admin panels live here forever, and that's fine.

### Level 2: Database Full-Text Search

**What it is:** Using your database's built-in full-text search capabilities. PostgreSQL, MySQL, and SQLite all have this.

**PostgreSQL example:**
```sql
-- Create a text search index
ALTER TABLE products ADD COLUMN search_vector tsvector;
CREATE INDEX idx_search ON products USING GIN(search_vector);

-- Search with ranking
SELECT * FROM products
WHERE search_vector @@ to_tsquery('wireless & headphones')
ORDER BY ts_rank(search_vector, to_tsquery('wireless & headphones')) DESC;
```

**Good for:**
- Medium datasets (up to a few million records)
- Full-text search with relevance ranking
- Applications already using PostgreSQL or MySQL
- Stemming (searching "running" also finds "run" and "runs")
- No additional infrastructure needed — it's just your database

**Limitations:**
- Limited typo tolerance (depends on the database)
- Basic synonym support (requires manual configuration)
- Search index updates happen with your database writes (can impact write performance at scale)
- Less sophisticated relevance ranking than dedicated search engines
- No faceted search out of the box (filtering by category, price range, brand simultaneously)

**When to use:** You need search that's better than `LIKE`, you're already using PostgreSQL or MySQL, and you don't want to add another service to your infrastructure. This is the right choice for most applications and can handle more than people expect.

**PostgreSQL in particular is surprisingly capable.** With `tsvector`, `GIN` indexes, and `ts_rank`, you get a solid search experience for most use cases. Try this before adding a dedicated search engine.

### Level 3: Dedicated Search Engine

**What it is:** A separate service built specifically for search. The main options:

**Elasticsearch / OpenSearch:**
- The most powerful and flexible option
- Handles massive datasets (billions of documents)
- Excellent relevance tuning, faceted search, aggregations, geo search
- Complex to operate and expensive to run (RAM-hungry)
- Best for: large-scale applications with sophisticated search needs

**Typesense:**
- Designed to be simple — easy to set up, easy to operate
- Built-in typo tolerance (searches work even with spelling mistakes)
- Fast — consistently sub-50ms response times
- Hosted option available (Typesense Cloud)
- Less flexible than Elasticsearch for complex queries
- Best for: most applications that outgrow database search

**Meilisearch:**
- Similar philosophy to Typesense — simplicity first
- Excellent typo tolerance and relevance out of the box
- Easy to set up and configure
- Hosted option available (Meilisearch Cloud)
- Best for: applications where search UX matters and you want fast setup

**Algolia (managed service):**
- Fully managed — no infrastructure to run
- Excellent search-as-you-type experience with instant results
- Rich dashboard for tuning relevance without code
- Expensive at scale (priced per search operation)
- Best for: e-commerce, documentation sites, and products where search is a core feature and you'd rather pay than operate

**Good for:**
- Large datasets (millions to billions of records)
- Typo tolerance ("headphons" finds "headphones")
- Faceted search (filter by brand, price range, color simultaneously)
- Instant search-as-you-type experiences
- Geo-spatial search (find stores within 10 miles)
- Complex relevance tuning

**Tradeoffs:**
- Another service to run, monitor, and maintain (unless using a managed option)
- Data must be synced from your primary database to the search engine
- Eventual consistency — there's always a brief delay between a record being saved in the database and appearing in search results
- Additional cost (infrastructure or subscription)

## How to Choose

| Situation | Recommendation |
|-----------|---------------|
| Under 100K records, simple filtering | Level 1: Database WHERE clause |
| Under 1M records, need relevance ranking | Level 2: PostgreSQL/MySQL full-text search |
| Need typo tolerance and you're using PostgreSQL | Try Level 2 first with `pg_trgm` extension |
| Need faceted search, instant search-as-you-type | Level 3: Typesense or Meilisearch |
| Large scale, complex relevance needs | Level 3: Elasticsearch |
| Search is your core product feature, don't want to operate infrastructure | Level 3: Algolia or Typesense Cloud |

**The decision tree:**
1. Start with your database. Can it handle your search needs? If yes, stop.
2. If database search is too slow or the results aren't good enough, try PostgreSQL full-text search with proper indexes.
3. If that's not enough, add a dedicated search engine. Start with Typesense or Meilisearch — they're simpler than Elasticsearch.
4. Only use Elasticsearch if you need its advanced features (complex aggregations, massive scale, custom analyzers).

## Keeping Search in Sync

When you use a dedicated search engine, you have two copies of your data — the primary database (source of truth) and the search index. They need to stay in sync.

### Approaches

**Direct sync on write (simplest):**
When you create or update a record in the database, immediately update the search index too. Simple, but adds latency to every write and fails if the search engine is down.

**Background sync (recommended):**
When a record changes, enqueue a job that updates the search index asynchronously. The search index may be a few seconds behind the database, but writes are fast and the system is resilient to search engine downtime.

**Change data capture (advanced):**
Use database change streams (PostgreSQL logical replication, MongoDB change streams) to automatically detect changes and push them to the search index. More complex to set up but very reliable.

**Full reindex (periodic):**
Periodically rebuild the entire search index from the database. Use this as a safety net alongside one of the above approaches — it catches anything that fell through the cracks. Schedule nightly or weekly.

### The Consistency Tradeoff

Accept that search results may be slightly stale. A product added 2 seconds ago might not appear in search yet. This is fine for virtually all applications. Design your UI accordingly — if a user just created something, show it in their "recent items" list (from the database) rather than relying on search to find it immediately.

## Search UX Considerations

A good search implementation isn't just fast and accurate — it helps users find what they want.

**Search-as-you-type (instant search):** Show results as the user types, updating with each keystroke. This requires fast search (under 50ms) and client-side debouncing (don't fire a request on every keystroke — wait 200–300ms after the user stops typing).

**Suggested queries / autocomplete:** As the user types, suggest complete queries or popular searches. Reduces typos and helps users discover content.

**Faceted filtering:** Let users narrow results by category, price range, rating, date, etc. Essential for e-commerce and any application with diverse content.

**No-results page:** Don't just say "No results found." Suggest alternative searches, check for typos, or show popular items. An empty results page is a dead end.

**Highlighting:** Show where the search term appears in the result. Helps users quickly evaluate whether a result is relevant.

## Indexing Strategy

What you index determines what users can search for and how good the results are.

**Index user-facing text.** Product names, descriptions, article content, user-generated content. Don't index internal IDs, timestamps, or technical metadata (unless users search by them).

**Boost important fields.** A match in the product name is more relevant than a match in the description. Configure field weights accordingly.

**Denormalize for search.** Your search document might include data from multiple database tables. A product search result might include the product name, category name, and brand name — even if those are separate tables in your database. This avoids joins at search time.

**Consider what users actually search for.** Look at real search queries (log them). If users search for "blue running shoes size 10," make sure color, type, and size are all indexed and searchable.

## Common Mistakes

**Adding Elasticsearch on day one.** Your database handles search fine for thousands of records. Don't add infrastructure complexity until your database-level search is measurably insufficient.

**Not indexing the right fields.** Users search for "blue shirt" but you only indexed the product name ("Men's Cotton Oxford"), not the color or category. Index what users actually search for.

**Ignoring search relevance.** The first result should be the most relevant. If "wireless headphones" returns a charging cable first because it mentions "wireless" in the description, your relevance ranking needs tuning.

**Not debouncing search-as-you-type.** Firing a search request on every keystroke (300ms × 10 characters = 3,000ms of wasted requests). Debounce — wait until the user pauses typing.

**Forgetting to sync deletes.** You delete a product from the database but forget to remove it from the search index. Users click a search result and get a 404.

**No monitoring.** You should know: average search latency, zero-results rate (what percentage of searches return nothing), and the most common search terms. These metrics tell you if search is working for your users.
