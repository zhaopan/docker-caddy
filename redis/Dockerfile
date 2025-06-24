ARG REDIS_VER=latest

FROM redis:${REDIS_VER}

# 复制时区配置
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

CMD [ "redis-server"]

EXPOSE 6379
