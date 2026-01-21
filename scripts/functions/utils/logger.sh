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

  local C_BOLD='\033[1m'
  local C_NOBOLD='\033[22m'

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
    "${C_BOLD}[HytaleDockerServer]${C_NOBOLD} ${C_YELLOW}[%-19s${level_color}${C_BOLD}%10s${C_NOBOLD}${C_YELLOW}]%15s${C_RESET} ${level_color}%s${C_RESET}" \
      "$timestamp" \
      "$log_level" \
      "[$type]" \
      "$message"

  echo -e "$formated" >&2
}