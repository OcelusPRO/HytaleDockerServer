#!/bin/sh
set -eu

# Load scripts
. /app/scripts/vars.sh
. /app/scripts/functions.sh


chown -R "hytale:hytale" "$SERVER_PATH" /app 2>/dev/null || true
echo "[HytaleDockerServer-Boot] Writing test in $SERVER_PATH..."

if ! touch "$SERVER_PATH/.write_test" >/dev/null 2>&1; then
    echo "-----------------------------------------------------------"
    echo "ERROR: Unable to write in $SERVER_PATH"
    echo "Check the permissions of your volume on the host."
    echo "-----------------------------------------------------------"
    exit 1
else
    echo "[HytaleDockerServer-Boot] Successful write to $SERVER_PATH, test cleanup..."
    rm "$SERVER_PATH/.write_test"
fi

echo "[HytaleDockerServer-Boot] Downloading the hytale-downloader from $DOWNLOADER_URL..."
curl --output /app/hytale-downloader.zip "$DOWNLOADER_URL"

echo "[HytaleDockerServer-Boot] Extracting the hytale-downloader..."
unzip /app/hytale-downloader.zip -d /app/hytale-downloader-files

echo "[HytaleDockerServer-Boot] Cleaning up the hytale-downloader zip file..."
rm /app/hytale-downloader.zip

echo "[HytaleDockerServer-Boot] Copying the Linux binary to /app/hytale-downloader and assigning execute permissions..."
cp /app/hytale-downloader-files/hytale-downloader-linux-amd64 /app/hytale-downloader
chmod +x /app/hytale-downloader

echo "[HytaleDockerServer-Boot] Cleaning up temporary files from hytale-downloader..."
rm -rf /app/hytale-downloader-files

downloader="/app/hytale-downloader"

if [ ! -f "$OAUTH_STORAGE" ]; then
    authenticate_hytale
else
    if ! refresh_access_token; then
        echo "[HytaleDockerServer-Auth] Refresh token expired. Reconnection required."
        authenticate_hytale
    fi
fi

if [ -f "$DOWNLOADER_CREDENTIALS" ]; then
  cp "$DOWNLOADER_CREDENTIALS" "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME"
fi


echo "[HytaleDockerServer-Boot] Checking the Hytale server version..."
command="$downloader -print-version"
$command
cp "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME" "$DOWNLOADER_CREDENTIALS"

latest="$($command)"
echo "[HytaleDockerServer-Boot] Latest version of the Hytale server available : $latest"

if [ ! -f "$SERVER_PATH/version.txt" ]; then
  echo "No installed version found. Downloading version $latest"
  download_server "/app/server" "$downloader" "$latest"
else
  echo "Checking the installed version..."
  current="$(cat "$SERVER_PATH/version.txt")"
  if [ "$current" != "$latest" ]; then
    echo "The installed version ($current) is different from the latest version ($latest). Downloading the new version."
    download_server "/app/server" "$downloader" "$latest"
  fi
fi

echo "[HytaleDockerServer-Boot] Creating the game session"
create_game_session

mkdir -p /etc
if [ ! -f "/etc/machine-id" ]; then
  new_id=$(cat /dev/urandom | tr -dc 'a-f0-8' | fold -w 32 | head -n 1)
  echo "$new_id" > /etc/machine-id
fi

chown -R "hytale:hytale" "$SERVER_PATH" /etc/machine-id /app 2>/dev/null || true
cd "$SERVER_PATH/Server" || exit

echo "[HytaleDockerServer-Boot] Hytale server starting"

# shellcheck disable=SC2086
exec gosu hytale \
  java ${JVM_ARGS} \
    -jar HytaleServer.jar \
    ${SERVER_ARGS}
