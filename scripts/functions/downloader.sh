#!/bin/bash

configure_downloader_credentials(){
  if [ -f "$DOWNLOADER_CREDENTIALS" ]; then
    send_log "SETUP" "Configuring downloader credentials from $DOWNLOADER_CREDENTIALS..." "INFO"
    cp "$DOWNLOADER_CREDENTIALS" "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME" > /dev/null 2>&1
  fi
}

get_downloader() {
  send_log "SETUP" "Downloading the hytale-downloader from $DOWNLOADER_URL..." "INFO"
  curl --output /app/hytale-downloader.zip "$DOWNLOADER_URL" >&2

  send_log "SETUP" "Extracting the hytale-downloader..." "INFO"
  unzip /app/hytale-downloader.zip -d /app/hytale-downloader-files >&2

  send_log "SETUP" "Cleaning up the hytale-downloader zip file..." "INFO"
  rm /app/hytale-downloader.zip

  send_log "SETUP" "Copying the Linux binary to /app/hytale-downloader and assigning execute permissions..." "INFO"
  cp /app/hytale-downloader-files/hytale-downloader-linux-amd64 /app/hytale-downloader
  chmod +x /app/hytale-downloader

  send_log "SETUP" "Cleaning up temporary files from hytale-downloader..." "INFO"
  rm -rf /app/hytale-downloader-files

  configure_downloader_credentials

  send_log "SETUP" "hytale-downloader is ready to use." "INFO"
  echo "/app/hytale-downloader"
}

find_downloader() {
  if [ -f "/app/hytale-downloader" ]; then
    echo "/app/hytale-downloader"
  else
    send_log "SETUP" "hytale-downloader not found. Initiating download and setup..." "WARN"
    get_downloader
  fi
}

# Run a command to check downloader credentials validity
run_void_downloader_command() {
  local downloader=""
  downloader=$(find_downloader)

  "$downloader" -print-version > /dev/null 2>&1

  cp "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME" "$DOWNLOADER_CREDENTIALS"
}

get_latest_version() {
  local downloader=""
  downloader=$(find_downloader)

  run_void_downloader_command

  local latest=""
  latest=$("$downloader" -print-version)
  echo "$latest"
}

get_version_file(){
  local version_file="$SERVER_PATH/version.txt"
  if [ -f "$version_file" ]; then
    echo "$version_file"
  else
    send_log "DOWNLOADER" "No version file found at $version_file. Creating one with 'unknown' version." "WARN"
    echo "unknown" > "$version_file"
    echo "$version_file"
  fi
}

get_installed_version(){
  cat "$(get_version_file)"
}

check_for_update() {
  local current=""
  current="$(get_installed_version)"
  local latest=""
  latest="$(get_latest_version)"

  if [ "$current" != "$latest" ]; then
    send_log "DOWNLOADER" "Update available: current version is $current, latest version is $latest." "WARN"
    echo "update_available"
    return 1
  else
    send_log "DOWNLOADER" "No update needed: current version $current is up to date." "INFO"
    echo "up_to_date"
    return 0
  fi
}

download_server(){
  local downloader=""
  downloader=$(find_downloader)
  local latest=""
  latest="$(get_latest_version)"

  local temp_data_folder="/app/temp-downloader-data"
  mkdir -p "$temp_data_folder"

  send_log "DOWNLOADER" "Downloading Hytale server version $latest..." "INFO"
  "$downloader" -download-path "$temp_data_folder"

  send_log "DOWNLOADER" "Extracting Hytale server version $latest to $SERVER_PATH..." "INFO"
  unzip -o "$temp_data_folder/$latest.zip" -d "$SERVER_PATH" >&2

  send_log "DOWNLOADER" "Cleaning up temporary files..." "INFO"
  rm -rf "$temp_data_folder"
  echo "$latest" > "$(get_version_file)"
}

