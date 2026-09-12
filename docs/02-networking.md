# 2. Networking and static IP

The DNS appliance needs a stable LAN address. Use either a manual static address or a DHCP reservation. Replace the placeholders with values from your network.

## Choose Ethernet or Wi-Fi

Ethernet is the best choice for a DNS server because it is more stable and avoids wireless setup during recovery. Wi-Fi is suitable when Ethernet is unavailable and the Bobcat variant includes Wi-Fi. The upstream project lists the G280 as Wi-Fi-free.

Connect Ethernet before first boot when possible. If using Wi-Fi, have the SSID and password ready; configure the connection locally through NetworkManager after SSH access is available.

## Identify interfaces

```bash
ip -br addr
nmcli device status
```

Typical interface names on the Bobcat build are:

```text
end0        Ethernet
wlan0       Wi-Fi
tailscale0  created later by Tailscale
```

Use Ethernet when available. Wi-Fi also works for Pi-hole/Unbound because DNS traffic is very small.

## Choose your local values

Write down these values from your own network:

```text
DNS_HOSTNAME       hostname you want for the Bobcat
BOBCAT_LAN_CIDR    static LAN address plus prefix, for example YOUR_IP/24
ROUTER_LAN_IP      router/default-gateway address
WIFI_PROFILE       NetworkManager Wi-Fi profile name, if using Wi-Fi
```

Do not copy values from another installation.

## Configure a static address with NetworkManager

List profiles:

```bash
nmcli connection show
```

For Ethernet, replace the placeholders before running:

```bash
sudo nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses BOBCAT_LAN_CIDR \
  ipv4.gateway ROUTER_LAN_IP \
  ipv4.dns ROUTER_LAN_IP

sudo nmcli connection up "Wired connection 1"
```

For Wi-Fi:

```bash
sudo nmcli connection modify "WIFI_PROFILE" \
  ipv4.method manual \
  ipv4.addresses BOBCAT_LAN_CIDR \
  ipv4.gateway ROUTER_LAN_IP \
  ipv4.dns ROUTER_LAN_IP

sudo nmcli connection up "WIFI_PROFILE"
```

If no Wi-Fi profile exists yet, create one instead:

```bash
nmcli device wifi list
sudo nmcli device wifi connect "YOUR_WIFI_SSID" password "YOUR_WIFI_PASSWORD" ifname wlan0
nmcli connection show
```

After the connection is working, use its profile name in the static-address example above if you need a manual address. Keep Wi-Fi credentials on the device only; never place them in this project or in screenshots.

Using the router as the Bobcat's own resolver during installation avoids creating a circular dependency before Pi-hole and Unbound are fully configured.

## Alternative: DHCP reservation

Instead of a manual static address, reserve the Bobcat's MAC address in your router and always assign the same IP. The important requirement is that the DNS server address does not change.

Do not publish the device's real MAC address in documentation or issue reports unless necessary.

## Verify connectivity

```bash
ip -br addr
ip route
ping -c 2 ROUTER_LAN_IP
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
ssh root@BOBCAT_LAN_IP
```

For regular administration, consider creating a non-root user and using SSH keys.

## Check the final network state

```bash
hostname
ip -br addr
ip route
```

Expected shape:

```text
DNS_HOSTNAME
lo      UNKNOWN  127.0.0.1/8 ::1/128
end0    UP       BOBCAT_LAN_CIDR
```

or, when using Wi-Fi:

```text
wlan0   UP       BOBCAT_LAN_CIDR
```

Continue with [03-pihole-unbound.md](03-pihole-unbound.md).
