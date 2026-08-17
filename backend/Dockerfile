# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install all deps (including devDeps for TypeScript build)
COPY package*.json ./
RUN npm install --legacy-peer-deps

# Copy source files
COPY tsconfig.json ./
COPY prisma ./prisma/
COPY src ./src/

# Generate Prisma client
RUN npx prisma generate

# Compile TypeScript
RUN npm run build

# ── Stage 2: Production Image ─────────────────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

# Install only production deps
COPY package*.json ./
RUN npm install --omit=dev --legacy-peer-deps && npm cache clean --force

# Copy built artifacts
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

# Non-root user for security
RUN addgroup -g 1001 -S orbit && adduser -S orbit -u 1001
USER orbit

EXPOSE 5000

# Run DB migration then start server
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
