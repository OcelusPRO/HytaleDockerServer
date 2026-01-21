#!/bin/bash

match_cron_field() {
  local current=$((10#$1))
  local pattern="$2"

  local parts="${pattern//,/ }"

  for part in $parts; do
    local step=1
    local range_expr="$part"

    if [[ "$part" == */* ]]; then
      range_expr="${part%/*}"
      step="${part#*/}"
    fi

    if [ "$range_expr" == "*" ]; then
      if (( current % step == 0 )); then
        return 0
      fi

    elif [[ "$range_expr" == *-* ]]; then
      local start="${range_expr%-*}"
      local end="${range_expr#*-}"

      start=$((10#$start))
      end=$((10#$end))

      if (( current >= start && current <= end )); then
        if (( (current - start) % step == 0 )); then
          return 0
        fi
      fi

    else
      local start=$((10#$range_expr))

      if [ "$step" -eq 1 ]; then
        if [ "$current" -eq "$start" ]; then
          return 0
        fi
      else
        if (( current >= start )); then
          if (( (current - start) % step == 0 )); then
            return 0
          fi
        fi
      fi
    fi
  done

  # No pattern matched
  return 1
}

is_cron_due() {
  local cron_expr="$1"
  read -r cur_min cur_hour cur_dom cur_mon cur_dow <<< "$(date +'%M %H %d %m %w')"
  read -r pat_min pat_hour pat_dom pat_mon pat_dow <<< "$cron_expr"
  match_cron_field "$cur_min"  "$pat_min"  || return 1
  match_cron_field "$cur_hour" "$pat_hour" || return 1
  match_cron_field "$cur_dom"  "$pat_dom"  || return 1
  match_cron_field "$cur_mon"  "$pat_mon"  || return 1
  match_cron_field "$cur_dow"  "$pat_dow"  || return 1

  return 0
}

start_auto_updater() {
  if [ "$ENABLE_AUTO_UPDATE" != "true" ]; then
    send_log "AUTO-UPDATER" "Auto-updates are disabled." "WARN"
    return
  fi

  send_log "AUTO-UPDATER" "Scheduler started with cron: '$AUTO_UPDATE_CRON'" "INFO"

  while true; do
    local current_sec=""
    current_sec=$(date +%S)
    local sleep_time=$((60 - 10#$current_sec + 2))
    sleep "$sleep_time"

    if is_cron_due "$AUTO_UPDATE_CRON"; then
      send_log "AUTO-UPDATER" "Cron match ($AUTO_UPDATE_CRON). Checking for updates..." "INFO"

      local current=""
      local latest=""

      current="$(get_installed_version)"
      latest="$(get_latest_version)"

      if [ "$current" != "$latest" ] && [ -n "$latest" ]; then
        send_log "AUTO-UPDATER" "New version detected: $latest (current: $current)." "WARN"
        send_log "AUTO-UPDATER" "Triggering update alert sequence." "WARN"
        find_command "auto_update_alert"
      else
        send_log "AUTO-UPDATER" "System is up to date ($current)." "INFO"
      fi
    fi
  done
}
