#!/bin/bash


DOWNLOADER_URL=$(get_from_env "DOWNLOADER_URL" "string" "https://downloader.hytale.com/hytale-downloader.zip")
DOWNLOAD_CREDENTIALS_FILE_NAME=".hytale-downloader-credentials.json"

SERVER_PATH=$(get_from_env "SERVER_PATH" "string" "/game" "trim")
mkdir -p "$SERVER_PATH"

OAUTH_STORAGE="$SERVER_PATH/.hytale_oauth.json"
DOWNLOADER_CREDENTIALS="$SERVER_PATH/$DOWNLOAD_CREDENTIALS_FILE_NAME"

ENABLE_AUTO_UPDATE=$(get_from_env "ENABLE_AUTO_UPDATE" "boolean" "true" "trim")
CRON_REGEX="^([^ ]+ +){4}[^ ]+$"
AUTO_UPDATE_CRON=$(get_from_env "AUTO_UPDATE_CRON" "format($CRON_REGEX)" "0 * * * *" "trim")