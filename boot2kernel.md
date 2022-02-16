# How to boot directly to the Kernel (EFISTUB)
This is a quick guide on how to boot to Pop_OS without systemd-boot, or any other bootmanager, simply by loading directly the linux kernel.

For **Fedora** and **Ubuntu** see the end.
![image](https://user-images.githubusercontent.com/29977030/152643674-3d052134-3377-4f9c-b6d0-2bec800626e4.png)


## Why?
For fun, proof of concept and perhaps to shave a couple of seconds from your boot time. But mostly for the former two.

## Sources
* **Inspiration** came from [this redditt post](https://www.reddit.com/r/linuxquestions/comments/ska8ed/linux_kernel_as_efi_loader/hvjuf5c/?context=3), so thanks to /u/flechin.
* **Guides** used, as always the excellent [arch wiki](https://wiki.archlinux.org/title/EFISTUB#efibootmgr) and as always a bit of Google search for bits and bobs.

## Disclaimer
Provided you don't delete any boot entries, this process does not involve and file copy/paste/deletion and as such it's harmless. 
If the boot entry you create doesn't work, your UEFI either will move to the next available boot entry, or get **stuck** at the OEM logo screen. If the latter happens, power off, restart, and go to the bios and manually select a different entry. Then delete the entry you created and try again.

## Principle
The linux kernel can be loaded directly from UEFI, without the need for a boot manager such as *grub* or *systemd-boot* or *rEFInd*.

**Pop!_OS**, and the use of *systemd-boot* means that the **kernel** and **initfamfs** are already placed in the **ESP** and as such you need just to create the bios boot entries. 

This means that once these are created, you don't need to move any files in and out of the ESP! **Pop!_OS** is great!

## How
Simple, we add the entries to the UEFI using ```efibootmgr```.

### Find the information
Another blessing of **systemd-boot** is that it creates simple loader files where all the info is stated. For instance, for my *current kernel*, if I look in ```/boot/efi/loader/entries/Pop_OS-current.conf``` I have:

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
efibootmgr -c -d /dev/sda -p 1 -L "Pop Current" -l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz.efi --unicode 'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img' --verbose
~~~
### Old
~~~
efibootmgr -c -d /dev/sda -p 1 -L "Pop Old" -l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz-previous.efi --unicode 'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img-previous' --verbose
~~~
### Recovery
~~~
efibootmgr -c -d /dev/sda -p 1 -L "Pop Recovery" -l /EFI/Recovery-7827-FA9E/vmlinuz.efi --unicode 'boot=casper hostname=recovery userfullname=Recovery username=recovery live-media-path=/casper-7827-FA9E live-media=/dev/disk/by-partuuid/a9fbe686-9f08-487c-9bc9-db094845b8c2 noprompt initrd=\EFI\Recovery-7827-FA9E\initrd.gz' --verbose
~~~
### Single user (with current kernel)
~~~
efibootmgr -c -d /dev/sda -p 1 -L "Pop Single" -l /EFI/Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b/vmlinuz.efi --unicode 'root=UUID=f925d79c-a485-43cf-8cd2-2d24cdea718b ro quiet loglevel=0 systemd.show_status=false splash mitigations=off single initrd=\EFI\Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b\initrd.img' --verbose
~~~


## Fedora
For distros that use grub, and as such keep their kernels and initrd files in the ```/boot``` partition (or directory), there is very little difference. 
The only issue is that you need to **copy the kernel and initrd** to the **ESP** after **every kernel upgrade**.

I find all the info in the loader entry fedora makes in ```/boot/loader/entries```, which looks like this (this is the same systemd-boot entry as before):
~~~
title Fedora Linux (5.16.5-200.fc35.x86_64) 35 (Workstation Edition)
version 5.16.5-200.fc35.x86_64
linux /boot/vmlinuz-5.16.5-200.fc35.x86_64
initrd /boot/initramfs-5.16.5-200.fc35.x86_64.img
options root=UUID=62a337f0-ae6b-4d17-83bb-8f1b86345e20 ro rhgb quiet
grub_users $grub_users
grub_arg --unrestricted
grub_class fedora
~~~

The kernel and initrd names, as well as all the kernel options and the partition UUID. When ```grub``` is updated, this config file is updated too.

I have a very basic script that does this (needs ```sudo``` to run):
~~~
#!/bin/bash
esp=/boot/efi/EFI/fedora
loc=/boot/loader/entries
loader=`ls $loc -ltr | tail -1 | cut -d " " -f 9`
kern=`cat $loc/$loader | grep linux | cut -d " " -f 2`
init=`cat $loc/$loader | grep initrd | cut -d " " -f 2`
echo $loader $kern $init
#\cp $kern $esp/vmlinuz.efi
#\cp $init $esp/initrd.img
~~~
**Note:** *The copy commands are hashed, and only the echo command to see that the script actually detects the correct files is left to run. If what you see is correct, unhash the copy commands and run it again.*

This copies the latest kernel and initrd to Fedora's ESP ```/boot/efi/EFI/fedora```, under the same name ```vmlinuz.efi``` and ```initrd.img``` repsectively. So the boot entry always points to these names.

This scripts needs to run **after every kernel update**

Once this is done, you just create the boot entry:
~~~
sudo efibootmgr -c -d /dev/sda -p 1 -L "Fedora Kernel" -l /EFI/fedora/vmlinuz.efi --unicode 'root=UUID=62a337f0-ae6b-4d17-83bb-8f1b86345e20 ro quiet splash mitigations=off initrd=\EFI\fedora\initrd.img' --verbose
~~~

You **only need to run this once** after fedora installs. Or re-run it if for some reason your boot entry is deleted (Windows update?).

## Ubuntu
Ubuntu doesn't use loader conf files, but it makes links to the latest kernel and initrd inside of ```/boot```, named ```vmlinuz``` and ```initrd.img``` respectively. These are updated to the latest installed kernel after every update, so it's simply a task of copying them to the ESP.

This little script does it:
~~~
#!/bin/bash
esp=/boot/efi/EFI/ubuntu
loc=/boot
\cp -H $loc/vmlinuz $esp/vmlinuz.efi
\cp -H $loc/initrd.img $esp/initrd.img
~~~

You can find the UUID of the **root** partition either with ```lsblk -o name,fstype,mountpoint,uuid | grep "/ "```

Sample output:
~~~
└─sda8 ext4     /                            6496be90-810c-4b5c-bc7f-624aa51c5d9d
~~~

or you can look inside ```/boot/efi/EFI/ubuntu/grub.cfg```.

Mine looks like this:
~~~
search.fs_uuid 6496be90-810c-4b5c-bc7f-624aa51c5d9d root hd0,gpt8 
set prefix=($root)'/boot/grub'
configfile $prefix/grub.cfg
~~~

Finally for your kernel options you need to look in ```/etc/default/grub```. 
Example:
~~~
# cat /etc/default/grub | grep CMDLINE
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash mitigations=off"
GRUB_CMDLINE_LINUX=""
~~~

So you build your ```efibootmgr``` command as before with the new info:

~~~
sudo efibootmgr -c -d /dev/sda -p 1 -L "Ubuntu Kernel" -l /EFI/ubuntu/vmlinuz.efi --unicode 'root=UUID=6496be90-810c-4b5c-bc7f-624aa51c5d9d ro quiet splash mitigations=off initrd=\EFI\ubuntu\initrd.img' --verbose
~~~

## Manjaro

Manjaro doesn't create links and doesn't use loader configs. So the script which copies the kernel and initrd should also find the latest kernel and initrd in ```/boot```. 

TBD.





