#!/bin/bash

send_log(){
  local type="$1"
  local message="$2"
  local log_level="${3:-INFO}"
  echo "[HytaleDockerServer $type]: $message" >&2
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