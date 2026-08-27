# vibeArchitecture

**Your AI writes the code. This makes sure it doesn't fall apart.**

AI coding tools build fast. But they don't think about security, data protection, or what happens when real users show up. That's how you end up with API keys anyone can steal, passwords stored in plain text, and apps that break the moment two people use them at the same time.

vibeArchitecture fixes this. It's a set of instructions your AI reads before writing code — so it builds things properly from the start. You don't need to understand any of it. Your AI does the work.

---

## Get Started in 60 Seconds

**Which option?**

| If you... | Use |
|---|---|
| Just want a ChatGPT conversation | **Option A** — Vibe Code Guardian GPT |
| Use Claude.ai or Claude Code daily | **Option A+** — Claude Skill |
| Use Cursor daily | **Option A++** — Cursor Skill (plus Option C for the full framework) |
| Want zero install, try it once | **Option B** — paste one prompt |
| Want checklists, guides, and full intake in your repo | **Option C** — copy the framework folder + an integration file |

Throughout this README, **project root** means the top-level folder of your app — the one that holds your `package.json`, `pyproject.toml`, `.git/`, or equivalent. The `vibeArchitecture/` folder, `PROJECT_PROFILE.md`, and integration files all go there.

### Option A: Use the ChatGPT GPT (zero setup)

