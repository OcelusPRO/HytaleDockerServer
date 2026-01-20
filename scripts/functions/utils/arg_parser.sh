#!/bin/bash

handle_validation_failure() {
  local var_name="$1"
  local value="$2"
  local expected="$3"
  local default_value="$4"

  if [ -n "$default_value" ]; then
    send_log "CONFIG" "Invalid value '$value' for $var_name. Expected $expected. Fallback to default ($default_value)." "WARN"
    echo "$default_value"
  else
    send_log "CONFIG" "CRITICAL: Invalid value '$value' for $var_name. Expected $expected." "ERROR"
    send_log "CONFIG" "No default value provided. Stopping server initialization to prevent corruption." "ERROR"
    kill -s TERM $$
    exit 1
  fi
}

apply_rules() {
  local value="$1"
  local rules="$2"

  if [ -z "$rules" ]; then
    echo "$value"
    return
  fi

  local OLD_IFS="$IFS"
  IFS=','
  for rule in $rules; do
    local rule_name=""
    rule_name=$(echo "$rule" | xargs)

    case "$rule_name" in
      "lower")
        value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
        ;;
      "upper")
        value=$(echo "$value" | tr '[:lower:]' '[:upper:]')
        ;;
      "trim")
        value=$(echo "$value" | xargs)
        ;;
      *)
        send_log "CONFIG" "Unknown rule '$rule_name'. Ignored." "WARN"
        ;;
    esac
  done
  IFS="$OLD_IFS"

  echo "$value"
}

parse_boolean(){
  local var_name="$1"
  local value="$2"
  local default_value="$3"

  local lower_val
  lower_val=$(echo "$value" | tr '[:upper:]' '[:lower:]')

  if [[ "$lower_val" == "true" || "$lower_val" == "false" ]]; then
    echo "$lower_val"
  else
    handle_validation_failure "$var_name" "$value" "boolean (true/false)" "$default_value"
  fi
}

parse_enum(){
  local var_name="$1"
  local var_type="$2"
  local value="$3"
  local default_value="$4"

  local options_str="${var_type#enum(}"
  options_str="${options_str%)}"

  local clean_val
  clean_val=$(echo "$value" | xargs)

  local match_found=false
  local OLD_IFS="$IFS"
  IFS=','
  for opt in $options_str; do
    local clean_opt
    clean_opt=$(echo "$opt" | xargs)
    if [ "$clean_val" == "$clean_opt" ]; then
      match_found=true
      break
    fi
  done
  IFS="$OLD_IFS"

  if [ "$match_found" = true ]; then
    echo "$clean_val"
  else
    handle_validation_failure "$var_name" "$value" "one of [$options_str]" "$default_value"
  fi
}

parse_format(){
  local var_name="$1"
  local format_str="$2"
  local value="$3"
  local default_value="$4"

  local regex="${format_str#format(}"
  regex="${regex%)}"

  if [[ "$value" =~ $regex ]]; then
    echo "$value"
  else
    handle_validation_failure "$var_name" "$value" "match regex $regex" "$default_value"
  fi
}



get_from_env() {
  local var_name="$1"
  local var_type="$2"
  local default_value="$3"
  local rules="$4"

  local value="${!var_name}"

  if [ -z "$value" ]; then
    if [ -n "$default_value" ]; then
      echo "$default_value"
      return 0
    else
      echo ""
      return 0
    fi
  fi

  if [ -n "$rules" ]; then
    value=$(apply_rules "$value" "$rules")
  fi

  case "$var_type" in
    "string")
      echo "$value"
      ;;
    "boolean")
      parse_boolean "$var_name" "$value" "$default_value"
      ;;
    enum*)
      parse_enum "$var_name" "$var_type" "$value" "$default_value"
      ;;
    format*)
      parse_format "$var_name" "$var_type" "$value" "$default_value"
      ;;
    *)
      send_log "CONFIG" "Unknown type '$var_type' for variable $var_name" "ERROR"
      kill -s TERM $$
      exit 1
      ;;
  esac
}

get_json_val() {
    echo "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"
}