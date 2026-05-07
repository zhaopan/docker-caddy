FROM golang:alpine AS builder

ENV GOTOOLCHAIN=auto

RUN set -e \
  && apk upgrade \
  && apk add jq curl git \
  && go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
  && xcaddy build v2.11.1 --output /caddy \
  --with github.com/pengcu/caddy-trojan

FROM alpine AS dist

ENV TZ=Asia/Shanghai

COPY --from=builder /caddy /usr/bin/caddy

COPY caddy/ /caddy/

ADD https://github.com/zhaopan/zhaopan.github.io/archive/refs/heads/master.zip /caddy/html/master.zip

RUN set -e \
  && apk upgrade \
  && apk add bash tzdata mailcap \
  && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo ${TZ} > /etc/timezone \
  && rm -rf /var/cache/apk/* \
  && unzip /caddy/html/master.zip -d /caddy/html/

EXPOSE 80
EXPOSE 443
EXPOSE 2019

WORKDIR /

CMD ["caddy", "run", "--config", "/caddy/Caddyfile", "--adapter", "caddyfile"]
