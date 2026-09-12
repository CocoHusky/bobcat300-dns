# 3. Install Pi-hole and Unbound

This is the core of the conversion. Pi-hole answers DNS requests from clients and applies filtering. Unbound runs locally on the Bobcat and performs recursive DNS resolution.

Final DNS path:

```text
client -> Pi-hole :53 -> Unbound 127.0.0.1:5335 -> DNS root/TLD/authoritative servers
```

## 1. Install Pi-hole

Install required tools first:

```bash
sudo apt update
sudo apt install -y curl dnsutils
```

Run the official Pi-hole installer:

```bash
curl -sSL https://install.pi-hole.net | bash
```

During setup:

- choose the active network interface;
- keep the Bobcat on its static/reserved IP;
- enable the web interface if desired;
- allow Pi-hole to install its normal blocklists;
- the temporary upstream DNS choice does not matter because we will replace it with Unbound.

After installation:

```bash
pihole status
```

Pi-hole should report FTL listening on TCP and UDP port 53.

## 2. Install Unbound

```bash
sudo apt install -y unbound
```

Create a dedicated Pi-hole Unbound configuration:

```bash
sudo nano /etc/unbound/unbound.conf.d/pi-hole.conf
```

Use:

```text
server:
    verbosity: 0
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no

    root-hints: "/var/lib/unbound/root.hints"

    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232

    prefetch: yes
    num-threads: 1

    so-rcvbuf: 1m

    private-address: 192.168.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: 169.254.0.0/16
    private-address: fd00::/8
    private-address: fe80::/10
```

The important parts are:

```text
interface: 127.0.0.1
port: 5335
```

This keeps Unbound private to the Bobcat. LAN clients talk to Pi-hole on port 53, not directly to Unbound.

## 3. Install/update root hints

```bash
sudo mkdir -p /var/lib/unbound
sudo curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
sudo chown unbound:unbound /var/lib/unbound/root.hints
```

## 4. Validate and restart Unbound

```bash
sudo unbound-checkconf
sudo systemctl enable unbound
sudo systemctl restart unbound
systemctl status unbound --no-pager
```

Test Unbound directly:

```bash
dig @127.0.0.1 -p 5335 google.com
```

Test DNSSEC:

```bash
dig @127.0.0.1 -p 5335 dnssec.works +dnssec
```

A successful DNSSEC-validating response should include the `ad` flag, for example:

```text
flags: qr rd ra ad
```

## 5. Point Pi-hole at Unbound

The tested Pi-hole v6 configuration used `/etc/pihole/pihole.toml`.

First make a backup:

```bash
sudo cp /etc/pihole/pihole.toml /etc/pihole/pihole.toml.backup
```

Edit:

```bash
sudo nano /etc/pihole/pihole.toml
```

Set the upstream resolver to:

```toml
upstreams = [
  "127.0.0.1#5335"
]
```

On the tested appliance this appeared near the top of the file as:

```toml
upstreams = [
    "127.0.0.1#5335"
] ### CHANGED, default = []
```

Restart Pi-hole DNS:

```bash
sudo systemctl restart pihole-FTL
pihole status
```

## 6. Allow both LAN and Tailscale clients

For Pi-hole v6, the tested system used:

```toml
listeningMode = "ALL"
```

in `/etc/pihole/pihole.toml`.

This allowed DNS requests arriving over the LAN interface and `tailscale0`.

Check the current value:

```bash
grep -n "listeningMode" /etc/pihole/pihole.toml
```

If you change it, restart FTL:

```bash
sudo systemctl restart pihole-FTL
```

`ALL` is appropriate here because the Bobcat is behind the home router/firewall and remote access is through Tailscale. Do **not** port-forward public internet DNS traffic to the Bobcat.

## 7. Verify the complete chain

Replace `192.168.0.164` with your Bobcat IP.

```bash
dig @192.168.0.164 google.com +short
dig @192.168.0.164 doubleclick.net +short
```

Expected behavior:

```text
google.com       -> normal public IP address
doubleclick.net  -> blocked response, commonly 0.0.0.0
```

Check listening sockets:

```bash
ss -lntup | grep -E '(:53 |:5335 )'
```

You want:

- Pi-hole/FTL on port 53;
- Unbound on `127.0.0.1:5335`.

## 8. Backup the working Unbound config

```bash
sudo cp /etc/unbound/unbound.conf.d/pi-hole.conf ~/pi-hole-unbound.conf.backup
```

Also keep a copy of:

```text
/etc/pihole/pihole.toml
/etc/unbound/unbound.conf.d/pi-hole.conf
```

Continue with [04-tailscale.md](04-tailscale.md).
