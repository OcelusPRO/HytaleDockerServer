# Hytale Docker Server
A high-performance, automated Docker image for running Hytale servers with Java 25. This project features automated updates, secure OAuth2 Device Flow authentication, and optimized memory management for low-latency gaming.

## Features

- Java 25 Runtime: Leverages the latest JVM features, including Generational ZGC and optimized native access for high performance.
- OAuth2 Device Flow: Headless authentication process following RFC 8628. No need to share your password with the container.
- Automated Updates: Automatically checks for and downloads the latest Hytale server version on startup using the official downloader.
- Persistent Session: Stores and refreshes access tokens in your volume to maintain server identity across restarts.
- Alpine Optimized: Includes gcompat and automated machine-id generation to ensure native library compatibility (Netty/QUIC).
- Security First: Runs as a non-root user (hytale) and uses gosu for proper signal handling.

## Quick Start

### 1. Prerequisites
Ensure you have Docker and Docker Compose installed.

### 2. Basic Configuration
Create a docker-compose.yml file in your server directory (sample):

```yaml
services:
  hytale:
    image: ocelus/hytale-docker-server:latest
    ports:
      - "5520:5520/udp"
    environment:
      - XMX=16G
      - GC_TYPE=zgc
    volumes:
      - ./hytale-data:/game
    restart: unless-stopped
```

### 3. First Launch (Authentication)

1. docker compose up
2. Watch the logs for the following instructions:
3. Navigate to the URL provided in the console (e.g., https://accounts.hytale.com/...).
4. Allow access to your Hytale account.
5. The server will automatically detect the authorization, generate its session tokens, and start.

> *Note : the downloader can request another authorization flow if the session expires.* 

#### Environment Variables

| category            | Variable         | Description                                      | Default                             |                                                  
|---------------------|------------------|--------------------------------------------------|-------------------------------------|
| **JVM Settings**    | `XMX`            | Maximum Java heap size                           | `4096M`                             |
| **JVM Settings**    | `XMS`            | Initial Java heap size                           | `2048M`                             |
| **JVM Settings**    | `GC_TYPE`        | Type of garbage collector (g1gc, zgc, or custom) | `g1gc`                              |
| **JVM Settings**    | `GC_ARGS`        | Additional custom garbage collector arguments    | (empty)                             |
| **JVM Settings**    | `USE_AOT`        | Enable Hytale AOT (Ahead-of-Time) file usage     | `false`                             |
| **JVM Settings**    | `DTERM_JLINE`    | Enable JLine support in DTerm                    | `true`                              |
| **JVM Settings**    | `DTERM_ANSI`     | Enable ANSI colors in DTerm                      | `true`                              |
| **JVM Settings**    | `JVM_ARGS`       | **Overrides** all other JVM args if set          | (empty)                             |
| **Server Settings** | `SERVER_PORT`    | Hytale server listening port                     | `5520`                              |
| **Server Settings** | `SERVER_IP`      | Hytale server IP address                         | `0.0.0.0`                           |
| **Server Settings** | `ENABLE_SENTRY`  | Enable Sentry error reporting                    | `true`                              |
| **Server Settings** | `OWNER_UUID`     | Owner UUID for server authentication             | (empty)                             |
| **Server Settings** | `SERVER_ARGS`    | **Overrides** all other server args if set       | (empty)                             |
| **Others**          | `DOWNLOADER_URL` | Custom Hytale server downloader zip URL          | `https://downloader.hytale.com/...` |

#### Volumes

- `/game`: This is the main directory for server files, world data, and authentication tokens. This must be persistent to avoid re-authenticating on every restart.
