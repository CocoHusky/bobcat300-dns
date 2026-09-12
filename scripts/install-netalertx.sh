#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${NETALERTX_DATA_DIR:-/opt/netalertx}"
PORT="${NETALERTX_PORT:-20211}"
GRAPHQL_PORT="${NETALERTX_GRAPHQL_PORT:-20214}"
IMAGE="ghcr.io/netalertx/netalertx:latest"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script with sudo/root." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Installing Docker using the official convenience script..."
  curl -fsSL https://get.docker.com | sh
fi

systemctl enable --now docker

mkdir -p "${DATA_DIR}/config" "${DATA_DIR}/db"

if docker ps -a --format '{{.Names}}' | grep -qx netalertx; then
  echo "Removing existing NetAlertX container; persistent data will be kept in ${DATA_DIR}."
  docker rm -f netalertx
fi

docker pull "${IMAGE}"

docker run -d \
  --name netalertx \
  --network=host \
  --restart unless-stopped \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  --cap-add=NET_BIND_SERVICE \
  -v "${DATA_DIR}:/data" \
  -v /etc/localtime:/etc/localtime:ro \
  --tmpfs /tmp:uid=20211,gid=20211,mode=1700 \
  -e PORT="${PORT}" \
  -e APP_CONF_OVERRIDE="{\"GRAPHQL_PORT\":\"${GRAPHQL_PORT}\"}" \
  "${IMAGE}"

echo
echo "NetAlertX started."
echo "LAN UI:       http://<BOBCAT_LAN_IP>:${PORT}"
echo "Tailscale UI: http://<BOBCAT_TAILSCALE_IP>:${PORT}"
echo
echo "Verify with:"
echo "  docker ps --filter name=netalertx"
echo "  docker logs --tail 100 netalertx"
echo "  ss -lntup | grep ${PORT}"
