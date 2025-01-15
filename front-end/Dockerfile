# Stage 1: Build environment
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY front-end/package.json front-end/package-lock.json* ./

# Install dependencies
RUN npm ci

# Copy the rest of the application code
COPY front-end/ .

# Run the build script which includes ABI copy
RUN npm run copy-abis
RUN npm run build

# Stage 2: Production environment
FROM node:20-alpine AS runner

WORKDIR /app

# Set environment to production
ENV NODE_ENV production

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy necessary files from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Set correct permissions
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose the port your app runs on
EXPOSE 3000

# Set the command to run your app
ENV PORT 3000
CMD ["node", "server.js"]