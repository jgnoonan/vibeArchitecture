# Before You Deploy

Your app works on your machine. Before you put it on the internet, walk through this list. Not every item applies to every project — skip what's clearly irrelevant to yours.

---

## Security

- [ ] Are all API keys, passwords, and secrets stored in environment variables (NOT in your code)?
- [ ] Double-check: is your `.env` file in `.gitignore`? Run `git status` and make sure it doesn't show up.
- [ ] Search your code for any hardcoded passwords, API keys, or tokens. (Ask your AI to help: "Search the codebase for hardcoded secrets.")
- [ ] Is your app served over HTTPS? (Most hosting platforms handle this automatically. Confirm it's on.)
- [ ] If users log in: are passwords hashed (not stored in plain text)?
- [ ] If users log in: does logging out actually end the session?
- [ ] Have you tested what happens when someone enters garbage into your forms? (Random characters, extremely long strings, script tags, blank required fields.)

## Data

- [ ] Is your database backed up? Do you know how to restore it?
- [ ] If your database were deleted right now, would you lose everything? If yes, fix that before deploying.
- [ ] Have you tested with more data than "just a couple of test records"? Some problems only show up with real-world amounts of data.
- [ ] Are database migrations up to date and committed to your repository?

## Error Handling

- [ ] Does your app show a helpful error page instead of crashing with a technical error message?
- [ ] If an external service (API, database, email) goes down, does your app handle it gracefully or crash?
- [ ] Try accessing a URL that doesn't exist in your app. Do you get a proper "not found" page?
- [ ] Try submitting a form with missing or invalid data. Does the app show a clear error message or does it break?

## Environment

- [ ] Is your production environment set up separately from your development environment? (Different database, different secrets, etc.)
- [ ] Are your environment variables configured in your hosting platform? (They won't read your local `.env` file.)
- [ ] Have you set your app to "production" mode? (Many frameworks have a development mode that shows debug info — you don't want that public.)
- [ ] Have you removed or disabled any test/debug features? (Debug panels, test accounts, development-only API endpoints.)

## Access and Accounts

- [ ] If your app has admin features: is the admin area properly protected? (Not just a hidden URL — actually requiring authentication.)
- [ ] Have you changed any default passwords? (Database admin, hosting dashboard, CMS admin, etc.)
- [ ] If you created a test account with a simple password during development, delete it or change the password.

## Performance Basics

- [ ] Does the main page load in a reasonable time? (Under 3 seconds on a normal connection is a good target.)
- [ ] If your app loads images: are they reasonably sized? (A 5MB photo as a thumbnail will make your site crawl.)
- [ ] Are large lists paginated? (If a page tries to show 10,000 items at once, it will freeze the browser.)

## Monitoring

- [ ] Will you know if your app goes down? (Set up a free uptime monitor like UptimeRobot, Better Stack, or your hosting platform's built-in monitoring.)
- [ ] Can you see error logs from your deployed app? (Know where they are and how to access them.)
- [ ] Do you have a way to check if requests are succeeding or failing? (Even basic access logs help.)

## Accessibility (If the Public Will Use Your App)

- [ ] Can you navigate the core user flow using only the keyboard? (Tab through the app without touching the mouse.)
- [ ] Do all images have alt text? (Ask your AI: "Check all images for missing alt attributes.")
- [ ] Do all form fields have visible labels (not just placeholder text)?
- [ ] Can you see which element is focused when Tabbing? (There should be a visible outline or highlight.)
- [ ] Run a Lighthouse accessibility audit in Chrome DevTools. Fix any critical issues.

## Legal (If the Public Will Use Your App)

- [ ] If you collect personal data: do you have a privacy policy? (Even a basic one.)
- [ ] If required: do you have terms of service?
- [ ] If you use cookies beyond essential ones: are you providing a cookie notice where required?

## The Final Test

- [ ] Have you tried using your app as if you were a brand-new user? (Sign up, perform the core actions, make mistakes.)
- [ ] Have you had someone else try it? (Fresh eyes catch things you've become blind to.)
- [ ] Do you know how to push an update if you need to fix something quickly?
- [ ] Do you know how to roll back to the previous version if an update breaks things?
