ARG CADDY_VERSION=latest

FROM caddy:${CADDY_VERSION}-builder AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-webdav

FROM caddy:${CADDY_VERSION}

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# 复制时区配置
ENV TZ=Asia/Shanghai
RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 80 443
