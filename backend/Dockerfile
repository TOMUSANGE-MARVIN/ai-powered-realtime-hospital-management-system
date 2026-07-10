FROM oven/bun:1-alpine AS base
WORKDIR /app
COPY package.json bun.lock ./

FROM base AS deps
RUN bun install --frozen-lockfile

FROM oven/bun:1-alpine AS release
WORKDIR /app
ENV NODE_ENV=production
COPY package.json ./
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN bunx prisma generate

EXPOSE 5000
CMD ["sh", "-c", "bunx prisma migrate deploy && bun run src/server.ts"]
