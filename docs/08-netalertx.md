# Optional network monitoring with NetAlertX

This Bobcat 300 DNS appliance already uses Armbian, Pi-hole, Unbound, Tailscale, and Chrony. If you also want the Bobcat to watch the LAN for new or changed devices, add **NetAlertX**.

> Pi.Alert is now archived. The actively maintained project is **NetAlertX**.

## Why NetAlertX instead of Log2Ram

Do **not** install a second Log2Ram-style service on this Armbian image. Armbian already mounts `/var/log` on compressed RAM-backed storage and periodically saves logs to disk. Adding another independent Log2Ram implementation is redundant and may conflict with Armbian's own `armbian-ramlog` service.

Verify the existing service with:

```bash
systemctl status armbian-ramlog --no-pager
mount | grep '/var/log'
```

Use NetAlertX if you want an additional useful service rather than duplicating log handling.

## What NetAlertX adds

NetAlertX provides LAN device discovery and change monitoring. It can help you see:

- devices currently on the network
- new or unknown devices
- IP/MAC/name changes
- device presence history
- basic network change alerts

This complements Pi-hole rather than replacing it. Pi-hole handles DNS filtering; NetAlertX watches the devices using the network.

## Recommended deployment

The cleanest deployment on the Bobcat is Docker with host networking. NetAlertX's current upstream quick-start uses host networking and the capabilities needed for LAN discovery.

### 1. Confirm architecture and resources

```bash
uname -m
free -h
df -h /
```

The tested Bobcat G285 is ARM64 (`aarch64`) with about 2 GB RAM.

### 2. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
sudo docker version
```

Optional: allow the current user to run Docker without `sudo`:

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
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  --cap-add=NET_BIND_SERVICE \
  -v /opt/netalertx:/data \
  -v /etc/localtime:/etc/localtime:ro \
  --tmpfs /tmp:uid=20211,gid=20211,mode=1700 \
  -e PORT=20211 \
  -e APP_CONF_OVERRIDE='{"GRAPHQL_PORT":"20214"}' \
  ghcr.io/netalertx/netalertx:latest
```

### 5. Verify the container

```bash
sudo docker ps --filter name=netalertx
sudo docker logs --tail 100 netalertx
ss -lntup | grep 20211
```

Open the web UI from a LAN computer:

```text
http://BOBCAT_LAN_IP:20211
```

For the reference build:

```text
http://BOBCAT_LAN_IP:20211
```

Do not expose this port directly to the public Internet.

## Access through Tailscale

Because the Bobcat already runs Tailscale, the NetAlertX interface can also be reached through the Bobcat's Tailscale IP:

```text
http://BOBCAT_TAILSCALE_IP:20211
```

Reference example:

```text
http://TAILSCALE_IP:20211
```

This is preferable to port-forwarding the NetAlertX UI from the router.

## Update NetAlertX

```bash
sudo docker pull ghcr.io/netalertx/netalertx:latest
sudo docker rm -f netalertx
```

Then rerun the same `docker run` command from the installation section. The persistent configuration and database stay under `/opt/netalertx`.

## Backup

Include `/opt/netalertx` in backups:

```bash
sudo tar -C /opt -czf ~/netalertx-backup-$(date +%F).tar.gz netalertx
```

## Remove NetAlertX

Remove only the container:

```bash
sudo docker rm -f netalertx
```

Keep `/opt/netalertx` if you may reinstall later. To remove all NetAlertX data as well:

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
