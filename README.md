# Bobcat 300 DNS Appliance

Repurpose a decommissioned Bobcat Miner 300 (G285 / RK3566) into a small always-on network appliance running:

- Armbian Linux
- Pi-hole for network-wide DNS filtering
- Unbound as a local recursive DNS resolver
- Tailscale for secure remote access and remote DNS filtering
- Chrony for reliable time synchronization
- Optional NetAlertX for LAN device discovery and change monitoring

This guide provides a repeatable conversion path. Replace every placeholder with a value from your own network.

> Implemented and tested on: Bobcat 285 / G285, Rockchip RK3566, ARM64, approximately 2 GB RAM, with a Debian Bookworm-based Armbian image.

## What the finished system does

```text
LAN clients
   |
   v
Bobcat 300
BOBCAT_LAN_IP
   |
   +--> Pi-hole :53
   |      |
   |      v
   |   Unbound 127.0.0.1:5335
   |      |
   |      v
   |   authoritative DNS hierarchy
   |
   +--> Tailscale TAILSCALE_IP
   |      |
   |      +--> remote devices can use the same Pi-hole
   |
   +--> optional NetAlertX :20211
          |
          +--> LAN device discovery and change monitoring

Armbian ramlog: /var/log on zram -> /var/log.hdd persistent backing storage
```

The router can continue to provide DHCP. Configure it to hand out the Bobcat as the primary DNS server.

## Installation order

- [`docs/01-armbian-install.md`](docs/01-armbian-install.md) — install and boot Armbian on the Bobcat
- [`docs/02-networking.md`](docs/02-networking.md) — hostname, static IP, Ethernet/Wi-Fi, SSH
- [`docs/03-pihole-unbound.md`](docs/03-pihole-unbound.md) — Pi-hole and recursive DNS setup
- [`docs/04-tailscale.md`](docs/04-tailscale.md) — remote access and remote Pi-hole DNS
- [`docs/05-time-sync.md`](docs/05-time-sync.md) — Chrony, RTC, and avoiding TLS failures after reboot
- [`docs/06-router-and-clients.md`](docs/06-router-and-clients.md) — point the network at the Bobcat
- [`docs/07-validation-maintenance.md`](docs/07-validation-maintenance.md) — health checks, backups, updates, and recovery
- [`docs/08-netalertx.md`](docs/08-netalertx.md) — optional LAN device monitoring with NetAlertX
- [`docs/09-storage-and-ramlog.md`](docs/09-storage-and-ramlog.md) — Armbian RAM-backed logging and storage
- [`scripts/health-check.sh`](scripts/health-check.sh) — quick validation script
- [`scripts/install-netalertx.sh`](scripts/install-netalertx.sh) — optional NetAlertX installer

## Quick start

1. Flash a Bobcat-compatible Armbian image to microSD.
2. Boot the Bobcat from microSD.
3. Configure network access and a static/reserved LAN address.
4. Set a generic hostname such as `dns-appliance`.
5. Install Pi-hole.
6. Install Unbound and listen only on `127.0.0.1:5335`.
7. Configure Pi-hole to use `127.0.0.1#5335` as its only upstream resolver.
8. Configure Pi-hole to listen on interfaces needed by LAN and Tailscale.
9. Install Tailscale and authenticate the node.
10. Set the Bobcat's Tailscale IP as the tailnet DNS server if remote filtering is desired.
11. Configure Chrony so time is corrected quickly after boot.
12. Set the router's LAN DNS server to the Bobcat's static/reserved address.
13. Optionally install NetAlertX for LAN device monitoring.
14. Run the validation commands in `docs/07-validation-maintenance.md` or with `scripts/health-check.sh`.

## Replace these placeholders

```text
BOBCAT_LAN_IP      replace with the Bobcat's LAN address
BOBCAT_LAN_CIDR    replace with the Bobcat's LAN address and prefix
ROUTER_LAN_IP      replace with the router/gateway address
TAILSCALE_IP       replace with `tailscale ip -4` output
DNS_HOSTNAME       replace with the hostname you choose
WIFI_PROFILE       replace with your NetworkManager Wi-Fi profile name
```

Do not commit real credentials, Wi-Fi SSIDs/passwords, MAC addresses, Tailscale state, private hostnames, or personal infrastructure names.

## Important notes

- Keep the Bobcat on a stable static IP or DHCP reservation.
- The router can continue handling DHCP; Pi-hole does not need to become the DHCP server.
- Do not expose TCP/UDP port 53 directly to the public internet.
- Tailscale provides the secure remote path instead.
- If the Bobcat boots with a wildly incorrect date, HTTPS/TLS and Tailscale can fail. The Chrony section addresses this.
- Back up configuration files before changing them.
- Do not install a separate Log2Ram service on this Armbian build; Armbian already provides RAM-backed/compressed logging through `armbian-ramlog`.
- NetAlertX is optional and should be reachable only over trusted LAN/Tailscale paths.

## Optional NetAlertX install

```bash
git clone https://github.com/CocoHusky/bobcat300-dns.git
cd bobcat300-dns
sudo bash scripts/install-netalertx.sh
```

Then open `http://BOBCAT_LAN_IP:20211` or `http://TAILSCALE_IP:20211` after substituting your own values.

## Final validation

```bash
hostname
ip -br addr
pihole status
systemctl is-active unbound
chronyc tracking
tailscale status
tailscale ip -4
ss -lntup | grep -E '(:53 |:5335 )'
```

Test Unbound directly:

```bash
dig @127.0.0.1 -p 5335 dnssec.works +dnssec
```

Test Pi-hole using your Bobcat LAN address:

```bash
dig @BOBCAT_LAN_IP google.com +short
dig @BOBCAT_LAN_IP doubleclick.net +short
```

## Scope

This project covers the supported microSD-based DNS appliance. Hardware expansion experiments and unrelated configurations are outside its scope.
