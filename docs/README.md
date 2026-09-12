# Documentation

Use the four core guides to build the appliance. Use the supporting guides when that part of the setup applies to you.

## Core setup

1. [Install Armbian and configure the network](01-armbian-install.md) — flash the matching image, connect Ethernet or Wi-Fi, and verify internet access.
2. [Install Pi-hole and Unbound](02-pihole-unbound.md) — create the local filtered DNS resolver.
3. [Add Tailscale](03-tailscale.md) — enable secure remote access and remote DNS.
4. [Install NetAlertX](04-netalertx.md) — add LAN device discovery and monitoring.

## After core setup

- [Time and RTC](time-and-rtc.md) — use when the clock is wrong or TLS/Tailscale cannot start.
- [Router and client DNS](router-and-clients.md) — make the rest of the home network use Pi-hole.
- [Validation, maintenance, and recovery](validation-maintenance.md) — verify services, back up configuration, update, and recover.
- [Troubleshooting](troubleshooting.md) — diagnose time, DNS, Tailscale, and reboot problems.
- [Security hardening](security-hardening.md) — apply after the appliance works and validation passes.

## Short version

```text
Armbian + network → Pi-hole + Unbound → Tailscale → NetAlertX
        ↓
Router DNS → Validation → Security hardening
```

NetAlertX is the only core monitoring component. Its installation is optional if you only want DNS, but it is documented as the fourth component when you choose the complete appliance setup.
