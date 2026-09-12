# Optional network monitoring with NetAlertX

If the Bobcat is already running Armbian, Pi-hole, Unbound, Tailscale, and Chrony, you can add **NetAlertX** to watch the LAN for new or changed devices.

> Pi.Alert is archived. The actively maintained continuation is **NetAlertX**.

## Why NetAlertX instead of Log2Ram

Do **not** install a second Log2Ram-style service on this Armbian image. Armbian already mounts `/var/log` on compressed RAM-backed storage and periodically saves logs to disk. Adding another independent Log2Ram implementation is redundant and may conflict with Armbian's own `armbian-ramlog` service.

Verify the existing service with:

```bash
systemctl status armbian-ramlog --no-pager
mount | grep '/var/log'
```

## What NetAlertX adds

NetAlertX provides LAN device discovery and change monitoring. It can help you see:

- devices currently on the network
- new or unknown devices
- IP/MAC/name changes
- device presence history
- basic network change alerts

This complements Pi-hole rather than replacing it.

## Recommended deployment

The cleanest deployment on the Bobcat is Docker with host networking so NetAlertX can perform LAN discovery.

### 1. Confirm architecture and resources

```bash
uname -m
free -h
df -h /
```

The Bobcat G285 is ARM64 (`aarch64`) with about 2 GB RAM.

### 2. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
sudo docker version
```

Optional:

```bash
sudo usermod -aG docker "$USER"
```

Log out and back in before using Docker without `sudo`.

### 3. Create persistent NetAlertX storage

```bash
sudo mkdir -p /opt/netalertx/config
sudo mkdir -p /opt/netalertx/db
```

### 4. Start NetAlertX

```bash
sudo docker run -d \
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
  -v /opt/netalertx:/data \
  -v /etc/localtime:/etc/localtime:ro \
  --tmpfs /tmp:uid=20211,gid=20211,mode=1700,rw,noexec,nosuid,nodev \
  -e PORT=20211 \
  -e PUID=20211 \
  -e PGID=20211 \
  -e LISTEN_ADDR=0.0.0.0 \
  -e GRAPHQL_PORT=20214 \
  ghcr.io/netalertx/netalertx:latest
```

Apply ARP-flux mitigation on the host so LAN IP/MAC association is more reliable with host networking:

```bash
sudo tee /etc/sysctl.d/99-netalertx.conf >/dev/null <<'EOF'
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.arp_announce=2
EOF
sudo sysctl --system
```

### 5. Verify the container

```bash
sudo docker ps --filter name=netalertx
sudo docker logs --tail 100 netalertx
ss -lntup | grep 20211
```

Open the web UI from a trusted LAN computer using:

```text
http://BOBCAT_LAN_IP:20211
```

Do not put your real LAN address into this public repository and do not expose this port directly to the public internet.

## Access through Tailscale

Because the Bobcat already runs Tailscale, the NetAlertX interface can also be reached through:

```text
http://TAILSCALE_IP:20211
```

Get the current address on the Bobcat with:

```bash
tailscale ip -4
```

Do not publish Tailscale peer lists, tailnet names, node IDs, or private device names in screenshots/logs.

## Update NetAlertX

```bash
sudo docker pull ghcr.io/netalertx/netalertx:latest
sudo docker rm -f netalertx
```

Then rerun the installer. Persistent configuration and database data stay under `/opt/netalertx`.

## Backup

```bash
sudo tar -C /opt -czf ~/netalertx-backup-$(date +%F).tar.gz netalertx
```

Treat backups as private because NetAlertX data can contain discovered device names, IP addresses, MAC addresses, and network history.

## Remove NetAlertX

Remove only the container:

```bash
sudo docker rm -f netalertx
```

Keep `/opt/netalertx` if you may reinstall later. To remove all NetAlertX data:

```bash
sudo rm -rf /opt/netalertx
```

## Health check

```bash
echo '=== NETALERTX ==='
sudo docker ps --filter name=netalertx
curl -I --max-time 5 http://127.0.0.1:20211/ || true
```

NetAlertX is optional. The Bobcat's DNS appliance functions normally without it.
