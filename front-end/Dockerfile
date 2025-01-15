# syntax=docker/dockerfile:1.4

# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache git

# Copy only package files for efficient caching
COPY front-end/package.json ./

# Install dependencies with caching
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# Copy installed dependencies
COPY --from=deps /app/node_modules ./node_modules
COPY front-end/ ./
COPY out ./out

# Build the application with cache mounting
RUN --mount=type=cache,target=/app/.next/cache \
    npm run copy-abis || true && \
    NEXT_TELEMETRY_DISABLED=1 npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Install production dependencies only with caching
COPY front-end/package.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm install --omit=dev

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Create a non-root user and set permissions
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000
ENV PORT=3000

CMD ["node", "server.js"]