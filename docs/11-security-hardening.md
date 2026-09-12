# 11. Security hardening

Apply this page after the appliance is working and the validation checks pass. Keep a local SSH session open while changing firewall rules so a mistake does not lock you out.

## Remove services you do not need

Check whether `rpcbind` is installed and listening:

```bash
systemctl is-active rpcbind rpcbind.socket 2>/dev/null || true
ss -lntup
```

If you do not use NFS or another service that requires it, disable it:

```bash
sudo systemctl disable --now rpcbind rpcbind.socket
```

Do not disable services blindly. Review the listener list and remove or disable only services you recognize and do not need.

## Review listeners

```bash
sudo ss -lntup
sudo ss -lnup
```

Expected appliance listeners normally include Pi-hole on port 53, Unbound only on `127.0.0.1:5335`, and Tailscale-managed interfaces. NetAlertX uses ports 20211 and 20214 only when the optional service is installed.

Investigate anything unexpected before exposing the appliance to other networks.

## Install a host firewall

If UFW is not installed, install it first:

```bash
sudo apt update
sudo apt install -y ufw
```

Replace `BOBCAT_LAN_CIDR` with your LAN subnet and `TAILSCALE_CIDR` with the trusted Tailscale address range or your narrower tailnet range. Keep the SSH rule before enabling UFW:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from BOBCAT_LAN_CIDR to any port 22 proto tcp
sudo ufw allow from TAILSCALE_CIDR to any port 22 proto tcp
sudo ufw allow from BOBCAT_LAN_CIDR to any port 53 proto tcp
sudo ufw allow from BOBCAT_LAN_CIDR to any port 53 proto udp
sudo ufw allow from TAILSCALE_CIDR to any port 53 proto tcp
sudo ufw allow from TAILSCALE_CIDR to any port 53 proto udp
```

If NetAlertX is installed, allow its web and API ports only from trusted networks:

```bash
sudo ufw allow from BOBCAT_LAN_CIDR to any port 20211 proto tcp
sudo ufw allow from TAILSCALE_CIDR to any port 20211 proto tcp
sudo ufw allow from BOBCAT_LAN_CIDR to any port 20214 proto tcp
sudo ufw allow from TAILSCALE_CIDR to any port 20214 proto tcp
```

Enable and inspect the firewall:

```bash
sudo ufw enable
sudo ufw status verbose
```

Do not allow port 53 from the public internet. Do not add broad `allow from any` rules for DNS, SSH, or NetAlertX.

## Confirm DNS exposure

Pi-hole `listeningMode "ALL"` is useful for LAN and Tailscale clients, but it binds broadly. Confirm the firewall and router prevent public access:

```bash
pihole-FTL --config dns.listeningMode
sudo ufw status verbose
sudo ss -lntup | grep -E '(:53 )'
```

Unbound must remain local-only:

```bash
sudo ss -lntup | grep 5335
```

The Unbound listener should be `127.0.0.1:5335`, not a LAN or Tailscale address.

## Verify Tailscale transport

Tailscale should carry remote access and remote DNS without router port-forwards:

```bash
tailscale status
tailscale netcheck
sudo ufw status verbose
```

Remove any router port-forward for TCP/UDP 53, 22, 20211, or 20214. Access those services through the trusted LAN or Tailscale instead.

## Re-test the appliance

```bash
getent hosts debian.org
dig @127.0.0.1 -p 5335 dnssec.works +dnssec
dig @BOBCAT_LAN_IP google.com +short
sudo systemctl is-active pihole-FTL unbound tailscaled
```

If NetAlertX is installed:

```bash
curl -I --max-time 5 http://127.0.0.1:20211/
```

Return to [07-validation-maintenance.md](07-validation-maintenance.md) whenever firewall or service changes affect DNS behavior.
