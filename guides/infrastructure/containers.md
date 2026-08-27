# Containers — Why and How

> This guide explains containerization for people who are new to it. Read it when Docker appears in your project or when you want to understand why containers are recommended.

## What's a Container?

A container is a lightweight, portable package that includes your application and everything it needs to run: the code, runtime, libraries, and settings. It runs the same way regardless of where it's deployed — your laptop, a test server, or production.

**The analogy:** Think of a shipping container. Before standardized containers, every shipment was loaded differently and needed different equipment at each port. Standardized containers work with any ship, any truck, any crane. Software containers work the same way — your application runs identically on any system that supports containers.

## Why Containers?

### The "Works on My Machine" Problem

Without containers:
- Your laptop runs Node 24, the server runs Node 22 — different behavior
- You have a library installed locally that the server doesn't have — crash
- Your OS uses different file paths — bugs that only appear in production

With containers:
- The container includes the exact version of everything your app needs
- It runs the same everywhere — your laptop, CI/CD, staging, production
- "It works in the container" means it works everywhere

### Simple Deployment

Instead of documenting a 15-step setup process ("install Node, install PostgreSQL, configure this, set that environment variable..."), you:
1. Build a container image (automated with a Dockerfile)
2. Push it to a container registry
3. Tell the server to run it

### Isolation

Each container is isolated from others and from the host system. One application's dependencies don't conflict with another's. An unstable application can't bring down other applications on the same server.

## Docker — The Basics

Docker is the most common container tool. The key concepts:

### Dockerfile

A text file that describes how to build your container image. It's a recipe:

```dockerfile
FROM node:24-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
USER node
CMD ["node", "server.js"]
```

This says: start with a Node.js 24 base image, copy the dependency files, install dependencies, copy the application code, expose port 3000, run as a non-root user, and start the server.

### Image

The built result of a Dockerfile. It's a snapshot — the packaged application ready to run. Images are stored in registries (Docker Hub, GitHub Container Registry, AWS ECR).

### Container

A running instance of an image. You can run multiple containers from the same image.

## Container Best Practices

### One Process Per Container

Each container should run one application. Don't put your web server, database, and background worker in the same container. Run them as separate containers. This lets you:
- Scale each independently (more web servers without more databases)
- Restart one without affecting others
- Monitor each separately

### Multi-Stage Builds

Building your application needs tools (compilers, build tools, dev dependencies) that running it doesn't. Multi-stage builds use one stage to build and a smaller stage to run:

```dockerfile
# Build stage — has all build tools and devDependencies
FROM node:24 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage — minimal, runtime deps only
FROM node:24-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
EXPOSE 3000
USER node
CMD ["node", "dist/server.js"]
```

The final image only contains the build output and production dependencies. It's smaller (faster to deploy, less attack surface) and doesn't include source code, build tools, or devDependencies.

**The common mistake:** copying `node_modules` from the build stage into the final stage. The build stage ran a full `npm ci`, so that folder contains TypeScript, test runners, linters — everything in `devDependencies`. Either reinstall with `npm ci --omit=dev` in the final stage (as above) or run `npm prune --omit=dev` at the end of the build stage before copying. (`--only=production` is the deprecated spelling of `--omit=dev`.)

### Build Secrets Never Go in ARG or ENV

A private registry token or an API key passed as `ARG NPM_TOKEN` or `ENV` is baked into an image layer forever — anyone who can pull the image can read it with `docker history` or by inspecting the layer. Use BuildKit's secret mount instead, which exposes the secret only during that one `RUN` step and leaves nothing in the image:

```dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci
```

```bash
docker build --secret id=npmrc,src=$HOME/.npmrc .
```

Same rule for `COPY .env .` — keep it in `.dockerignore` (below) and inject runtime config as environment variables when the container starts.

### Don't Run as Root

By default, processes in containers run as root. If an attacker exploits your application, they have root access inside the container. Add a non-root user:

```dockerfile
USER node    # Node.js images include a 'node' user
```

Or create one:
```dockerfile
RUN addgroup --system app && adduser --system --ingroup app app
USER app
```

### Pin Base Image Versions

**Bad:** `FROM node:latest` — this changes without warning. Your build might work today and break tomorrow because `latest` now points to a new major version.

**Good:** `FROM node:24.11-slim` — this is predictable and reproducible. (Pinning to the image digest, `node:24.11-slim@sha256:...`, is stricter still: tags can be re-pushed, digests can't.)

Update pinned versions deliberately and test after updating.

### Use .dockerignore

Just like `.gitignore` keeps files out of git, `.dockerignore` keeps files out of your container image:

```
.git
.env
node_modules
*.md
.DS_Store
tests/
```

This prevents secrets (`.env`), unnecessary bulk (`node_modules` gets reinstalled in the container anyway), and irrelevant files from bloating the image.

### Scan for Vulnerabilities

Container images contain an operating system and libraries that may have known vulnerabilities. Scan them:
- **Trivy** — free, open-source scanner
- **Snyk Container** — free tier available
- **GitHub/GitLab** — built-in scanning in CI pipelines
- **Docker Scout** — built into Docker Desktop

Run scans in your build pipeline and on a regular schedule (base image vulnerabilities are discovered after you build).

## Docker Compose — Local Development

Docker Compose lets you run multiple containers together. A `docker-compose.yml` file defines your application's services:

```yaml
services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
    depends_on:
      - db
  db:
    image: postgres:18
    environment:
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=myapp
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

`docker compose up` starts everything. Great for local development and simple deployments. Not sufficient for production at scale — for that, you'd use a container orchestration platform.

## When You DON'T Need Containers

Containers aren't mandatory. Many hosting platforms handle deployment without them:
- **Vercel, Netlify** — deploy from git, no containers needed
- **Railway, Render** — support both containers and direct deployment from source
- **Heroku** — buildpacks handle packaging

If your hosting platform deploys directly from your code and that works for you, containers add complexity without immediate benefit. Consider containers when:
- You need reproducible builds across multiple environments
- You're running multiple services that need isolation
- Your hosting platform requires containers
- You want to avoid vendor lock-in (containers run anywhere)

## Container Orchestration — You Probably Don't Need It Yet

Kubernetes, Amazon ECS, and similar tools manage fleets of containers across multiple servers. They handle scaling, load balancing, health checks, and automatic restart.

**You need orchestration when:** You're running many containers across many servers, you need auto-scaling, and you have the operational expertise to manage it.

**You don't need it when:** You're running a few containers on one or two servers. Use Docker Compose, a simple platform like Fly.io or Railway, or a managed container service like AWS App Runner or Google Cloud Run.

Kubernetes is powerful but operationally complex. Running your own Kubernetes cluster is a full-time job. Only adopt it when the problems it solves are problems you actually have.
