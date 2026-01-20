#!/bin/bash

send_log(){
  local type="$1"
  local message="$2"
  local log_level="${3:-INFO}"

  # Définition des couleurs ANSI
  local C_RESET='\033[0m'
  local C_YELLOW='\033[0;33m'
  local C_CYAN='\033[0;36m'
  local C_RED='\033[0;31m'

  local level_color=""
  case "$log_level" in
      "INFO")  level_color="$C_CYAN" ;;
      "WARN")  level_color="$C_YELLOW" ;;
      "ERROR") level_color="$C_RED" ;;
      *)       level_color="$C_RESET" ;;
  esac

  local timestamp=""
  timestamp=$(date "+%Y/%m/%d %H:%M:%S")
  printf -v formated \
    "[HytaleDockerServer] ${C_YELLOW}[%-19s${level_color}%10s${C_YELLOW}]%15s${C_RESET} ${level_color}%s${C_RESET}" \
      "$timestamp" \
      "$log_level" \
      "[$type]" \
      "$message"

  echo -e "$formated" >&2
}

get_json_val() {
    echo "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"
}

change_machine_id() {
  send_log "SYSTEM" "Generate new machine-id" "INFO"
  new_id=$(cat /dev/urandom | tr -dc 'a-f0-8' | fold -w 32 | head -n 1)
  send_log "SYSTEM" "New machine-id: $new_id" "INFO"
  echo "$new_id" > /etc/machine-id
}

test_perm(){
  local path="$1"
  if ! touch "$path/.write_test" >/dev/null 2>&1; then
      send_log "ENTRYPOINT" "-----------------------------------------------------------" "ERROR"
      send_log "ENTRYPOINT" "ERROR: Unable to write in $path"                             "ERROR"
      send_log "ENTRYPOINT" "Check the permissions of your volume on the host."           "ERROR"
      send_log "ENTRYPOINT" "-----------------------------------------------------------" "ERROR"
      exit 1
  else
      rm "$path/.write_test"
  fi
}