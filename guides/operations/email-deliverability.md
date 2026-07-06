# Email Deliverability — Why and How

> This guide explains how to make sure the email your app sends actually arrives. Read it when your app sends email (verification, password reset, receipts, notifications).

## Why This Matters

Most apps depend on email to work at all. If a new user never gets their verification link, they can't finish signing up. If a password-reset email lands in spam, they're locked out. If a receipt never arrives, they think the payment failed. These aren't marketing problems — they're login and reliability problems.

The trap is that sending email *looks* like it works during development. You send yourself a test message, it shows up, you move on. Then real users on Gmail, Outlook, and Yahoo never see anything, because those providers silently filter mail from senders they don't trust. There's no error. The email just quietly disappears into spam or gets rejected.

This guide covers the small number of things you must do so that your email is trusted and delivered.

## Don't Send Raw Email From Your App Server

The naive approach is to have your application open an SMTP connection and send mail directly. Avoid this. Two reasons:

- **Reputation.** Big mail providers decide whether to trust you based on the reputation of the server (IP address) sending the mail. A fresh cloud server has no reputation, so your mail gets treated as suspicious. Dedicated email providers maintain trusted infrastructure and reputation for you.
- **Cloud providers block it anyway.** Most cloud hosts (AWS, Google Cloud, Azure, DigitalOcean, and others) block outbound port 25 by default to prevent spam. Your direct SMTP attempts will often just fail.

**Use a transactional email provider.** These are services built specifically for app-generated email. Common ones:

- **Resend** — developer-friendly, simple setup, popular with newer projects
- **Postmark** — strong reputation, focused on transactional mail
- **SendGrid** — widely used, large free tier
- **Amazon SES** — cheap at scale, more setup work
- **Mailgun** — established, good API

Any of these is fine. You send email by calling their API (or their SMTP relay); they handle the trusted infrastructure. Pricing is covered in `guides/operations/cost-management.md` under Third-Party Services — for most small apps this is a few dollars a month or free.

## Authenticate Your Sending Domain

Mail providers won't trust you just because you signed up with a provider. You have to prove that email claiming to come from your domain is really authorized by you. This is done with three DNS records:

- **SPF** (Sender Policy Framework) — lists which servers are allowed to send email for your domain. If mail comes from somewhere else, it's suspect.
- **DKIM** (DomainKeys Identified Mail) — adds a cryptographic signature to each message that proves it genuinely came from your domain and wasn't altered or forged in transit.
- **DMARC** (Domain-based Message Authentication) — a policy record that tells receiving servers what to do when a message fails SPF or DKIM (ignore, quarantine to spam, or reject), and where to send reports about who's sending mail as you.

Think of it like a signed, sealed letter on official letterhead. SPF says which post offices may mail on your behalf, DKIM is the tamper-proof wax seal, and DMARC is the instruction on file telling the recipient what to do if the seal is broken.

**Without these records, Gmail and Outlook will route you to spam or reject you outright.** And as of February 2024, Gmail and Yahoo *require* SPF, DKIM, and DMARC for bulk senders (roughly 5,000+ messages a day) — but the same signals decide trust for small senders too, so set them up regardless of volume.

Your email provider generates the exact record values and gives you copy-paste instructions. You add them to your domain's DNS. This is usually three records and takes about fifteen minutes.

## Use a Real Sending Domain You Control

Send from an address at a domain you own — ideally a dedicated subdomain like `mail.yourapp.com` or `notifications.yourapp.com`. Set the from-address to something like `noreply@mail.yourapp.com`.

**Do not send from a free `@gmail.com` (or `@yahoo.com`, `@outlook.com`) address.** You can't add DKIM/DMARC records to Gmail's domain, and Gmail publishes a strict DMARC policy of its own — so mail sent "from" a gmail.com address through your app will fail authentication and get rejected. It also looks like exactly the kind of forgery these systems are designed to stop.

## Separate Transactional From Marketing Email

Transactional email is mail the user needs: verification, password reset, receipts, security alerts. Marketing email is mail you want to send: newsletters, promotions, re-engagement.

