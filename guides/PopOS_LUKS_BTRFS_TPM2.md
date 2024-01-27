# Install PopOS on custom partition layout with LUKS, BTRFS with snapshot and TPM2
WIP

POP with LUKS and BTRFS with snapsot from here: https://mutschler.dev/linux/pop-os-btrfs-22-04/

Differences:
* No first install
* Manually partition 2GB ESP, 4GB RECOVERY, then from gnome-disks, 90GB ext4 with LUKS.
* You need to create crypttab after installation with the partitions (not the mapper) UUID.

LUKS wit TPM2 from here: https://askubuntu.com/questions/1470391/luks-tpm2-auto-unlock-at-boot-systemd-cryptenroll

With clevis.

Only downside: the LUKS password prompt still appears.

Full write up later. With and without BTRFS.
