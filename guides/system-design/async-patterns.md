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

## Getting Started

If your application doesn't use async processing yet and you want to add it:

1. **Identify the work that doesn't need to be synchronous.** Email sending is the classic first candidate.
2. **Pick a simple queue.** If you already use Redis, use a queue library built on Redis (Bull/BullMQ for Node.js, Celery for Python, Sidekiq for Ruby).
3. **Write a worker that processes messages.** Start with one type of job.
4. **Add a dead letter queue from the start.** Don't skip this.
5. **Make your handlers idempotent.** Design them to be safely retried.
6. **Monitor the queue depth.** Know when work is piling up.

Ask your AI: *"Help me set up a background job queue for [sending emails / processing images / generating reports]."*
