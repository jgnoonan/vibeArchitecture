# Something Broke

Your app isn't working. Take a breath. Follow these steps in order.

---

## Step 1: Don't Panic, Assess

- **Is it completely down, or partially broken?** (Whole site unreachable vs. one feature not working)
- **When did it start?** (After a deployment? After a change? Randomly?)
- **Who is affected?** (Everyone? Some users? Just you?)
- **Is it still happening?** (Sometimes problems resolve themselves — a temporary network issue, a service that recovered.)

## Step 2: Check the Obvious Things First

These catch the problem 80% of the time:

- [ ] **Is your hosting platform up?** Check your provider's status page (most have one). If they're having an outage, there's nothing to do but wait.
- [ ] **Did you deploy recently?** If the problem started right after a deployment, that deployment is the most likely cause. Roll back if you know how.
- [ ] **Did you change environment variables recently?** A typo in a database URL or API key will bring things down instantly.
- [ ] **Is your database accessible?** Can you connect to it from your hosting platform? Has it run out of storage? Has the password changed?
- [ ] **Have you hit a service limit?** Free tiers have limits (database rows, API calls, bandwidth, storage). Check if you've exceeded them.
- [ ] **Is a third-party service down?** If your app depends on an external API (payment processor, email service, AI provider), check their status pages too.

## Step 3: Look at the Logs

Logs are your best friend when things break. Find them:

- **Hosting platform logs:** Most platforms (Vercel, Railway, Fly.io, Heroku, etc.) have a log viewer in their dashboard.
- **Application logs:** If you set up logging, check the log output for error messages.
- **Database logs:** If you suspect a database issue, check the database service's logs or metrics.

**What to look for:**
- Error messages (anything with "error", "failed", "exception", "timeout", or "refused")
- Timestamps that match when the problem started
- Repeated errors (the same error appearing many times suggests a systematic problem, not a one-off)

**If you can't find logs:** This is a sign you need to set up better logging. For now, try to reproduce the problem locally where you can see error output directly.

## Step 4: Can You Reproduce It?

- Try to make the error happen again. Use the same steps, same inputs, same conditions.
- Try it locally (on your machine). If it works locally but not in production, the problem is likely:
  - Environment variables (missing or wrong in production)
  - Database differences (different data, different version)
  - Network/permissions (production can't reach a service that your machine can)
- If you CAN reproduce it locally, that's actually good news — it's much easier to debug on your machine.

## Step 5: Fix It

**If a recent deployment caused it:**
- Roll back to the previous working version.
- Then investigate what in the deployment caused the problem. Fix it locally, test it, then redeploy.

**If it's an environment or configuration issue:**
- Fix the environment variables, configuration, or credentials.
- Double-check by comparing production config against a working environment.

**If it's a code bug:**
- Isolate the failing component. Which endpoint, page, or function is broken?
- Check the error message — it usually points to the file and line where the problem is.
- Fix it, test locally, then deploy the fix.

**If it's a third-party service outage:**
- There's usually nothing you can do except wait.
- If this happens often, it's a sign your app needs better error handling for that service (showing a friendly message instead of crashing, using cached data, etc.).

**If you don't know what caused it:**
- Ask your AI for help. Share the error messages, logs, and what you've already checked.
- Explain what changed recently (deployments, configuration, data).

## Step 6: After It's Fixed

- [ ] **Confirm the fix is working.** Don't just deploy and walk away. Verify the problem is actually resolved.
- [ ] **Write down what happened.** Even a few sentences: what broke, why, and what you did to fix it. You'll thank yourself when a similar problem happens later.
- [ ] **Think about prevention.** Could monitoring have caught this sooner? Could a test have prevented it? Could the app have handled the failure more gracefully? You don't have to act on these immediately, but keep them in mind.

## Common Problems and Quick Fixes

| Symptom | Likely Cause | Quick Check |
|---------|-------------|-------------|
| "500 Internal Server Error" | Code error or missing config | Check application logs for the error message |
| "502 Bad Gateway" or "503 Service Unavailable" | App crashed or isn't starting | Check if the app process is running; check hosting platform logs |
| Page loads but shows no data | Database connection issue | Verify database credentials and connectivity |
| "Connection refused" | Service isn't running or wrong port/URL | Check that the database/service is running and the URL is correct |
| Everything is extremely slow | Database queries, memory, or external service | Check database performance, memory usage, and external API response times |
| Login doesn't work | Session/token configuration, wrong secrets | Verify auth-related environment variables in production |
| Works for you but not other users | Caching, DNS, regional differences | Try from a different browser, incognito mode, or different network |
| "CORS error" in browser console | API doesn't allow requests from your frontend's domain | Check and update CORS configuration on your API |
