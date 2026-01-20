# syntax=docker/dockerfile:1.7
FROM eclipse-temurin:25-jre-alpine-3.23

LABEL org.opencontainers.image.title="Hytale Docker Server"
LABEL org.opencontainers.image.description="Automated Hytale server with Device Flow update and authentication"
LABEL org.opencontainers.image.authors="ocelus"
LABEL org.opencontainers.image.url="https://github.com/oceluspro/hytaledockerserver"
LABEL org.opencontainers.image.source="https://github.com/oceluspro/hytaledockerserver"
LABEL org.opencontainers.image.vendor="Ocelus"
LABEL org.opencontainers.image.base.name="eclipse-temurin:25-jre-alpine-3.23"

#######################################
# Environment variables documentation #
#######################################

# JVM Settings
LABEL io.github.hytaledockerserver.env.XMX="Xmx java arg (ex: 4096M)"
LABEL io.github.hytaledockerserver.env.XMS="Xms java arg (ex: 2048M)"
LABEL io.github.hytaledockerserver.env.GC_TYPE="Type of garbage collector (g1gc or zgc) (or custom jvm gc args) (default g1gc)"
LABEL io.github.hytaledockerserver.env.GC_ARGS="Aditional custom garbage collector args (for g1gc or zgc) (default empty)"
LABEL io.github.hytaledockerserver.env.USE_AOT="Use hytale AOT file (true/false) (default false)"
LABEL io.github.hytaledockerserver.env.DTERM_JLINE="Enable JLine support in DTerm (true/false) (default true)"
LABEL io.github.hytaledockerserver.env.DTERM_ANSI="Enable ANSI colors in DTerm (true/false) (default true)"
LABEL io.github.hytaledockerserver.env.JVM_ARGS="Override all other jvm args if set (default empty)"

# Hytale Server Settings
LABEL io.github.hytaledockerserver.env.SERVER_PORT="Hytale server port (default 5520)"
LABEL io.github.hytaledockerserver.env.SERVER_IP="Hytale server IP (default 0.0.0.0)"
LABEL io.github.hytaledockerserver.env.ENABLE_SENTRY="Enable Sentry error reporting (true/false) (default true)"
LABEL io.github.hytaledockerserver.env.OWNER_UUID="Owner UUID for server authentication (default empty)"
LABEL io.github.hytaledockerserver.env.SERVER_ARGS="Override all other server args if set (default empty)"

# others
LABEL io.github.hytaledockerserver.env.DOWNLOADER_URL="Custom Hytale server downloader URL (default https://downloader.hytale.com/hytale-downloader.zip)"


COPY --chmod=755 scripts/ /app/scripts/
COPY --chmod=644 defaults/ /app/defaults/

RUN apk add --no-cache curl unzip gcompat libgcc bash jq
RUN addgroup -g 1000 container && adduser -u 1000 -G container -S -D container
RUN chown -R container:container /home/container /app
RUN mkdir -p /etc && echo "PLACEHOLDER" > /etc/machine-id && chown "container:container" /etc/machine-id

USER container
ENV  USER=container HOME=/home/container

WORKDIR /home/container

EXPOSE 5520/udp

ENTRYPOINT ["/bin/bash", "/app/scripts/entrypoint.sh"]