#!/bin/bash

COMMAND_PIPE="${COMMAND_PIPE:-COMMAND_PIPE}"
send_server_command() {
  if [[ -p "$COMMAND_PIPE" ]]; then
    echo "$@" > "$COMMAND_PIPE"
  else
    send_log "COMMANDS" "Error: Command pipe not found at $COMMAND_PIPE" "ERROR"
  fi
}

execute_command() {
  local command_name="$1"
  shift
  if declare -F execute > /dev/null; then
    send_log "COMMANDS" "Executing command '$command_name' with arguments: $*" "INFO"
    execute "$@"
  else
    send_log "COMMANDS" "Command '$command_name' does not have an execute function." "ERROR"
  fi
}

find_command() {
  local command_name="$1"
  local BASE_COMMANDS_PATH="/app/scripts/functions/commands"
  local internal_command_path="$BASE_COMMANDS_PATH/internal/$command_name.sh"
  local custom_command_path="$BASE_COMMANDS_PATH/custom/$command_name.sh"
  (
    if [[ -f "$custom_command_path" ]]; then
      # shellcheck disable=SC1090
      source "$custom_command_path"
      execute_command "$command_name" "${@:2}"
    elif [[ -f "$internal_command_path" ]]; then
      # shellcheck disable=SC1090
      source "$internal_command_path"
      execute_command "$command_name" "${@:2}"
    else
      send_server_command "$@"
    fi
  )
}