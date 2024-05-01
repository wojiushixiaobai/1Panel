FROM golang:1.21-buster as builder
ARG VERSION=v1.10.6-lts
ENV VERSION=${VERSION}

ARG DEPENDENCIES="      \
        ca-certificates \
        wget"

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends ${DEPENDENCIES} \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex \
    && git clone -b ${VERSION} --depth=1 https://github.com/1Panel-dev/1Panel /opt/1Panel

WORKDIR /opt/1Panel

RUN set -ex \
    && mkdir -p build dist \
    && wget https://github.com/wojiushixiaobai/1Panel-loongarch64/releases/download/${VERSION}/web-${VERSION}.tar.gz \
    && wget https://github.com/1Panel-dev/installer/raw/main/1pctl \
    && wget https://github.com/1Panel-dev/installer/raw/main/1panel.service \
    && wget https://github.com/1Panel-dev/installer/raw/main/install.sh \
    && tar xf web-${VERSION}.tar.gz -C cmd/server/web --strip-components=1 \
    && rm -f web-${VERSION}.tar.gz \
    && sed -i "s@ORIGINAL_VERSION=.*@ORIGINAL_VERSION=${VERSION}@g" 1pctl \
    && sed -i "s@github.com/glebarez/sqlite@gorm.io/driver/sqlite@g" cmd/server/cmd/root.go \
    && sed -i "s@github.com/glebarez/sqlite@gorm.io/driver/sqlite@g" backend/init/db/db.go \
    && go mod tidy \
    && go get -u gorm.io/driver/sqlite

RUN set -ex \
    && mkdir 1panel-${VERSION}-linux-loong64 \
    && GOOS=linux GOARCH=loong64 go build -trimpath -ldflags '-s -w' -o ./build/1panel ./cmd/server/main.go \
    && cp -f build/1panel 1panel-${VERSION}-linux-loong64/ \
    && cp -f 1pctl 1panel-${VERSION}-linux-loong64/ \
    && cp -f 1panel.service 1panel-${VERSION}-linux-loong64/ \
    && cp -f install.sh 1panel-${VERSION}-linux-loong64/ \
    && cp -f README.md 1panel-${VERSION}-linux-loong64/ \
    && cp -f LICENSE 1panel-${VERSION}-linux-loong64/ \
    && tar -czf 1panel-${VERSION}-linux-loong64.tar.gz 1panel-${VERSION}-linux-loong64 \
    && sha256sum 1panel-${VERSION}-linux-loong64.tar.gz > dist/1panel-${VERSION}-linux-loong64.tar.gz.sha256 \
    && mv 1panel-${VERSION}-linux-loong64.tar.gz dist/ \
    && rm -rf 1panel-${VERSION}-linux-loong64 build

FROM debian:buster-slim

WORKDIR /opt/1Panel

COPY --from=builder /opt/1Panel/dist /opt/1Panel/dist

VOLUME /dist

CMD cp -rf dist/* /dist/




