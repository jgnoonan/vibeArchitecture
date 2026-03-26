# vibeArchitecture

**Architectural guardrails for AI-generated code.**

You know how to describe what you want. Your AI knows how to write code. But between "working on my laptop" and "working in production" there's a gap filled with security vulnerabilities, data loss, surprise cloud bills, and 2 AM outages.

vibeArchitecture bridges that gap. Drop it into your project, and your AI coding agent will ask the right questions before writing code — then enforce the right patterns while it builds.

## Who This Is For

You're building software with AI (Claude, Cursor, Copilot, Codex, etc.) and you want it to actually work — not just on your machine, but for real users, reliably, without losing their data or exposing their information.

You don't need a computer science degree. You don't need to understand "microservices" or "eventual consistency." You just need to answer some questions about what you're building, and the framework handles the rest.

## Quick Start

### Step 1: Get vibeArchitecture

**Easiest — Download the ZIP (no git knowledge needed):**
1. Click the green **"Code"** button at the top of this page
2. Click **"Download ZIP"**
3. Unzip the downloaded file
4. Copy the resulting folder into your project's main folder (the top-level folder where your code lives)
5. Rename it to `vibeArchitecture` if it has a different name after unzipping

**With git — Clone or submodule:**

If you're comfortable with git, you can clone this repository and copy the folder in, or add it as a submodule so it's easy to update later:
```bash
git submodule add https://github.com/jgnoonan/vibeArchitecture.git vibeArchitecture
```

### Step 2: Set up your AI tool

Copy the integration file for your tool into your **project root** (the same folder that contains the `vibeArchitecture/` folder):

| Tool | Command |
|------|---------|
| **Claude Code** | `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md` |
| **Cursor** | `cp vibeArchitecture/integrations/cursorrules ./.cursorrules` |
| **GitHub Copilot / Codex** | `cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md` |
| **Other tools** | Tell the agent: "Read vibeArchitecture/ARCHITECT.md before we start" |

Not sure how to run these commands? Just ask your AI agent: *"Copy the vibeArchitecture integration file for [your tool name] into the project root."* It will do it for you.

### Step 3: Start building

That's it. On first run, the AI will automatically add `vibeArchitecture/` to your project's `.gitignore` (the framework is a tool, not part of your codebase), walk you through a short conversation about your project, and then apply the right level of guidance as you build. Your project profile is saved at the project root so it stays in your repository.

## New to GitHub and Git?

If terms like "repository," "clone," and "git" are unfamiliar, here's what you need to know.

### What is GitHub?

GitHub is a website where developers store and share code. Think of it like Google Drive for code — it keeps a copy of your project online, tracks every change you've ever made, and lets you undo mistakes. This vibeArchitecture project is stored on GitHub, which is how you found this page.

### What is Git?

Git is a tool that runs on your computer and tracks changes to your files. Every time you save a meaningful change, git records what changed and when. If you break something, you can go back to any previous version. GitHub is the online service; git is the tool on your computer that talks to it.

### Do I Need Git?

**For using vibeArchitecture:** No. You can download the ZIP file (Step 1 above) and skip git entirely.

**For building your project:** Strongly recommended. Git protects you from losing work and is required if you want to deploy your app to most hosting platforms. The good news: your AI coding agent can set it up for you.

### Setting Up Git (When You're Ready)

Ask your AI agent: *"Help me set up git for this project."* It will walk you through it. But if you want to do it yourself:

