# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Set npm to use local cache
ENV npm_config_cache=/app/.npm

# Copy package files
COPY front-end/package.json ./

# Install dependencies
RUN npm install

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# Copy installed dependencies and other files
COPY --from=deps /app/node_modules ./node_modules
COPY front-end/ ./
COPY out /app/out

# Ensure correct permissions
RUN chmod +x node_modules/.bin/* && \
    ls -la node_modules/.bin/

# Set environment variables
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_PATH=/app/node_modules

# Debug the contract files
RUN ls -la /app/out || true

# Skip copyArtifacts for now and just build
RUN node /app/node_modules/next/dist/bin/next build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Install production dependencies
COPY front-end/package.json ./
RUN npm install --omit=dev

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000
ENV PORT=3000

CMD ["node", "server.js"]