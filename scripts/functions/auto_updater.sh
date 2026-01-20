#!/bin/bash

# TODO
start_auto_updater() {
  ENABLE_AUTO_UPDATE_LOWER=$(echo "$ENABLE_AUTO_UPDATE" | tr '[:upper:]' '[:lower:]')
  if [ "$ENABLE_AUTO_UPDATE_LOWER" != "true" ]; then
    send_log "AUTO-UPDATER" "Auto-updates are disabled." "WARN"
    return
  fi

  downloader="$1"
  current="$(cat "$SERVER_PATH/version.txt")"

  while true; do
    sleep 3600
    latest=$( get_latest_version "$downloader" )

    if [ "$current" != "$latest" ]; then
      send_log "AUTO-UPDATER" "New version detected: $latest (current: $current)." "ERROR"
      send_log "AUTO-UPDATER" "Send restart alert to the server." "ERROR"
      find_command "auto_update_alert"
    fi
  done
}

