# Deployment — Why and How

> This guide explains deployment practices, strategies, and why they matter. Read it when setting up your deployment process or choosing a deployment strategy.

## What "Deployment" Actually Means

Deployment is the process of getting your code from "working on my machine" to "running on a server that users can access." It includes:

1. Building the application (compiling, bundling, etc.)
2. Running tests to verify nothing is broken
3. Packaging it for the target environment
4. Sending it to the server(s)
5. Starting the new version
6. Verifying it's working
7. Routing user traffic to it

Each step can fail. Automating all of them eliminates human error and makes deployments boring and routine — which is exactly what you want.

## CI/CD — Continuous Integration and Continuous Deployment

### Continuous Integration (CI)

Every time code is pushed to the repository, an automated process:
1. Checks out the code
2. Installs dependencies
3. Runs the test suite
4. Reports success or failure

This catches bugs before they reach production. If tests fail, the deployment doesn't happen.

### Continuous Deployment (CD)

After CI passes, an automated process deploys the code to the target environment. The full pipeline:

```
Push code → Run tests → Build → Deploy to staging → Run integration tests → Deploy to production
```

### Why Automation Matters

Manual deployment processes:
- Depend on a specific person being available
- Skip steps when someone is in a hurry
- Introduce subtle differences between deployments
- Create anxiety ("deployment day" shouldn't be a stressful event)
- Can't be rolled back quickly

Automated deployment processes:
- Run the same way every time
- Run every check, every time
- Can be triggered by anyone on the team
- Make deployments routine and low-risk
- Enable fast rollback

### Getting Started

Most hosting platforms have CI/CD built in:
- **Vercel, Netlify:** Deploy on push to main branch, automatic
- **Railway, Render:** Connect to GitHub, deploy on push
- **Fly.io:** `fly deploy` command, can be automated with GitHub Actions
- **GitHub Actions:** Flexible CI/CD that works with any hosting

For a simple project, "deploy on push to main" with a test step is a good starting point.

## Deployment Strategies

### Rolling Deployment

The new version gradually replaces old instances. If you have 4 servers, one at a time gets the new version while the others continue running the old version.

**Advantages:** Simple, low-risk, no extra infrastructure needed.
**Disadvantages:** For a brief period, old and new versions run simultaneously. Your code must handle this (database schema must work with both versions).
**Best for:** Most applications, most of the time.

### Blue-Green Deployment

Two identical environments exist: "blue" (current production) and "green" (new version). You deploy to green, test it, then switch all traffic from blue to green. If something goes wrong, switch back instantly.

**Advantages:** Zero-downtime deployment, instant rollback.
**Disadvantages:** Requires double the infrastructure (temporarily). Database changes need care since both environments share the database.
**Best for:** Applications where downtime is unacceptable and fast rollback is critical.

### Canary Deployment

Send a small percentage of traffic (1%, 5%, 10%) to the new version. Monitor for errors. If everything looks good, gradually increase. If problems appear, route all traffic back to the old version.

**Advantages:** Catches problems before they affect all users. Real production traffic is the ultimate test.
**Disadvantages:** More complex to set up. Requires good monitoring to detect problems at low traffic percentages.
**Best for:** High-traffic applications where a bug affecting all users would be severe.

### Feature Flags

Deploy code to production but keep new features hidden behind a configuration switch. Enable the feature for specific users (internal team first, then beta users, then everyone).

**Advantages:** Separates deployment from release. You can deploy code daily but release features weekly. If a feature causes problems, disable it without deploying.
**Disadvantages:** Adds complexity to your code (conditional logic around features). Old feature flags need cleanup.
**Best for:** Teams that want to deploy frequently and control feature rollout independently.

### What to Start With

Start with rolling deployments or your platform's default strategy. Move to canary or feature flags when your application's scale or criticality demands it. Blue-green is worth considering whenever you need zero-downtime deploys.

## Rollback

### The Non-Negotiable Rule

Before every deployment, know the answer to: "If this breaks production, how do I undo it, and how long will that take?"

### Rollback vs. Roll Forward

- **Rollback:** Deploy the previous working version. Fast, known to work, buys time to investigate.
- **Roll forward:** Fix the bug and deploy a new version. Takes longer but avoids any issues with reverting.

**Use rollback when:** The problem is serious and users are impacted right now. You don't have time to diagnose.

**Use roll forward when:** The problem is minor, you know the fix, and it can be deployed quickly.

### Database Rollback Complications

Code rollback is straightforward — deploy the previous version. Database changes are harder:
- If the new deployment added a column, the old code doesn't know about it (usually fine).
- If the new deployment removed a column, the old code expects it (broken).
- If the new deployment changed data format, the old code may not understand the new format (broken).

This is why database schema changes should be **backward compatible**. The expand-and-contract pattern (see the schema design guide) exists specifically to make rollback safe.

## Environment Configuration

### The Rule: Same Process, Different Config

Your deployment process should be identical for all environments. The ONLY differences between development, staging, and production should be:
- Environment variables (database URLs, API keys, feature flags)
- Scale (smaller instances, fewer replicas)
- Data (test data vs. real data)

Never hardcode environment-specific values. Never maintain separate code branches for different environments.

### Production Mode

Most frameworks have a "development mode" that:
- Shows detailed error pages with stack traces
- Enables hot reloading
- Disables caching
- May expose debug endpoints

All of these must be disabled in production. Ensure your framework is configured for production mode in your deployment. This is usually an environment variable like `NODE_ENV=production` or `RAILS_ENV=production`.
