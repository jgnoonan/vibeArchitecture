# Payments — Why and How

> This guide explains why payment integrations go wrong and how to do them safely. Read it when you're integrating payments (Stripe, etc.).

## Why Payments Are Different

Most bugs cost you a support ticket. A payment bug costs you money — either you give away paid features for free, or you charge people incorrectly and lose their trust. Payment providers (Stripe, Paddle, Braintree, PayPal) handle the hard parts of moving money, but the way you wire them into your app is where the mistakes happen.

The single most important idea in this guide: **the browser is not trustworthy.** Anything the user's browser tells you — "I paid," "the amount was $5," "the payment succeeded" — can be faked by anyone who opens the developer tools. The truth about a payment comes from the payment provider's servers talking to your server. Everything below follows from that.

## The #1 Mistake: Granting Access on the Redirect

When a checkout finishes, the provider sends the user's browser back to a "success" page you control — something like `https://yourapp.com/success`. It is tempting to grant the paid feature right there: "they landed on `/success`, so they must have paid."

They didn't. A user can type that URL directly into their browser, or bookmark it, or share it. The redirect is just a browser navigation — it carries no proof of payment. If unlocking the feature happens on `/success`, anyone who guesses the URL gets the feature for free.

The correct source of truth is the **webhook**: a message the provider's servers send directly to your server when money actually moves. For Stripe this is the `checkout.session.completed` or `payment_intent.succeeded` event. You grant entitlement (mark the order paid, unlock the feature, extend the subscription) when you receive and **verify** that webhook — never on the redirect.

**"Completed" is not always "paid."** For delayed payment methods (bank debits, some bank transfers, buy-now-pay-later), Stripe sends `checkout.session.completed` when the customer *finishes checkout*, while `payment_status` is still `"unpaid"`; the money arrives days later. Grant access only when `payment_status == "paid"` on the completed event, or when the follow-up `checkout.session.async_payment_succeeded` event arrives (and revoke or never grant on `checkout.session.async_payment_failed`). Other providers have the same distinction under different names — find it before you ship.

The `/success` page should only say "Thanks, we're confirming your payment." The actual unlocking happens server-side, driven by the webhook.

```
❌ WRONG — trusting the browser redirect
  GET /success  →  markUserAsPaid(currentUser)   // anyone can hit this URL

✅ RIGHT — trusting the verified webhook
  POST /webhooks/stripe
    verifySignature(request)                       // reject forgeries
    if event.type == "checkout.session.completed"
       and event.data.object.payment_status == "paid":
        grantEntitlement(event.data.object.customer)   // real proof of payment
    if event.type == "checkout.session.async_payment_succeeded":
        grantEntitlement(event.data.object.customer)   // delayed methods settle here
  GET /success  →  "Thanks! Confirming your payment…"  // shows status only
```

## Verify Webhook Signatures

A webhook is just an HTTP request to a public URL. If your endpoint trusts whatever arrives, anyone who finds the URL can POST a fake "payment succeeded" event and unlock features for free. This is the payment equivalent of leaving the door unlocked.

Every provider signs its webhooks. Stripe sends a `Stripe-Signature` header; you have a **signing secret** (different from your API keys) that you use to confirm the request really came from Stripe and wasn't tampered with. Verify the signature **before** you read or act on the payload.

```js
// Stripe example — verify before trusting anything in the body
const sig = request.headers['stripe-signature'];
let event;
try {
  // Uses the RAW request body, not parsed JSON
  event = stripe.webhooks.constructEvent(rawBody, sig, WEBHOOK_SIGNING_SECRET);
} catch (err) {
  return response.status(400).send('Invalid signature'); // reject forgeries
}
// Only now is it safe to act on event.type / event.data
```

The shape is the same in any language: `verify(rawBody, signatureHeader, signingSecret)` → accept or reject. Two things people get wrong:

- **Use the raw request body.** Signatures are computed over the exact bytes received. If your framework parses the body into JSON first, verification fails — you need the raw payload.
- **Keep the signing secret in server-side env vars**, never in the frontend.

See `guides/api/api-security.md` for the broader "every endpoint is a door" mindset.

## Webhooks Must Be Idempotent

Providers do not promise to deliver each event exactly once. They promise to deliver it **at least once** — which means the same event can arrive twice (or more) because of retries, network hiccups, or timeouts on your side. If your handler grants a month of access or ships a product every time it runs, a duplicate delivery double-charges your fulfillment: two shipments, two months of access, two credit top-ups.

Make the handler **idempotent** — safe to run more than once with the same result. Every event has a unique ID (Stripe: `event.id`). Record which event IDs you've already processed and skip duplicates:

```
onWebhook(event):
    if alreadyProcessed(event.id):   // seen this exact event before
        return 200 OK                 // acknowledge, do nothing
    grantEntitlement(...)
    markProcessed(event.id)           // record atomically with the grant
```

Store the processed ID in the same database transaction as the entitlement so the two can't get out of sync. This is a specific case of a general problem — see `guides/reliability/concurrency.md` for how duplicate and concurrent operations cause double-processing and how to guard against them.

