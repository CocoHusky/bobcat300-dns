# 3. Add Tailscale for secure remote access and remote DNS

Tailscale gives the Bobcat a private tailnet address and lets laptops/phones use the same Pi-hole when away from home without exposing DNS to the public internet.

Use the current Tailscale address and names from your own device and account.

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

The Bobcat should ideally not use the tailnet DNS server that points back to itself. After Pi-hole is working, keep the host's resolver path independent:

```bash
sudo tailscale set --accept-dns=false
```

The tailnet can still use the Bobcat as its configured nameserver; this setting applies to the Bobcat host and avoids a circular dependency while Tailscale and Chrony bootstrap.

Immediately verify that the host resolver was restored:

```bash
sudo tailscale debug prefs | grep -E 'CorpDNS|AcceptDNS'
cat /etc/resolv.conf
getent hosts debian.org
```

`CorpDNS` should be `false`, and the lookup should succeed using the normal local resolver. If `/etc/resolv.conf` still points to `100.100.100.100` or another stale Tailscale resolver, restore NetworkManager's managed resolver link:

```bash
sudo ln -sf /run/NetworkManager/resolv.conf /etc/resolv.conf
sudo systemctl restart NetworkManager
getent hosts debian.org
```

If that target does not exist on your image, inspect the available NetworkManager resolver files with `ls -l /run/NetworkManager/` and use the target provided by that image. Do not overwrite `/etc/resolv.conf` with a public or installation-specific address.

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
pihole-FTL --config dns.listeningMode
```

Set:

```bash
sudo pihole-FTL --config dns.listeningMode "ALL"
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

Normal setup is covered in [time-and-rtc.md](time-and-rtc.md); recovery steps are in [troubleshooting.md](troubleshooting.md).
