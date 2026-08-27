# Your First Successful Use (5 Minutes)

This walkthrough shows exactly what happens when vibeArchitecture is working. We'll use **Option B** (paste one prompt) — no install required. The same flow applies to Cursor, Claude Code, or the Cursor/Claude Skills once enabled. Not sure which option fits you? The "Which option?" table at the top of the README's Get Started section is the quick answer.

---

## Step 1: Open a new project folder

Create an empty folder anywhere — `recipe-box/` is fine. You don't need code yet.

Optional but recommended: `git init` so the AI can commit as it goes.

---

## Step 2: Paste the bootstrap prompt

In your AI tool, paste:

> Read https://raw.githubusercontent.com/jgnoonan/vibeArchitecture/main/BOOTSTRAP.md and follow its instructions before we start building. Ask me the intake questions first.

Or, if you already copied the framework into your project (Option C):

> Read vibeArchitecture/ARCHITECT.md and let's get started on a new project.

---

## Step 3: Answer the intake (example answers)

The AI asks a few questions — **not all at once**. Example conversation:

| AI asks | You answer |
|---------|------------|
| What are you building? | A recipe sharing app for my family |
| Who will use it? | People I know — about 15 family members |
| What data will it handle? | Names, emails, recipes, maybe photos |
| Any users in the EU, UK, or California? | No — everyone's in Ohio |
| How will people use it? | Web browser |
| What happens if it goes down? | Annoying, not a disaster |
| New or existing? | New project |
| What's your background? | New to this — AI does most of the coding (→ **beginner** experience level) |
| Will it use AI services? | No |

The AI determines **Shared tier** (family accounts + personal data, but not public internet or payments) and turns on the **privacy overlay** (`rules/privacy.md`) because the app stores other people's names and emails.

---

## Step 4: Confirm your project profile

The AI creates `PROJECT_PROFILE.md` in your project root and shows you something like [sample-PROJECT_PROFILE.md](sample-PROJECT_PROFILE.md).

You should see:

- A **tier** (here: Shared)
- An **experience level** (here: beginner)
- Which **rule files** are active

If anything looks wrong, say so — the AI updates the profile before coding.

---

## Step 5: Start building

Now ask for a feature:

> Add user signup and login with email and password.

**What you should notice:**

1. The AI does **not** skip straight to code on the first message (intake came first).
2. Generated code uses **hashed passwords**, **parameterized queries**, and **environment variables** for secrets — see [before-and-after.md](before-and-after.md).
3. Explanations match your experience level — plain language, consequences not jargon.

---

## Step 6: It persists across sessions

Close the chat. Open a new one tomorrow. Say:

> Continue working on Recipe Box.

A working setup finds your existing `PROJECT_PROFILE.md`, reads **Shared tier**, and **skips re-intake** — it loads the same rules and keeps going.

**Caveat for the Claude.ai Skill path:** a Claude.ai chat doesn't see files from a previous chat. If you're using the Skill in the browser rather than Claude Code, keep `PROJECT_PROFILE.md` in a Claude Project (as project knowledge) or in your repo and attach it when you start the new chat — otherwise Claude will run intake again. In Claude Code, Cursor, and Option C setups, the file lives in your project folder and persists on its own.

---

## What "success" looks like

You know vibeArchitecture is working when:

- [ ] Intake ran **before** the first line of code
- [ ] `PROJECT_PROFILE.md` exists in your project root with a real tier
- [ ] The AI refuses or fixes unsafe patterns (hardcoded secrets, plain-text passwords, SQL string concatenation)
- [ ] A new chat session picks up the profile without re-asking everything

If intake never runs, your integration isn't wired up — re-check README Option C or enable the Skill (named `vibe-architecture`) in Cursor/Claude settings.

---

## Next steps

- **Before you deploy:** ask the AI to walk through `checklists/before-you-deploy.md`
- **Understand a rule:** ask *"Why do we need rate limiting?"* — the AI pulls from `guides/`
- **See the code difference:** [before-and-after.md](before-and-after.md)
