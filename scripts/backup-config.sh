#!/usr/bin/env bash
set -euo pipefail

DEST="${1:-/root/bobcat-dns-backup}"
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
Tailscale state was NOT copied automatically because it contains node identity/state.
If you want it in a private backup, run:

  cp /var/lib/tailscale/tailscaled.state /root/bobcat-dns-backup/

Never commit that state file to a public repository.
EOF

echo
echo "Backup directory: $DEST"
