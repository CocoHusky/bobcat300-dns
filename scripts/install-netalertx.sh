#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${NETALERTX_DATA_DIR:-/opt/netalertx}"
PORT="${NETALERTX_PORT:-20211}"
GRAPHQL_PORT="${NETALERTX_GRAPHQL_PORT:-20214}"
LAN_IFACE="${NETALERTX_INTERFACE:-$(ip -4 route show default 2>/dev/null | awk 'NR == 1 {print $5}')}"
SCAN_SUBNET="${NETALERTX_SCAN_SUBNET:-}"
IMAGE="ghcr.io/netalertx/netalertx:latest"
SYSCTL_FILE="/etc/sysctl.d/99-netalertx.conf"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script with sudo/root." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Installing Docker using the official convenience script..."
  if ! command -v curl >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl
  fi
  curl -fsSL https://get.docker.com | sh
fi

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl
fi

systemctl enable --now docker

if [[ -z "${LAN_IFACE}" || "${LAN_IFACE}" == "tailscale0" ]]; then
  echo "Could not identify a physical default-route interface. Set NETALERTX_INTERFACE." >&2
  exit 1
fi

if [[ -z "${SCAN_SUBNET}" ]]; then
  SCAN_SUBNET="$(ip -4 route show dev "${LAN_IFACE}" proto kernel scope link 2>/dev/null | awk 'NR == 1 {print $1}')"
fi

if [[ -z "${SCAN_SUBNET}" || "${SCAN_SUBNET}" == "default" ]]; then
  echo "Could not identify the LAN subnet on ${LAN_IFACE}. Set NETALERTX_SCAN_SUBNET, for example 192.168.1.0/24." >&2
  exit 1
fi

APP_CONF_OVERRIDE="{\"GRAPHQL_PORT\":\"${GRAPHQL_PORT}\",\"SCAN_SUBNETS\":\"['${SCAN_SUBNET} --interface=${LAN_IFACE}']\"}"

mkdir -p "${DATA_DIR}/config" "${DATA_DIR}/db"

cat > "${SYSCTL_FILE}" <<'EOF'
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.arp_announce=2
EOF
sysctl -w net.ipv4.conf.all.arp_ignore=1 >/dev/null
sysctl -w net.ipv4.conf.all.arp_announce=2 >/dev/null

# Pull before taking down an existing container so a registry or network
# failure does not unnecessarily interrupt a working installation.
docker pull "${IMAGE}"

if docker ps -a --format '{{.Names}}' | grep -qx netalertx; then
  echo "Removing existing NetAlertX container; persistent data will be kept in ${DATA_DIR}."
  docker rm -f netalertx
fi

docker run -d \
  --name netalertx \
  --network=host \
  --restart unless-stopped \
  --read-only \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  --cap-add=SETGID \
  --cap-add=SETUID \
  --cap-add=NET_ADMIN \
  --cap-add=NET_BIND_SERVICE \
  --cap-add=NET_RAW \
  --pids-limit=512 \
  --log-opt=max-size=10m \
  --log-opt=max-file=3 \
  -v "${DATA_DIR}:/data" \
  -v /etc/localtime:/etc/localtime:ro \
  --tmpfs /tmp:uid=20211,gid=20211,mode=1700,rw,noexec,nosuid,nodev \
  -e PORT="${PORT}" \
  -e PUID=20211 \
  -e PGID=20211 \
  -e LISTEN_ADDR=0.0.0.0 \
  -e APP_CONF_OVERRIDE="${APP_CONF_OVERRIDE}" \
  "${IMAGE}"

echo "Waiting for NetAlertX to become ready..."
ready=0
for _ in $(seq 1 60); do
  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' netalertx 2>/dev/null || true)"
  if [[ "${health}" == "healthy" ]]; then ready=1; break; fi
  if [[ "${health}" == "unhealthy" ]]; then
    docker logs --tail 100 netalertx >&2
    echo "NetAlertX reported an unhealthy state." >&2
    exit 1
  fi
  status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 2 "http://127.0.0.1:${PORT}/" 2>/dev/null || true)"
  if [[ "${status}" =~ ^[23][0-9][0-9]$ ]]; then ready=1; break; fi
  sleep 1
done

if [[ "${ready}" -ne 1 ]] || ! docker ps --filter name=netalertx --filter status=running --format '{{.Names}}' | grep -qx netalertx; then
  docker logs --tail 100 netalertx >&2
  echo "NetAlertX did not remain running." >&2
  exit 1
fi

echo
echo "NetAlertX started."
echo "Scan subnet: ${SCAN_SUBNET} via ${LAN_IFACE}"
echo "LAN UI:       http://<BOBCAT_LAN_IP>:${PORT}"
echo "Tailscale UI: http://<BOBCAT_TAILSCALE_IP>:${PORT}"
echo
echo "Verify with:"
echo "  docker ps --filter name=netalertx"
echo "  docker logs --tail 100 netalertx"
echo "  curl -I --max-time 5 http://127.0.0.1:${PORT}/"
echo "  ss -lntup | grep ${PORT}"
echo "  sysctl net.ipv4.conf.all.arp_ignore net.ipv4.conf.all.arp_announce"
