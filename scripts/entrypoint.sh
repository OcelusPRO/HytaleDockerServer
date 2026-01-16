#!/bin/sh
set -eu

# Load scripts
. /app/scripts/vars.sh
. /app/scripts/functions.sh


chown -R "hytale:hytale" "$SERVER_PATH" /app 2>/dev/null || true
echo "[HytaleDockerServer-Boot] Test d'écriture dans $SERVER_PATH..."

if ! touch "$SERVER_PATH/.write_test" >/dev/null 2>&1; then
    echo "-----------------------------------------------------------"
    echo "ERREUR : Impossible d'écrire dans $SERVER_PATH"
    echo "Vérifiez les permissions de votre volume sur l'hôte."
    echo "-----------------------------------------------------------"
    exit 1
else
    echo "[HytaleDockerServer-Boot] Écriture réussie dans $SERVER_PATH, nettoyage du test..."
    rm "$SERVER_PATH/.write_test"
fi

echo "[HytaleDockerServer-Boot] Téléchargement du hytale-downloader depuis $DOWNLOADER_URL..."
curl --output /app/hytale-downloader.zip "$DOWNLOADER_URL"

echo "[HytaleDockerServer-Boot] Extraction du hytale-downloader..."
unzip /app/hytale-downloader.zip -d /app/hytale-downloader-files

echo "[HytaleDockerServer-Boot] Nettoyage du fichier zip du hytale-downloader..."
rm /app/hytale-downloader.zip

echo "[HytaleDockerServer-Boot] copie du binaire linux vers /app/hytale-downloader et attribution des droits d'exécution..."
cp /app/hytale-downloader-files/hytale-downloader-linux-amd64 /app/hytale-downloader
chmod +x /app/hytale-downloader

echo "[HytaleDockerServer-Boot] Nettoyage des fichiers temporaires du hytale-downloader..."
rm -rf /app/hytale-downloader-files

downloader="/app/hytale-downloader"

if [ ! -f "$OAUTH_STORAGE" ]; then
    authenticate_hytale
else
    if ! refresh_access_token; then
        echo "[HytaleDockerServer-Auth] Refresh token expiré. Re-connexion nécessaire."
        authenticate_hytale
    fi
fi

if [ -f "$DOWNLOADER_CREDENTIALS" ]; then
  cp "$DOWNLOADER_CREDENTIALS" "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME"
fi


echo "[HytaleDockerServer-Boot] Vérification de la version du serveur Hytale..."
command="$downloader -print-version"
$command
cp "/app/$DOWNLOAD_CREDENTIALS_FILE_NAME" "$DOWNLOADER_CREDENTIALS"

latest="$($command)"
echo "[HytaleDockerServer-Boot] Dernière version disponible du serveur Hytale : $latest"

if [ ! -f "$SERVER_PATH/version.txt" ]; then
  echo "Aucune version installé trouvée. Téléchargement de la version $latest"
  download_server "/app/server" "$downloader" "$latest"
else
  echo "Vérification de la version installée..."
  current="$(cat "$SERVER_PATH/version.txt")"
  if [ "$current" != "$latest" ]; then
    echo "Version installée ($current) différente de la dernière version ($latest). Téléchargement de la nouvelle version."
    download_server "/app/server" "$downloader" "$latest"
  fi
fi

echo "[HytaleDockerServer-Boot] Création de la session de jeu"
create_game_session

mkdir -p /etc
if [ ! -f "/etc/machine-id" ]; then
  new_id=$(cat /dev/urandom | tr -dc 'a-f0-8' | fold -w 32 | head -n 1)
  echo "$new_id" > /etc/machine-id
fi

chown -R "hytale:hytale" "$SERVER_PATH" /etc/machine-id /app 2>/dev/null || true
cd "$SERVER_PATH/Server" || exit

echo "[HytaleDockerServer-Boot] Démarrage du serveur Hytale"

# shellcheck disable=SC2086
exec gosu hytale \
  java ${JVM_ARGS} \
    -jar HytaleServer.jar \
    ${SERVER_ARGS}
