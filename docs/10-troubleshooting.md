# 10. Troubleshooting and time/RTC recovery

Normal time and RTC setup is covered in [05-time-and-rtc.md](05-time-and-rtc.md). Use this page when the clock is already wrong or a service failed during recovery.

Correct system time matters because HTTPS, package repositories, Tailscale, DNSSEC, and TLS certificate validation all depend on it.

If the hardware RTC restores a date several years in the past during boot, the machine may remain reachable over LAN SSH while TLS-based services such as Tailscale fail.

The fix is to make Chrony correct large clock errors immediately after network access becomes available and keep the RTC synchronized.

## 1. Confirm Chrony is installed

```bash
dpkg -l | grep chrony
systemctl status chrony --no-pager
```

If needed:

```bash
sudo apt update
sudo apt install -y chrony
sudo systemctl enable --now chrony
```

## 2. Check the Chrony configuration

```bash
sudo nano /etc/chrony/chrony.conf
```

Ensure these directives are present:

```text
rtcsync
makestep 1 3
```

What they do:

- `rtcsync` allows the kernel to periodically synchronize the hardware RTC from the correct system time.
- `makestep 1 3` allows Chrony to immediately step the system clock when the error is larger than 1 second during the first three clock updates after startup.

These are useful on embedded hardware that may boot with an old RTC value.

## 3. Restart Chrony

```bash
sudo systemctl restart chrony
```

Then check synchronization:

```bash
chronyc tracking
chronyc sources -v
```

A healthy `chronyc tracking` result should show a valid reference source and:

```text
Leap status : Normal
```

After correction, allow Chrony time to synchronize before relying on TLS-based services.

## 4. Check the system clock and RTC

```bash
date
timedatectl
```

You want:

```text
System clock synchronized: yes
NTP service: active
```

Depending on the image/systemd integration, `timedatectl` may not perfectly describe Chrony's state. `chronyc tracking` is the authoritative check when Chrony is the active NTP client.

## 5. Manual emergency recovery

If the device boots years in the past and network services fail before Chrony can recover, set the date approximately correct once:

```bash
sudo date -s "YYYY-MM-DD HH:MM:SS"
```

Use the actual current date/time, not the example above.

Then:

```bash
sudo systemctl restart chrony
sudo systemctl restart tailscaled
```

Check:

```bash
chronyc tracking
tailscale status
tailscale ip -4
```

## 6. Recognizing a time-caused Tailscale failure

The failure can look like:

```text
x509: certificate has expired or is not yet valid
current time is far in the past
```

and:

```text
unexpected state: NoState
no current Tailscale IPs
```

If you see that, check `date` before reinstalling or re-authenticating Tailscale.

## 7. Reboot validation

After Chrony is configured, reboot:

```bash
sudo reboot
```

Reconnect and verify:

```bash
date
chronyc tracking
tailscale status | head
tailscale ip -4
```

If the date is correct and Tailscale reconnects automatically, the boot-time recovery is working.

After recovery, return to [06-router-and-clients.md](06-router-and-clients.md) and then complete [07-validation-maintenance.md](07-validation-maintenance.md).