Keep them on **separate subdomains or separate sending streams** — for example, `mail.yourapp.com` for transactional and `news.yourapp.com` for marketing.

Why: marketing email gets spam complaints and unsubscribes; that's normal. But those complaints damage the sending reputation of whatever domain they come from. If your password-reset emails share a domain with your newsletter, a bad marketing campaign can tank the deliverability of critical login mail. Keeping them separate means a marketing problem can never lock your users out.

## Protect Your Reputation

Deliverability is earned over time and easily lost. A few habits:

- **Warm up gradually.** Don't go from zero to 50,000 emails overnight on a brand-new domain. Ramp volume up over days or weeks so providers see a steady, trustworthy pattern. (Most transactional apps grow naturally and never need to think about this — it matters mainly for large launches or migrations.)
- **Watch bounce and complaint rates.** Your provider's dashboard shows these. High **bounces** (mail to addresses that don't exist) and high **complaints** (people marking you as spam) signal to providers that you're a bad sender. Keep complaint rates well under 0.3% — Gmail's stated threshold.
- **Honor unsubscribes immediately.** For any non-essential mail, include a working unsubscribe link and stop sending the moment someone opts out. Since 2024, bulk senders must support one-click unsubscribe. Ignoring opt-outs generates complaints and, in many places, breaks the law.
- **Don't repeatedly email unverified addresses.** If someone typed their address wrong, hammering it with retries just piles up bounces. Send the verification once (with a resend option), and stop mailing an address that hard-bounces.

## Testing Your Setup

Before you rely on email in production, test it against the providers real users actually use:

1. **Send a real message to a Gmail address and an Outlook address** — not just to yourself on the same domain. Test the actual verification and password-reset flows.
2. **Check the spam folder**, not just the inbox. Landing in spam is a failure, even though the mail technically "arrived."
3. **Inspect the authentication results.** In Gmail, open the message, click the three-dot menu, and choose "Show original." You want to see `SPF: PASS`, `DKIM: PASS`, and `DMARC: PASS`. A free tool like mail-tester.com does the same check and gives you a score plus specific fixes.
4. **Confirm links work end-to-end** — that the verification and reset links in the delivered email actually complete the flow.

If SPF, DKIM, or DMARC show anything other than PASS, fix the DNS records before launching. That's almost always the cause of mail going missing.

## Verification and Reset Links Must Expire

Deliverability gets the email into the inbox; security governs what's inside it. Verification and password-reset links are effectively temporary keys to an account, so they must **expire** (minutes to an hour, not days) and be **single-use** (invalid the moment they're used once). A reset link that lives forever in an inbox is a permanent backdoor.

This is an authentication concern — see `guides/security/authentication.md` and the token rules in `rules/security.md`.

## Quick Checklist

- [ ] Sending through a transactional email provider, not raw SMTP from your app server
- [ ] SPF, DKIM, and DMARC records added to your domain's DNS
- [ ] Sending from a domain/subdomain you control (`mail.yourapp.com`), not a free gmail.com address
- [ ] Transactional and marketing email on separate subdomains/streams
- [ ] Tested to real Gmail and Outlook inboxes, checked spam folder, confirmed SPF/DKIM/DMARC all PASS
- [ ] Watching bounce and complaint rates in the provider dashboard
- [ ] Unsubscribe honored for non-essential mail; not repeatedly emailing bad addresses
- [ ] Verification and reset links expire and are single-use

## Minimum Setup (Solo Dev)

> You don't need a deliverability specialist. The minimum viable setup is:
>
> 1. **Sign up for a transactional email provider** (Resend, Postmark, SendGrid, SES, or Mailgun).
> 2. **Verify a sending domain** you own — use a subdomain like `mail.yourapp.com`.
> 3. **Add the 3 DNS records** the provider gives you (SPF, DKIM, DMARC) to your domain.
> 4. **Send a test email to a real Gmail and Outlook address**, check the spam folder, and confirm SPF/DKIM/DMARC all show PASS (via "Show original" or mail-tester.com).
>
> Provider + verified domain + three DNS records + one test. That's the whole job, and it's the difference between your users receiving their login emails and never seeing them.
