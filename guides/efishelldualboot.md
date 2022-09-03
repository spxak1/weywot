# Dual boot Windows with Pop!\_OS without copying Windows's efi files

Note: This is slightly advanced, but it is a more elegant solution to copying MS efi files over to Pop's ESP. **It comes with two caveats, see the end!**

## What is this guide?

This is a guide to get to boot Pop with other OS, namely Windows 10/11 or any other distribution, on UEFI systems, that are already preinstalled, or where the user cannot figure out partitioning, or if encryption is used in Pop and as such other OS are on separate drives.

This guide is also the better solution if Pop!\_OS and other OS share the same drive.

## Requirements

* A computer with two (or more) OS installed already
* Internet connection
* A camera (to take a screengrab)
* Basic knowledge of how to get the systemd-boot at boot
* Patience and will to learn, it's not easy

## Principle of operation

### The issue
Systemd-boot can only read files to boot from that are present on the same partition as its own efi stub. While Pop!\_OS makes a large enough ESP, and indeed Windows will use it if installed *after* Pop, if Windows is already installed, or if it lives on a different drive to Pop, then there is no Windows entry in the systemd-boot menu.

### The workaround
The easiest thing is to simply copy Windows efi stub in Pop's ESP. This is the quickest way to get a menu entry for Windows on the systemd-boot menu. This has some advantages and some disadvantages:

#### Advantages

* Zero configuration required
* The entry that appears is not a custom one, but the auto-windows entry which means:
* Holding **w** during boot, boots to windows and holding **l** boots to linux
* You can reboot to Windows from Pop, simply with ```sudo systemctl reboot --boot-loader-entry=auto-windows

#### Disadvantages

* It is a brute force method and involves mounting Windows's ESP which many users can mess up
* Copied files never change, although Windows may actually update its own at its ESP
* Not elegant (if that matters)

Having said all that, this is still the preferred dual boot method if you insist to keep install Windows first (as people still *wrongly* advise for Pop).

### This method
This method makes use of the EFI shell, a shell that works early during boot, before the OS are loaded. With this shell, we can run scripts, and load an OS using its own efi files.

#### The process
* System POSTs
* EFI shell loads
* Unlike systemd-boot, the EFI shell can see *all* FAT32 partitions
* The EFI shell loads an EFI file to boot an OS from any of those partitions

#### What we need to do
* Install EFI shell
* Write the EFI shell script
* Add an entry to systemd-boot menu that points to that script

Let's do it

## Configuration
Note: This guide assumes two OS, each *completely* on its own SSD drive. I will add later a version with two OS on the same SSD (although the slightly more experience users can adapt this one easily).

All the work is done from within Pop.

### Install the EFI shell

Download the file from [here](https://github.com/tianocore/edk2/blob/UDK2018/ShellBinPkg/UefiShell/X64/Shell.efi)
This is a legitimate file, so if in doubt check it comes from tiancore's EDK2 project.

The file downloaded is named ```Shell.efi```. 
Move the file to ```/boot/efi```. **NOT** in ```/boot/efi/EFI```, but the ESP, which is ```/boot/efi```. 

You need root for that. Use ```sudo su```. **Be careful, you're root now!**

~~~
mv Shell.efi /boot/efi
cd /boot/efi
mv Shell.efi shellx64.efi
~~~

The last step is crucial as systemd-boot will not see the file with *correct* name, ```shellx64.efi``` and will automatically create an entry in the menu for it.

### Reboot to the EFI shell

Bring up the menu (spam the space bar after POST) and select EFI Shell.

This will drop you to a screen like this:

![EFI Shell](../assets/efi_shell.jpg)

What we need is to take a picture of this screen, and reboot to Pop.

#### What is on this screen?
This is the shell (at the end there is a prompt and it can take commands, like a linux terminal, but that's for another day).
It starts by listing all the storage devices.
Devices named **FSX**, like FS0, FS1 etc, are partitions that the UEFI can see (i.e Fat32).
Devices named **BLKX**, like BLK0, BLK5 etc are block devices and/or partitions that the UEFI cannot see (ext4, ntfs, btrfs etc).

What we are after is the **alias** of the partition that holds Windows's ESP. We don't know which one it is, but it's one of either FS0, FS1, FS2, FS3, FS4. 

You can (if you understand some basics) figure out which one is the partition we're after. You can see that FS0, sits on SATA device 0x0, while FS3 and FS2 on SATA device 0x1. Which means the first is **sda** and the second **sdb**. Probably! So we will check with the partUUID quoted, which unlike all other notation used here is the **same** in all OS/UEFI etc.

### Reboot to Pop

Bring up a terminal and check the partuuid with:

~~~
lsblk -o name,type,partuuid
 





