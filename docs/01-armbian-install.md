# 1. Install Armbian on a Bobcat 300 G285

This guide is for the Bobcat Miner 300 G285 / Bobcat 285 based on the Rockchip RK3566.

## Hardware used

- Bobcat Miner 300 G285
- microSD card; 32 GB is more than enough for this appliance
- computer with a microSD reader
- Ethernet or Wi-Fi network access

The LoRa concentrator is not required for the DNS appliance.

## Use a G285-compatible Armbian image

The tested system used the community Bobcat Armbian project:

`https://github.com/sicXnull/Bobcat-Armbian`

For the G285, use the image intended for the Bobcat 285/G285, such as:

```text
BobcatArmbian285.img.xz
```

Do not blindly use the G290/G295 image on a G285. The models have different device trees and hardware definitions.

## Flash the image

On macOS, Linux, or Windows, use a normal image writer such as Raspberry Pi Imager, balenaEtcher, or another tool that can decompress/write `.img.xz` images.

Write the image to the microSD card, eject it cleanly, and place the card in the Bobcat.

## First boot

Power on the Bobcat and allow several minutes for the first boot.

Once the device is on the network, SSH into it using the address your router assigned:

```bash
ssh root@BOBCAT_LAN_IP
```

Replace `BOBCAT_LAN_IP` with the address shown by your router or DHCP server.

The tested image identified itself as:

```text
Armbian v26.02 rolling for Bobcat 285
Linux 6.18.4-current-rockchip64
Debian Bookworm based userspace
```

## Confirm you are on the expected board and storage

```bash
hostnamectl
uname -a
lsblk
cat /proc/device-tree/model 2>/dev/null; echo
tr '\0' '\n' < /proc/device-tree/compatible 2>/dev/null
```

For the tested G285, the device-tree model was:

```text
Bobcat 285
```

The root filesystem was on the microSD card and the original internal eMMC remained present but untouched.

A typical storage layout looked like:

```text
mmcblk0   ~29.7G   microSD / Armbian root
mmcblk1   ~57.6G   original internal eMMC
```

## Do not overwrite the internal eMMC unless you intend to

For a DNS appliance, running from microSD is sufficient and makes recovery easy. If the SD image becomes damaged, reflash a card and restore the configuration.

Do not run installation tools that copy the OS to internal eMMC unless you have verified exactly what they will overwrite.

## Protect the working kernel while setting up the appliance

On the tested system the working Rockchip kernel/U-Boot packages were held so a normal package upgrade would not unexpectedly change the boot stack:

```bash
sudo apt-mark hold \
  linux-image-current-rockchip64 \
  linux-dtb-current-rockchip64 \
  linux-u-boot-bobcat-29x-current
```

Check holds with:

```bash
apt-mark showhold
```

This is conservative. Remove a hold only when you deliberately want to test a kernel/device-tree/U-Boot update and have a recoverable SD-card image.

## Basic update

```bash
sudo apt update
sudo apt upgrade
```

Review the proposed upgrade before accepting it, especially on community images.

## Set the hostname

Use a generic hostname of your choice, for example:

```bash
sudo hostnamectl set-hostname dns-appliance
```

Confirm:

```bash
hostname
```

Continue with [02-networking.md](02-networking.md).
