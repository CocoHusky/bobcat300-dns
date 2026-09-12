# 4. Install NetAlertX

With Armbian, Pi-hole, Unbound, and Tailscale working, install **NetAlertX** to watch the LAN for new or changed devices.

> Pi.Alert is archived. The actively maintained continuation is **NetAlertX**.

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

Supported Bobcat Miner 300 revisions are expected to be ARM64 (`aarch64`). Available memory varies by board and image; confirm it with `free -h` before enabling additional services.

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

Set the scan subnet to the LAN attached to the default route. Use your actual LAN subnet and interface values:

```bash
ip -4 route show default
ip -4 route show dev LAN_INTERFACE proto kernel scope link
```

The installer derives this automatically. To override it, pass `NETALERTX_SCAN_SUBNET` and optionally `NETALERTX_INTERFACE` when running the installer. NetAlertX must receive `SCAN_SUBNETS` through `APP_CONF_OVERRIDE`; do not leave it unset on a host-network deployment.

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
  -e APP_CONF_OVERRIDE='{"GRAPHQL_PORT":"20214","SCAN_SUBNETS":"['"'"'LAN_SUBNET --interface=LAN_INTERFACE'"'"']"}' \
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

## Keep notifications useful

Start with only new-device notifications. Add down/reconnect notifications only for devices you explicitly consider critical. Broad routine event notifications can become noisy and make important changes easy to miss.

## Update NetAlertX

```bash
sudo env NETALERTX_SCAN_SUBNET=LAN_SUBNET NETALERTX_INTERFACE=LAN_INTERFACE bash scripts/install-netalertx.sh
```

The installer pulls the image before stopping the current container. Persistent configuration and database data stay under `/opt/netalertx`. Replace the example subnet/interface with your own values.

## Backup

```bash
sudo env INCLUDE_SENSITIVE_BACKUPS=1 bash scripts/backup-config.sh "$HOME/netalertx-backup"
```

The backup helper stops NetAlertX briefly to create a consistent archive, then restarts it if it was running. Treat backups as private because NetAlertX data can contain discovered device names, IP addresses, MAC addresses, and network history.

## API warnings that are not necessarily a broken install

Some NetAlertX releases may log an unauthorized request from the in-app unread-message polling endpoint even while the authenticated API and GraphQL services work. Before rotating credentials or resetting the installation, verify the actual services:

```bash
curl -I --max-time 5 http://127.0.0.1:20211/
curl -I --max-time 5 http://127.0.0.1:20214/docs
sudo docker logs --tail 100 netalertx
```

Use the UI's authenticated API/GraphQL checks when available. Treat the warning as an authentication problem only if authenticated requests also fail or the GraphQL service is unavailable.

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
