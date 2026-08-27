# Security Policy

vibeArchitecture is a documentation framework: Markdown files, a Bash sync script, and a GitHub Actions workflow. There is no server, no dependency tree, and nothing that runs in your production environment. Even so, mistakes here can matter — a rule that recommends an insecure pattern, a script that does something unexpected, or a CI workflow with more permissions than it needs.

## Reporting a vulnerability

Please use coordinated disclosure. Report privately through GitHub's private vulnerability reporting:

**https://github.com/jgnoonan/vibeArchitecture/security/advisories/new**

Do not open a public issue for security problems. Include what's affected (file path or workflow), why it's a problem, and a suggested fix if you have one.

## What counts

- Rules or guides that recommend an insecure practice, or omit a mitigation in a way that would lead an AI coding tool to generate vulnerable code
- Problems in `scripts/sync.sh` or `.github/workflows/*` (unsafe shell handling, excessive permissions, unpinned or compromised actions)
- Prompt-injection or instruction-smuggling risks in the integration files, skills, or GPT configuration

Ordinary factual corrections, outdated advice, and broken links are welcome as regular issues or pull requests — see `CONTRIBUTING.md`.

## Response

You'll get an acknowledgement within a few days. Confirmed issues are fixed on `main`, released in the next tagged version (see `CHANGELOG.md`), and credited if you'd like.

## Supported versions

Only the latest tagged release (`vX.Y.Z` on the [Releases](https://github.com/jgnoonan/vibeArchitecture/releases) page) and `main` receive fixes. Skills and copied-in folders are snapshots — update them after a security-relevant release (see "Updating From a Previous Version" in the README).
