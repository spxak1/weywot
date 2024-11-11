# Convert Fedora Workstation (40) to systemd-boot (with ```/boot``` partition)

## TL/DR

~~~
sudo dnf install systemd-boot
sudo bootctl install
sudo dnf install edk2-ext4
sudo mkdir /boot/efi/EFI/systemd/drivers
sudo cp /usr/share/edk2/drivers/ext4x64.efi cp /usr/share/edk2/drivers/ext4x64.efi
sudo reboot
~~~

## Case study

Fedora installs with ```grub``` out of the box. However Fedora uses loader files for grub, as it would for ```systemd-boot```.
This is probably also why ```grub-customizer``` doesn't work with Fedora (but I have not confirmed this, so it may very well be wrong).

The default installation of Fedora with ```grub``` creates a separate ```/boot``` partition. It is on this partition that all boot files (except for the EFI stub) are kept.

~~~
root@brahe:/boot# ls
config-6.8.5-301.fc40.x86_64
efi
EFI
grub2
initramfs-0-rescue-fd4a0a17b4024e6cb4139c8b1d44dfe6.img
initramfs-6.8.5-301.fc40.x86_64.img
loader
lost+found
refind_linux.conf
symvers-6.8.5-301.fc40.x86_64.xz
System.map-6.8.5-301.fc40.x86_64
vmlinuz-0-rescue-fd4a0a17b4024e6cb4139c8b1d44dfe6
vmlinuz-6.8.5-301.fc40.x86_64
~~~

The two kernes ```vmlinuz-6.8.5-301.fc40.x86_64``` and ```vmlinuz-0-rescue-fd4a0a17b4024e6cb4139c8b1d44dfe6``` are there, along with their initrd files, and the ```loader``` folder is also there.

Inside the ```loader``` folder we have the ```entries``` folder and in that we have:
~~~
root@brahe:/boot/loader/entries# ls
fd4a0a17b4024e6cb4139c8b1d44dfe6-0-rescue.conf
fd4a0a17b4024e6cb4139c8b1d44dfe6-6.8.5-301.fc40.x86_64.conf
~~~

The two loader config files for each of the two kernels is there:
~~~
root@brahe:/boot/loader/entries# cat fd4a0a17b4024e6cb4139c8b1d44dfe6-6.8.5-301.fc40.x86_64.conf
title Fedora Linux (6.8.5-301.fc40.x86_64) 40 (Workstation Edition)
version 6.8.5-301.fc40.x86_64
linux /vmlinuz-6.8.5-301.fc40.x86_64
initrd /initramfs-6.8.5-301.fc40.x86_64.img
options root=UUID=81489d94-dba1-4898-926a-a1211da509ca ro rootflags=subvol=root rhgb quiet 
grub_users $grub_users
grub_arg --unrestricted
grub_class fedora
~~~

All these files (kernel, initrd, loader folder and entry configs), on a default ```systemd-boot``` install are located in the EFI partition, inside ```/boot/efi``` (if that's the mount point for it, as it is with Fedora, but not with Arch -it's ```/efi```)

## The problem

```systemd-boot``` cannot read file on partitions outside of its own. So neither the loader files, nor the kernel/initrds will be loaded. It just won't work.

## The fix

