# 4. Add Tailscale for secure remote access and remote DNS

Tailscale gives the Bobcat a private tailnet address and lets laptops/phones use the same Pi-hole when away from home without exposing DNS to the public internet.

This public guide does not include the real Tailscale IP, tailnet name, device names, or account identifiers from the tested system.

## 1. Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
systemctl status tailscaled --no-pager
```

## 2. Authenticate the Bobcat

```bash
sudo tailscale up
```

Open the authentication URL displayed in the terminal and approve the device in your Tailscale account.

Confirm:

```bash
tailscale status
tailscale ip -4
ip -br addr show tailscale0
```

Treat the output of `tailscale status` as environment-specific information. It can include private device names and addresses, so review it before posting publicly.

## 3. Verify Pi-hole directly over Tailscale

Use the address dynamically instead of hard-coding it:

```bash
TS_IP="$(tailscale ip -4)"
dig @"$TS_IP" google.com
dig @"$TS_IP" doubleclick.net
```

The normal domain should resolve and a blocked domain should return the Pi-hole blocking response.

If this fails, verify Pi-hole's listening mode:

```bash
grep -n "listeningMode" /etc/pihole/pihole.toml
```

The working configuration used:

```toml
listeningMode = "ALL"
```

Then restart Pi-hole if needed:

```bash
sudo systemctl restart pihole-FTL
```

## 4. Use the Bobcat as tailnet DNS

In the Tailscale admin console, open DNS settings and add the Bobcat's current Tailscale IP as a global nameserver.

Get that value directly from the device:

```bash
tailscale ip -4
```

Enable **Override DNS servers** if you want connected tailnet devices to use the Bobcat Pi-hole automatically.

Do not copy an address from another installation and do not commit your real tailnet DNS address to this public repository.

## 5. Test from a remote device

Disconnect a phone/laptop from the home LAN, keep Tailscale connected, and browse normally.

For a direct test, substitute your own address:

```bash
dig @TAILSCALE_IP google.com
dig @TAILSCALE_IP doubleclick.net
```

## 6. SSH through Tailscale

```bash
ssh root@TAILSCALE_IP
```

If MagicDNS is enabled, you may also use your chosen tailnet hostname. Avoid publishing private MagicDNS/tailnet names in logs or screenshots.

## 7. Useful diagnostics

```bash
systemctl is-active tailscaled
tailscale status
tailscale ip -4
tailscale netcheck
ip -br addr show tailscale0
journalctl -u tailscaled -n 50 --no-pager
```

Before sharing diagnostics publicly, redact private peer names, tailnet names, IPs, node IDs, login URLs, and account identifiers.

## Important: Tailscale depends on correct system time

TLS certificates will fail if the Bobcat boots with a wildly incorrect RTC date. The hardware used for this project once booted with a very old RTC value, causing Tailscale to appear offline even though LAN SSH still worked.

The mitigation is covered in [05-time-sync.md](05-time-sync.md).
