# 7. Validation, maintenance, backups, and recovery

Use this page after setup and whenever the Bobcat is rebooted, updated, or moved to a different network.

## One-shot health check

```bash
hostname
ip -br addr
pihole status
systemctl is-active unbound
chronyc tracking
tailscale status | head -15
tailscale ip -4
ss -lntup | grep -E '(:53 |:5335 )'
cat /etc/resolv.conf
getent hosts debian.org
df -h /
free -h
```

Or use:

```bash
bash scripts/health-check.sh
```

## Expected healthy state

```text
Pi-hole:        running and listening on port 53
Unbound:        active on 127.0.0.1:5335
LAN address:    stable/static or reserved
Tailscale:      Running with a private tailnet address
Chrony:         synchronized / Leap status Normal
Disk:           plenty of free space
Memory:         low utilization on an idle DNS appliance
```

## Validate DNS in layers

### Layer 1: Unbound directly

```bash
dig @127.0.0.1 -p 5335 google.com +short
dig @127.0.0.1 -p 5335 dnssec.works +dnssec | grep 'flags:'
```

### Layer 2: Pi-hole on LAN

```bash
dig @BOBCAT_LAN_IP google.com +short
dig @BOBCAT_LAN_IP doubleclick.net +short
```

### Layer 3: Pi-hole through Tailscale

```bash
TS_IP="$(tailscale ip -4)"
dig @"$TS_IP" google.com +short
dig @"$TS_IP" doubleclick.net +short
```

Testing one layer at a time makes failures much easier to isolate.

## Check services

```bash
systemctl status pihole-FTL --no-pager
systemctl status unbound --no-pager
systemctl status chrony --no-pager
systemctl status tailscaled --no-pager
```

Recent logs:

```bash
journalctl -u pihole-FTL -n 50 --no-pager
journalctl -u unbound -n 50 --no-pager
journalctl -u chrony -n 50 --no-pager
journalctl -u tailscaled -n 50 --no-pager
```

Before posting logs publicly, redact private hostnames, LAN addresses, MAC addresses, Wi-Fi profile/SSID names, Tailscale peer names/addresses, login URLs, node IDs, and any account identifiers.

## Important configuration files

Back up these files privately after you have a working system:

```text
/etc/pihole/pihole.toml
/etc/unbound/unbound.conf.d/pi-hole.conf
/etc/chrony/chrony.conf
/etc/NetworkManager/system-connections/
/var/lib/tailscale/tailscaled.state
```

The NetworkManager profiles and Tailscale state are sensitive. Do not commit them to a public repository.

## Create a local configuration backup

```bash
sudo mkdir -p /root/bobcat-dns-backup
sudo cp /etc/pihole/pihole.toml /root/bobcat-dns-backup/
sudo cp /etc/unbound/unbound.conf.d/pi-hole.conf /root/bobcat-dns-backup/
sudo cp /etc/chrony/chrony.conf /root/bobcat-dns-backup/
sudo cp -a /etc/NetworkManager/system-connections /root/bobcat-dns-backup/
```

Optionally include Tailscale state in a private/offline backup:

```bash
sudo cp /var/lib/tailscale/tailscaled.state /root/bobcat-dns-backup/
```

## Make a full SD-card image

Once the appliance is stable, make a full image of the microSD card for disaster recovery. Shut down cleanly first:

```bash
sudo poweroff
```

Then image the card from another computer. Treat that image as sensitive because it can contain Wi-Fi credentials, local addresses, Pi-hole history, and Tailscale identity material.

## Package updates

```bash
sudo apt update
sudo apt upgrade
```

Review changes before accepting them.

On a community Bobcat Armbian image, the kernel, device-tree, and U-Boot packages may be held to protect a known-good boot stack:

```bash
apt-mark showhold
```

Do not casually unhold the boot stack on a working appliance unless you have a recoverable SD-card image.

## Update Pi-hole

```bash
pihole -up
pihole status
```

## Update Tailscale

```bash
tailscale version
systemctl status tailscaled --no-pager
tailscale status
```

## After every reboot

```bash
date
chronyc tracking
ip -br addr
pihole status
systemctl is-active unbound
tailscale status | head
tailscale ip -4
```

The time check comes first because a bad RTC date can make otherwise healthy HTTPS/TLS-based services look broken.

## If the internet works but Tailscale is offline

```bash
date
chronyc tracking
journalctl -u tailscaled -n 50 --no-pager
```

If the logs show an x509 certificate validity error and the date is wrong, correct time first. Do not reinstall Tailscale.

## If Pi-hole works but external names do not resolve

```bash
dig @127.0.0.1 -p 5335 google.com
systemctl status unbound --no-pager
sudo unbound-checkconf
grep -n "upstreams" /etc/pihole/pihole.toml
```

The Pi-hole upstream should point to:

```text
127.0.0.1#5335
```

## If LAN clients bypass Pi-hole

Check the router DHCP DNS settings. The Bobcat should be the advertised DNS resolver. Avoid a public secondary resolver if you want every client to use Pi-hole.

## If remote Tailscale clients do not use Pi-hole

```bash
tailscale ip -4
pihole-FTL --config dns.listeningMode
dig @"$(tailscale ip -4)" google.com
```

Then confirm the Bobcat's current Tailscale address is configured as the tailnet nameserver.

## Recovery philosophy

The recovery path depends on the Bobcat revision: G280/G285 use a microSD image, while G290/G295 use the upstream eMMC flasher workflow. Recovery can therefore be simple:

1. flash a known-working Bobcat Armbian image;
2. restore network configuration;
3. reinstall Pi-hole, Unbound, and Tailscale;
4. restore private configuration backups;
5. verify with the health-check script.

After the appliance passes validation, apply [11-security-hardening.md](11-security-hardening.md).
