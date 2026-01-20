#!/bin/bash

OPS_LIST=$(get_from_env "OPS_LIST" "string" "" "trim")
OPS_MODE=$(get_from_env "OPS_MODE" "enum(add, override)" "override" "lower")

WHITELIST_ENABLED=$(get_from_env "WHITELIST_ENABLED" "boolean" "false")

WHITELIST_LIST=$(get_from_env "WHITELIST_LIST" "string" "" "trim")
WHITELIST_MODE=$(get_from_env "WHITELIST_MODE" "enum(add, override)" "override" "lower")

SERVER_NAME=$(get_from_env "SERVER_NAME" "string" "Hytale Server" "trim")
SERVER_MOTD=$(get_from_env "SERVER_MOTD" "string" "" "trim")
SERVER_PASSWORD=$(get_from_env "SERVER_PASSWORD" "string" "" "trim")
MAX_PLAYERS=$(get_from_env "MAX_PLAYERS" "format(^[0-9]+$)" "100" "trim")
MAX_VIEW_RADIUS=$(get_from_env "MAX_VIEW_RADIUS" "format(^[0-9]+$)" "32" "trim")