# Concurrency: When Things Happen at the Same Time

> For the compact rules, see `rules/reliability.md` under "Concurrency."

## Why This Matters

Imagine a shared spreadsheet where two people edit the same cell at the same time. One person types "42" and the other types "99." What ends up in the cell? It depends on who saved last — and the other person's change is silently lost.

This is a **race condition** — two operations racing to use the same resource, with the outcome depending on who gets there first. In software, this happens constantly: two users buying the last item in stock, two threads writing to the same file, two API calls updating the same database row.

Race conditions are particularly dangerous because they're intermittent. Your code works perfectly in testing (one user, one thread, everything sequential), then fails mysteriously in production (hundreds of users, dozens of threads, everything overlapping). They're one of the hardest bugs to reproduce and diagnose.

## The Core Problem: Shared Mutable State

Nearly every concurrency bug comes from the same root cause: **multiple actors changing the same thing at the same time**. The fix is always one of three strategies:

1. **Don't share** — give each actor its own copy
2. **Don't mutate** — everyone reads, nobody writes (or writes go through a single coordinator)
3. **Coordinate access** — use locks, transactions, or atomic operations to ensure only one actor changes the resource at a time

## Common Concurrency Scenarios

### File Access

Most operating systems do **not** lock files automatically. If two processes open the same file and write to it, the results are unpredictable — you might get a mix of both writes, or one might overwrite the other entirely.

**The wrong way:**
```
Process A: open file → read contents → modify → write file
Process B: open file → read contents → modify → write file
```
If both processes read before either writes, one set of changes is lost.

**Safe approaches:**

- **File locks:** Acquire an exclusive lock before writing, release when done. Other processes wait until the lock is released. Most languages have this built in (`flock` on Unix, `LockFileEx` on Windows, `fcntl` locks).

- **Write-to-temp-then-rename:** Write your changes to a temporary file, then rename it to the target filename. On most operating systems, rename is an atomic operation — it either completes entirely or not at all. This avoids corrupting the original file if something goes wrong mid-write.

- **Use a database instead:** If multiple processes need to share state, a database handles concurrency for you through transactions. Files are a poor choice for shared mutable state.

### Database Rows

Two users both read the same product with "5 in stock." Both click "buy." Both operations read 5, subtract 1, and write 4. You just sold 6 items from a stock of 5.

**Optimistic concurrency (good for low contention):**
Add a version number or timestamp to the row. When you update, include a condition: "update this row, but only if the version is still what I read." If someone else changed it first, your update affects zero rows — you know to retry with fresh data.

**Pessimistic concurrency (good for high contention):**
Lock the row before reading it: `SELECT ... FOR UPDATE`. This tells the database "I'm going to change this, don't let anyone else touch it until I'm done." The lock is released when the transaction commits.