Also: **acknowledge fast.** Return `200` quickly once you've safely recorded the event. If the work is slow, record the event and do the heavy lifting in a background job. A slow endpoint looks like a failure to the provider, which then retries — creating more duplicates.

## Keep Secret Keys Server-Side

Payment providers give you (at least) two kinds of keys:

- **Publishable / public key** — safe to include in your frontend. It can only start a checkout, not read data or move money.
- **Secret key** — full power over your account. It can issue refunds, read customer data, and create charges.

The secret key belongs in **server-side environment variables only.** Never commit it to your repository, never send it to the browser, never put it in client-side JavaScript. If it leaks, an attacker can drain your account and access customer records. If you ever suspect a leak, roll (regenerate) the key immediately in the provider dashboard.

This mirrors the general rule in `rules/api.md`: secrets live on the server, in config, out of source control.

## Reconcile Amounts and Currency Server-Side

If your checkout takes the price from the browser — a hidden form field, a query parameter, a JSON body — the user can change it. `amount=1000` becomes `amount=1`, and you sell a $10 product for one cent.

Never trust an amount, currency, quantity, or discount that came from the client. Look up the price on your **server** from your own database or the provider's product catalog, and build the checkout from that. The client sends *which* product the user wants (a product ID); the server decides what it costs.

The same applies when you handle the webhook: confirm the amount and currency the provider reports match what you expected for that order before fulfilling. If they don't match, flag it rather than shipping.

## Keep Card Data Off Your Server (PCI Scope)

If raw credit card numbers ever pass through your server, you inherit the full weight of **PCI DSS 4.0.1** — the payment card industry's security standard — with its audits and strict requirements. That is a burden you almost never want.

The way out is to **never let card data touch your server.** Use the provider's **hosted checkout page** (the user is redirected to Stripe's own page) or an embedded field like **Stripe Elements / Payment Element**, where the card number is captured by an iframe owned by the provider and sent straight to them. Your server only ever sees a token or a reference — never the actual card number.

This dramatically shrinks your PCI scope: you're handling references, not card data — typically the SAQ A self-assessment. **SAQ A is smaller, not empty.** Since PCI DSS 4.0.1's requirements became mandatory (March 2025), merchants that embed the provider's iframe or redirect from their own page must meet **Requirement 6.4.3** (inventory every script on the payment page, with a written justification, and ensure its integrity — CSP, SRI, or a script-monitoring tool) and **Requirement 11.6.1** (a mechanism that detects unauthorized changes to the payment page's HTTP headers and content, checked at least weekly). This is the Magecart threat: an attacker who can inject one script onto your checkout page skims cards straight out of the iframe's parent. Keep the payment page lean, lock it down with CSP, and use your provider's or a third-party page-integrity monitor. See `rules/compliance.md` for how hosted checkout and tokenization reduce PCI DSS scope, and when a fuller compliance obligation still applies.

## Failed and Disputed Payments, and Subscriptions

Payments aren't a single moment — they have a lifecycle, and the provider tells you about each stage through more webhook events. Handle these at least at a basic level:

- **Failed payments** — a card gets declined, or a subscription renewal fails (Stripe: `invoice.payment_failed`). Don't silently keep the feature unlocked forever. Notify the user, give them a chance to update their card (a "dunning" flow), and revoke access after a grace period if it stays unpaid.
- **Disputes / chargebacks** — a customer tells their bank the charge was wrong (Stripe: `charge.dispute.created`). Money can be pulled back from you. At minimum, log these and alert a human; you may want to revoke access to the disputed purchase.
- **Subscription lifecycle** — subscriptions renew, get cancelled, upgraded, or downgraded, each with its own event (`customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid`). Drive access from these events, not from a one-time "they paid once" flag. Someone who cancelled should lose access when the paid period ends.

You don't need to handle every event on day one, but design so that access is a reflection of the *current* subscription state the provider reports — not a permanent switch you flip once.

## Quick Checklist for Payment Integrations

- [ ] Entitlement is granted **only** on a verified webhook, never on the `/success` redirect
- [ ] Entitlement requires `payment_status == "paid"` (or `checkout.session.async_payment_succeeded`) — not merely "completed"
- [ ] Every webhook endpoint verifies the provider's signature before trusting the payload
- [ ] Signature verification uses the **raw** request body
- [ ] Webhook handlers are idempotent — dedupe by event ID so retries don't double-grant
- [ ] Handlers acknowledge quickly (`200`), doing slow work in the background
- [ ] Secret key lives in server-side env vars only; publishable key in the client
- [ ] Prices, amounts, currency, and discounts are decided server-side, never trusted from the client
- [ ] Card data never touches your server — hosted checkout or provider-owned Elements only
- [ ] Payment page scripts are inventoried and integrity-protected, with change detection (PCI DSS 4.0.1 reqs 6.4.3 / 11.6.1)
- [ ] Failed payments (`invoice.payment_failed`) trigger notification and eventual access revocation
- [ ] Disputes are logged and alert a human
- [ ] Access reflects current subscription state, not a one-time "paid" flag
- [ ] Related reading: `guides/api/api-security.md`, `guides/reliability/concurrency.md`, `rules/compliance.md`, `rules/api.md`
