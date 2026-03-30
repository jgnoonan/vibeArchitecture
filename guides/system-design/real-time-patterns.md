# Real-Time Communication: Live Updates, Chat, and Notifications

> This is an architectural planning guide. Real-time features don't have a dedicated rules file because the choice of approach depends on your specific use case. The reliability rules (`rules/reliability.md`) and API rules (`rules/api.md`) apply to real-time connections.

## What Is "Real-Time"?

In a traditional web application, the flow is simple: the user makes a request, the server responds. The page only changes when the user does something (clicks, submits, navigates). If another user posts a comment, you don't see it until you refresh.

Real-time communication breaks this pattern. The server can push updates to the client without the user doing anything. A chat message appears instantly. A notification pops up. A stock price ticks. A live dashboard refreshes.

**Common real-time use cases:**
- Chat and messaging
- Notifications (someone liked your post, your order shipped)
- Live dashboards and analytics
- Collaborative editing (multiple people editing the same document)
- Live feeds (social media, news, sports scores)
- Presence indicators (who's online right now)
- Real-time search or autocomplete results
- Multiplayer games

## Do You Need Real-Time?

Real-time adds complexity. Before committing to it, ask whether your use case actually requires instant updates:

**Truly needs real-time:**
- Chat — users expect messages to appear instantly
- Collaborative editing — two people editing the same document need to see each other's changes immediately
- Live trading or bidding — seconds matter
- Multiplayer games — sub-second latency is critical

**Probably fine with polling or near-real-time:**
- Notifications — a 5–10 second delay is usually acceptable. Users won't notice.
- Dashboards — refreshing every 30 seconds is often sufficient
- Order status updates — checking every minute is fine
- Social media feeds — a short delay doesn't hurt the experience

**Definitely doesn't need real-time:**
- Email-style messaging (users expect some delay)
- Reports and analytics (minutes or hours of freshness is fine)
- Profile updates (eventually consistent is perfectly acceptable)

If polling every 10–30 seconds gives an acceptable experience, do that. It's dramatically simpler to build, debug, and scale than a real-time connection.

## The Three Main Approaches

### 1. Polling (Simplest)

**How it works:** The client asks the server "anything new?" at regular intervals. If there's new data, the server returns it. If not, it returns an empty response.

```
Client: Any updates? (every 10 seconds)
Server: Nope.
Client: Any updates?
Server: Nope.
Client: Any updates?
Server: Yes! Here's a new message.
```

**Advantages:**
- Trivially simple to implement — it's just regular HTTP requests
- Works with any server, any hosting platform, any infrastructure
- Easy to debug (it's just API calls)
- No persistent connection to manage

**Disadvantages:**
- Wastes resources — most polls return empty responses
- Not truly instant — there's always a delay up to the polling interval
- Scales poorly if many clients poll frequently (thousands of clients polling every second = thousands of requests per second)

**Use when:** The delay is acceptable, you have relatively few clients, and simplicity matters more than instant delivery. For most notification systems and dashboards, polling every 10–30 seconds is fine.

### 2. Server-Sent Events (SSE)

**How it works:** The client opens a single HTTP connection to the server. The server holds this connection open and pushes data through it whenever there's something new. The connection is one-way — server to client only.

```
Client: I'd like updates, please. (opens connection)
Server: (holds connection open)
Server: Here's a new message. (pushes data)
Server: Here's another one. (pushes data)
...
```

**Advantages:**
- Simple — uses plain HTTP, works through firewalls and proxies
- Built into browsers — the `EventSource` API handles reconnection automatically
- Efficient — one persistent connection instead of repeated polls
- Easy to implement on the server — just write to the response stream

**Disadvantages:**
- One-way only — server pushes to client, client can't send through the same connection (use regular HTTP requests for client-to-server)
- Limited to text data (not binary)
- Browser limit of ~6 connections per domain (fine for most apps, but a constraint if you need many SSE streams)
- Some hosting platforms don't support long-lived HTTP connections

**Use when:** You need server-to-client push (notifications, live feeds, dashboards) but the client doesn't need to send frequent messages back. SSE is the sweet spot between polling and WebSockets — much simpler than WebSockets, much more efficient than polling.

### 3. WebSockets

**How it works:** The client and server establish a persistent, full-duplex connection. Either side can send messages to the other at any time.

```
Client: Let's upgrade to WebSocket. (handshake)
Server: Agreed. Connection open.
Client: Here's a message from me.
Server: Here's a message for you.
Server: Here's another update.
Client: And another from me.
...
```

**Advantages:**
- Full duplex — both sides can send at any time
- Very low latency — messages are near-instant
- Efficient for high-frequency bidirectional communication
- Supports binary data

**Disadvantages:**
- More complex to implement than SSE or polling
- Connection management is your responsibility — reconnection, heartbeats, error handling
- Doesn't work through some corporate proxies and firewalls
- Stateful connections make horizontal scaling harder (a user's WebSocket is connected to a specific server)
- Not all hosting platforms support WebSockets (serverless platforms especially)

**Use when:** You need fast, bidirectional communication — chat, collaborative editing, multiplayer games. Don't use WebSockets for use cases that only need server-to-client push (use SSE instead).

## How to Choose

| Use Case | Recommendation | Why |
|----------|---------------|-----|
| Notifications | Polling or SSE | Delay is acceptable; one-way push is sufficient |
| Live dashboard | SSE or Polling | Server pushes data; client doesn't send |
| Chat | WebSockets | Bidirectional; users expect instant delivery |
| Collaborative editing | WebSockets | Bidirectional; low latency critical |
| Live feed / social | SSE | Server pushes; client reads |
| Multiplayer game | WebSockets | Bidirectional; sub-second latency |
| Order status | Polling | Low frequency; simple implementation |
| Autocomplete | Regular HTTP (debounced) | Not real-time; just fast request-response |

**Start with polling.** If the experience isn't good enough, upgrade to SSE. If you need bidirectional, use WebSockets. Don't start with WebSockets unless your use case clearly demands it.

## Scaling Real-Time Connections

Real-time connections are stateful — each user has a persistent connection to a specific server. This creates scaling challenges that don't exist with stateless HTTP.

### The Problem

With regular HTTP, a load balancer can send any request to any server. With WebSockets or SSE, the user's connection is tied to one server. If you need to send a message to a user, you need to find which server holds their connection.

### Solutions

**For small scale (single server):** No problem. All connections are on one server.

**For moderate scale (a few servers):**
- **Redis Pub/Sub.** When Server A needs to send a message to a user connected to Server B, it publishes to a Redis channel. All servers subscribe to the channel and deliver messages to their connected users. This is the most common approach and works well up to tens of thousands of concurrent connections.

**For large scale (many servers, many connections):**
- **Dedicated real-time services.** Use a managed service like Pusher, Ably, or Supabase Realtime. They handle the connection management, scaling, and message routing. You publish events to their API; they deliver to connected clients.
- **Socket.IO with Redis adapter.** If using Node.js, Socket.IO with its Redis adapter handles multi-server WebSocket scaling out of the box.

**Practical advice:** Unless you're building a product where real-time is the core feature (a chat platform, a collaborative tool), use a managed service. The operational complexity of scaling WebSocket infrastructure is significant, and managed services handle it for a few dollars a month.

## Authentication for Real-Time Connections

WebSocket and SSE connections need authentication too. The approaches differ from regular HTTP:

**For SSE:** The initial HTTP request can carry cookies, so session-based auth works normally.

**For WebSockets:**
- Pass an authentication token as a query parameter during the handshake: `ws://server/socket?token=xyz`. The server validates the token before accepting the connection.
- Or authenticate over the WebSocket after connection: the first message from the client contains the auth token.
- Don't rely on cookies for WebSocket auth — browser support varies.
- **Validate on connection and periodically.** A token that was valid when the connection opened might be revoked later. For long-lived connections, re-validate periodically.

## Error Handling and Reconnection

Real-time connections drop. Networks switch (Wi-Fi to cellular), servers restart, load balancers time out. Your client must handle this gracefully.

**Automatic reconnection with backoff:** When the connection drops, wait 1 second and try again. If it fails, wait 2 seconds, then 4, then 8, up to a maximum (30 seconds). This prevents thousands of clients from hammering a recovering server.

**SSE handles this automatically.** The browser's `EventSource` API reconnects on its own. You just need a `Last-Event-Id` mechanism on the server to replay missed messages.

**WebSockets need manual reconnection logic.** Libraries like Socket.IO handle this for you. If using raw WebSockets, implement reconnection yourself.

**Message ordering and deduplication.** When a client reconnects, it may receive duplicate messages or miss some. Assign sequence numbers or IDs to messages. On reconnection, the client tells the server the last message it received, and the server replays anything newer.

## Common Mistakes

**Using WebSockets for everything.** If you just need to push a notification every few minutes, SSE or polling is simpler and more reliable. WebSockets are for high-frequency bidirectional communication.

**Not handling disconnections.** The connection will drop. If your app doesn't reconnect automatically, users see stale data and assume the app is broken.

**No heartbeats.** Some network intermediaries (proxies, load balancers) close idle connections. Send a periodic ping/pong (every 30 seconds) to keep the connection alive.

**Sending too much data.** Pushing every database change to every connected client wastes bandwidth and overwhelms the browser. Filter server-side — only send data relevant to each specific user.

**Not considering offline/background.** Mobile apps go to background. Laptop lids close. When the app returns, it needs to catch up on missed updates. Design a "catch-up" mechanism — fetch recent changes on reconnect.
