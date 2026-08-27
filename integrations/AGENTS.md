Read `vibeArchitecture/ARCHITECT.md` before writing any code, and follow its instructions completely.

# Project Architecture

This project uses **vibeArchitecture** for architectural guidance.

## Framework Entry Point

@./vibeArchitecture/ARCHITECT.md

(The `@` line above inlines the entry point in tools that support imports, such as Claude Code and Gemini CLI. If your tool doesn't expand it, the first line of this file already tells you what to read.)

## Required: Follow Before Writing Code

1. **First-time setup.** Add `vibeArchitecture/` to this project's `.gitignore` if it isn't already there — unless the folder was installed as a git submodule (check `.gitmodules`), in which case leave it tracked. The framework is a development tool — a copied-in folder should not be committed to this project's repository. Never gitignore `PROJECT_PROFILE.md` or this file.

2. **Check the project profile.** If `PROJECT_PROFILE.md` does not exist in the project root (or still contains placeholder text), run the intake questionnaire from `vibeArchitecture/intake/questionnaire.md` before writing any code. Walk the user through it conversationally. Save the completed profile to the **project root**, not inside `vibeArchitecture/`. If the profile exists but **Experience level** is not set to `beginner`, `intermediate`, or `experienced`, follow `vibeArchitecture/ARCHITECT.md` Step 2: ask the one explanation-preference question, update the profile, then continue.

3. **Load the rules.** Once the profile exists, read `vibeArchitecture/rules/_index.md` and load all rule files for the project's tier. Follow these rules for every piece of code you write.

4. **Communicate clearly.** Match depth to **Experience level** in the profile (`ARCHITECT.md` How to Communicate). Plain language for beginner/intermediate; concise and technical for experienced.

5. **Consult guides when needed.** The `vibeArchitecture/guides/` directory has detailed explanations. Load them when the user asks "why?" or when you need deeper context for a decision.

6. **Surface checklists at milestones.**
   - `vibeArchitecture/checklists/before-you-build.md` at project start
   - `vibeArchitecture/checklists/before-you-deploy.md` when deployment is discussed
   - `vibeArchitecture/checklists/production-readiness.md` for Business or Regulated tier projects approaching launch
   - `vibeArchitecture/checklists/something-broke.md` when the user reports a bug, error, outage, or something not working

<!-- Add project-specific instructions below this line -->
