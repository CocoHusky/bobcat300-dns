# Time and RTC

Correct time is required before relying on HTTPS, package repositories, DNSSEC, or Tailscale. Complete this step after networking and before Pi-hole or Tailscale setup.

## Install and enable Chrony

```bash
sudo apt update
sudo apt install -y chrony
sudo systemctl enable --now chrony
```

Ensure `/etc/chrony/chrony.conf` contains:

```text
rtcsync
makestep 1 3
```

`makestep` corrects a large clock error during the first updates after boot. `rtcsync` allows the synchronized system clock to be written back to the hardware RTC.

## Verify synchronization and write the RTC

```bash
chronyc tracking
chronyc sources -v
date
```

Wait until `Leap status : Normal` and the clock is correct, then write it to the RTC:

```bash
sudo hwclock --systohc
hwclock --show
```

Whether the RTC retains time across complete power loss depends on the miner's RTC backup hardware. The write command cannot add backup power that the board does not have.

## If the clock is far in the past

Set an approximately correct time once, then let Chrony take over:

```bash
sudo date -s "YYYY-MM-DD HH:MM:SS"
sudo systemctl restart chrony
chronyc tracking
sudo hwclock --systohc
```

Use the actual current date and time. Continue with [02-pihole-unbound.md](02-pihole-unbound.md).
