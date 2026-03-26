# Project Intake Questionnaire

## Instructions for the AI Agent

Walk the user through these questions to understand their project and determine the appropriate tier of architectural guidance.

### How to conduct this conversation

1. **Explain what's happening first.** Say something like: *"Before we start building, I'd like to ask a few questions about your project. This helps me give you the right level of guidance — not too much for a simple project, not too little for something critical. It takes about 5 minutes."*
2. **Ask one or two questions at a time.** Do not present all questions at once.
3. **Use the wording below** (or natural variations). The questions are written in plain English deliberately.
4. **Adapt based on answers.** Follow the skip logic noted in each question.
5. **Be conversational, not interrogative.** This should feel like a helpful chat, not a form.
6. **After all questions**, determine the tier using the logic at the end of this document.
7. **Generate PROJECT_PROFILE.md** using the template, then confirm it with the user.

---

## The Questions

### Q1: What are you building?

*Ask:* "Tell me about what you want to build. Just describe it in your own words — what will it do, and what problem does it solve?"

Purpose: Establishes context. Also helps identify if an existing product might be a better fit.

**After the user answers:** If the project sounds like something well-served by an existing product (standard blog, e-commerce store, CMS, landing page, portfolio site), mention it once, gently:

*"That sounds similar to what [product] does out of the box. Have you looked into that? Using an existing product can save a lot of time. Building your own is totally fine — just want to make sure you know the option exists."*

If they want to proceed with building, move on. Never push back more than once.

---

### Q2: Who will use this?

*Ask:* "Who is this for?"
- **Just me** — personal project, learning, experimenting
- **People I know** — friends, family, coworkers, a small group
- **Anyone on the internet** — public sign-up, open access
- **Paying customers** — people pay for this, or a business depends on it

This is the primary tier determinant:
- "Just me" → **Personal**
- "People I know" → **Shared**
- "Anyone on the internet" → **Public**
- "Paying customers" → **Business**

**If "Just me":** Skip Q7 and Q8.

---

### Q3: Will people need to log in?

*Ask:* "Will users need to create an account or log in?"
- **No** — anyone can use it without an account
- **Yes** — users will sign up and log in

If No and tier is Personal or Shared: simplifies security guidance significantly.

---

### Q4: What information will you store?

*Ask:* "What kind of information will your app store? Pick everything that applies."
- Names, email addresses, or phone numbers
- Passwords (for login — the system stores them even if users don't see them)
- Payment or financial information (credit cards, bank details, transactions)
- Health or medical information
- Government-issued IDs (SSN, driver's license, passport numbers)
- Location tracking or movement data
- None of the above — just non-personal stuff (todos, game scores, preferences)

**Tier upgrades based on answers:**
- Health/medical data → upgrade to **Regulated**
- Payment/financial data → upgrade to at least **Business**
- Government IDs → upgrade to at least **Business**
- Names/emails/phone → flag that a privacy policy is likely needed

---

### Q5: How will people use it?

*Ask:* "How will people access your app?"
- **Web browser** — a website or web app
- **Mobile app** — iOS, Android, or both
- **Desktop app** — installed on a computer
- **API** — other programs connect to it
- **Command-line tool** — run from a terminal
- **More than one of these**

Skip if Q2 was "Just me" and the project is clearly a local script or tool.

---

### Q6: Where will it run?

*Ask:* "Where will your app be hosted?"
- **Just on my computer** — not on the internet
- **In the cloud** — AWS, Google Cloud, Azure, Vercel, Railway, Fly.io, etc.
- **On a company's internal network** — not accessible from the public internet
- **Not sure yet**

If "Just on my computer" combined with "Just me" from Q2: almost certainly **Personal** tier.

If "Not sure yet": recommend cloud hosting for anything above Personal tier. Note the uncertainty in the profile.

---

### Q7: How many users do you expect?

*Ask:* "Roughly how many people will use this? A ballpark is fine."
- **Under 100**
- **Hundreds to a few thousand**
- **Tens of thousands or more**
- **No idea**

**Skip if Q2 was "Just me."**

If "No idea": that's fine. Design for hundreds initially, make it possible to scale later.

---

### Q8: What happens if it stops working?

*Ask:* "Imagine your app goes down completely. What's the impact?"
- **No big deal** — I'll fix it when I get to it
- **Annoying** — some people will be inconvenienced
- **Serious** — people can't do their work or important tasks
- **Critical** — money is lost, legal issues arise, or people could be harmed

**Skip if Q2 was "Just me."**

If "Critical": upgrade to at least **Business**. If combined with sensitive data from Q4, likely **Regulated**.

---

### Q9: What's your budget?

*Ask:* "Do you have a budget for hosting and cloud services?"
- **Free tier only** — $0/month
- **Small** — up to $25/month
- **Moderate** — up to $100/month
- **Flexible** — whatever it takes

**After answering, give a reality check based on the tier:**
- Personal: "Good news — you can do this for free or nearly free."
- Shared: "A small cloud setup typically runs $5–25/month."
- Public: "A public app usually costs $20–100/month depending on traffic and storage. Databases, file storage, and email services each add cost."
- Business: "A production business app typically runs $100–500+/month for infrastructure, depending on scale and reliability needs."
- Regulated: "Compliance requirements add cost — security tooling, audit logging, specialized hosting. $200–1,000+/month is common."

If their budget doesn't match typical costs for their tier, flag it honestly but constructively.

---

### Q10: New project or existing code?

*Ask:* "Are we starting from scratch, or adding to an existing project?"
- **Starting from scratch**
- **Adding to existing code**

If existing code: note in the profile that the AI should review the current codebase against the tier's rules and flag areas of concern before adding new features.

---

## Tier Determination Logic

```
Start with Q2 answer:
  "Just me"              → Personal
  "People I know"        → Shared
  "Anyone on the internet" → Public
  "Paying customers"     → Business

Then check for upgrades (tier can only go UP):
  Q4 has health/medical data            → Regulated
  Q4 has payment/financial data          → at least Business
  Q4 has government IDs                  → at least Business
  Q8 is "Critical"                       → at least Business
  Q8 is "Critical" + sensitive data (Q4) → Regulated
```

---

## After Determining the Tier

1. **Tell the user their tier and what it means.** Read from `tier-definitions.md`. Be encouraging, not intimidating. Example: *"Based on your answers, this is a Public-tier project. That means we'll apply security and data protection rules appropriate for an app that strangers on the internet will use. Nothing scary — just smart defaults."*

2. **Flag warnings where needed:**
   - Storing personal data at any tier: *"Since you're storing personal information, you'll likely need a privacy policy. I can't write legal documents, but it's worth looking into a template or getting professional advice."*
   - Health/financial data: *"This type of data has legal requirements around storage and handling. I'll apply the right architectural rules, but you should also consult someone who knows [HIPAA/PCI-DSS] requirements."*
   - Budget mismatch: *"Based on what you've described, hosting typically costs [range]. Your budget of [amount] might be tight. We can discuss options to work within it."*

3. **Fill in PROJECT_PROFILE.md** with answers and tier. Use the template in the project root.

4. **Confirm with the user:** *"Here's what I've captured. Does this look right? We can adjust anything."*

5. **Load the rules** from `rules/_index.md` for the determined tier and begin building.
