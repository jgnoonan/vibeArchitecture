# Integration Templates

These are ready-to-use configuration files that tell your AI coding agent to use vibeArchitecture. Copy the one that matches your tool into your **project root** (the top-level directory of your project, alongside the `vibeArchitecture/` folder).

## Setup

### Claude Code

Copy `CLAUDE.md` to your project root:

```bash
cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md
```

Claude Code automatically reads `CLAUDE.md` at the start of every session. This template uses `@./vibeArchitecture/ARCHITECT.md` to inline the framework entry point (an import feature of Claude Code and Gemini CLI; other tools fall back to the plain first line of the file).

**Upgrading from 1.4.0 or earlier?** Every template (`AGENTS.md`, `CLAUDE.md`, `android-studio/AGENTS.md`, `cursor/vibeArchitecture.mdc`) now opens with the plain line "Read `vibeArchitecture/ARCHITECT.md` before writing any code…" so tools that don't expand `@` imports still find the framework. Re-copy your integration file once; anything you added below the `<!-- Add project-specific instructions below this line -->` marker can be pasted back.

### Cursor

Cursor reads a project-root `AGENTS.md` natively, so the Copilot/Codex instructions below work as-is. If you prefer a Cursor-specific rule, copy the rule file into `.cursor/rules/`:

```bash
mkdir -p .cursor/rules
cp vibeArchitecture/integrations/cursor/vibeArchitecture.mdc .cursor/rules/
```

Cursor loads rules from `.cursor/rules/` automatically. The rule uses `alwaysApply: true` and references `@./vibeArchitecture/ARCHITECT.md`.

**Legacy (deprecated):** `.cursorrules` in the project root still works on older Cursor versions. Copy `integrations/cursorrules` only if your Cursor version does not support `.cursor/rules/` or `AGENTS.md`. If you already have a `.cursorrules` from an earlier vibeArchitecture version, move to `.cursor/rules/vibeArchitecture.mdc` or `AGENTS.md` and delete it — the legacy file is maintained by hand and gets the fewest updates.

**Cursor Skill (optional):** Install `CursorSkill/vibe-architecture/` to `~/.cursor/skills/vibe-architecture/` (or `.cursor/skills/vibe-architecture/` for one project) for skill-based activation without per-project setup. The skill was named `vibeArchitecture` before 1.5.0 — remove that older folder if it's still present. See the main README.

### GitHub Copilot / Codex

Copy `AGENTS.md` to your project root:

```bash
cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md
```

Copilot and Codex read `AGENTS.md` for project-level agent instructions. Copilot also reads `.github/copilot-instructions.md` — copy the same file there if you'd rather keep it out of the root:

```bash
mkdir -p .github && cp vibeArchitecture/integrations/AGENTS.md .github/copilot-instructions.md
```

### Gemini CLI

Gemini CLI reads `GEMINI.md` from the project root and supports the same `@` import syntax as Claude Code:

```bash
cp vibeArchitecture/integrations/CLAUDE.md ./GEMINI.md
```

### Windsurf

Copy `AGENTS.md` to the project root, or place it under `.windsurf/rules/`:

```bash
cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md
```

### Cline, Roo Code, Kiro, Amp, and other AGENTS.md-aware tools

Any tool that reads a project-root `AGENTS.md` works with the same file:

```bash
cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md
```

### Android Studio (AI provider with `AGENTS.md` support)

Recent Android Studio versions support AI providers beyond Gemini — including Anthropic Claude. If you've configured Claude as your AI provider (Settings > Tools > AI), vibeArchitecture works through Android Studio's `AGENTS.md` file support.

Copy the Android Studio-specific integration file to your **project root**:

```bash
cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md
```

This file includes an `@./vibeArchitecture/ARCHITECT.md` import line for tools that expand imports. If your tool doesn't expand imports, the plain first line ("Read `vibeArchitecture/ARCHITECT.md` before writing any code") covers it — the AI reads the entry point on its own.

If you already have an `AGENTS.md` in your project root, merge the content rather than overwriting it.

**Note:** Android Studio also has a Rules feature under Settings > Tools > AI > Prompt Library. The `AGENTS.md` file approach is preferred because it's checked into version control and shared with your team. Rules are stored locally in the IDE.

### Xcode (with the Claude Agent)

Recent Xcode versions with the Claude Agent integration read `CLAUDE.md` from the project root automatically. Use the same Claude Code integration:

```bash
cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md
```

Set up Claude Agent in Xcode via Settings > Intelligence > Anthropic > Claude Agent. See the main README for full setup instructions.

### Other AI Tools

If your tool uses a different configuration file, the content is the same — adapt the instructions from any of the templates above. The key instruction is: **read `vibeArchitecture/ARCHITECT.md` before writing any code and follow its instructions.**

## What These Templates Do

Each template tells the AI agent to:

1. Add `vibeArchitecture/` to the project's `.gitignore` (first-time setup — skipped when the framework is a git submodule)
2. Read `vibeArchitecture/ARCHITECT.md` at the start of every session
3. Run the intake questionnaire if the project profile hasn't been completed
4. Save `PROJECT_PROFILE.md` to the **project root** (not inside `vibeArchitecture/`)
5. Load and enforce the appropriate rules based on the project's tier
6. Communicate in plain language with the user
7. Consult the detailed guides when deeper explanation is needed
8. Surface checklists at milestones: before-you-build, before-you-deploy, production-readiness (Business/Regulated), and something-broke (incidents)

The templates are intentionally short. All the logic lives in `ARCHITECT.md` and the framework modules — the integration file just points the AI there.

## Why vibeArchitecture Is Gitignored

The framework is a development tool, not part of your project's source code. When you copy the folder in (the default install), adding `vibeArchitecture/` to `.gitignore` means:

- Your project's repository stays clean — no framework files mixed in
- Updates to the framework don't create noise in your project's git history
- The framework can be updated independently (replace the folder)

If you installed it as a git submodule instead, don't gitignore it — the submodule pointer is what your repository tracks, and `git submodule update --remote` updates it.

Your `PROJECT_PROFILE.md` is saved at the project root (outside `vibeArchitecture/`) so it IS committed to your project's repository — it's project-specific data that the AI needs on every session.

## Customizing

You can add project-specific instructions below the vibeArchitecture section in any of these files. For example:

```markdown
# Project Architecture

[vibeArchitecture instructions — keep these]

# Project-Specific Instructions

- This project uses Next.js 14 with the App Router
- We use Tailwind CSS for styling
- Database is PostgreSQL via Prisma ORM
- Authentication is handled by Clerk
```

Keep the vibeArchitecture instructions at the top so the AI reads them first.
