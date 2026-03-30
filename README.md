# vibeArchitecture

**Your AI writes the code. This makes sure it doesn't fall apart.**

AI coding tools build fast. But they don't think about security, data protection, or what happens when real users show up. That's how you end up with API keys anyone can steal, passwords stored in plain text, and apps that break the moment two people use them at the same time.

vibeArchitecture fixes this. It's a set of instructions your AI reads before writing code — so it builds things properly from the start. You don't need to understand any of it. Your AI does the work.

---

## Get Started in 60 Seconds

### Option A: Paste one prompt (no downloads, no setup)

Copy this into any AI coding tool (Claude, Cursor, ChatGPT, Copilot, Codex — anything):

> **Read the BOOTSTRAP.md file from https://github.com/jgnoonan/vibeArchitecture and follow its instructions before we start building. Ask me the intake questions first.**

That's it. Your AI will ask you a few questions about what you're building, then write code with proper guardrails automatically.

### Option B: Full setup (more features, detailed guides)

For the complete framework with detailed explanations, checklists, and IDE-specific integrations:

<details>
<summary><strong>Click to expand full setup instructions</strong></summary>

#### Step 1: Get vibeArchitecture

**Easiest — Download the ZIP (no git knowledge needed):**
1. Click the green **"Code"** button at the top of this page
2. Click **"Download ZIP"**
3. Unzip and copy the folder into your project as `vibeArchitecture`

**With git:**
```bash
git submodule add https://github.com/jgnoonan/vibeArchitecture.git vibeArchitecture
```

#### Step 2: Set up your AI tool

Copy the integration file for your tool into your project root:

| Tool | Command |
|------|---------|
| **Claude Code** | `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md` |
| **Cursor** | `cp vibeArchitecture/integrations/cursorrules ./.cursorrules` |
| **VS Code (Copilot)** | `cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md` |
| **VS Code (Claude)** | `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md` |
| **GitHub Copilot / Codex** | `cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md` |
| **Xcode (26.3+)** | `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md` |
| **Android Studio (Panda+)** | `cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md` |
| **Other tools** | Tell the agent: "Read vibeArchitecture/ARCHITECT.md before we start" |

Not sure how to run these commands? Ask your AI: *"Copy the vibeArchitecture integration file for [your tool] into the project root."*

#### Step 3: Start building

**New project:**
> *"Read vibeArchitecture/ARCHITECT.md and let's get started on a new project."*

**Existing project:**
> *"Read vibeArchitecture/ARCHITECT.md. This is an existing project — analyze the codebase and build a project profile."*

The AI handles everything from there.

</details>

---

## What It Actually Does

**1. Asks your AI the right questions first.**
Before writing a single line of code, your AI asks what you're building, who will use it, and what data is involved. A personal project gets light guidance. An app handling payments gets serious guardrails.

**2. Enforces best practices automatically.**
Your AI follows rules that experienced engineers learned the hard way — proper security, input validation, error handling, database design, and deployment practices. You don't need to know what these are. The AI just does them.

**3. Catches problems before they matter.**
Missing input validation? The AI won't skip it. Hardcoded API keys? The AI will use environment variables instead. No error handling? The AI adds it. The same mistakes that take down real apps are prevented before they start.

---

## What Happens Without It

These are real patterns in AI-generated code:

- **API keys in the source code** — visible to anyone who inspects the page or reads the repository
- **No input validation** — a single malicious form submission can delete your database
- **Passwords stored in plain text** — one data breach and every user's password is exposed
- **No error handling** — one failed API call crashes the entire app
- **No rate limiting** — a bot hits your API 10,000 times per minute and you get a $2,000 cloud bill

vibeArchitecture prevents all of these. Automatically.

---

## Five Levels of Guidance

Not every project needs the same rigor. The intake conversation determines the right level:

| Level | Who's Using It | Example | What's Enforced |
|-------|---------------|---------|-----------------|
| **Personal** | Just you | A todo app, a personal dashboard | Basic hygiene |
| **Shared** | People you know | A family app, a team tool | + Security, data protection, testing |
| **Public** | Anyone online | A blog, a community forum | + API design, accessibility |
| **Business** | Paying customers | A SaaS product, an e-commerce store | + Reliability, infrastructure, monitoring |
| **Regulated** | Legal requirements | Healthcare, finance | + Compliance, audit logging |

