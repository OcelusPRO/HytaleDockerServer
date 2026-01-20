#!/bin/bash

. /app/scripts/functions/utils/logger.sh
. /app/scripts/functions/utils/arg_parser.sh

load_args_into_env() {
  for arg in "$@"; do
    case "$arg" in
      --*=*)
        local key="${arg%%=*}"
        key="${key#--}"

        local value="${arg#*=}"
        if [ -n "${!key}" ] && [ "${!key}" != "$value" ]; then
          send_log "CONFIG" "Overriding env var '$key' with argument value." "INFO"
        fi
          export "$key"="$value"
        ;;
    esac
  done
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