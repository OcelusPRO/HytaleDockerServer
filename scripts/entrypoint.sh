#!/bin/bash
set -eu

. /app/scripts/functions.sh
load_args_into_env "$@"

. /app/scripts/vars.sh

test_perm "$SERVER_PATH"
test_perm "/app"

cd /app || exit


send_log "ENTRYPOINT" "Checking hytale auth status" "INFO"
check_auth


send_log "ENTRYPOINT" "Checking the Hytale server version..." "INFO"
status=$( check_for_update )
if [ "$status" = "update_available" ]; then
  send_log "ENTRYPOINT" "Update available. Downloading the latest version." "INFO"
  download_server
fi

send_log "ENTRYPOINT" "Checking machine-id" "INFO"
machine_id_content=$(cat /etc/machine-id)
placeholder_value="PLACEHOLDER"
if [ "$machine_id_content" = "$placeholder_value" ]; then
  send_log "ENTRYPOINT" "Machine-id is a placeholder. Generating a new one." "INFO"
  change_machine_id
fi


send_log "ENTRYPOINT" "Creating the game session" "INFO"
create_game_session

send_log "ENTRYPOINT" "Applying server configurations..." "INFO"
configure_game_files

cd "$SERVER_PATH/Server" || exit

rm COMMAND_PIPE 2>/dev/null || true
mkfifo COMMAND_PIPE
exec 3<>COMMAND_PIPE

rm OUTPUT_PIPE 2>/dev/null || true
mkfifo OUTPUT_PIPE
exec 4<>OUTPUT_PIPE
mkdir -p /app/logs
touch /app/logs/full_session.log
echo "" > /app/logs/full_session.log
cat < OUTPUT_PIPE | tee -a /app/logs/full_session.log &


start_auto_updater &
UPDATER_PID=$!


send_log "ENTRYPOINT" "Hytale server starting" "INFO"

# shellcheck disable=SC2086
java ${JVM_ARGS} \
    -jar HytaleServer.jar \
    ${SERVER_ARGS} < COMMAND_PIPE > OUTPUT_PIPE &
SERVER_PID=$!

trap 'echo "stop" > COMMAND_PIPE' TERM INT


while kill -0 "$SERVER_PID" 2>/dev/null; do
  if read -r -t 1 line; then
    find_command "$line"
  fi
done

echo "" >&2
send_log "ENTRYPOINT" "Hytale server stopped."
kill "$UPDATER_PID" 2>/dev/null || true

rm COMMAND_PIPE 2>/dev/null || true
rm OUTPUT_PIPE 2>/dev/null || true

exec 3>&-
exec 4>&-

kill $$ 2>/dev/null
exit 0