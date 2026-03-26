# Before You Build

Things to decide before you (or your AI) write the first line of code. You don't need perfect answers — but thinking through these now prevents expensive surprises later.

---

## What You're Building

- [ ] Can you describe what the app does in one or two sentences? If you can't, you're not ready to build yet.
- [ ] Have you checked if an existing product or service already does this? Sometimes the best code is no code.
- [ ] Do you know who will use this? (Just you? A small group? The public? Paying customers?)
- [ ] Have you filled out the vibeArchitecture Project Profile? (If not, ask your AI agent to run the intake questionnaire.)

## Accounts and Access

- [ ] Will users need to create accounts? If yes, how will they sign up and log in?
- [ ] Will there be different types of users (regular users, admins, etc.)? If so, what can each type do?
- [ ] If no accounts: can ANYONE access ALL features, or are some things restricted?

## Data

- [ ] What data will your app store? Make a list — even a rough one.
- [ ] Is any of that data sensitive? (Personal info, financial data, health records, passwords)
- [ ] Where will the data live? (A database, files, a third-party service)
- [ ] If the data were lost permanently, what would happen? (This tells you how seriously to take backups.)

## Money and Costs

- [ ] Do you have a hosting budget? Even a rough range helps.
- [ ] Will the app use any paid services? (Databases, email sending, file storage, AI APIs, payment processing)
- [ ] Have you looked at what those services cost? Free tiers have limits. Know what yours are.

## The Basics

- [ ] Is the project in a git repository? (If you're not sure what this is, ask your AI to set one up.)
- [ ] Do you have a `.gitignore` file? (This keeps private files from being uploaded to the internet.)
- [ ] If you have any API keys or passwords, are they in a `.env` file that's listed in `.gitignore`?

## Legal and Privacy (If Others Will Use Your App)

- [ ] If you collect personal information (names, emails, etc.), are you aware you likely need a privacy policy?
- [ ] If you handle payments, are you using an established payment processor (Stripe, Square, etc.) rather than handling card numbers yourself?
- [ ] If your users are in Europe, are you aware of GDPR requirements?
- [ ] If you handle health data, are you aware of HIPAA requirements?
- [ ] Do you need terms of service? (Generally yes, if strangers will use your app.)

## Deployment (Where It Will Live)

- [ ] Do you know where you'll deploy this? (Vercel, Railway, Fly.io, AWS, a VPS, etc.)
- [ ] Have you confirmed your app can actually run on that platform? (Some platforms have limitations on databases, file storage, or background jobs.)
- [ ] Do you have a domain name, or will you use the platform's default URL?

## What "Done" Looks Like

- [ ] What's the smallest version of this that would be useful? Start there.
- [ ] Are there features you're excited about but don't need on day one? Write them down and save them for later.
- [ ] How will you know if it's working correctly? (What would you test?)
