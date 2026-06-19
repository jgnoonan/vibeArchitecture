# Your First Successful Use (5 Minutes)

This walkthrough shows exactly what happens when vibeArchitecture is working. We'll use **Option B** (paste one prompt) — no install required. The same flow applies to Cursor, Claude Code, or the Cursor/Claude Skills once enabled.

---

## Step 1: Open a new project folder

Create an empty folder anywhere — `recipe-box/` is fine. You don't need code yet.

Optional but recommended: `git init` so the AI can commit as it goes.

---

## Step 2: Paste the bootstrap prompt

In your AI tool, paste:

> Read the BOOTSTRAP.md file from https://github.com/jgnoonan/vibeArchitecture and follow its instructions before we start building. Ask me the intake questions first.

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
| New or existing? | New project |
| How do you want explanations? | Step by step (→ **beginner** experience level) |
| Will it use AI services? | No |

The AI determines **Shared tier** (family accounts + personal data, but not public internet or payments).

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

---

## Quick reference: which option should I use?

| If you… | Use |
|---------|-----|
| Want zero install, try it once | **Option B** — bootstrap prompt (above) |
| Use Cursor daily | **Cursor Skill** + optional full framework folder |
| Use Claude.ai in the browser | **Claude Skill** (upload ZIP) |
| Want checklists, guides, and full intake | **Option C** — copy framework + integration file |
| Just want a ChatGPT conversation | **Vibe Code Guardian** GPT (link in README) |

---

## What "success" looks like

You know vibeArchitecture is working when:

- [ ] Intake ran **before** the first line of code
- [ ] `PROJECT_PROFILE.md` exists in your project root with a real tier
- [ ] The AI refuses or fixes unsafe patterns (hardcoded secrets, plain-text passwords, SQL string concatenation)
- [ ] A new chat session picks up the profile without re-asking everything

If intake never runs, your integration isn't wired up — re-check README Option C or enable the Skill in Cursor/Claude settings.

---

## Next steps

- **Before you deploy:** ask the AI to walk through `checklists/before-you-deploy.md`
- **Understand a rule:** ask *"Why do we need rate limiting?"* — the AI pulls from `guides/`
- **See the code difference:** [before-and-after.md](before-and-after.md)
