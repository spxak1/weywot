# How to boot directly to the Kernel (EFISTUB)
This is a quick guide on how to boot to Pop_OS without systemd_boot, or any other bootmanager, simply by loading directly the linux kernel.

## Why?
For fun, proof of concept and perhaps to shave a couple of seconds from your boot time. But mostly for the former two.

## Sources
* **Inspiration** came from [this redditt post](https://www.reddit.com/r/linuxquestions/comments/ska8ed/linux_kernel_as_efi_loader/hvjuf5c/?context=3), so thanks to /u/flechin.
* **Guides** used, as always the excellent [arch wiki](https://wiki.archlinux.org/title/EFISTUB#efibootmgr) and as always a bit of Google search for bits and bobs.

## Disclaimer
Provided you don't delete any boot entries, this process does not involve and file copy/paste/deletion and as such it's harmless. 
If the boot entry you create doesn't work, your UEFI either will move to the next available boot entry, or get **stuck** at the OEM logo screen. If the latter happens, power off, restart, and go to the bios and manually select a different entry. Then delete the entry you created and try again.

## Principle
The linux kernel can be loaded directly from UEFI, without the need for a boot manager such as *grub* or *systemd_boot* or *rEFInd*.

**Pop!_OS**, and the use of *systemd_boot* means that the **kernel** and **initfamfs** are already placed in the **ESP** and as such you need just to create the bios boot entries. 

This means that once these are created, you don't need to move any files in and out of the ESP! **Pop!_OS** is great!

## How
Simple, we add the entries to the UEFI using ```efibootmgr```.

### Find the information
Another blessing of **systemd_boot** is that it creates simple loader files where all the info is stated. For instance, for my *current kernel*, if I look in ```/boot/efi/loader/entries/Pop_OS-current.conf``` I have:

~~~
title Pop!_OS
linux /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz.efi
initrd /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/initrd.img
options root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off intel_pstate=disable intel_iommu=igfx_off
~~~

Everything I need is there: The path and name to the kernel and initrd and all the kernel options currently used!

All you need is to use these three lines

### The command:
Here is (the very long) command:
~~~
efibootmgr -c -d /dev/sda -p 1 -L "Pop Current" -l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz.efi --unicode 'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img' --verbose
~~~

### Let's break it down:

* ```-c``` creates the entry
* ```-d``` names the device where the **ESP** is located. 
* ```-p 1``` states the partition. This is the ```/boot/efi``` partition and all following paths are relative to this one!
* ```-L "Pop Current"``` creates the label. This is the name you will see in your UEFI for this boot entry. In this case the current kernel for Pop.
* ```-l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz.efi``` this is where the kernel is located. I just **copy  the fist line of the loader file shown above**. You can find this as follows:

Change to *root* (be careful now!) with ```sudo su``` and go to ```/boot/efi/EFI```. Look at the name of your ```Pop_OS-XXXXXX-XXXXX-XXXXX-XXXX-XXXXXXXX``` folder. Use that, not mine. The kernel name ```vmlinuz.efi``` is the same, as everytime there is a kernel update, the OS makes a copy of the new (**current**) kernel to that folder under that name! 

* ```--unicode``` sets the text ouput

Everything else is now the **kernel options**. These may be different for your usecase, but **these are the minimum required**.

* ```'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b rw initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img'```. These state the location of the *root* partition, and the location of the *initrd*. The *initrd* file is in the **same location as the kernel**. But **notice how the path is written** with forward slashes (\\) rather than backward slashes (/) as expected. 

For the **root** partition UUID, you can do: ```blkid``` and see it in the output, e.g. ```/dev/sda3: UUID="f925d79c-a485-43cf-8cd2-2d24cdea718b" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="63b38b7c-c4d9-4452-9403-127034ea8ebd"```. You need the **UUID** not the **PARTUUID**. 

Again, the **simplest way** is to **copy the 3rd line of the loader file, as shown above**.

* ```--verbose``` is just there to show you the added entry once the command completes.

### More kernel options

You can of course add kernel options as you please, but remember **everytime you want to change an option, you need to delete and re-create the entry**. So yes, it's cumbersome.

### How to delete an entry
If you mess up, or if you want to remove an older entry and create a new one (because e.g. you want a different kernel option), you can do:

~~~
sudo efibootmgr
BootCurrent: 0015
Timeout: 2 seconds
BootOrder: 0015,000D,000E,0014,0006,0011,0013
Boot000B* Fedora
Boot000C* Linux Boot Manager
Boot000D* Pop Current
Boot000E* Pop Old
Boot000F* ubuntu
Boot0010* rEFInd Boot Manager
Boot0011* Windows Boot Manager
Boot0012* manjaro
Boot0013* Ubuntu Boot Manager
Boot0014* Pop Recovery
Boot0015* Pop Single
~~~~

Find the one you want deleted, e.g. **Pop Current** and do:

~~~
sudo efibootmgr -b 0D -B
~~~

The **0D** part is the last two digits of the **Boot000D** in front of the entry in the output above.

## My entries

I like having 4 entries for **Pop!_OS**

* Current Kernel
* Old Kernel
* Recovery
* Single user mode

Here they are:
### Current
~~~
efibootmgr -c -d /dev/sda -p 1 -L "Pop Current" -l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz.efi --unicode 'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off rw initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img' --verbose
~~~
### Old
efibootmgr -c -d /dev/sda -p 1 -L "Pop Old" -l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz-previous.efi --unicode 'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off rw initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img-previous' --verbose
### Recovery
efibootmgr -c -d /dev/sda -p 1 -L "Pop Recovery" -l /EFI/Recovery-7827-FA9E/vmlinuz.efi --unicode 'boot=casper hostname=recovery userfullname=Recovery username=recovery live-media-path=/casper-7827-FA9E live-media=/dev/disk/by-partuuid/a9fbe686-9f08-487c-9bc9-db094845b8c2 noprompt initrd=\EFI\Recovery-7827-FA9E\initrd.gz' --verbose
### Single user (with current kernel)
efibootmgr -c -d /dev/sda -p 1 -L "Pop Single" -l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz.efi --unicode 'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off rw single initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img' --verbose



