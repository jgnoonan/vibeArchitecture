# Integration Templates

These are ready-to-use configuration files that tell your AI coding agent to use vibeArchitecture. Copy the one that matches your tool into your **project root** (the top-level directory of your project, alongside the `vibeArchitecture/` folder).

## Setup

### Claude Code

Copy `CLAUDE.md` to your project root:

```bash
cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md
```

Claude Code automatically reads `CLAUDE.md` at the start of every session.

### Cursor

Copy `cursorrules` to your project root as `.cursorrules`:

```bash
cp vibeArchitecture/integrations/cursorrules ./.cursorrules
```

Cursor automatically reads `.cursorrules` for project-level instructions.

### GitHub Copilot / Codex

Copy `AGENTS.md` to your project root:

```bash
cp vibeArchitecture/integrations/AGENTS.md ./AGENTS.md
```

Copilot and Codex read `AGENTS.md` for project-level agent instructions.

### Android Studio (Panda and newer)

Android Studio Panda and newer versions support AI providers beyond Gemini — including Anthropic Claude. If you've configured Claude as your AI provider (Settings > Tools > AI), vibeArchitecture works natively through Android Studio's `AGENTS.md` file support.

Copy the Android Studio-specific integration file to your **project root**:

```bash
cp vibeArchitecture/integrations/android-studio/AGENTS.md ./AGENTS.md
```

This version uses Android Studio's `@` import syntax to automatically inline the vibeArchitecture entry point, so the AI receives the framework instructions as part of every prompt — no manual "read this file" step needed.

If you already have an `AGENTS.md` in your project root, merge the content rather than overwriting it.

**Note:** Android Studio also has a Rules feature under Settings > Tools > AI > Prompt Library. The `AGENTS.md` file approach is preferred because it's checked into version control and shared with your team. Rules are stored locally in the IDE.

### Xcode (26.3 and newer)

Xcode 26.3+ includes a native Claude Agent that automatically reads `CLAUDE.md` from the project root. Use the same Claude Code integration:

```bash
cp vibeArchitecture/integrations/CLAUDE.md ./CLAUDE.md
```

Set up Claude Agent in Xcode via Settings > Intelligence > Anthropic > Claude Agent. See the main README for full setup instructions.

### Other AI Tools

If your tool uses a different configuration file, the content is the same — adapt the instructions from any of the templates above. The key instruction is: **read `vibeArchitecture/ARCHITECT.md` before writing any code and follow its instructions.**

## What These Templates Do

Each template tells the AI agent to:

1. Add `vibeArchitecture/` to the project's `.gitignore` (first-time setup)
2. Read `vibeArchitecture/ARCHITECT.md` at the start of every session
3. Run the intake questionnaire if the project profile hasn't been completed
4. Save `PROJECT_PROFILE.md` to the **project root** (not inside `vibeArchitecture/`)
5. Load and enforce the appropriate rules based on the project's tier
6. Communicate in plain language with the user
7. Consult the detailed guides when deeper explanation is needed

The templates are intentionally short. All the logic lives in `ARCHITECT.md` and the framework modules — the integration file just points the AI there.

## Why vibeArchitecture Is Gitignored

The framework is a development tool, not part of your project's source code. By adding `vibeArchitecture/` to `.gitignore`:

- Your project's repository stays clean — no framework files mixed in
- Updates to the framework don't create noise in your project's git history
- The framework can be updated independently (re-clone or update submodule)

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
