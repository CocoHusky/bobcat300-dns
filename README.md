# Bobcat 300 DNS Appliance

Repurpose a decommissioned Bobcat Miner 300 (G285 / RK3566) into a small always-on network appliance running:

- Armbian Linux
- Pi-hole for network-wide DNS filtering
- Unbound as a local recursive DNS resolver
- Tailscale for secure remote access and remote DNS filtering
- Chrony for reliable time synchronization
- Optional NetAlertX for LAN device discovery and change monitoring

This repository documents the conversion that was actually implemented on a Bobcat 285. It focuses on the useful end state and the repeatable setup steps. It intentionally leaves out abandoned experiments and hardware changes that were never used in the final system.

> Tested reference system: Bobcat 285 / G285, RK3566, ~2 GB RAM, Armbian 26.02 rolling, Linux 6.18.4-current-rockchip64.

## What the finished system does

The Bobcat becomes a dedicated DNS appliance on the home network.

```text
LAN clients
   |
   v
Bobcat 300
192.168.0.164
   |
   +--> Pi-hole :53
   |      |
   |      v
   |   Unbound 127.0.0.1:5335
   |      |
   |      v
   |   authoritative DNS hierarchy
   |
   +--> Tailscale 100.x.x.x
   |      |
   |      +--> remote devices can use the same Pi-hole
   |
   +--> optional NetAlertX :20211
          |
          +--> LAN device discovery and change monitoring
```

The router continues to provide DHCP. The router is configured to hand out the Bobcat as the primary DNS server.

## Repository layout

- [`docs/01-armbian-install.md`](docs/01-armbian-install.md) — install and boot Armbian on the Bobcat
- [`docs/02-networking.md`](docs/02-networking.md) — hostname, static IP, Ethernet/Wi-Fi, SSH
- [`docs/03-pihole-unbound.md`](docs/03-pihole-unbound.md) — Pi-hole and recursive DNS setup
- [`docs/04-tailscale.md`](docs/04-tailscale.md) — remote access and remote Pi-hole DNS
- [`docs/05-time-sync.md`](docs/05-time-sync.md) — Chrony, RTC, and avoiding TLS failures after reboot
- [`docs/06-router-and-clients.md`](docs/06-router-and-clients.md) — point the network at the Bobcat
- [`docs/07-validation-maintenance.md`](docs/07-validation-maintenance.md) — health checks, backups, updates, and recovery
- [`docs/08-netalertx.md`](docs/08-netalertx.md) — optional LAN device monitoring with NetAlertX
- [`scripts/health-check.sh`](scripts/health-check.sh) — quick validation script
- [`scripts/install-netalertx.sh`](scripts/install-netalertx.sh) — optional NetAlertX installer

## Quick start

The detailed procedure is in the docs, but the full flow is:

1. Flash a Bobcat-compatible Armbian image to microSD.
2. Boot the Bobcat from microSD.
3. Configure network access and a static LAN address.
4. Set a hostname such as `bobs-dns`.
5. Install Pi-hole.
6. Install Unbound and listen only on `127.0.0.1:5335`.
7. Configure Pi-hole to use `127.0.0.1#5335` as its only upstream resolver.
8. Configure Pi-hole to listen on interfaces needed by LAN and Tailscale.
9. Install Tailscale and authenticate the node.
10. Set the Bobcat's Tailscale IP as the tailnet DNS server if remote filtering is desired.
11. Configure Chrony so time is corrected quickly after boot.
12. Set the router's LAN DNS server to the Bobcat's static LAN IP.
13. Optionally install NetAlertX for LAN device monitoring.
14. Run the validation commands in this repo.

## Reference addresses from the tested build

These are examples only. Replace them with your own network values.

```text
Hostname:          bobs-dns
LAN IP:            192.168.0.164
LAN gateway:       192.168.0.1
Pi-hole DNS:       192.168.0.164:53
Unbound:           127.0.0.1:5335
Tailscale IP:      100.116.249.106
NetAlertX UI:      192.168.0.164:20211   (optional)
```

## Important notes

- Keep the Bobcat on a stable static IP or DHCP reservation.
- The router can continue handling DHCP; Pi-hole does not need to become the DHCP server.
- Do not expose TCP/UDP port 53 directly to the public internet.
- Tailscale provides the secure remote path instead.
- If the Bobcat boots with a wildly incorrect date, HTTPS/TLS and Tailscale can fail. The Chrony section addresses this.
- Back up configuration files before changing them.
- **Do not install a separate Log2Ram service on this Armbian build.** Armbian already uses RAM-backed/compressed logging with `armbian-ramlog`, so a second implementation is unnecessary and may conflict.
- NetAlertX is optional and should not be exposed directly to the public Internet; use LAN or Tailscale access.

## Optional NetAlertX install

For a Bobcat that is already configured with this repo:

```bash
git clone https://github.com/CocoHusky/bobcat300-dns.git
cd bobcat300-dns
sudo bash scripts/install-netalertx.sh
```

Then open:

```text
http://BOBCAT_LAN_IP:20211
```

or, over Tailscale:

```text
http://BOBCAT_TAILSCALE_IP:20211
```

See [`docs/08-netalertx.md`](docs/08-netalertx.md) for the complete setup, update, backup, and removal instructions.

## Final validation

On the Bobcat:

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

If NetAlertX is installed:

```bash
sudo docker ps --filter name=netalertx
ss -lntup | grep 20211
```

Test DNS directly:

```bash
dig @127.0.0.1 -p 5335 dnssec.works +dnssec
dig @192.168.0.164 google.com +short
dig @192.168.0.164 doubleclick.net +short
```

A working system should return a normal IP for `google.com`, while a blocked domain such as `doubleclick.net` should resolve to a blocking response such as `0.0.0.0` depending on Pi-hole settings.

## Scope

This repo is specifically about converting the Bobcat into a useful Linux network appliance. It does not document unused USB experiments, speculative hardware mods, or dead-end debugging that was not part of the final conversion.
