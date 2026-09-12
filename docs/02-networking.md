# 2. Networking and static IP

The DNS appliance needs a stable LAN address. The tested build used:

```text
Hostname: bobs-dns
LAN IP:   192.168.0.164/24
Gateway:  192.168.0.1
```

Use values appropriate for your own network.

## Identify interfaces

```bash
ip -br addr
nmcli device status
```

Typical interface names on the Bobcat build are:

```text
end0     Ethernet
wlan0    Wi-Fi
tailscale0  created later by Tailscale
```

Use Ethernet when available. Wi-Fi also works for Pi-hole/Unbound because DNS traffic is very small.

## Configure a static address with NetworkManager

List profiles:

```bash
nmcli connection show
```

For Ethernet, replace `Wired connection 1` with the actual profile name:

```bash
sudo nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.0.164/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns 192.168.0.1

sudo nmcli connection up "Wired connection 1"
```

For Wi-Fi, if your active profile is named `bobcat-wifi`:

```bash
sudo nmcli connection modify "bobcat-wifi" \
  ipv4.method manual \
  ipv4.addresses 192.168.0.164/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns 192.168.0.1

sudo nmcli connection up "bobcat-wifi"
```

Using the router as the Bobcat's own resolver during installation avoids creating a circular dependency before Pi-hole and Unbound are fully configured.

## Alternative: DHCP reservation

Instead of a manual static address, you can reserve the Bobcat's MAC address in your router and always assign the same IP. Either approach is fine; the important requirement is that the DNS server address does not change.

## Verify connectivity

```bash
ip -br addr
ip route
ping -c 2 192.168.0.1
ping -c 2 1.1.1.1
getent hosts debian.org
```

You want all three layers to work:

1. local interface has the intended IP;
2. internet routing works;
3. DNS resolution works.

## SSH access

From another LAN machine:

```bash
ssh root@192.168.0.164
```

For regular administration, consider creating a non-root user and using SSH keys. The examples in this repo show `root` because that is how the initial appliance was configured.

## Check the final network state

```bash
hostname
ip -br addr
ip route
```

Expected shape:

```text
bobs-dns
lo      UNKNOWN  127.0.0.1/8 ::1/128
end0    UP       192.168.0.164/24
```

or, when using Wi-Fi:

```text
wlan0   UP       192.168.0.164/24
```

Continue with [03-pihole-unbound.md](03-pihole-unbound.md).