Since ```systemd-boot``` 250, it can load EFI drivers so that it can access different partitions with different filesystems to the default FAT32.
This is documented in the [systemd-boot github page here](https://github.com/systemd/systemd/blob/71e5a35a5be99a1f244d38ee1dfe7db39242a977/NEWS#L3177C1-L3181C38).

Fedora uses ```ext4``` for the ```/boot``` partition, so this guide is currently limitted to ```ext4``` only. 

The EFI driver for the filesystem should be found in ```EFI/systemd/drivers``` folder. It will be loaded **before** the loader entries, and that's a good thing because these too are in the ```/boot``` folder.

## Application

### Check the partitions' GUID

How dows ```systemd-boot``` know where is the ```/boot``` partition? It looks for the correct GUID. These are listed at the [updated discoverable partitions specification](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/).
The ```/boot``` partition is what is known system-wise as ```XBOOTLDR``` (from extended boot loader) and has a GUID of ```bc13c2ff-59e6-4262-a352-b275fd6f7172```.

Check your partitions have the correct GUID's. Apparently Fedora has a bug and anacoda, during installation, may not give the correct GUIDs.

~~~
root@brahe:~# lsblk -o +parttype
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS PARTTYPE
zram0       252:0    0     8G  0 disk [SWAP]      
nvme0n1     259:0    0 238.5G  0 disk             
├─nvme0n1p1 259:1    0   600M  0 part /boot/efi   c12a7328-f81f-11d2-ba4b-00a0c93ec93b
├─nvme0n1p2 259:2    0     1G  0 part /boot       bc13c2ff-59e6-4262-a352-b275fd6f7172
└─nvme0n1p3 259:3    0 236.9G  0 part /home       0fc63daf-8483-4772-8e79-3d69d8477de4
                                      /
~~~
There it is, ```/dev/nvme0n1p2``` in my case. While you're here, check that the GUID for the EFI partition and the rest of data check out. They do.

### Install systemd-boot

~~~
sudo dnf install systemd-boot-unsigned
~~~

This should do it.

#### A note on sdubby vs grubby

On default ```systemd-boot``` installations of Fedora, the application ```sdubby``` is used as a replacement for ```grubby```. What this does is to place the kernel/initrd and loader files in the **correct** location for ```systemd-boot```, which is on the ```EFI partition```. Since your EFI partition is rather small, as is the case when you use ```grub``` by default, you may want to keep your kernel/initrd and loader files on the ```/boot``` partition. ***Keeping** ```grubby``` will do this for you.

If you (have to) remove ```grubby``` and install ```sdubby```, after the first kernel upgrade, all files are moved to the EFI partition, so the EFI drivers **are no longer needed**.

You could technically install Fedora, install ```systemd-boot``` and replace ```grubby``` with ```sdubby```, do a ```dnf update``` to install the new kernel, and completely save yourself from all this process mentioned here.

In any event, that's how it's done, just *understand the difference*.
~~~
sudo dnf remove grubby
sudo dnf install sdubby
~~~

#### Install systemd-boot

To install the boot loader, do:
~~~
sudo bootctl install
~~~

This will place the EFI stub in the EFI partition:
~~~
root@brahe:/boot/efi/EFI# ls systemd/
systemd-bootx64.efi
~~~

This has also created a boot option in your bios named ```Linux Boot Manager```.

Now, if you reboot at this point, and select ```Linux Boot Manager```, depending on your bios, you will see either:

* A menu with the only option to enter the uefi menu (the bios)
* Nothing, the system will just proceed to the next working boot option, probably adding a delay to your boot process

The reason for that is that ```systemd-boot``` cannot see the loader files.

## Install the EFI driver

First make the folder for the drivers

~~~
sudo mkdir /boot/efi/EFI/systemd/drivers
~~~

There are 3 different drivers I've tried:

* EFIFS
* rEFInd
* EDK2

### The EFIFS driver doesn't load

EFIFs provides a comprehensive list of drivers for many filesystems. You can install it with ```sudo dnf install efifs``` and it will place an ```efifs``` folder in ```/boot/efi/EFI```.

~~~
root@brahe:/boot/efi/EFI# ls efifs/
affs.efi   cbfs.efi     ext2.efi  hfsplus.efi    minix2.efi     minix.efi   odc.efi       sfs.efi      ufs1_be.efi  zfs.efi
afs.efi    cpio_be.efi  f2fs.efi  iso9660.efi    minix3_be.efi  newc.efi    procfs.efi    squash4.efi  ufs1.efi
bfs.efi    cpio.efi     fat.efi   jfs.efi        minix3.efi     nilfs2.efi  reiserfs.efi  tar.efi      ufs2.efi
btrfs.efi  exfat.efi    hfs.efi   minix2_be.efi  minix_be.efi   ntfs.efi    romfs.efi     udf.efi      xfs.efi
~~~

However, I **have not managed to get systemd-boot to use these drivers**. Obviously you need to copy those you need to your ```systemd/drivers``` folder.
But still, ```systemd-boot``` will not (pre)load them.

I can manually load the ```ext2.efi``` driver from my HP crappy (boot to efi file) bios, or using UEFI utilities (not covered here). Once the driver is loaded, I can load ```systemd-boot``` and it will immediately see the loader files and produce a menu to boot Fedora from.
So the system works, but ```systemd-boot``` will **not load the EFIFS driver**.

### The rEFInd driver doesn't work

You can install ```rEFInd``` with ```sudo dnf install rEFInd``` and then install the bootmanager with ```sudo refind-install```. 

This will place all files in the EFI partition.

~~~
root@brahe:/boot/efi/EFI# ls -R refind
refind:
BOOT.CSV  drivers_x64  icons  keys  refind.conf  refind_x64.efi  vars

refind/drivers_x64:
ext4_x64.efi

[... more files follow ... truncated]
~~~

This will also create a new boot option in your bios, named ```rEFInd Boot Manager```. But that's not what you're here for, althoug ```rEFInd``` is a great boot manager.

Refind also placed an ```ext4``` driver, but sadly it doesn't work. It won't load automatically by ```systmed-boot``` and even if I load it, ```systemd-boot``` won't see the loaders or the ```/boot``` partition.
I will revisit this later, as I may have missed something.

### EDK2 Works!

There is more to EDK2 than its ext4 driver. You also get the uefi shell tools with it. Not required here but I mention it anyway.

Install with:
~~~
sudo dnf install edk2-ext4
~~~

The driver is placed in ```/usr/share/edk2/drivers/```.

So:
~~~
sudo cp /usr/share/edk2/drivers/ext4x64.efi /boot/efi/EFI/systemd/drivers/
~~~

You only need ```ext4x64.efi``` as the other two are for other architectures.

#### UEFI shell

You can also copy the shell tool to have access to it from ```systemd-boot``` menu:
~~~
sudo cp /usr/share/edk2/ovmf/Shell.efi /boot/efi/shellx64.efi
~~~

Note it's copied in the ```/boot/efi``` folder, not ```/boot/efi/EFI```. The name change is required.


That's it. If you reboot now, ```systemd-boot``` will preload the driver, see the loader config files and boot the kernel from ```/boot```. Success.

Note, if you only need to install ```Shell.efi```, you can just do:

~~~
sudo dnf install edk2-ovmf-20240524-3.fc39.noarch
~~~

And you can find it in ```/usr/share/edk2/ovmf```.


## Wrap up

The arch wiki ([point 3.2 here](https://wiki.archlinux.org/title/systemd-boot)) suggests this:

> As of version 250, systemd ships with systemd-boot-update.service. Enabling this service will update the bootloader upon the next boot.

I haven't looked into what this does, but I will soon.








