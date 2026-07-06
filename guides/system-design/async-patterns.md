# Asynchronous Patterns: Doing Things in the Background

> For the compact rules, see `rules/system-design.md` and `rules/reliability.md` (concurrency section).

## What Does "Asynchronous" Mean?

In most web applications, when a user makes a request, the server does the work immediately and sends back a response. The user waits. This is "synchronous" — everything happens in order, one step at a time.

"Asynchronous" means the server accepts the request, says "got it, I'll handle this," and does the work later — in the background. The user doesn't wait for the work to finish.

**Analogy:** Ordering food at a sit-down restaurant (synchronous) vs. ordering for delivery (asynchronous). At the restaurant, you wait at the table until the food is ready. With delivery, you place the order, go about your day, and get a notification when it arrives.

## When to Go Asynchronous

Not everything needs to be async. Use it when:

- **The work takes a long time.** Sending an email, generating a PDF, resizing an image, processing a payment receipt. If it takes more than a second or two, the user shouldn't be staring at a loading spinner.
- **The user doesn't need the result immediately.** A welcome email can be sent 30 seconds after sign-up. An analytics report can be generated in the background.
- **The work can fail independently.** If sending a confirmation email fails, the order itself shouldn't fail. Process them separately.
- **You're doing fan-out work.** "Notify all 1,000 followers that this user posted" should not happen inside the HTTP request that creates the post.

**Keep it synchronous when:**
- The user is waiting for the result ("show me my account balance")
- The operation is fast (under a second)
- The operation must succeed or fail atomically with the request ("create this order and reserve inventory")

## Message Queues

A message queue is the most common tool for async work. Your application puts a "message" (a description of work to do) into the queue. A separate worker process picks up messages and does the work.

**Analogy:** A to-do list on a shared whiteboard. Anyone can add a task. Workers check the board, grab a task, and do it. When they're done, they erase it and grab the next one.

### How It Works

```
User Request → Application Server → [Queue] → Worker → Does the Work
                    ↓
              "Got it!" (immediate response to user)
```

