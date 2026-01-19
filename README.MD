# Hytale Docker Server
A high-performance, automated Docker image for running Hytale servers with Java 25. This project features automated updates, secure OAuth2 Device Flow authentication, and optimized memory management for low-latency gaming.

[![Docker Hub Version](https://img.shields.io/docker/v/ocelus/hytale-docker-server?label=docker%20hub&logo=docker)](https://hub.docker.com/r/ocelus/hytale-docker-server)
[![Docker Hub Pulls](https://img.shields.io/docker/pulls/ocelus/hytale-docker-server?logo=docker)](https://hub.docker.com/r/ocelus/hytale-docker-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/ocelus/hytale-docker-server/latest?logo=docker)](https://hub.docker.com/r/ocelus/hytale-docker-server)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/oceluspro/hytaledockerserver/docker-image.yml?label=build&logo=github)](https://github.com/oceluspro/hytaledockerserver/actions)
[![GitHub stars](https://img.shields.io/github/stars/oceluspro/hytaledockerserver?style=flat&logo=github)](https://github.com/oceluspro/hytaledockerserver)
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
Deployment Examples

You can find various configuration templates in the [samples](./samples) directory of this repository. These examples demonstrate different use cases, including High Performance setups using Generational ZGC, Standard community configurations, and Debug modes for development. Each sample is designed to help you quickly deploy a Hytale server tailored to your specific needs.

### 3. First Launch (Authentication)

1. docker compose up
2. Watch the logs for the following instructions:
3. Navigate to the URL provided in the console (e.g., https://accounts.hytale.com/...).
4. Allow access to your Hytale account.
5. The server will automatically detect the authorization, generate its session tokens, and start.

> *Note : the downloader can request another authorization flow if the session expires.* 

#### Environment Variables

| category            | Variable         | Description                                      | Default                                               |                                                  
|---------------------|------------------|--------------------------------------------------|-------------------------------------------------------|
| **JVM Settings**    | `XMX`            | Maximum Java heap size                           | `4096M`                                               |
| **JVM Settings**    | `XMS`            | Initial Java heap size                           | `2048M`                                               |
| **JVM Settings**    | `GC_TYPE`        | Type of garbage collector (g1gc, zgc, or custom) | `g1gc`                                                |
| **JVM Settings**    | `GC_ARGS`        | Additional custom garbage collector arguments    | (empty)                                               |
| **JVM Settings**    | `USE_AOT`        | Enable Hytale AOT (Ahead-of-Time) file usage     | `false`                                               |
| **JVM Settings**    | `DTERM_JLINE`    | Enable JLine support in DTerm                    | `true`                                                |
| **JVM Settings**    | `DTERM_ANSI`     | Enable ANSI colors in DTerm                      | `true`                                                |
| **JVM Settings**    | `JVM_ARGS`       | **Overrides** all other JVM args if set          | (empty)                                               |
| **Server Settings** | `SERVER_PORT`    | Hytale server listening port                     | `5520`                                                |
| **Server Settings** | `SERVER_IP`      | Hytale server IP address                         | `0.0.0.0`                                             |
| **Server Settings** | `ENABLE_SENTRY`  | Enable Sentry error reporting                    | `false`                                               |
| **Server Settings** | `OWNER_UUID`     | Owner UUID for server authentication             | (empty)                                               |
| **Server Settings** | `SERVER_ARGS`    | **Overrides** all other server args if set       | (empty)                                               |
| **Others**          | `DOWNLOADER_URL` | Custom Hytale server downloader zip URL          | `https://downloader.hytale.com/hytale-downloader.zip` |

#### Volumes

- `/game`: This is the main directory for server files, world data, and authentication tokens. This must be persistent to avoid re-authenticating on every restart.

## Use Pterodactyl Panel
> Work in progress !
Copy the [hytale-server-egg.json](./hytale-server-egg.json) file to your pterodactyl panel and add it to your server.

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=OcelusPRO/HytaleDockerServer&type=date&legend=top-left)](https://www.star-history.com/#OcelusPRO/HytaleDockerServer&type=date&legend=top-left)