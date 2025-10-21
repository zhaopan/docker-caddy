ARG REDIS_VER=latest

FROM redis:${REDIS_VER}

# 复制时区配置
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# 复制 Redis 配置文件
COPY redis5.conf /etc/redis/redis.conf
COPY redis-slave.conf /etc/redis/redis-slave.conf
COPY sentinel.conf /etc/redis/sentinel.conf

# 创建数据目录
RUN mkdir -p /data && chown redis:redis /data

EXPOSE 6379
