FROM oven/bun:1-alpine AS base
WORKDIR /app
COPY package.json bun.lock ./

FROM base AS dev-deps
RUN bun install --frozen-lockfile

FROM base AS prod-deps
RUN bun install --frozen-lockfile --production

FROM base AS build
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
COPY --from=dev-deps /app/node_modules ./node_modules
COPY . .
RUN bun run build

FROM node:20-alpine AS release
WORKDIR /app
ENV NODE_ENV=production
COPY package.json ./
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/build ./build

EXPOSE 3000
CMD ["node_modules/.bin/react-router-serve", "./build/server/index.js"]
