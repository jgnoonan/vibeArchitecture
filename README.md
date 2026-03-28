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
| **Android Studio (Panda+)** | `cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md` |
| **Other tools** | Tell the agent: "Read vibeArchitecture/ARCHITECT.md before we start" |

Not sure how to run these commands? Just ask your AI agent: *"Copy the vibeArchitecture integration file for [your tool name] into the project root."* It will do it for you.

### Step 3: Start building

On first run, the AI will automatically add `vibeArchitecture/` to your project's `.gitignore` (the framework is a tool, not part of your codebase), then guide you through an intake process before applying the right level of guidance.

**Starting a new project?** Just tell your AI agent:

> *"Read vibeArchitecture/ARCHITECT.md and let's get started on a new project."*

The AI will walk you through a short conversation about what you're building, who will use it, and what data is involved. Then it starts coding with the right guardrails in place.

**Adding vibeArchitecture to an existing project?** Tell your AI agent:

> *"Read vibeArchitecture/ARCHITECT.md. This is an existing project — analyze the codebase and build a project profile."*

The AI will scan your existing code and report back what it found: your tech stack, database, security setup, deployment configuration, and more. It will flag anything that needs attention (like hardcoded secrets or missing input validation), organized by priority. Then it will ask you a few questions it can't answer by reading the code — things like who your users are and what happens if the app goes down. The result is a project profile and a prioritized gap assessment so you know exactly what to address and in what order.

Your project profile is saved at the project root so it stays in your repository.

## Using with Android Studio

Android Studio Panda and newer versions let you configure **Anthropic Claude as your AI provider** directly in the IDE — no separate terminal tool needed.

### Setting Up Claude in Android Studio

1. Open **Settings > Tools > AI**
2. Select **Anthropic** as the AI provider
3. Enter your Anthropic API key
4. Choose your model (Claude Sonnet or Opus recommended)

### Adding vibeArchitecture

Follow the normal Quick Start above (Steps 1–3). When you get to Step 2, use the Android Studio integration:

```bash
cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md
```

Or just ask the AI in Android Studio: *"Copy vibeArchitecture/integrations/android-studio/AGENTS.md to the project root as AGENTS.md."*

This integration file uses Android Studio's `@` import syntax to automatically include vibeArchitecture's instructions in every AI prompt. No extra steps needed — the framework is active as soon as the file is in place.

### Starting the Intake

For a **new Android project**, tell the AI in Android Studio's chat:

> *"Let's get started on a new project. I'm building an Android app with Kotlin."*

For an **existing Android project**:

> *"This is an existing project — analyze the codebase and build a project profile."*

Because the `AGENTS.md` file is already loaded automatically, you don't need to tell the AI to read vibeArchitecture — it already has.

### What About Gemini?

If you switch back to Gemini as your AI provider, the `AGENTS.md` file still works — Android Studio loads it for any configured AI provider. You can also use Gemini for its built-in features (code completion, lint fixes) alongside Claude without conflict.

## Using with Xcode

Xcode doesn't have a built-in Claude integration, so you'll use **Claude Code** alongside Xcode. Claude Code runs in your terminal and can read, create, and modify files in your project — the same files Xcode sees.

### Setting Up Claude Code

Claude Code is a command-line tool from Anthropic. To install it:

1. **Open Terminal**
2. **Install Claude Code:**

```bash
npm install -g @anthropic-ai/claude-code
```

If you don't have npm, ask your AI agent for help installing Node.js first, or see [Anthropic's Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for alternative install methods.

3. **Navigate to your project folder** (the folder containing your `.xcodeproj` or `.xcworkspace` file):

```bash
cd ~/path/to/your/xcode-project
```

4. **Start Claude Code:**

```bash
claude
```

### The Workflow

You'll use both tools side by side:

- **Xcode** — for editing code, running the app, using the debugger, and testing on simulators
- **Claude Code (in your terminal)** — for AI-assisted architecture, code generation, answering questions, and vibeArchitecture guidance

They share the same project folder, so changes made by Claude Code appear immediately in Xcode, and vice versa. Think of it like having an architect (Claude Code) and a workbench (Xcode) in the same workshop.

### Adding vibeArchitecture

Follow the normal Quick Start above (Steps 1–3). When you get to Step 2, use the Claude Code integration:

```bash
cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md
```

### Starting the Intake

For a **new iOS/macOS project**, tell Claude Code:

> *"Read vibeArchitecture/ARCHITECT.md and let's get started on a new project. I'm building an iOS app with Swift."*

For an **existing Xcode project**, tell Claude Code:

> *"Read vibeArchitecture/ARCHITECT.md. This is an existing iOS project — analyze the codebase and build a project profile."*

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

**For new projects:**

1. **The AI asks you questions** — plain English, no jargon. Things like "Who will use this?" and "What happens if it goes down?"
2. **Your answers create a project profile** — this tells the AI how much architectural rigor your project needs
3. **The AI enforces the right rules** — a personal hobby project gets light guidance; an app handling medical data gets comprehensive guardrails
4. **You build with confidence** — knowing the AI is watching for the mistakes that experienced engineers have learned to avoid the hard way

**For existing projects:**

1. **The AI analyzes your codebase** — it detects your tech stack, database, authentication, security posture, deployment setup, and testing coverage
2. **It reports what it found** — in plain English, including what's working well and what needs attention
3. **It asks only the questions code can't answer** — who your users are, what downtime means for you, your budget
4. **Your answers plus the analysis create a project profile and gap assessment** — a prioritized list of what to fix (critical items first) alongside your regular feature work
5. **The AI enforces the right rules going forward** — and helps you close the gaps incrementally

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
    ├── AGENTS.md                         # For GitHub Copilot / Codex
    └── android-studio/
        └── AGENTS.md                     # For Android Studio (Panda+)
```

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
