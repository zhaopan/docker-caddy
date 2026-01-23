ARG MONGO_VERSION=8.0
FROM mongo:${MONGO_VERSION}

ENV TZ=Asia/Shanghai

RUN apt-get update && apt-get install -y tzdata \
    &&ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

USER mongodb

EXPOSE 27017
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mongod"]
