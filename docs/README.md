# Documentation

Use the six core guides to build and finish the appliance. Use the supporting guides when that part of the setup applies to you.

## Core setup

1. [Install Armbian and configure the network](01-armbian-install.md) — flash the matching image, connect Ethernet or Wi-Fi, and verify internet access.
2. [Install Pi-hole and Unbound](02-pihole-unbound.md) — create the local filtered DNS resolver.
3. [Add Tailscale](03-tailscale.md) — enable secure remote access and remote DNS.
4. [Install NetAlertX](04-netalertx.md) — add LAN device discovery and monitoring.
5. [Validate and maintain the appliance](05-validation-maintenance.md) — verify DNS, services, backups, and recovery.
6. [Apply security hardening](06-security-hardening.md) — restrict access after validation.

## After core setup

- [Router and client DNS](router-and-clients.md) — make the rest of the home network use Pi-hole.
- [Troubleshooting](troubleshooting.md) — diagnose time/RTC, DNS, Tailscale, and reboot problems.

## Short version

```text
Armbian + network → Pi-hole + Unbound → Tailscale → NetAlertX
        ↓
Validation → Security hardening
```

NetAlertX is the only core monitoring component. Its installation is optional if you only want DNS, but it is documented as the fourth component when you choose the complete appliance setup.
