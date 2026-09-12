# 4. Add Tailscale for secure remote access and remote DNS

Tailscale gives the Bobcat a private tailnet IP and lets laptops/phones use the same Pi-hole when away from home without exposing DNS to the public internet.

The tested Bobcat received:

```text
TAILSCALE_IP
```

Your Tailscale IP will be different.

## 1. Install Tailscale

Use the official installer:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

The tested Debian/Bookworm system installed the `tailscale` package and enabled `tailscaled.service` automatically.

Check it:

```bash
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
```

You should see a `100.x.x.x` address.

Also confirm the interface exists:

```bash
ip -br addr show tailscale0
```

## 3. Verify Pi-hole directly over Tailscale

On the Bobcat itself, use its Tailscale IP:

```bash
TS_IP="$(tailscale ip -4)"
dig @"$TS_IP" google.com
dig @"$TS_IP" doubleclick.net
```

On the tested system, the normal domain resolved successfully and the blocked domain returned `0.0.0.0`.

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

In the Tailscale admin console, open the DNS settings and add the Bobcat's **Tailscale IP** as a global nameserver.

For the tested build that was:

```text
TAILSCALE_IP
```

Enable **Override DNS servers** if you want connected tailnet devices to use the Bobcat Pi-hole automatically.

Do not enter the example IP from this repo; use:

```bash
tailscale ip -4
```

on your own Bobcat.

## 5. Test from a remote device

Disconnect a phone/laptop from the home LAN, keep Tailscale connected, and browse normally.

You can also directly test the DNS server from another tailnet device:

```bash
dig @100.x.x.x google.com
dig @100.x.x.x doubleclick.net
```

Replace `100.x.x.x` with the Bobcat Tailscale IP.

## 6. SSH through Tailscale

Even if the home LAN address changes or you are away from home, normal SSH can use the Tailscale address:

```bash
ssh root@100.x.x.x
```

If MagicDNS is enabled and the name resolves, you may also be able to use the tailnet hostname.

## 7. Useful diagnostics

```bash
systemctl is-active tailscaled
tailscale status
tailscale ip -4
tailscale netcheck
ip -br addr show tailscale0
journalctl -u tailscaled -n 50 --no-pager
```

A healthy node should show:

```text
tailscaled: active
state: Running
Tailscale IPv4: 100.x.x.x
```

## Important: Tailscale depends on correct system time

TLS certificates will fail if the Bobcat boots with a wildly incorrect RTC date. On the tested hardware, the RTC once restored a 2017 timestamp, which caused Tailscale to appear offline even though the machine itself was reachable over LAN SSH.

The permanent mitigation is covered in [05-time-sync.md](05-time-sync.md).
