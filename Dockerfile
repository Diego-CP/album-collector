# BASE

# HIGH CVE-2026-12151 on bundled npm module undici - from 24-alpine 
# sha256:a0b9bf06e4e6193cf7a0f58816cc935ff8c2a908f81e6f1a95432d679c54fbfd
# Only affects WebSocket client
# Not reachable: app opens no outbound WebSocket connections, and npm is not run at
# runtime.
# Reviewed 29 Jun 2026. Accepted.
FROM node:24-alpine AS base
WORKDIR /app

# dumb-init becomes PID 1 and forwards SIGTERM to Node. On EKS:
# when Kubernetes stops a pod it sends SIGTERM, allowing Express to shut
# down gracefully
RUN apk add --no-cache dumb-init

# BUNDLE

# DB: dbmate (DB migration tool)
# Fetched in its own stage so curl isn't in the final image. arm64 to match nodes
FROM alpine:3 AS dbmate
RUN apk add --no-cache curl && \
    curl -fsSL -o /dbmate \
      https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-arm64 && \
    chmod +x /dbmate

# DEPENDENCIES

# Copy package files and install dependencies as root
# npm ci only runs when package.json / package-lock.json change
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# RUNTIME

FROM base AS runtime
ENV NODE_ENV=production
ENV PORT=3000

# Bring in dependencies and app code
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .

# Used by the migration Job
COPY --from=dbmate /dbmate /usr/local/bin/dbmate

# Switch to non-root user for runtime
USER node
EXPOSE 3000

# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD node -e "fetch('http://localhost:'+(process.env.PORT||3000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
