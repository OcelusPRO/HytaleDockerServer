#!/bin/bash

PORT_REGEX="^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"
SERVER_PORT=$(get_from_env "SERVER_PORT" "format($PORT_REGEX)" "5520" "trim")

SERVER_IP=$(get_from_env "SERVER_IP" "string" "0.0.0.0")

UUID_REGEX="^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
OWNER_UUID=$(get_from_env "OWNER_UUID" "format($UUID_REGEX)" "" "trim")
export OWNER_UUID


ENABLE_SENTRY=$(get_from_env "ENABLE_SENTRY" "boolean" "true" "trim")
SENTRY_ARG="--disable-sentry"
if [ "$ENABLE_SENTRY" = "true" ]; then
  SENTRY_ARG=""
fi

OWNER_UUID_ARG=""
if [ -n "$OWNER_UUID" ]; then
  OWNER_UUID_ARG="--owner_uuid $OWNER_UUID"
fi

server_args_default="--assets $SERVER_PATH/Assets.zip --bind $SERVER_IP:$SERVER_PORT $SENTRY_ARG $OWNER_UUID_ARG"
SERVER_ARGS=$(get_from_env "SERVER_ARGS" "string" "$server_args_default" "trim")
export SERVER_ARGS
