#!/bin/bash

mk_cd(){
  path="$1"
  mkdir -p "$path"
  cd "$path" || exit
}
download_server(){
  path="$1" # /app/server
  downloader="$2"
  version="$3"
  mk_cd "$path"
  "$downloader"
  unzip -o "$version.zip" -d "$SERVER_PATH"
  echo "$version" > "$SERVER_PATH/version.txt"
}
get_json_val() {
    echo "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"
}
authenticate_hytale() {
    echo "[HytaleDockerServer-Auth] Device Flow authentication initialization..."
    auth_req=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/device/auth" -d "client_id=hytale-server" -d "scope=openid offline auth:server")

    device_code=$(get_json_val "$auth_req" "device_code")
    url=$(get_json_val "$auth_req" "verification_uri_complete")
    poll_interval=$(get_json_val "$auth_req" "interval")
    poll_interval="${poll_interval:-5}"

    # Étape 2 : Instructions utilisateur
    echo "----------------------------------------------------------------------"
    echo " ACTION REQUIRED: Please authorize this Hytale server "
    echo " URL  : $url"
    echo "----------------------------------------------------------------------"

    # Étape 3 : Polling (Attente de l'autorisation)
    echo "[HytaleDockerServer-Auth] Pending authorization..."
    while true; do
        token_req=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
          -d "client_id=hytale-server" \
          -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
          -d "device_code=$device_code")

        access_token=$(get_json_val "$token_req" "access_token")

        if [ -n "$access_token" ]; then
            echo "$token_req" > "$OAUTH_STORAGE"
            echo "[HytaleDockerServer-Auth] Authorization successful !"
            break
        fi

        sleep $poll_interval
    done

    profile_req=$(curl -X GET "https://account-data.hytale.com/my-account/get-profiles" -H "Authorization: Bearer $access_token")
    profile_uuid=$(get_json_val "$profile_req" "uuid")
}
refresh_access_token() {
    echo "[HytaleDockerServer-Auth] Refreshing the access token..."
    old_refresh_token=$(get_json_val "$(cat "$OAUTH_STORAGE")" "refresh_token")

    refresh_req=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
      -d "client_id=hytale-server" \
      -d "grant_type=refresh_token" \
      -d "refresh_token=$old_refresh_token")

    if echo "$refresh_req" | grep -q "access_token"; then
        echo "$refresh_req" > "$OAUTH_STORAGE"
        return 0
    else
        return 1
    fi
}
create_game_session() {
    access_token=$(get_json_val "$(cat "$OAUTH_STORAGE")" "access_token")
    profile_req=$(curl -s -H "Authorization: Bearer $access_token" "https://account-data.hytale.com/my-account/get-profiles")
    profile_uuid=$(echo "$profile_req" | sed -n 's/.*"uuid":"\([^"]*\)".*/\1/p' | head -n 1)
    selected_uuid="${OWNER_UUID:-$profile_uuid}"

    echo "[HytaleDockerServer-Auth] Generating a new game session..."
    session_req=$(curl -s -X POST "https://sessions.hytale.com/game-session/new" \
      -H "Authorization: Bearer $access_token" \
      -H "Content-Type: application/json" \
      -d "{\"uuid\": \"$selected_uuid\"}")

    session_token=$(get_json_val "$session_req" "sessionToken")
    identity_token=$(get_json_val "$session_req" "identityToken")

    # check if tokens are empty
    if [ -z "$session_token" ] || [ -z "$identity_token" ]; then
        echo "[HytaleDockerServer-Auth] Game session creation failed.."
        echo "$session_req"
        exit 1
    fi

    echo "[HytaleDockerServer-Auth] Session successfully created :"
    export HYTALE_SERVER_SESSION_TOKEN="${HYTALE_SERVER_SESSION_TOKEN:-$session_token}"
    export HYTALE_SERVER_IDENTITY_TOKEN="${HYTALE_SERVER_IDENTITY_TOKEN:-$identity_token}"
    export OWNER_UUID="$selected_uuid"
}
get_latest_version() {
  downloader="$1"

  if [ -f "$DOWNLOADER_CREDENTIALS" ]; then
    cp "$DOWNLOADER_CREDENTIALS" "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME"
    cp "$DOWNLOADER_CREDENTIALS" "./$DOWNLOAD_CREDENTIALS_FILE_NAME"
  fi
  command="$downloader -print-version"
  $command
  cp "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME" "$DOWNLOADER_CREDENTIALS"
  latest="$($command)"

  echo "$latest"
}

start_auto_updater() {
  ENABLE_AUTO_UPDATE_LOWER=$(echo "$ENABLE_AUTO_UPDATE" | tr '[:upper:]' '[:lower:]')
  if [ "$ENABLE_AUTO_UPDATE_LOWER" != "true" ]; then
    echo "[HytaleDockerServer-Updater] Auto-updates are disabled."
    return
  fi

  downloader="$1"
  current="$(cat "$SERVER_PATH/version.txt")"

  while true; do
    sleep 3600
    latest=$( get_latest_version "$downloader" )

    if [ "$current" != "$latest" ]; then
      echo "[HytaleDockerServer-Updater] New version detected: $latest (current: $current)."
      send_stop_signal
      return
    fi
  done
}

send_stop_signal() {
  echo "[HytaleDockerServer-Updater] Sending reboot warning (5 minutes)..."
  command='eventtitle --title="The server will restart in 5 minutes"  --secondary="Warning, Server Update" --major'
  echo "$command" > pipe

  sleep 180
  echo "[HytaleDockerServer-Updater] Sending reboot warning (2 minutes)..."
  command='eventtitle --title="The server will restart in 2 minutes"  --secondary="Warning, Server Update" --major'
  echo "$command" > pipe

  sleep 60
  echo "[HytaleDockerServer-Updater] Sending reboot warning (1 minute)..."
  command='eventtitle --title="The server will restart in 1 minute"  --secondary="Warning, Server Update" --major'
  echo "$command" > pipe


  sleep 30
  echo "[HytaleDockerServer-Updater] Sending reboot warning (30 seconds)..."
  command='eventtitle --title="The server will restart in 30 seconds"  --secondary="Warning, Server Update" --major'
  echo "$command" > pipe

  sleep 20
  echo "[HytaleDockerServer-Updater] Sending reboot warning (10 seconds)..."
  command='eventtitle --title="The server will restart in 10 seconds"  --secondary="Warning, Server Update" --major'
  echo "$command" > pipe

  sleep 10
  echo "[HytaleDockerServer-Updater] Sending stop command to the server..."
  command='eventtitle --title="Server is restarting now!"  --secondary="Warning, Server Update" --major'
  echo "$command" > pipe
  sleep 2
  echo "stop" > pipe
}