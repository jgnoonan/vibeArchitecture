# Fixtures for dockerfile.yaml
# ruleid: va-docker-unpinned-base-image
FROM node:latest AS deps
# ruleid: va-docker-unpinned-base-image
FROM node AS build
# ruleid: va-docker-secret-in-build
ARG NPM_TOKEN
# ok: va-docker-secret-in-build
ARG NODE_ENV=production
RUN npm ci --omit=dev
# ok: va-docker-unpinned-base-image
FROM build AS test
# ok: va-docker-unpinned-base-image
FROM node:24.8-slim@sha256:0000000000000000000000000000000000000000000000000000000000000000
COPY --from=build /app /app
USER node
CMD ["node", "/app/server.js"]
