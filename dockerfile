FROM oven/bun:1 as base
WORKDIR /usr/src/app

# Install dependencies
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
RUN cd /temp/dev && bun install --frozen-lockfile

# Copy app
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# Build app
WORKDIR /usr/src/app/apps/web
RUN bun install
RUN bun run build

# Final image
FROM base AS release
COPY --from=install /temp/dev/node_modules node_modules
COPY --from=prerelease /usr/src/app/apps/web/.next ./apps/web/.next
COPY --from=prerelease /usr/src/app/apps/web/public ./apps/web/public
COPY --from=prerelease /usr/src/app/apps/web/package.json ./apps/web/package.json
COPY --from=prerelease /usr/src/app/apps/web/next.config.js ./apps/web/next.config.js

WORKDIR /usr/src/app/apps/web
EXPOSE 3000/tcp
ENTRYPOINT ["bun", "start"]