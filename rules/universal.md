# Universal Rules

These apply to EVERY project regardless of tier. No exceptions.

## Version Control

- Use git. Commit early, commit often. Every meaningful change gets its own commit.
- Never commit secrets — API keys, passwords, database credentials, tokens, or private keys must never appear in any committed file. This includes source code, config files, documentation, and comments.
- Use `.gitignore`. At minimum ignore: `.env` files, dependency directories (`node_modules/`, `venv/`, etc.), build output, IDE settings, OS files (`.DS_Store`, `Thumbs.db`).
- If a secret is accidentally committed, it is compromised. Removing it from current code is not enough — it lives in git history. Rotate (change) the secret immediately.

## Secrets and Configuration

- Store secrets in environment variables loaded from a `.env` file that is NOT committed to version control.
- Add `.env` to `.gitignore` BEFORE creating the `.env` file. If you create the file first and commit it, the secret is already exposed.
- Provide a `.env.example` file (committed) showing required variables without real values.

## Error Handling

- Never show raw error details to users. Stack traces, database errors, and file paths help attackers and confuse users. Show a friendly message; log the details.
- Handle errors explicitly. Don't let the app crash silently or show a blank screen.
- Catch errors at boundaries (API endpoints, event handlers, background jobs) so one failure doesn't take down the whole application.

## Data Safety

- Have a backup plan, even for personal projects. Know how to export and restore your database.
- Prefer soft delete (marking records as deleted) over permanent deletion until you're certain the data isn't needed.
- Never run destructive operations (DROP TABLE, bulk DELETE) without a confirmed backup.

## Dependencies

- Use a lock file (`package-lock.json`, `poetry.lock`, `Cargo.lock`, etc.) so all environments use identical dependency versions.
- Keep dependencies updated. Outdated packages are the most common source of known security vulnerabilities.
- Evaluate before adding. Is it maintained? Does it have known vulnerabilities? Could you write it in a few lines instead of adding a dependency?

## Code Quality

- Functions do one thing. If you can't describe a function's purpose in one sentence, split it.
- Name things clearly. `calculateTotalPrice` beats `calc`. `userEmail` beats `x`.
- Avoid duplication — if you copy-paste the same logic three times, extract it. But don't over-abstract code used only once.

## Working with AI Agents

- Review generated code before committing. AI produces plausible-looking code that can be subtly wrong.
- "It works on my machine" is not sufficient. Test with realistic data and conditions.
- If you don't understand what code does, ask the AI to explain it before committing.
- Be skeptical of AI-suggested architectural decisions. The AI optimizes for "getting it done" — these rules exist to also make sure it's done right.
