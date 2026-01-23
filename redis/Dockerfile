ARG REDIS_VER=5-alpine

FROM redis:${REDIS_VER}

# 复制时区配置
ENV TZ=Asia/Shanghai
RUN apk update && apk add tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/cache/apk/*

# 复制 Redis 配置文件
COPY redis5.conf /etc/redis/redis.conf

# 创建数据目录
RUN mkdir -p /data && chown redis:redis /data

EXPOSE 6379

CMD ["redis-server", "/etc/redis/redis.conf"]
