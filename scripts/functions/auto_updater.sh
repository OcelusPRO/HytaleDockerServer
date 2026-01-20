#!/bin/bash

start_auto_updater() {
  ENABLE_AUTO_UPDATE_LOWER=$(echo "$ENABLE_AUTO_UPDATE" | tr '[:upper:]' '[:lower:]')
  if [ "$ENABLE_AUTO_UPDATE_LOWER" != "true" ]; then
    send_log "AUTO-UPDATER" "Auto-updates are disabled." "WARN"
    return
  fi

  current="$(get_installed_version)"

  while true; do
    sleep 3600
    latest=$(get_latest_version)

    if [ "$current" != "$latest" ]; then
      send_log "AUTO-UPDATER" "New version detected: $latest (current: $current)." "ERROR"
      send_log "AUTO-UPDATER" "Send restart alert to the server." "ERROR"
      find_command "auto_update_alert"
    fi
  done
}

