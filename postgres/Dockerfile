ARG PG_VERSION=16-alpine
FROM postgres:${PG_VERSION} AS builder

ENV TZ=Asia/Shanghai

RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

EXPOSE 5432
