# 7. Validation, maintenance, backups, and recovery

Use this page after setup and whenever the Bobcat is rebooted, updated, or moved to a different network.

## One-shot health check

Run:

```bash
hostname
ip -br addr
pihole status
systemctl is-active unbound
chronyc tracking
tailscale status | head -15
tailscale ip -4
ss -lntup | grep -E '(:53 |:5335 )'
df -h /
free -h
```

Or use the included script:

```bash
bash scripts/health-check.sh
```

## Expected healthy state

You should have:

```text
Pi-hole:        running and listening on port 53
Unbound:        active on 127.0.0.1:5335
LAN address:    stable/static
Tailscale:      Running with a 100.x.x.x IP
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
dig @192.168.0.164 google.com +short
dig @192.168.0.164 doubleclick.net +short
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

## Important configuration files

Back up these files after you have a working system:

```text
/etc/pihole/pihole.toml
/etc/unbound/unbound.conf.d/pi-hole.conf
/etc/chrony/chrony.conf
/etc/NetworkManager/system-connections/
/var/lib/tailscale/tailscaled.state
```

The Tailscale state file contains node identity/state. Treat it as sensitive and do not commit it to GitHub.

## Create a local configuration backup

Example:

```bash
sudo mkdir -p /root/bobcat-dns-backup
sudo cp /etc/pihole/pihole.toml /root/bobcat-dns-backup/
sudo cp /etc/unbound/unbound.conf.d/pi-hole.conf /root/bobcat-dns-backup/
sudo cp /etc/chrony/chrony.conf /root/bobcat-dns-backup/
sudo cp -a /etc/NetworkManager/system-connections /root/bobcat-dns-backup/
```

Optionally include Tailscale state in a **private** backup:

```bash
sudo cp /var/lib/tailscale/tailscaled.state /root/bobcat-dns-backup/
```

## Make a full SD-card image

Once the appliance is stable, making a full image of the microSD card gives you the fastest disaster recovery. Shut down cleanly first:

```bash
sudo poweroff
```

Then image the SD card from another computer using a disk-imaging tool.

## Package updates

Normal userspace updates:

```bash
sudo apt update
sudo apt upgrade
```

Review changes before accepting them.

On the tested appliance the kernel, device-tree, and U-Boot packages were held because the Bobcat uses a community Armbian image:

```bash
apt-mark showhold
```

Do not casually unhold the boot stack on a working DNS appliance unless you have a recoverable SD-card image.

## Update Pi-hole

```bash
pihole -up
```

After updating:

```bash
pihole status
dig @127.0.0.1 google.com +short
```

## Update Tailscale

Because Tailscale is installed from its apt repository, normal apt updates can update it.

Check the installed version:

```bash
tailscale version
```

After an update:

```bash
systemctl status tailscaled --no-pager
tailscale status
```

## After every reboot

A short post-boot check is enough:

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

Check:

```bash
date
chronyc tracking
journalctl -u tailscaled -n 50 --no-pager
```

If the logs contain an x509 message saying a certificate is expired or not yet valid and the date is wrong, correct time first. Do not reinstall Tailscale.

## If Pi-hole works but external names do not resolve

Test Unbound directly:

```bash
dig @127.0.0.1 -p 5335 google.com
systemctl status unbound --no-pager
sudo unbound-checkconf
```

Then check the Pi-hole upstream:

```bash
grep -n "upstreams" /etc/pihole/pihole.toml
sed -n '1,25p' /etc/pihole/pihole.toml
```

It should point to:

```text
127.0.0.1#5335
```

## If LAN clients bypass Pi-hole

Check the router DHCP DNS settings. The Bobcat should be the advertised DNS resolver. Avoid a public secondary resolver if you want every client to use Pi-hole.

## If remote Tailscale clients do not use Pi-hole

Verify all three:

```bash
tailscale ip -4
grep -n "listeningMode" /etc/pihole/pihole.toml
dig @"$(tailscale ip -4)" google.com
```

Then check the tailnet DNS settings and confirm the Bobcat's current Tailscale IP is configured as the nameserver.

## Recovery philosophy

The conversion intentionally keeps the original internal storage separate and runs the appliance from microSD. That means recovery can be simple:

1. flash a known-working Bobcat Armbian image;
2. restore network configuration;
3. reinstall Pi-hole, Unbound, and Tailscale;
4. restore the backed-up configuration files;
5. verify with the health-check script.

That is usually safer than making undocumented changes to the Bobcat's original internal firmware.
