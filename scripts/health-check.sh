#!/usr/bin/env bash
set -u

section() {
  printf '\n=== %s ===\n' "$1"
}

section "HOST"
hostname
uname -a
ip -br addr

section "TIME"
date
if command -v chronyc >/dev/null 2>&1; then
  chronyc tracking || true
else
  echo "chronyc not installed"
fi

section "PI-HOLE"
if command -v pihole >/dev/null 2>&1; then
  pihole status || true
else
  echo "pihole command not found"
fi

section "UNBOUND"
systemctl is-active unbound 2>/dev/null || true
if command -v dig >/dev/null 2>&1; then
  echo "Direct Unbound lookup:"
  dig @127.0.0.1 -p 5335 google.com +short || true
  echo "DNSSEC flags:"
  dig @127.0.0.1 -p 5335 dnssec.works +dnssec 2>/dev/null | grep 'flags:' || true
fi

section "LAN DNS"
LAN_IFACE="${LAN_INTERFACE:-$(ip -4 route show default 2>/dev/null | awk 'NR == 1 {print $5}')}"
LAN_IP="${LAN_IP:-}"
if [ -z "$LAN_IP" ] && [ -n "$LAN_IFACE" ]; then
  LAN_IP="$(ip -4 -o addr show dev "$LAN_IFACE" scope global | awk 'NR == 1 {split($4,a,"/"); print a[1]}')"
fi

echo "LAN interface: ${LAN_IFACE:-none}"
echo "Detected LAN IP: ${LAN_IP:-none}"
if [ -n "${LAN_IP:-}" ] && command -v dig >/dev/null 2>&1; then
  echo "Normal lookup:"
  dig @"$LAN_IP" google.com +short || true
  echo "Blocking lookup:"
  dig @"$LAN_IP" doubleclick.net +short || true
fi

section "TAILSCALE"
if command -v tailscale >/dev/null 2>&1; then
  systemctl is-active tailscaled 2>/dev/null || true
  tailscale status | head -15 || true
  TS_IP="$(tailscale ip -4 2>/dev/null | head -1 || true)"
  echo "Tailscale IPv4: ${TS_IP:-none}"
  tailscale debug prefs 2>/dev/null | grep -E 'CorpDNS|AcceptDNS' || true
  if [ -n "${TS_IP:-}" ] && command -v dig >/dev/null 2>&1; then
    echo "DNS over Tailscale:"
    dig @"$TS_IP" google.com +short || true
  fi
else
  echo "tailscale command not found"
fi

section "HOST RESOLVER"
cat /etc/resolv.conf 2>/dev/null || true
getent hosts debian.org 2>/dev/null || echo "Host resolver lookup failed"

section "LISTENING PORTS"
ss -lntup 2>/dev/null | grep -E '(:53 |:5335 )' || true
ss -lntup 2>/dev/null | grep -E '(:20211 |:20214 )' || true

section "DOCKER"
systemctl is-active docker 2>/dev/null || true

section "NETALERTX"
if command -v docker >/dev/null 2>&1; then
  docker ps --filter name=netalertx || true
  docker inspect --format 'Health: {{if .State.Health}}{{.State.Health.Status}}{{else}}not reported{{end}}' netalertx 2>/dev/null || true
  curl -I --max-time 5 http://127.0.0.1:20211/ 2>/dev/null || true
else
  echo "docker command not found"
fi

section "ARP SETTINGS"
sysctl net.ipv4.conf.all.arp_ignore 2>/dev/null || true
sysctl net.ipv4.conf.all.arp_announce 2>/dev/null || true

section "RESOURCES"
df -h /
free -h

section "SERVICE SUMMARY"
for svc in pihole-FTL unbound chrony tailscaled; do
  printf '%-12s ' "$svc"
  systemctl is-active "$svc" 2>/dev/null || true
done
