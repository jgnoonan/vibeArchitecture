# Threat Modeling: Thinking Like an Attacker

> For the compact rules, see `rules/security.md`.

## What Is Threat Modeling?

Threat modeling is the practice of asking: "What could go wrong with my application's security, and what am I going to do about it?"

You don't need to be a security expert to do this. You just need to think systematically about who might attack your app, how they'd do it, and which attacks would hurt the most. Then you focus your defenses on the threats that matter.

**Analogy:** When you lock up your house, you think about how someone could break in. Front door, back door, windows, garage. You don't install a bank vault door — you get good locks on the doors and windows that matter. Threat modeling is the same thinking applied to software.

## Why Bother?

Most security breaches exploit basic, well-known vulnerabilities — not sophisticated zero-day attacks. Hardcoded API keys, SQL injection, missing authentication on admin endpoints, overly permissive access. These are the unlocked windows.

Threat modeling helps you find them before an attacker does. 30 minutes of thinking about threats can prevent months of incident response.

## A Simple Threat Modeling Process

You don't need a formal methodology to start. Just answer four questions:

### 1. What are you protecting?

List the valuable things in your application:

- **User data:** Emails, passwords, personal information, payment details
- **Business data:** Financial records, intellectual property, analytics
- **System access:** Admin accounts, API keys, database credentials, deployment pipelines
- **Reputation:** User trust, which evaporates the moment you have a data breach

Be specific. "User data" isn't enough. What user data? Emails and names? Credit card numbers? Medical records? The sensitivity determines the level of protection.

### 2. Who might attack you?

Think about the likely threats for your specific application:

- **Opportunistic attackers:** Automated bots scanning the internet for known vulnerabilities. They don't target you specifically — they target everyone. This is the most common threat and the easiest to defend against (keep software updated, don't use default passwords, follow the rules in `rules/security.md`).
- **Credential stuffers:** Attackers who have stolen username/password lists from other breaches and try them on your site. This is why your users need strong, unique passwords and you should support two-factor authentication.
- **Malicious users:** People who have legitimate accounts but try to access data they shouldn't. "Can I see other users' data by changing the ID in the URL?" This is authorization testing.
- **Insiders:** People with legitimate access (employees, contractors, AI agents with API keys) who misuse it. Limit access to what people actually need — the principle of least privilege.
- **Targeted attackers:** Someone specifically going after your application. Uncommon for small applications, but real for apps handling money, health data, or political content.

For most applications, the first three categories cover 99% of real threats.

### 3. How would they do it?

For each threat, think about the attack path. A useful framework is **STRIDE** — six categories of attacks:

**Spoofing — pretending to be someone else**
- Using stolen credentials to log in as another user
- Forging API tokens
- Sending emails that look like they're from your application

**Tampering — modifying data without permission**
- Changing a price in a hidden form field before submitting
- Modifying request data between the browser and server
- SQL injection to modify database records

**Repudiation — denying an action happened**
- "I never placed that order" (without audit logs, you can't prove they did)
- Deleting evidence of unauthorized access
- Changing timestamps

**Information Disclosure — exposing data that should be private**
- Error messages that reveal database structure or file paths
- API endpoints that return more data than the user should see
- Logs that contain passwords or personal data
- Source code accidentally deployed to production

**Denial of Service — making the app unavailable**
- Flooding the API with requests
- Submitting extremely expensive queries
- Filling up disk space with uploads

**Elevation of Privilege — gaining access beyond what's allowed**
- A regular user accessing admin functions
- Exploiting a bug to bypass authorization checks
- Using a low-privilege API key to access high-privilege operations

You don't need to worry about all of these for every application. Focus on the ones that are most relevant:

- **Every application** should worry about: Spoofing (auth), Tampering (input validation), Information Disclosure (data leaks)
- **Applications with user roles** should also worry about: Elevation of Privilege
- **Business applications** should also worry about: Repudiation (audit logging), Denial of Service

### 4. What are you going to do about it?

For each threat you've identified, choose one of four responses:

- **Mitigate:** Reduce the risk with a specific defense. "SQL injection → use parameterized queries."
- **Accept:** Acknowledge the risk and decide it's tolerable. "A targeted nation-state attack is possible but extremely unlikely given our app's purpose."
- **Transfer:** Shift the risk to someone else. "Use a payment processor (Stripe) so we never touch credit card numbers directly."
- **Avoid:** Don't do the thing that creates the risk. "We won't store Social Security numbers because we don't actually need them."

## Defense in Depth

Don't rely on a single defense. Layer your protections so that if one fails, another catches the attack:

- **Layer 1: Input validation** — Reject obviously bad data at the API boundary
- **Layer 2: Authentication** — Verify the user is who they claim to be
- **Layer 3: Authorization** — Verify the user is allowed to do what they're requesting
- **Layer 4: Data protection** — Encrypt sensitive data, use parameterized queries
- **Layer 5: Monitoring** — Detect unusual patterns that suggest an attack in progress
- **Layer 6: Backups** — If all else fails, recover from a known good state

Think of it like a castle: moat, walls, locked doors, guards, a safe for the valuables. An attacker has to get past all of them.

## Your First Threat Model

Don't try to cover everything at once. Start with this 15-minute exercise:

1. **List your sensitive data.** What data, if exposed, would cause real harm?
2. **Check the basics.** For each item in `rules/security.md`, ask: "Is this protecting my sensitive data?"
3. **Test authorization.** Log in as a regular user. Try to access admin functions by modifying URLs. Try to access another user's data by changing IDs in the URL.
4. **Check for hardcoded secrets.** Search your codebase for API keys, passwords, and connection strings that aren't in environment variables.
5. **Review error messages.** Do your error pages reveal information that would help an attacker (stack traces, SQL queries, file paths)?

That's a threat model. Write down what you found and what you're going to fix. You've just done something that many professional teams skip.

## When to Revisit

Threat modeling isn't a one-time event. Revisit it when:

- You add a new feature that handles sensitive data
- You integrate with a new third-party service
- You change how authentication or authorization works
- You've had a security incident
- You're preparing for a major release

Ask your AI: *"Help me do a quick threat model for the [feature/endpoint] I'm building. What are the main security risks?"*
