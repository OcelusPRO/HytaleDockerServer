#!/bin/bash


DOWNLOADER_URL=$(get_from_env "DOWNLOADER_URL" "string" "https://downloader.hytale.com/hytale-downloader.zip")
DOWNLOAD_CREDENTIALS_FILE_NAME=".hytale-downloader-credentials.json"
export DOWNLOADER_URL
export DOWNLOAD_CREDENTIALS_FILE_NAME

SERVER_PATH=$(get_from_env "SERVER_PATH" "string" "/game" "trim")
mkdir -p "$SERVER_PATH"
export SERVER_PATH

PERMS_PATH="$SERVER_PATH/Server/permissions.json"
WHITELIST_PATH="$SERVER_PATH/Server/whitelist.json"
CONFIG_PATH="$SERVER_PATH/Server/config.json"
export PERMS_PATH
export WHITELIST_PATH
export CONFIG_PATH

OAUTH_STORAGE="$SERVER_PATH/.hytale_oauth.json"
DOWNLOADER_CREDENTIALS="$SERVER_PATH/$DOWNLOAD_CREDENTIALS_FILE_NAME"
export OAUTH_STORAGE
export DOWNLOADER_CREDENTIALS

ENABLE_AUTO_UPDATE=$(get_from_env "ENABLE_AUTO_UPDATE" "boolean" "true" "trim")
CRON_REGEX="^([^ ]+ +){4}[^ ]+$"
AUTO_UPDATE_CRON=$(get_from_env "AUTO_UPDATE_CRON" "format($CRON_REGEX)" "*/30 * * * *" "trim")
export ENABLE_AUTO_UPDATE
export AUTO_UPDATE_CRON