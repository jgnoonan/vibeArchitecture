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

### Other AI Tools

If your tool uses a different configuration file, the content is the same — adapt the instructions from any of the templates above. The key instruction is: **read `vibeArchitecture/ARCHITECT.md` before writing any code and follow its instructions.**

## What These Templates Do

Each template tells the AI agent to:

1. Read `vibeArchitecture/ARCHITECT.md` at the start of every session
2. Run the intake questionnaire if the project profile hasn't been completed
3. Load and enforce the appropriate rules based on the project's tier
4. Communicate in plain language with the user
5. Consult the detailed guides when deeper explanation is needed

The templates are intentionally short. All the logic lives in `ARCHITECT.md` and the framework modules — the integration file just points the AI there.

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
