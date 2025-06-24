ARG MONGO_VERSION=latest

FROM mongo:${MONGO_VERSION}

# 复制时区配置
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

EXPOSE 27017
