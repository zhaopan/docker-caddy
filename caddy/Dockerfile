ARG CADDY_VERSION=2.10

FROM caddy:${CADDY_VERSION}

# 复制时区配置
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 80 443