1. User signs up
2. Application creates the account in the database (synchronous — user needs this immediately)
3. Application puts "send welcome email to user@example.com" on the queue (asynchronous)
4. Application responds: "Account created!" (user doesn't wait for the email)
5. A worker picks up the message and sends the email

### Popular Queue Services

- **Redis (with Bull/BullMQ, Celery, Sidekiq):** Good starting point. You might already be running Redis for caching. Adding a queue is straightforward.
- **Amazon SQS:** Fully managed, very reliable, pay-per-use. Good for AWS deployments.
- **RabbitMQ:** Feature-rich, self-hosted or managed. Good when you need advanced routing.
- **Cloud-native options:** Google Cloud Tasks, Azure Service Bus.

For most applications, Redis with a queue library is the right starting point. Don't overthink this.

## Events vs. Commands

There are two ways to think about async messages:

**Commands** say "do this":
- "Send an email to user@example.com"
- "Process payment for order #1234"
- "Resize image upload #5678"

The sender knows who the receiver is and what they should do. It's a direct instruction.

**Events** say "this happened":
- "UserRegistered: user_id=42"
- "OrderPlaced: order_id=1234"
- "ImageUploaded: image_id=5678"

The sender doesn't know or care who's listening. Any number of services can react to the event. The email service hears "UserRegistered" and sends a welcome email. The analytics service hears the same event and updates the sign-up dashboard.

**Events are better for decoupling.** The user registration code doesn't need to know about emails, analytics, or any other system that cares about new users. It just announces what happened.

**Commands are simpler for direct tasks.** "Send this specific email" is clearer than "a thing happened, someone figure out what to do."

Start with commands for simplicity. Move to events when you find yourself adding more and more steps to a single operation.

## Dead Letter Queues

What happens when a message can't be processed? Maybe the email service is down, or the data in the message is corrupted. If the worker fails and the message goes back on the queue, it might fail again, and again, forever — a "poison message."

A dead letter queue (DLQ) catches these. After a message fails a certain number of times (typically 3–5), it's moved to a separate DLQ instead of being retried endlessly.

You can then:
- Inspect the failed messages to understand why they failed
- Fix the problem and replay them
- Discard them if they're no longer relevant

**Always set up a DLQ.** Without one, a single bad message can block your entire queue.

## Idempotency: Safe to Retry

Messages can be delivered more than once. The network hiccupped, the worker crashed after processing but before acknowledging, the queue retried. Your message handler must be safe to run multiple times without side effects.

**Bad:** "Add $50 to the user's balance." If this runs twice, they get $100.
**Good:** "Set the user's balance to $550 for transaction TX-123." If this runs twice, the result is the same.

Idempotency keys help: include a unique ID with every message. Before processing, check if you've already processed that ID. If you have, skip it.

See `rules/reliability.md` (concurrency section) and `guides/reliability/concurrency.md` for more on idempotency.

## Backpressure: When Work Piles Up

What happens when messages arrive faster than workers can process them? The queue grows. Memory fills up. Eventually, things break.

**Backpressure** is a mechanism that slows down producers when consumers can't keep up:

- **Queue size limits:** When the queue reaches a maximum size, reject new messages (and handle the rejection gracefully — show the user a "try again later" message).
- **Rate limiting on producers:** Limit how fast your application adds messages to the queue.
- **Scaling workers:** Add more worker processes when the queue grows. Many platforms can auto-scale workers based on queue depth.
- **Priority queues:** Process important messages first. A payment confirmation is more urgent than an analytics event.

The simplest approach: monitor your queue depth. If it's growing consistently, you need more workers or your workers are too slow.

## When You Don't Need Kafka

Kafka (and similar event streaming platforms) gets mentioned a lot, but it solves problems most applications don't have:

- Processing millions of events per second
- Replaying the complete history of events
- Multiple independent consumers reading the same stream at their own pace

If you're processing hundreds or thousands of messages per minute, a simple queue (Redis, SQS, RabbitMQ) is plenty. Kafka adds significant operational complexity.

**The rule of thumb:** If you're asking "should I use Kafka?", the answer is almost certainly no. When you actually need it, you'll know — because simpler tools will be measurably failing to keep up.

## Background Jobs for Solo & Serverless Projects

The queue theory above assumes you have a worker running somewhere. If you're a solo developer on serverless (Vercel, Netlify, Cloudflare Workers, Supabase), you often *don't* — and that changes the practical advice. Here's how to actually do background work when you don't run your own always-on server.

**Why you can't just do the slow thing inside the request.** A web request is meant to be quick. Serverless platforms kill a function after a short timeout (often 10–60 seconds), the user is stuck watching a spinner the whole time, and if the function is cut off mid-way the work is simply lost — with no retry. So sending a welcome email, generating a report, calling a slow AI model, or processing an uploaded image should *not* happen inside the request that the user is waiting on. Accept the request, hand the work off, respond immediately.

**The options ladder — climb only as high as you need:**

1. **Platform cron / scheduled functions.** For work on a schedule (nightly reports, hourly cleanup, "check for expired trials"). Vercel Cron, Cloudflare Cron Triggers, Supabase scheduled functions (pg_cron), or a GitHub Actions cron workflow. Zero extra infrastructure — you already have the platform. This is the simplest possible background system: a function that wakes up on a timer.

2. **Hosted queues.** For work triggered by a user action that shouldn't block the response ("they just signed up, send the email"). A hosted queue takes your job over HTTP and calls your function back later, with retries built in — no server to run. Upstash QStash (built for serverless, calls your endpoint), AWS SQS, Inngest, or Trigger.dev (these last two also handle multi-step workflows and scheduling). This is the sweet spot for most solo serverless apps.

3. **A real worker on a long-running host.** When volume is high enough that per-job HTTP calls get expensive or slow, run an actual always-on process (a small VM, a container, a Render/Railway/Fly worker) pulling from a queue. More to operate, so only climb here when the numbers justify it.

**Jobs run at-least-once, so make them idempotent.** Every option above can deliver the same job *twice* — a network hiccup, a retry after a timeout, a redelivery. If "send invoice email" runs twice, the customer gets two emails; if "charge the card" runs twice, that's real money. Give each job a stable idempotency key (the order ID, a UUID you generate once) and check "have I already done this one?" before acting. This is the same idea as the idempotency section above — see `guides/reliability/concurrency.md` and `rules/reliability.md`.

**Retry with backoff, and have a failure path.** When a job fails, retry it — but wait longer between each attempt (backoff) so you don't hammer a service that's already struggling. And cap it: after a handful of failures, send the job to a dead-letter/failure store (as covered above) instead of retrying forever. Most hosted queues do backoff and dead-lettering for you; make sure it's turned on, and make sure *someone gets alerted* when a job lands in the failure pile.

**Quick decision guide:**
- On a schedule? → platform cron.
- Triggered by a user action, low/medium volume? → hosted queue (QStash/Inngest/Trigger.dev).
- Multi-step or needs orchestration? → Inngest / Trigger.dev.
- High volume, cost-sensitive? → a real worker on a long-running host.

For more on running background work without your own server, see `guides/infrastructure/serverless-and-edge.md`.

## Getting Started

If your application doesn't use async processing yet and you want to add it:

1. **Identify the work that doesn't need to be synchronous.** Email sending is the classic first candidate.
2. **Pick a simple queue.** If you already use Redis, use a queue library built on Redis (Bull/BullMQ for Node.js, Celery for Python, Sidekiq for Ruby).
3. **Write a worker that processes messages.** Start with one type of job.
4. **Add a dead letter queue from the start.** Don't skip this.
5. **Make your handlers idempotent.** Design them to be safely retried.
6. **Monitor the queue depth.** Know when work is piling up.

Ask your AI: *"Help me set up a background job queue for [sending emails / processing images / generating reports]."*