Each level builds on the one below it.

---

<details>
<summary><strong>For developers: technical details</strong></summary>

### How It Works Under the Hood

vibeArchitecture is a set of Markdown files your AI agent reads. No dependencies, no build step, no lock-in.

- **Rules layer** (~80–120 lines per file): Compact rules loaded into the AI's context every session. Uses 3–6% of a 200K context window for typical projects.
- **Guides layer** (~30 files): Detailed explanations loaded only when the AI or user needs deeper context. Never loaded preemptively.
- **Intake system**: Adaptive questionnaire that determines project tier and generates a `PROJECT_PROFILE.md`.
- **Integration files**: Drop-in configs for Claude Code, Cursor, Copilot, Codex, Xcode, and Android Studio.

### Token Usage

| Tier | Est. tokens | % of 200K window |
|------|-------------|-------------------|
| Personal | ~2,850 | ~1.4% |
| Shared | ~5,550 | ~2.8% |
| Public | ~6,400 | ~3.2% |
| Business | ~11,100 | ~5.6% |
| Regulated | ~13,800 | ~6.9% |

Guides average ~1,560 tokens each and are loaded on demand. A typical session pulls one or two at most.

### What's Covered

Rules and guides exist for: security, data integrity, testing, API design, accessibility, reliability, infrastructure, observability, performance, system design, multi-agent/LLM systems, and compliance (GDPR, HIPAA, PCI-DSS, SOC 2).

### File Structure

```
vibeArchitecture/
├── ARCHITECT.md                          # AI reads this first
├── BOOTSTRAP.md                          # Condensed one-file version
├── PROJECT_PROFILE.md                    # Generated by intake
├── intake/                               # Adaptive intake questionnaire
├── rules/                                # Compact rules by tier
├── guides/                               # Detailed explanations (on demand)
├── checklists/                           # Human-readable action items
├── appendices/                           # Anti-patterns, glossary, resources
└── integrations/                         # Drop-in configs for AI tools
```

</details>

<details>
<summary><strong>Using with Xcode (26.3+)</strong></summary>

Xcode 26.3+ includes a native Claude Agent that automatically reads `CLAUDE.md` from your project root.

1. Open **Xcode > Settings > Intelligence**
2. Click **Anthropic** under Providers
3. Click **Get** next to Claude Agent and install it
4. Sign in with your Claude.ai account or provide an API key
5. Copy the integration file: `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md`

The Claude Agent reads `CLAUDE.md` at the start of every session. vibeArchitecture is active automatically.

**New project:** *"Let's get started on a new project. I'm building an iOS app with Swift."*
**Existing project:** *"This is an existing project — analyze the codebase and build a project profile."*

</details>

<details>
<summary><strong>Using with Android Studio (Panda+)</strong></summary>

Android Studio Panda+ lets you configure Claude as your AI provider.

1. Open **Settings > Tools > AI**
2. Select **Anthropic** as the AI provider
3. Enter your Anthropic API key
4. Copy the integration file: `cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md`

The `AGENTS.md` file is loaded automatically for any configured AI provider.

**New project:** *"Let's get started on a new project. I'm building an Android app with Kotlin."*
**Existing project:** *"This is an existing project — analyze the codebase and build a project profile."*

</details>

<details>
<summary><strong>New to GitHub and Git?</strong></summary>

**GitHub** is a website where people store and share code — like Google Drive for code. **Git** is a tool on your computer that tracks changes to your files so you can undo mistakes.

**Do you need git to use vibeArchitecture?** No. Download the ZIP (Option B, Step 1) and skip git entirely.

**Should you use git for your project?** Yes, when you're ready. It protects you from losing work and is required for most hosting platforms. Ask your AI: *"Help me set up git for this project."*

**Setting up git yourself:**

1. Install git: Mac (`git --version` in Terminal — installs automatically), Windows ([git-scm.com](https://git-scm.com/download/win)), Linux (`sudo apt install git`)
2. Set your name: `git config --global user.name "Your Name"`
3. Set your email: `git config --global user.email "your@email.com"`
4. In your project folder: `git init && git add . && git commit -m "Initial commit"`

From there, your AI can handle git for you.

</details>

---

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
