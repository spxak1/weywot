# Boot from SD Card on a system without support to boot from SD Reader

Typical case is most Laptops that have the SD Card Reader connected via PCIe rather than USB. Laptops with SD Card Readers connected via USB should boot fine anyway.

With information from [this post](https://ubuntuforums.org/showthread.php?t=986126&page=3).

## Process
Since the SD Card cannot be accesses by the BIOS/UEFI at boot, the bootloader needs to be on a separate, accessible drive. This can be an SSD/HDD or a USB.

* Start installation of the OS in custom mode (currently only tested with Pop, easy with systemd-boot)
* Create (or use) the ESP ```/boot/efi``` on the accessible device
* Create all other partitions on SD card
* Do not reboot
* Chroot (follow instructinos from [here](https://support.system76.com/articles/bootloader/) for UEFI/systemd-boot)
* Add SD Card drivers to ```initramfs``` so that once the EFI stub is loaded the system can read the SD card
* Create the new initramfs and copy it to the ESP
* Reboot

## Creating the new initramfs

**Note:** Previous steps omitted as they are trivial

After installation prepare for chroot:

Mount the ```/``` (root) partition:
~~~
sudo mount /dev/mmcblk0p1 /mnt
~~~

Mount the ESP:
~~~
sudo mount /dev/sda1 /mnt/boot/efi
~~~

Mount auxiliary partitions and chroot:
~~~
for i in dev dev/pts proc sys run; do sudo mount -B /$i /mnt/$i; done
sudo cp -n /etc/resolv.conf /mnt/etc/
sudo chroot /mnt
~~~

Now edit ```/etc/initramfs-tools/modules``` (note this is on your chroot system, not the booted USB) to add:
~~~
mmc_block
sdmod
~~~

Save and exit and rebuild the initramfs with ```update-initramfs -c -k all```. This will also copy the new initramfs file to the ESP.
You can check in ```/boot``` and in ```/boot/efi/EFI/Pop_XXXXXXX``` for the creation dates (```ls -l```) and note that ```initrd.img``` should have the current date and time.

Exit chroot with ```exit``` and reboot.
