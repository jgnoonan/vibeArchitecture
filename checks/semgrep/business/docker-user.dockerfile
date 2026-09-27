# Fixtures for docker-user.yaml. Each stage is one scenario.
# Scenario 1: never drops root.
FROM node:24.8-slim AS never-drops
COPY . /app
# ruleid: va-docker-runs-as-root
CMD ["node", "/app/server.js"]

# Scenario 2: drops root before starting.
FROM node:24.8-slim AS drops
USER node
# ok: va-docker-runs-as-root
# ok: va-docker-explicit-root-user
CMD ["node", "/app/server.js"]

# Scenario 3: switches back to root at the end.
FROM node:24.8-slim AS back-to-root
# ruleid: va-docker-explicit-root-user
USER root
CMD ["node", "/app/server.js"]