1. **Install git:**
   - **Mac:** Open Terminal and type `git --version`. If it's not installed, your Mac will prompt you to install it.
   - **Windows:** Download from [git-scm.com](https://git-scm.com/download/win) and run the installer. Use the default settings.
   - **Linux:** Run `sudo apt install git` (Ubuntu/Debian) or `sudo dnf install git` (Fedora).

2. **Set your name and email** (git uses this to label your changes):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

3. **Initialize git in your project** (do this once, in your project's main folder):
   ```bash
   git init
   ```

4. **Save your first snapshot:**
   ```bash
   git add .
   git commit -m "Initial commit"
   ```

That's the basics. From here, your AI agent can handle git for you — it knows how to commit changes, create branches, and push to GitHub.

### Setting Up a GitHub Account (When You're Ready)

If you want to store your project online (recommended — it's a backup and lets you deploy):

1. Go to [github.com](https://github.com) and sign up for a free account
2. Create a new repository (GitHub will walk you through it)
3. Ask your AI agent: *"Help me push this project to my GitHub repository at [your repo URL]"*

You don't need a GitHub account to start building. You can set this up later when you're ready to deploy or want an online backup.

## What Happens

1. **The AI asks you questions** — plain English, no jargon. Things like "Who will use this?" and "What happens if it goes down?"
2. **Your answers create a project profile** — this tells the AI how much architectural rigor your project needs
3. **The AI enforces the right rules** — a personal hobby project gets light guidance; an app handling medical data gets comprehensive guardrails
4. **You build with confidence** — knowing the AI is watching for the mistakes that experienced engineers have learned to avoid the hard way

## How It's Organized

| Folder | What's In It | Who It's For |
|--------|-------------|--------------|
| `intake/` | The questions your AI will ask you | You (the human) |
| `rules/` | Compact rules the AI follows while coding | Your AI agent |
| `guides/` | Detailed explanations of why rules exist | You, when you want to understand more |
| `checklists/` | Plain-English to-do lists for key milestones | You |
| `appendices/` | Common mistakes, glossary, further reading | You |

## Five Levels of Guidance

Not every project needs the same level of rigor. The intake conversation determines your project's level:

| Level | Who's Using It | Example |
|-------|---------------|---------|
| **Personal** | Just you | A todo app, a personal dashboard |
| **Shared** | People you know | A family photo album, a team tool |
| **Public** | Anyone on the internet | A blog platform, a community forum |
| **Business** | Paying customers | A SaaS product, an e-commerce store |
| **Regulated** | Legal requirements apply | Healthcare app, financial platform |

Each level builds on the one below it. A Personal project gets basic hygiene rules. A Regulated project gets everything.

## Token Efficiency

vibeArchitecture is designed with AI context windows in mind. The rules layer is compact (80–120 lines per file). The AI only loads the rules for your project's level. Detailed explanations live in separate files and are only pulled in when you ask "why?" — not on every request.

## Full File Structure

```
vibeArchitecture/
├── ARCHITECT.md                          # AI reads this first
├── PROJECT_PROFILE.md                    # Generated by intake — your project's profile
├── intake/
│   ├── questionnaire.md                  # The adaptive intake conversation
│   └── tier-definitions.md               # What each level means
├── rules/                                # Compact rules — loaded into AI context
│   ├── _index.md                         # Tier-to-rules mapping
│   ├── universal.md                      # All projects
│   ├── security.md                       # Shared+
│   ├── data.md                           # Shared+
│   ├── api.md                            # Public+
│   ├── reliability.md                    # Business+
│   ├── infrastructure.md                 # Business+
│   ├── observability.md                  # Business+
│   ├── performance.md                    # Business+
│   └── compliance.md                     # Regulated only
├── guides/                               # Detailed explanations — loaded on demand
│   ├── security/                         # Secrets, input validation, authentication
│   ├── data/                             # Schema design, integrity, lifecycle
│   ├── api/                              # API design, API security
│   ├── reliability/                      # Failure modes, resilience patterns
│   ├── infrastructure/                   # Deployment, containers
│   ├── observability/                    # Logging, monitoring
│   ├── performance/                      # Database performance, caching
│   └── operations/                       # Cost management, day 2 operations
├── checklists/                           # Human-readable action items
│   ├── before-you-build.md
│   ├── before-you-deploy.md
│   └── something-broke.md
├── appendices/
│   ├── anti-patterns.md                  # Common mistakes and how to avoid them
│   ├── glossary.md                       # Plain-English definitions
│   └── further-reading.md               # Curated learning resources
└── integrations/                         # Drop-in configs for AI tools
    ├── CLAUDE.md                         # For Claude Code
    ├── cursorrules                       # For Cursor
    └── AGENTS.md                         # For GitHub Copilot / Codex
```

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
