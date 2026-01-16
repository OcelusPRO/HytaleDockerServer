#!/bin/sh

export DOWNLOADER_URL="${DOWNLOADER_URL:-https://downloader.hytale.com/hytale-downloader.zip}"
export DOWNLOAD_CREDENTIALS_FILE_NAME=".hytale-downloader-credentials.json"

export SERVER_PATH="${SERVER_PATH:-/game}"
mkdir -p "$SERVER_PATH"

export XMX="${XMX:-4096M}"
export XMS="${XMS:-2048M}"

if [ -t 0 ]; then
  DTERM_JLINE_DEFAULT="true"
  DTERM_ANSI_DEFAULT="true"
else
  DTERM_JLINE_DEFAULT="false"
  DTERM_ANSI_DEFAULT="true"
fi
export DTERM_JLINE="${DTERM_JLINE:-$DTERM_JLINE_DEFAULT}"
export DTERM_ANSI="${DTERM_ANSI:-$DTERM_ANSI_DEFAULT}"


export GC_TYPE="${GC_TYPE:-g1gc}"
GC_TYPE_LOWER=$(echo "$GC_TYPE" | tr '[:upper:]' '[:lower:]')
gc_args=""
case "$GC_TYPE_LOWER" in
  "g1gc")
    gc_args="-XX:+UseG1GC -XX:MaxGCPauseMillis=200" ;;
  "zgc")
    gc_args="-XX:+UseZGC -XX:+ZGenerational" ;;
  *)
    gc_args="$GC_TYPE" ;; ## Si inconnu on envoi la valeur de l'utilisateur directement
esac
gc_args="$gc_args -XX:+AlwaysPreTouch -XX:+UnlockExperimentalVMOptions -XX:+ParallelRefProcEnabled"

export GC_ARGS="${GC_ARGS:-$gc_args}"
export USE_AOT="${USE_AOT:-false}"
USE_AOT_LOWER=$(echo "$USE_AOT" | tr '[:upper:]' '[:lower:]')
aot_arg=""
if [ "$USE_AOT_LOWER" = "true" ]; then
  aot_arg="-XX:AOTCache=HytaleServer.aot"
fi

jvm_args="-Xms$XMS -Xmx$XMX -Dterminal.jline=$DTERM_JLINE -Dterminal.ansi=$DTERM_ANSI $GC_ARGS $aot_arg"
export JVM_ARGS="${JVM_ARGS:-$jvm_args}"

export SERVER_PORT="${SERVER_PORT:-5520}"
export SERVER_IP="${SERVER_IP:-0.0.0.0}"
export ENABLE_SENTRY="${ENABLE_SENTRY:-true}"
export OWNER_UUID="${OWNER_UUID:-}"
# On convertit en minuscules de manière compatible POSIX
ENABLE_SENTRY_LOWER=$(echo "$ENABLE_SENTRY" | tr '[:upper:]' '[:lower:]')

SENTRY_ARG="--disable-sentry"
if [ "$ENABLE_SENTRY_LOWER" = "true" ]; then
  SENTRY_ARG=""
fi

OWNER_UUID_ARG=""
if [ -n "$OWNER_UUID" ]; then
  OWNER_UUID_ARG="--owner_uuid $OWNER_UUID"
fi

server_args="--assets $SERVER_PATH/Assets.zip --bind $SERVER_IP:$SERVER_PORT $SENTRY_ARG $OWNER_UUID_ARG"
export SERVER_ARGS="${SERVER_ARGS:-$server_args}"

export OAUTH_STORAGE="$SERVER_PATH/.hytale_oauth.json"
export DOWNLOADER_CREDENTIALS="$SERVER_PATH/$DOWNLOAD_CREDENTIALS_FILE_NAME"