Open **[Vibe Code Guardian](https://chatgpt.com/g/g-69cd25c7200c8191938a6de92ddc56fb-vibe-code-guardian)** and describe what you want to build. It asks a few questions, then writes code with security and reliability guardrails automatically. Nothing to install, nothing to configure.

### Option A+: Install as a Claude Skill (Claude.ai or Claude Code)

If you use Claude.ai (Pro, Max, Team, or Enterprise) or Claude Code, you can install vibeArchitecture as a Skill that activates automatically whenever you start building a project.

<details>
<summary><strong>Claude Skill installation steps</strong></summary>

**Claude.ai (browser or desktop app):**

1. **Easiest:** download `vibe-architecture.zip` from the [latest GitHub Release](https://github.com/jgnoonan/vibeArchitecture/releases/latest) and skip to step 3. Otherwise, download the `ClaudeSkill/vibe-architecture/` folder from this repo (or download the whole repo ZIP and find it inside)
2. ZIP the `vibe-architecture/` folder inside `ClaudeSkill/` so the structure is:
   ```
   vibe-architecture.zip
   └── vibe-architecture/
       ├── SKILL.md
       ├── references/
       └── assets/
   ```
3. Go to [claude.ai](https://claude.ai) > **Settings** > **Capabilities**
4. Upload the ZIP file
5. Enable the skill

**Claude Code (terminal):**

Copy the folder into your project as `.claude/skills/vibe-architecture/` (this project only) or into `~/.claude/skills/vibe-architecture/` (all your projects). Claude Code picks it up on the next session.

Once installed, Claude will automatically run the intake questionnaire and apply architectural guardrails whenever you ask it to build something. No prompt to paste, no files to copy -- it just works.

**Keeping your profile between chats:** in Claude Code, `PROJECT_PROFILE.md` is a real file in your project and persists on its own. In Claude.ai, a chat doesn't remember files from a previous chat — keep the profile in a Claude Project (as project knowledge) or in your repository, and attach it when you start a new chat.

</details>

### Option A++: Install as a Cursor Skill (for Cursor users)

If you use Cursor, install vibeArchitecture as an Agent Skill so it activates when you build software — even without copying integration files into every project. (Cursor also reads a project-root `AGENTS.md` natively, so Option C works without any Cursor-specific file.)

<details>
<summary><strong>Cursor Skill installation steps</strong></summary>

1. Download the `CursorSkill/vibe-architecture/` folder from this repo
2. Copy it to `~/.cursor/skills/vibe-architecture/` (available in all projects) or `.cursor/skills/vibe-architecture/` (this project only)
3. Cursor discovers skills in those folders automatically — see the Cursor docs for Agent Skills if your version asks you to enable or import them

For the full framework with guides and checklists, also add the `vibeArchitecture/` folder to your project (Option C) and copy `integrations/cursor/vibeArchitecture.mdc` to `.cursor/rules/`.

</details>

### Option B: Paste one prompt (any AI tool)

Copy this into Claude, Cursor, Copilot, Codex, or any other AI coding tool:

> **Read https://raw.githubusercontent.com/jgnoonan/vibeArchitecture/main/BOOTSTRAP.md and follow its instructions before we start building. Ask me the intake questions first.**

That's it. Your AI will ask you a few questions about what you're building, then write code with proper guardrails automatically.

> **Note:** this option relies on your AI tool being able to fetch a URL. Some tools can't (or won't) read from the web. If your AI says it can't open the link, use **Option C** below — download the framework into your project and point the AI at the local `BOOTSTRAP.md` or `ARCHITECT.md` instead.

### Option C: Full setup (more features, detailed guides)

For the complete framework with detailed explanations, checklists, and IDE-specific integrations:

<details>
<summary><strong>Click to expand full setup instructions</strong></summary>

#### Step 1: Get vibeArchitecture

**Recommended — copy the folder in and gitignore it:**
1. Click the green **"Code"** button at the top of this page, then **"Download ZIP"** (or `git clone` the repo somewhere else)
2. Unzip and copy the folder into your project root as `vibeArchitecture/`
3. Add a `vibeArchitecture/` line to your project's `.gitignore` (the AI does this for you on the first session)

The framework is a development tool, not part of your app, so it stays out of your repository. To update later, replace the folder.

**Alternative — git submodule (for teams who want the framework version pinned in the repo):**
```bash
git submodule add https://github.com/jgnoonan/vibeArchitecture.git vibeArchitecture
```
With a submodule you do **not** gitignore `vibeArchitecture/` — the submodule pointer is what gets committed. Tell the AI it's a submodule so it skips the gitignore step.

#### Step 2: Set up your AI tool

Copy the integration file for your tool into your project root:

| Tool | Command |
|------|---------|
| **Claude Code** | `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md` |
| **Cursor** | `mkdir -p .cursor/rules && cp vibeArchitecture/integrations/cursor/vibeArchitecture.mdc .cursor/rules/` — or just use `AGENTS.md` (Cursor reads it natively) |
| **Cursor (legacy `.cursorrules`, deprecated)** | `cp vibeArchitecture/integrations/cursorrules ./.cursorrules` |
| **GitHub Copilot** | `cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md` — or `mkdir -p .github && cp vibeArchitecture/integrations/AGENTS.md .github/copilot-instructions.md` |
| **OpenAI Codex** | `cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md` |
| **Gemini CLI** | `cp vibeArchitecture/integrations/CLAUDE.md ./GEMINI.md` (same content; Gemini CLI supports `@` imports) |
| **Windsurf** | `cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md` (or place it under `.windsurf/rules/`) |
| **Cline, Roo Code, Kiro, Amp, or any AGENTS.md-aware tool** | `cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md` |
| **VS Code (Claude extension)** | `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md` |
| **Xcode (with the Claude Agent)** | `cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md` |
| **Android Studio (with an AI provider that reads AGENTS.md)** | `cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md` |
| **Other tools** | Tell the agent: "Read vibeArchitecture/ARCHITECT.md before we start" |

Every integration file starts with the same plain-text instruction ("read `vibeArchitecture/ARCHITECT.md` before writing any code"), so it works even in tools that don't expand `@` imports. Do **not** gitignore `CLAUDE.md`, `AGENTS.md`, or `PROJECT_PROFILE.md` — those belong to your project.

Not sure how to run these commands? Ask your AI: *"Copy the vibeArchitecture integration file for [your tool] into the project root."*

#### Step 3: Start building

**New project:**
> *"Read vibeArchitecture/ARCHITECT.md and let's get started on a new project."*

**Existing project:**
> *"Read vibeArchitecture/ARCHITECT.md. This is an existing project — analyze the codebase and build a project profile."*

The AI handles everything from there.

</details>

---

## Updating From a Previous Version

vibeArchitecture is versioned — see [CHANGELOG.md](CHANGELOG.md) for what's new. Your installed copy shows its version at the top of `ARCHITECT.md` (or `BOOTSTRAP.md`). How you update depends on how you installed:

| How you use it | How to update |
|---|---|
| **ChatGPT GPT (Option A)** | Nothing to do — the GPT is updated centrally. |
| **Claude Skill (Option A+)** | Installed skills are snapshots — they don't update themselves. Download `vibe-architecture.zip` from the [latest Release](https://github.com/jgnoonan/vibeArchitecture/releases/latest) (or re-zip `ClaudeSkill/vibe-architecture/` yourself) and upload it in **Settings > Capabilities**, replacing the old skill. For Claude Code, replace the folder under `.claude/skills/` or `~/.claude/skills/`. |
| **Cursor Skill (Option A++)** | Replace the folder at `~/.cursor/skills/vibe-architecture/` (or `.cursor/skills/vibe-architecture/`) with the latest from this repo. |
| **Paste one prompt (Option B)** | Nothing to do — the prompt reads `BOOTSTRAP.md` live from GitHub, so every new session gets the latest version. |
| **Full setup, git submodule (Option C)** | Run `git submodule update --remote vibeArchitecture`, then commit the updated submodule pointer. |
| **Full setup, copied folder (Option C)** | Download the ZIP again and replace your project's `vibeArchitecture/` folder. Your `PROJECT_PROFILE.md` lives in your project root, not inside the framework folder, so it's untouched. |

Releases are tagged on GitHub (`v1.5.0`, etc.) — see the [Releases](https://github.com/jgnoonan/vibeArchitecture/releases) page or `git tag` to pin a specific version. Each release also carries a ready-made `vibe-architecture.zip` for the Claude Skill.

Integration files (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`) are thin pointers into the framework folder — you don't need to re-copy them unless the CHANGELOG says so.

### Coming from 1.4.0 or earlier? Four one-time steps

1. **The skill was renamed** from `vibeArchitecture` to `vibe-architecture`. Remove the old skill, then install the new one: in Claude.ai, delete the old skill under **Settings > Capabilities** and upload the new ZIP; in Claude Code, delete `.claude/skills/vibeArchitecture/` (or the copy under `~/.claude/skills/`) and add `.claude/skills/vibe-architecture/`; in Cursor, do the same under `.cursor/skills/` or `~/.cursor/skills/`. Leaving both installed means two skills compete.
2. **Re-copy your integration file.** The first line of `AGENTS.md` / `CLAUDE.md` changed so tools that don't understand `@` imports still read the framework. Run the copy command from Option C, Step 2 again for your tool (keep any project-specific notes you added below the marker line).
3. **Using `.cursorrules`?** That format is deprecated in Cursor. Move to `.cursor/rules/vibeArchitecture.mdc` (Option C, Step 2) or a project-root `AGENTS.md`, then delete `.cursorrules`.
4. **Your `PROJECT_PROFILE.md` may be missing two new fields** — *Platform* (web, mobile app, both, other) and *Downtime impact*. Nothing to do by hand: the AI notices and asks you once on the next session, then saves the answers.

After updating, ask your AI: *"vibeArchitecture was updated — read the CHANGELOG and tell me what's new for this project's tier."*

---

## See It In Action

New here? These three files show exactly what changes after vibeArchitecture is active:

| | |
|--|--|
| **[5-minute walkthrough](examples/first-success-walkthrough.md)** | Prompt → intake questions → profile → first feature |
| **[Sample PROJECT_PROFILE.md](examples/sample-PROJECT_PROFILE.md)** | What the AI generates after intake (Recipe Box, Shared tier) |
| **[Before / after code](examples/before-and-after.md)** | Same login API request — with and without guardrails |

No install needed to read them. To try it yourself, paste the [Option B prompt](#option-b-paste-one-prompt-any-ai-tool) into any AI coding tool.

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

vibeArchitecture is built to stop these before they ship — by making your AI apply the right guardrails as it writes the code. It steers the AI; it isn't a scanner bolted on afterward, so reviewing what the AI produces still matters.

---

## Five Levels of Guidance

Not every project needs the same rigor. The intake conversation determines the right level:

| Level | Who's Using It | Example | What's Enforced |
|-------|---------------|---------|-----------------|
| **Personal** | Just you | A todo app, a personal dashboard | Basic hygiene |
| **Shared** | People you know | A family app, a team tool | + Security, data protection, testing |
| **Public** | Anyone online | A blog, a community forum | + API design, accessibility |
| **Business** | Paying customers | A SaaS product, an e-commerce store | + Reliability, infrastructure, monitoring, performance (system design when you're an experienced developer or the codebase is already complex) |
| **Regulated** | Legal requirements | Healthcare, finance | + Compliance, audit logging |

Each level builds on the one below it.

**Plus a privacy overlay.** Independent of tier, if your app stores personal data about other people — or any of your users are in the EU, UK, or California — the AI also applies data-subject-rights rules (data export, deletion on request, consent). GDPR and CCPA are triggered by *who your users are*, not by how big the app is, so even a small Public app gets these.

---

<details>
<summary><strong>For developers: technical details</strong></summary>

### How It Works Under the Hood

vibeArchitecture is a set of Markdown files your AI agent reads. No dependencies, no build step, no lock-in.

- **Rules layer** (~50–150 lines per file): Compact rules loaded into the AI's context every session. Uses roughly 1–13% of a 200K context window depending on tier.
- **Guides layer** (50+ files): Detailed explanations loaded only when the AI or user needs deeper context. Never loaded preemptively.
- **Intake system**: Adaptive questionnaire that determines project tier and generates a `PROJECT_PROFILE.md`.
- **Integration files**: Drop-in configs for Claude Code, Cursor, Copilot, Codex, Gemini CLI, Windsurf, Xcode, and Android Studio.

### Token Usage

Measured from file sizes (bytes ÷ 4) at release 1.5.0; base rule sets only.

| Tier | Est. tokens | % of 200K window |
|------|-------------|-------------------|
| Personal | ~1,800 | ~0.9% |
| Shared | ~9,200 | ~4.6% |
| Public | ~13,200 | ~6.6% |
| Business | ~19,900 | ~9.9% |
| Regulated | ~26,800 | ~13.4% |

Conditional rule sets add to these when they apply: privacy overlay ~2,100, multi-agent ~2,300, mobile ~1,300, system-design ~1,800, compliance ~3,000. Guides average ~2,900 tokens each and are loaded on demand; a typical session pulls one or two at most.

### What's Covered

Rules and guides exist for: security (including SSRF, CSRF, MFA, auth with passkeys/OAuth, fail-closed guards, device-scoped authorization, abuse/bot controls, threat modeling, secrets management, input validation, and client state management), cryptography and end-to-end encryption (including hybrid post-quantum key agreement against harvest-now-decrypt-later), data integrity, schema design and data lifecycle, data privacy (GDPR/CCPA data-subject rights, plus metadata-plane auditing for privacy-marketed products), testing (unit/integration strategy, testing AI systems, and adversarial review of AI-built codebases with an assurance register), API design and versioning, payment/webhook integration, accessibility (web and native mobile), reliability (failure modes, resilience patterns, high availability, concurrency, incident response), infrastructure (cloud fundamentals, containers, deployment, serverless/edge realities, regulated deployment), local-first and peer-to-peer architectures, real-time patterns, async patterns, observability (logging, monitoring), performance (caching, database performance, scaling, search architecture), system design and architecture styles, multi-agent/LLM systems (including the OWASP LLM Top 10 2026 and Agentic Top 10, MCP patterns, orchestration, agent observability, agent sandboxing, and agentic security — `guides/multi-agent/agentic-security.md`), mobile-native apps (including app-store review and push-payload privacy), day-2 operations (cost management, runbooks, email deliverability, internationalization), supply chain security (including SBOM and SAST), and compliance (GDPR, EU AI Act, EU Cyber Resilience Act, HIPAA, PCI-DSS, SOC 2). See `appendices/standards-mapping.md` for how the rules line up with OWASP (Top 10 2025, LLM 2026, Agentic 2026), ASVS 5, MASVS 2, NIST SSDF, NIST AI RMF, SLSA, and CIS Controls.

### File Structure

```
vibeArchitecture/
├── ARCHITECT.md                  # AI reads this first (version in file header)
├── BOOTSTRAP.md                  # Condensed one-file version
├── CHANGELOG.md                  # Framework version history
├── CONTRIBUTING.md               # How to contribute + the sync workflow
├── SECURITY.md                   # How to report a vulnerability
├── LICENSE                       # MIT
├── PROJECT_PROFILE.template.md   # Template for intake (saved as PROJECT_PROFILE.md in projects)
├── intake/                       # Adaptive intake questionnaire + tier definitions
├── rules/                        # Compact rules by tier (canonical source; includes privacy overlay)
├── guides/                       # Detailed explanations (on demand)
├── checklists/                   # Human-readable action items
├── appendices/                   # Anti-patterns, glossary, standards mapping, further reading,
│                                 #   ADR template, assurance register template
├── integrations/                 # Drop-in configs for AI tools
├── examples/                     # Walkthrough, sample profile, before/after
├── ClaudeSkill/vibe-architecture/  # Installable Claude Skill (Claude.ai + Claude Code)
├── CursorSkill/vibe-architecture/  # Installable Cursor Agent Skill (generated from ClaudeSkill)
├── CodeGuardian/                 # Config for the Vibe Code Guardian ChatGPT GPT
├── scripts/sync.sh               # Keeps skill packages + integration files in sync
├── docs/history/                 # Historical design notes (reference only)
└── .github/                      # CI (sync check, link check, markdownlint), templates
```

</details>

<details>
<summary><strong>Using with Xcode (Claude Agent)</strong></summary>

Recent Xcode versions with the Claude Agent integration read `CLAUDE.md` from your project root automatically.

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
<summary><strong>Using with Android Studio (AI provider with AGENTS.md support)</strong></summary>

Recent Android Studio versions let you configure Claude as your AI provider and read a project-root `AGENTS.md`.

1. Open **Settings > Tools > AI**
2. Select **Anthropic** as the AI provider
3. Enter your Anthropic API key
4. Copy the integration file: `cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md`

The `AGENTS.md` file is loaded automatically for the configured AI provider. If your version doesn't expand `@` imports, the plain first line of the file still tells the AI to read `ARCHITECT.md`.

**New project:** *"Let's get started on a new project. I'm building an Android app with Kotlin."*
**Existing project:** *"This is an existing project — analyze the codebase and build a project profile."*

</details>

<details>
<summary><strong>New to GitHub and Git?</strong></summary>

**GitHub** is a website where people store and share code — like Google Drive for code. **Git** is a tool on your computer that tracks changes to your files so you can undo mistakes.

**Do you need git to use vibeArchitecture?** No. Download the ZIP (Option C, Step 1), copy the folder in, and skip git entirely.

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

## Security

Found a vulnerability in the framework or its tooling? Please use coordinated disclosure — see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
