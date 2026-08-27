# Further Reading

Curated resources for learning more. Organized by difficulty — start with the accessible ones and go deeper as your interest and experience grow.

---

## Starting Points (Accessible, No Prior Experience Needed)

**The Twelve-Factor App** — [github.com/heroku/12factor](https://github.com/heroku/12factor)
A set of principles for building modern web applications. Short, practical, and widely referenced. Read this first if you've never thought about application architecture.

**OWASP Top 10** — [owasp.org/Top10](https://owasp.org/www-project-top-ten/)
The ten most critical web application security risks. Updated periodically. Essential knowledge for anyone building a web application.

**web.dev by Google** — [web.dev](https://web.dev)
Practical guides on web performance, accessibility, and best practices. The Core Web Vitals section is particularly useful for frontend performance.

**AWS Well-Architected Framework** — [aws.amazon.com/architecture/well-architected](https://aws.amazon.com/architecture/well-architected/)
Despite the name, the principles apply regardless of cloud provider. The six pillars (operational excellence, security, reliability, performance efficiency, cost optimization, sustainability) align closely with vibeArchitecture's modules. The whitepapers are free and well-written.

---

## Books (Progressively Deeper)

**The Phoenix Project** — Gene Kim, Kevin Behr, George Spafford
A novel about an IT organization in crisis. Surprisingly engaging and teaches DevOps principles through storytelling rather than theory. Good starting point for understanding why operational practices matter.

**Release It!** — Michael Nygard
Practical patterns for building production-ready software. Covers stability patterns (circuit breakers, timeouts, bulkheads) with real-world war stories. The most directly applicable book for what vibeArchitecture teaches.

**Designing Data-Intensive Applications** — Martin Kleppmann
The definitive guide to data systems: databases, replication, partitioning, consistency, batch processing, stream processing. Dense but exceptionally clear. Read this when you're ready to understand the "why" behind database and data architecture decisions at a deep level.

**Fundamentals of Software Architecture** — Mark Richards, Neal Ford
A comprehensive introduction to software architecture concepts, patterns, and trade-offs. Good for understanding architectural thinking as a discipline.

**Building Secure and Reliable Systems** — Google SRE Team
Combines security and reliability into a unified approach. Written by people who operate some of the world's largest systems. Free to read online.

---

## Online Resources

**Google SRE Books** — [sre.google/books](https://sre.google/books/)
Three books available free online: Site Reliability Engineering, The Site Reliability Workbook, and Building Secure and Reliable Systems. The SRE Book is the foundational text for understanding operational reliability.

**OWASP Cheat Sheet Series** — [cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org)
Practical, concise guides on specific security topics: authentication, session management, input validation, cryptographic storage, and dozens more. Excellent reference material.

**PostgreSQL Documentation** — [postgresql.org/docs](https://www.postgresql.org/docs/current/)
Arguably the best database documentation in existence. The tutorial sections are genuinely readable, and the reference sections are comprehensive.

**High Scalability Blog** — [highscalability.com](https://highscalability.com)
Case studies of how real companies architect their systems. Good for understanding what different scales of operation look like in practice.

**Martin Fowler's Website** — [martinfowler.com](https://martinfowler.com)
In-depth articles on software architecture patterns, microservices, refactoring, and design. Written clearly and backed by decades of consulting experience.

**ByteByteGo** — [blog.bytebytego.com](https://blog.bytebytego.com)
System design concepts explained with clear diagrams. Good for visual learners and for understanding large-scale system architecture.

---

## Security-Specific Resources

**OWASP Top 10** — The essential starting point (linked above)

**Have I Been Pwned** — [haveibeenpwned.com](https://haveibeenpwned.com)
Check if email addresses or passwords have appeared in data breaches. Also offers an API for checking passwords during registration.

**Mozilla Observatory** — [observatory.mozilla.org](https://observatory.mozilla.org)
Scans your website for security headers and configuration. Free, quick, and gives specific recommendations.

**Security Headers** — [securityheaders.com](https://securityheaders.com)
Analyzes your site's HTTP security headers and grades them. Quick way to check your security header configuration.

**OWASP MASVS / MASTG** — [mas.owasp.org](https://mas.owasp.org)
The mobile application security standard and its companion testing guide. The mobile analog of ASVS — see `appendices/standards-mapping.md`.

**Signal protocol documentation** — [signal.org/docs](https://signal.org/docs)
The published specifications for X3DH, PQXDH, the Double Ratchet, and — since October 2025 — SPQR (Sparse Post-Quantum Ratchet) and the resulting Triple Ratchet, which adds ongoing post-quantum key updates rather than only a post-quantum handshake. The reference patterns for end-to-end encrypted messaging. Read these before designing any E2EE protocol; see `guides/security/cryptography.md`.

**NIST post-quantum standards** — [csrc.nist.gov/projects/post-quantum-cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
FIPS 203 (ML-KEM), FIPS 204 (ML-DSA), and FIPS 205 (SLH-DSA, the hash-based signature scheme), plus HQC, selected in 2025 as a second key-encapsulation mechanism to back up ML-KEM. These are the standardized post-quantum algorithms behind hybrid key agreement.

---

## AI and Agent Security

**OWASP GenAI Security Project** — [genai.owasp.org](https://genai.owasp.org)
Home of the LLM Top 10 (2026 edition), the Top 10 for Agentic Applications (2026), and related cheat sheets on agentic threats and MCP security. `guides/multi-agent/llm-security.md` and `guides/multi-agent/agentic-security.md` map both lists to this framework's rules.

**NIST AI 600-1: Generative AI Profile** — [nist.gov/itl/ai-risk-management-framework](https://www.nist.gov/itl/ai-risk-management-framework)
The companion to the AI Risk Management Framework 1.0. Practical, numbered lists of GenAI-specific risks and suggested actions — the closest thing to a checklist for "have we thought about this?"

**Model Context Protocol specification** — [modelcontextprotocol.io/specification](https://modelcontextprotocol.io/specification)
The spec itself, including the authorization section (OAuth 2.1 resource servers, resource indicators) and tool annotations. Read the current revision before building or vetting an MCP server; see `guides/multi-agent/mcp-tool-patterns.md`.

**Simon Willison — "The lethal trifecta for AI agents"** — [simonwillison.net](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/)
The clearest short explanation of why prompt injection plus private data plus an exfiltration channel is unsolvable by filtering, and what to do instead. His ongoing prompt-injection series is the best running commentary on the topic.

**Provider safety and security documentation** — Anthropic, OpenAI, and Google each publish guidance on prompt-injection mitigation, tool use, computer-use agents, and data retention/training policies for their APIs. Read your provider's before shipping an agent, and re-read when they change the model.

---

## Tools Worth Knowing About

**Infrastructure & Deployment:**
- Terraform — infrastructure as code (multi-cloud)
- Docker — containerization
- GitHub Actions — CI/CD pipelines
- Vercel / Railway / Fly.io — simple deployment platforms

**Monitoring & Observability:**
- UptimeRobot / Better Stack — uptime monitoring (free tiers)
- Sentry — error tracking (free tier)
- Grafana — dashboards and visualization (open source)
- Prometheus — metrics collection (open source)

**Security:**
- Dependabot / Snyk — dependency vulnerability scanning
- Trivy — container image scanning
- truffleHog / gitleaks — secret scanning in git history

**Database:**
- pgAdmin / DBeaver — database management GUIs
- PgBouncer — PostgreSQL connection pooler
- Prisma / Drizzle / SQLAlchemy — popular ORMs

---

## Staying Current

The technology landscape changes. These sources provide ongoing, high-signal updates:

- **Hacker News** — [news.ycombinator.com](https://news.ycombinator.com) — Technology news and discussion. High signal-to-noise ratio for technical topics.
- **The Pragmatic Engineer Newsletter** — [pragmaticengineer.com](https://blog.pragmaticengineer.com) — Industry insights focused on engineering practices and culture.
- **TLDR Newsletter** — [tldr.tech](https://tldr.tech) — Daily digest of the most important tech news. Low commitment, high relevance.
