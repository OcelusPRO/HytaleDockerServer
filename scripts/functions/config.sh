#!/bin/bash


init_json_files() {
  mkdir -p "$(dirname "$PERMS_PATH")"

  if [ ! -f "$PERMS_PATH" ]; then
    cat "/app/defaults/permissions.json" > "$PERMS_PATH"
  fi

  if [ ! -f "$WHITELIST_PATH" ]; then
    cat "/app/defaults/whitelist.json" > "$WHITELIST_PATH"
  fi

  if [ ! -f "$CONFIG_PATH" ]; then
    cat "/app/defaults/config.json" > "$CONFIG_PATH"
  fi
}

configure_whitelist() {
  local target_file="$WHITELIST_PATH"
  local mode="$WHITELIST_MODE"
  local tmp_file="${target_file}.tmp"

  local enabled="${WHITELIST_ENABLED:-null}"

  send_log "CONFIG" "Configuring Whitelist..." "INFO"

  local new_entries="[]"
  if [ -n "$WHITELIST_LIST" ]; then
    new_entries=$(echo "$WHITELIST_LIST" | jq -R 'split(",") | map(gsub(" "; "")) | map(select(length > 0))')
  fi

  jq --argjson en "$enabled" \
    --argjson new "$new_entries" \
    --arg mode "$mode" \
    '
      (if $en != null then .enabled = $en else . end) |
      (if ($new | length) > 0 then
          if $mode == "override" then
            .list = $new
          else
            .list = (.list + $new | unique)
          end
      else . end)
    ' "$target_file" > "$tmp_file" && mv "$tmp_file" "$target_file"
}

configure_ops() {
  local target_file="$PERMS_PATH"
  local mode="$OPS_MODE"
  local tmp_file="${target_file}.tmp"
  if [ -z "$OPS_LIST" ] && [ "$mode" != "override" ]; then
    return 0
  fi

  send_log "CONFIG" "Configuring OPs (Mode: $mode)..." "INFO"

  local new_ops="[]"
  if [ -n "$OPS_LIST" ]; then
    new_ops=$(echo "$OPS_LIST" | jq -R 'split(",") | map(gsub(" "; "")) | map(select(length > 0))')
  fi
  jq --argjson new "$new_ops" --arg mode "$mode" '
      .groups.OP //= ["*"] |
      .users //= {} |

      (if $mode == "override" then
          .users |= map_values(if .groups then .groups -= ["OP"] else . end)
      else . end) |

      reduce $new[] as $uuid (.;
          .users[$uuid].groups = (.users[$uuid].groups // [] + ["OP"] | unique)
      )
  ' "$target_file" > "$tmp_file" && mv "$tmp_file" "$target_file"
}

configure_server_config() {
  local target_file="$CONFIG_PATH"
  local tmp_file="${target_file}.tmp"

  send_log "CONFIG" "Configuring server settings (config.json)..." "INFO"

  jq --arg name "$SERVER_NAME" \
    --arg motd "$SERVER_MOTD" \
    --arg pwd "$SERVER_PASSWORD" \
    --argjson maxp "$MAX_PLAYERS" \
    --argjson view "$MAX_VIEW_RADIUS" \
    '
      .ServerName = $name |
      .MOTD = $motd |
      .Password = $pwd |
      .MaxPlayers = $maxp |
      .MaxViewRadius = $view
    ' "$target_file" > "$tmp_file" && mv "$tmp_file" "$target_file"
}

configure_game_files() {
  init_json_files
  configure_whitelist
  configure_ops
  configure_server_config
  send_log "CONFIG" "Game configuration files applied." "INFO"
}