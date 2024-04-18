# 定义变量，用来选择 yarn/pnpm ，默认为 yarn
ARG TARGET=yarn

# Yarn build
FROM node:14-alpine AS yarn-build
WORKDIR /app
COPY . /app
RUN yarn install && yarn build

# Pnpm build
FROM node:20-slim AS pnpm-base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
WORKDIR /app
COPY . /app


FROM pnpm-base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM pnpm-base AS pnpm-build
# 高版本 node 兼容
ENV NODE_OPTIONS --openssl-legacy-provider
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run build

# 通过传递的变量决定最终 build
FROM ${TARGET}-build as builder

FROM nginx:stable-alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]