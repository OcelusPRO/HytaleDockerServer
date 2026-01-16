# syntax=docker/dockerfile:1.7
FROM eclipse-temurin:25-jre-alpine-3.23

RUN apk add --no-cache gosu curl unzip gcompat libgcc
RUN addgroup -g 1000 hytale && \
    adduser -u 1000 -G hytale -S -D hytale

WORKDIR /app
COPY --chmod=755 scripts/ /app/scripts/

EXPOSE 5520/udp

ENTRYPOINT ["/bin/sh", "/app/scripts/entrypoint.sh"]