**Which to choose:**
- Optimistic is faster when conflicts are rare (most of the time, nobody else is touching the same row).
- Pessimistic is safer when conflicts are frequent or the stakes are high (financial transactions, inventory that's almost sold out).

### Threads and Shared Memory

When multiple threads in the same application share memory (variables, data structures, caches), you need explicit coordination.

**Mutex (mutual exclusion):** A lock that only one thread can hold at a time. Before accessing shared data, a thread acquires the mutex. Other threads that try to acquire it will wait until it's released.

Think of it like a single-occupancy bathroom — the door has a lock. If it's occupied, you wait outside until the person inside is done.

**Read-write lock (RwLock):** A smarter lock that allows multiple readers OR a single writer, but not both. If nobody is writing, any number of threads can read simultaneously. When a writer needs access, it waits for all readers to finish, then gets exclusive access.

Use this when reads are much more common than writes — which they usually are.

**Atomic operations:** For simple values (counters, flags, booleans), atomic operations update the value in a single CPU instruction that can't be interrupted. No lock needed, very fast. Available in most languages for basic types.

Use atomics for simple counters (request count, error count) or boolean flags (is_shutting_down). Don't try to build complex coordination from atomics unless you really know what you're doing.

**Channels / message passing:** Instead of sharing memory, send data between threads through a channel (like a pipe). One thread puts a message in, another thread takes it out. No shared state, no locks needed.

This is the preferred approach in Go ("don't communicate by sharing memory; share memory by communicating") and works well in Rust, Elixir, and other languages with strong channel support.

### API and Distributed Systems

When multiple servers or services can process the same request, concurrency gets harder because you can't use in-process locks — the lock on Server A means nothing to Server B.

**Distributed locks:** Use a shared service (Redis, ZooKeeper, etcd) to coordinate. Before doing critical work, acquire a lock in the shared service. Other servers check the same service and wait. Always set a timeout on distributed locks — if the process holding the lock crashes, you don't want it locked forever.

**Idempotency keys:** Assign a unique ID to each operation. Before processing, check if that ID has already been processed. If it has, return the same result instead of processing again. This makes it safe to retry operations without side effects.

This is critical for payment processing — if a network timeout makes you unsure whether a charge went through, you can safely retry with the same idempotency key. The payment provider will recognize it and return the original result instead of charging again.

**Eventual consistency:** Accept that in distributed systems, not everything will be perfectly synchronized at every instant. After an update, it may take a moment for all servers to see the new data. Design your user experience around this — "your changes may take a few seconds to appear" is fine for most applications.

## The Rust Perspective

Rust deserves special mention because its compiler prevents an entire class of concurrency bugs at compile time. The ownership system ensures that:

- You can't accidentally share mutable data between threads
- You can't read memory that another thread might be modifying
- You can't forget to release a lock (it's released when the lock guard goes out of scope)

This eliminates **data races** — the most dangerous kind of concurrency bug, where two threads access the same memory with at least one writing, without synchronization.

However, Rust does **not** prevent **logical race conditions.** Two threads can still read a value, both decide to update it, and one overwrites the other's work. The standard library tools for handling this:

- `Mutex<T>` — wraps shared data, ensures exclusive access
- `RwLock<T>` — read-many / write-one access
- `Arc<T>` — reference-counted shared ownership (needed to share data across threads)
- `mpsc` channels — message passing between threads
- `Atomic*` types — lock-free operations on simple values
- `tokio::sync` — async-aware versions of the above for async Rust

The Rust compiler will refuse to compile code that has potential data races. If the compiler is fighting you about sharing data between threads, it's probably telling you something important. Listen to it.

## Common Mistakes

**Not thinking about concurrency at all.** The most common mistake. Code that works perfectly with one user fails mysteriously with many. If your application will ever handle more than one request at a time (it will), think about what happens when two requests touch the same data.

**Holding locks too long.** Acquire the lock, do the minimum work necessary, release it. Don't make API calls, do I/O, or run complex logic while holding a lock — everything else that needs that resource is frozen while you hold it.

**Deadlocks.** Thread A holds Lock 1 and waits for Lock 2. Thread B holds Lock 2 and waits for Lock 1. Neither can proceed — the application hangs forever. Prevent deadlocks by always acquiring multiple locks in the same order, or by using timeouts on lock attempts.

**Assuming file operations are atomic.** Writing to a file is not atomic. If your process crashes mid-write, the file is corrupted. Writing 100 bytes might appear as 50 bytes if another process reads it at the wrong moment. Always use write-to-temp-then-rename for important files.

**Not making retried operations idempotent.** If a network timeout leaves you unsure whether an operation completed, and you retry, you might execute it twice. Charging a customer twice, sending a notification twice, creating a duplicate record. Use idempotency keys or check-before-write patterns to prevent this.

**Using global variables as shared state.** Global or module-level variables are shared across all threads and requests. A web framework handling concurrent requests will have multiple threads reading and writing global state simultaneously. Use thread-local storage, request-scoped state, or proper synchronization.

## When to Worry About This

**Always, even a little.** Even a simple web application handles multiple requests concurrently. Most web frameworks do this automatically — your code might be running in parallel without you realizing it.

**More as you scale.** The more users, threads, workers, or instances you have, the more likely concurrent access becomes. Something that "never happens" with 10 users happens every minute with 10,000.

**Especially with:** file I/O, shared caches, counters, inventory or stock management, financial operations, background job processing, and any situation where multiple AI agents are modifying the same project.
