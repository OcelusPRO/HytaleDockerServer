#!/bin/bash


authenticate_hytale() {
    send_log "AUTH" "Device Flow authentication initialization..." "INFO"
    auth_req=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/device/auth" -d "client_id=hytale-server" -d "scope=openid offline auth:server")

    device_code=$(get_json_val "$auth_req" "device_code")
    url=$(get_json_val "$auth_req" "verification_uri_complete")
    poll_interval=$(get_json_val "$auth_req" "interval")
    poll_interval="${poll_interval:-5}"

    send_log "AUTH" "----------------------------------------------------------------------"  "WARN"
    send_log "AUTH" " ACTION REQUIRED: Please authorize this Hytale server "                  "WARN"
    send_log "AUTH" " URL  : $url"                                                            "WARN"
    send_log "AUTH" "----------------------------------------------------------------------"  "WARN"

    send_log "AUTH" "Pending authorization..." "INFO"
    while true; do
        token_req=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
          -d "client_id=hytale-server" \
          -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
          -d "device_code=$device_code")

        access_token=$(get_json_val "$token_req" "access_token")

        if [ -n "$access_token" ]; then
            echo "$token_req" > "$OAUTH_STORAGE"
            send_log "AUTH" "Authorization successful !" "INFO"
            break
        fi

        sleep $poll_interval
    done

    profile_req=$(curl -X GET "https://account-data.hytale.com/my-account/get-profiles" -H "Authorization: Bearer $access_token")
    profile_uuid=$(get_json_val "$profile_req" "uuid")
}

refresh_access_token() {
    send_log "AUTH" "Refreshing the access token..." "INFO"
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

    send_log "AUTH" "Generating a new game session..." "INFO"
    session_req=$(curl -s -X POST "https://sessions.hytale.com/game-session/new" \
      -H "Authorization: Bearer $access_token" \
      -H "Content-Type: application/json" \
      -d "{\"uuid\": \"$selected_uuid\"}")

    session_token=$(get_json_val "$session_req" "sessionToken")
    identity_token=$(get_json_val "$session_req" "identityToken")

    # check if tokens are empty
    if [ -z "$session_token" ] || [ -z "$identity_token" ]; then
        send_log "AUTH" "Game session creation failed.." "ERROR"
        send_log "AUTH" "$session_req" "ERROR"
        exit 1
    fi

    send_log "AUTH" "Session successfully created :" "INFO"

    export HYTALE_SERVER_SESSION_TOKEN="${HYTALE_SERVER_SESSION_TOKEN:-$session_token}"
    export HYTALE_SERVER_IDENTITY_TOKEN="${HYTALE_SERVER_IDENTITY_TOKEN:-$identity_token}"
    export OWNER_UUID="$selected_uuid"
}

check_auth(){
  if [ ! -f "$OAUTH_STORAGE" ]; then
      authenticate_hytale
  else
      if ! refresh_access_token; then
          send_log "AUTH" "Refresh token expired. Reconnection required." "ERROR"
          authenticate_hytale
      fi
  fi
}