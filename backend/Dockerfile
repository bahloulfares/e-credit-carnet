# =============================================================================
# Stage 1: Build
# =============================================================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files and Prisma schema first (better layer caching)
COPY package*.json ./
COPY prisma/ ./prisma/

# Install all dependencies (including devDependencies for build)
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy source and build TypeScript
COPY . .
RUN npm run build

# =============================================================================
# Stage 2: Production image
# =============================================================================
FROM node:18-alpine AS runner

WORKDIR /app

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Copy only what's needed at runtime
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma

USER nodejs

EXPOSE 3000

# Run DB migrations then start the server
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
