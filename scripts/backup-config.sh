#!/usr/bin/env bash
set -euo pipefail

DEST="${1:-/root/bobcat-dns-backup}"
INCLUDE_SENSITIVE="${INCLUDE_SENSITIVE_BACKUPS:-0}"
mkdir -p "$DEST"

copy_if_exists() {
  local src="$1"
  if [ -e "$src" ]; then
    cp -a "$src" "$DEST/"
    echo "Backed up: $src"
  else
    echo "Skipped missing: $src"
  fi
}

copy_if_exists /etc/pihole/pihole.toml
copy_if_exists /etc/unbound/unbound.conf.d/pi-hole.conf
copy_if_exists /etc/chrony/chrony.conf
copy_if_exists /etc/NetworkManager/system-connections

echo
cat <<'EOF'
The files above are PRIVATE machine backups. They may contain local addresses,
Wi-Fi credentials, Pi-hole history, and other installation-specific data.
Do not commit this directory to the public repository.

Tailscale state and NetAlertX data were NOT copied automatically because they
contain node identity and LAN inventory/history.
EOF

if [ "$INCLUDE_SENSITIVE" = "1" ]; then
  copy_if_exists /var/lib/tailscale/tailscaled.state
  if [ -d /opt/netalertx ]; then
    tar -C /opt -czf "$DEST/netalertx-data.tar.gz" netalertx
    echo "Backed up private NetAlertX data: /opt/netalertx"
  fi
  echo "Sensitive backups were included; protect them as private/offline data."
else
  cat <<'EOF'

To include sensitive state in a private backup:

  sudo env INCLUDE_SENSITIVE_BACKUPS=1 bash scripts/backup-config.sh

Never commit Tailscale state or NetAlertX backups to a public repository.
EOF
fi

echo
echo "Backup directory: $DEST"
