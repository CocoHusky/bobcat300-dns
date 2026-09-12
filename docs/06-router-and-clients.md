# 6. Point the home network at the Bobcat

At this point the Bobcat should already answer DNS locally through Pi-hole and Unbound. The next step is making other devices use it automatically.

Replace the placeholders with values from your network.

## Keep DHCP on the router

There is no requirement to make Pi-hole the DHCP server.

Keep normal router DHCP and change only the DNS server distributed to clients:

```text
Router
  |- DHCP -> client IP/gateway assignments
  `- DNS  -> Bobcat Pi-hole address
```

## Set the router's LAN DNS

In the router's DHCP/LAN settings, set the primary DNS server to the Bobcat's static or reserved address.

```text
Primary DNS:   BOBCAT_LAN_IP
Secondary DNS: blank
```

Leaving the secondary DNS blank prevents clients from bypassing Pi-hole by randomly choosing another resolver.

Do not enter a secondary public DNS such as a third-party resolver if your goal is consistent Pi-hole filtering.

## Renew client DHCP leases

Existing clients may continue using their previous DNS settings until the DHCP lease renews. Reconnect Wi-Fi, renew DHCP, or reboot the client.

### macOS check

```bash
scutil --dns | grep 'nameserver\[[0-9]*\]'
```

### Linux check

```bash
resolvectl status
```

or:

```bash
cat /etc/resolv.conf
```

## Test from another LAN device

```bash
nslookup google.com BOBCAT_LAN_IP
nslookup doubleclick.net BOBCAT_LAN_IP
```

or:

```bash
dig @BOBCAT_LAN_IP google.com +short
dig @BOBCAT_LAN_IP doubleclick.net +short
```

The first should resolve normally; the second should show the Pi-hole blocking result if it is on the active blocklist.

## Confirm queries reach Pi-hole

On the Bobcat:

```bash
pihole status
```

Open the Pi-hole web interface using your own LAN address:

```text
http://BOBCAT_LAN_IP/admin/
```

You should see client queries appear in the dashboard/query log.

## Remote devices through Tailscale

LAN clients normally use the Bobcat's LAN address. Remote Tailscale clients use the Bobcat's Tailscale address through the tailnet DNS configuration described in [04-tailscale.md](04-tailscale.md).

```text
home client ----LAN----> Pi-hole -> Unbound
remote client --TS-----> Pi-hole -> Unbound
```

Do not publish screenshots of router DHCP pages, Pi-hole client lists, or Tailscale peer lists without redacting local device names, MAC addresses, IPs, and account-specific identifiers.

## Avoid public DNS exposure

Do not forward router port 53 to the Bobcat.

Pi-hole should be reachable only through trusted LAN interfaces and Tailscale. Tailscale provides encrypted remote connectivity without turning the Bobcat into an open resolver on the internet.

Continue with [07-validation-maintenance.md](07-validation-maintenance.md).
