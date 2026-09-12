# 9. Storage, RAM logging, and flash-wear reduction

Run Armbian from microSD while leaving the original internal eMMC untouched. Armbian provides compressed RAM-backed logging through `armbian-ramlog`.

## How logging is arranged

```text
/var/log       -> zram-backed temporary logs
/var/log.hdd   -> persistent backing storage on the boot medium
```

Pi-hole logs are included in this arrangement. The service initializes and synchronizes the RAM-backed log area; therefore `active (exited)` is a normal status after initialization completes.

Verify the arrangement:

```bash
systemctl status armbian-ramlog --no-pager
mount | grep '/var/log'
```

Do not install a separate Log2Ram implementation. It duplicates Armbian's existing service and may conflict with it.

The benefit is fewer small writes to the microSD card, which is useful for an always-on DNS appliance. The tradeoff is that logs still in RAM may be lost after sudden power failure, while persistent application databases and configuration remain on disk.

Keep a known-good microSD image because it is the primary recovery path. Treat full images and configuration backups as private: they can contain Wi-Fi credentials, local addresses, DNS history, Tailscale identity, and NetAlertX inventory.

Continue with [07-validation-maintenance.md](07-validation-maintenance.md).
