# 6. Point the home network at the Bobcat

At this point the Bobcat should already answer DNS locally through Pi-hole and Unbound. The next step is making other devices use it automatically.

The tested network used:

```text
Bobcat DNS: 192.168.0.164
Router:     192.168.0.1
```

Use your own addresses.

## Keep DHCP on the router

There is no requirement to make Pi-hole the DHCP server.

The tested setup kept normal router DHCP and changed only the DNS server distributed to clients.

This is a simple arrangement:

```text
Router
  |- DHCP -> client IP/gateway assignments
  `- DNS  -> Bobcat Pi-hole address
```

## Set the router's LAN DNS

In the router's DHCP/LAN settings, set the primary DNS server to the Bobcat's static address.

Example:

```text
Primary DNS:   192.168.0.164
Secondary DNS: blank
```

Leaving the secondary DNS blank prevents clients from bypassing Pi-hole by randomly choosing another resolver.

Do not enter a secondary public DNS such as `8.8.8.8` if your goal is consistent Pi-hole filtering. Some clients may use it instead of the Bobcat.

## Renew client DHCP leases

Existing clients may continue using their previous DNS settings until the DHCP lease renews.

You can reconnect Wi-Fi, renew DHCP, or reboot a client.

### macOS check

```bash
scutil --dns | grep 'nameserver\[[0-9]*\]'
```

### Linux check

Depending on the distribution:

```bash
resolvectl status
```

or:

```bash
cat /etc/resolv.conf
```

## Test from another LAN device

```bash
nslookup google.com 192.168.0.164
nslookup doubleclick.net 192.168.0.164
```

or with `dig`:

```bash
dig @192.168.0.164 google.com +short
dig @192.168.0.164 doubleclick.net +short
```

The first should resolve normally; the second should show the Pi-hole blocking result if it is on the active blocklist.

## Confirm queries reach Pi-hole

On the Bobcat:

```bash
pihole status
```

Open the Pi-hole web interface if installed:

```text
http://192.168.0.164/admin/
```

You should see client queries appear in the dashboard/query log.

## Remote devices through Tailscale

LAN clients normally use the Bobcat's LAN IP.

Remote Tailscale clients use the Bobcat's `100.x.x.x` address through the tailnet DNS configuration described in [04-tailscale.md](04-tailscale.md).

This gives the same logical path from home or away:

```text
home client ----LAN----> Pi-hole -> Unbound
remote client --TS-----> Pi-hole -> Unbound
```

## Avoid public DNS exposure

Do not forward router port 53 to the Bobcat.

Pi-hole should be reachable only through trusted LAN interfaces and Tailscale. Tailscale provides encrypted remote connectivity without turning the Bobcat into an open resolver on the internet.

Continue with [07-validation-maintenance.md](07-validation-maintenance.md).
