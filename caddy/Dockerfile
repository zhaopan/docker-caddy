ARG CADDY_VERSION=latest

FROM caddy:${CADDY_VERSION}

# 复制时区配置
ENV TZ=Asia/Shanghai
RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 80 443
