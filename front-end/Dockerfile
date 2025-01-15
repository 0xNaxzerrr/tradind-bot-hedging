# syntax=docker/dockerfile:1.4

# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache git

# Copy only package files for efficient caching
COPY front-end/package.json ./

# Set npm to use local cache and create node_modules with correct permissions
ENV npm_config_cache=/app/.npm
RUN mkdir -p /app/.npm && \
    chown -R node:node /app

# Switch to non-root user
USER node

# Install dependencies with caching
RUN npm install

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# Create and set permissions for .next cache directory
RUN mkdir -p /app/.next && \
    chown -R node:node /app

# Switch to non-root user
USER node

# Copy installed dependencies
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node front-end/ ./
COPY --chown=node:node out ./out

# Build the application with cache mounting
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run copy-abis || true && \
    npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy package.json for production dependencies
COPY front-end/package.json ./

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Install production dependencies
RUN npm install --omit=dev

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

EXPOSE 3000
ENV PORT=3000

CMD ["node", "server.js"]