# Dual Boot Pop!_OS with Windows using systemd-boot
### The ultimate guide for any combination

## Introduction
Pop!_OS uses **systemd-boot** as its boot manager. Most new users don't know how **systemd-boot** works and the fact that it is mostly transparent to the user (as a boot-manager should be), makes it hard for some users to understand. As such a common advice when new users want to dual boot with Windows is to install **grub**. Grub is better known as it is commonly used by other distributions, namely **Ubuntu** and has a visible menu at boot, which new users grow to expect. As such it is common *advice* between new users to install **grub** in order to dual boot Pop!_OS with Windows. This, is **totally unecessary** as not only it removes the ease and simplicity of **systemd-boot** and replaces it with the rather complex configuration of **grub**, but also **grub** has the tedency to break with **Windows updates**, while **systemd-boot** does not. 

### Purpose
The purpose of this guide is to make it easy to install Pop!_OS and Windows in a system and easily select the OS to boot at start up. It covers:

1. Dual boot using a single drive
2. Dual boot using two drives with each OS on its own storage device
3. Installing Pop!_OS first, then Windows
4. Installing Windows first, then Pop!_OS

### Disclaimer
While this is a guide tested many times, the procedures followed include creating/deleting/changing partitions, and as such your data, if you get something wrong, can be lost. Make sure you **backup your data** before you start, and you understand **you do this at your own risk**.

### Prerequisites

Some basic skills are required before you move on. You need to be apt enough in **linux** to complete the followin tasks:

1. Use ```lsblk``` 
2. Mount a partition
3. Copy files **and** folders from the terminal
4. Create Live USB sticks from Windows and Linux
5. Install Pop!_OS and Windows from USB
6. Understand the difference between **mbr** and **gpt** and how to use ```fdisk``` to change disks from on type to the other
7. Understand the difference between **UEFI** and **legacy** modes in BIOS and use your system's bios to check/modify
8. Use your system's bios to change the boot order
9. Use your system's bios to disable **secure boot** and enable AHCI for storage

While these will all be used in this guide, they will be handy when setting up and/or troubleshooting your installation. 

### Not covered
This guide does not cover how to install Pop!_OS, Windows, how to create partitions on either OS, how to resize partitions. 
**This guid does not cover installation on Legacy/Bios systems. This is for UEFI only**.

## Dual booting with separate drives
This is the simplest case. Each operating system is installed separately on its own drive. This requires a minimum of two drives (obviously) and the order of installation does not matter. It is *advisable* to only have one drive installed at a time of installing each OS, so that you avoid confusion. However with Pop!_OS not using **sstemd-boot** rather than **grub**, there is no danger of misplacing the boot loader, so both drives can be connected while installing Pop!_OS, just make sure you select only the drive you want Pop!_OS installed before you install Pop!_OS.

### Installation
Install each OS to its onwn drive. At this point you can boot each OS by selectig the boot device from your BIOS.
At this point Pop!_OS may **or** many **not** provide you with a **menu**. But there is one:

With Pop!_OS selected to boot, when your system shows the manufacturers logo (i.e. during POST), you **spam** or **hold** the **spacebar**. This will bring up the **menu**. This menu does **not** include an option for Windows (yet).

#### How to add an option for Windows in Pop!_OS boot menu

This is the easiest case.

Steps:

1. Boot Pop!_OS
2. Start a terminal
3. Run ```lsblk``` and identify the drive with Pop!_OS and the drive with Windows. Sample output of two fresh installations looks like this:

~~~
otheos@pop-os:~$ lsblk
NAME          MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda             8:0    0 119.2G  0 disk  
├─sda1          8:1    0   498M  0 part  /boot/efi
├─sda2          8:2    0     4G  0 part  /recovery
├─sda3          8:3    0 110.8G  0 part  /
└─sda4          8:4    0     4G  0 part  
  └─cryptswap 253:0    0     4G  0 crypt [SWAP]
sdb             8:16   0 111.8G  0 disk  
├─sdb1          8:17   0   100M  0 part  
├─sdb2          8:18   0    16M  0 part  
├─sdb3          8:19   0 111.2G  0 part  
└─sdb4          8:20   0   505M  0 part 
~~~

In the example above, ```/dev/sda``` is the drive with Pop!_OS and ```/dev/sdb``` is the drive with Windows. You can tell from the mounted partitions of Pop!_OS on ```/dev/sda```. 








**What you want to achieve:**

Install Pop!\_OS after Windows on the same drive. You want a menu to pop up after POST so that you can select Pop or Windows.

**What is happening:**

Pop!\_OS uses systemd-boot to start up. This is not grub. It is simple once you get the concept.

**How to make the menu appear:**

First lets make the menu appear. Normally you need to press the spacebar after POST to make the menu appear. If you want the menu to appear every time, you need to add a timeout to the config file that controls the menu.

This is done by modifying  /boot/efi/loader/loader.conf file to add a timeout, so the file looks like this:

    default Pop_OS-current 
    timeout 5 

This menu will appear for 5 seconds (hint 5 in the line above). If you want to change the default, you know what to do.

If you reboot now, the menu will pop up, but the options you will see are only

* Pop\_OS-current kernel
* Pop\_OS-previous kernel
* UEFI menu

The last option just takes you to your systems UEFI (legacy BIOS not supported)

The two Pop entries are for redundancy. If a new kernel update breaks your system, you can always boot the old one and remove it.

**How to make Windows appear as an option:**

For Windows to appear as an option, systemd-boot requires its EFI files to be in the same partition as those of Pop. You cannot use Windows's EFI partition because it is too small, otherwise, during installation, you could just use that partition for Pop too.

So you will need to copy Windows EFI files onto Pop's EFI partition (that's why when installing its a good idea to make this large, 1GB to be safe).

Find Windows EFI partition and mount it under Pop! so you can copy the files. The Windows partition contains an EFI folder with two subfolders: "Boot" and "Microsoft".

Copy the Microsoft folder to  /boot/efi/EFI

This folder also contains  a "Pop\_OS-fe5b298c-b5ab-4b9d-8476-b5ff61d93baf" folder, along with Recovery, Linux, BOOT, and systemd. The long string after the Pop\_OS will be different in your system.

That's it.

Now the menu will appear as follows:

* Pop\_OS-current kernel
* Pop\_OS-previous kernel
* Windows
* UEFI menu

**What to set UEFI boot options to:**

Set your UEFI to boot from Pop. This will offer you the menu you just made at every boot, and you can boot Windows from it.

**How to make Windows the default boot option:**

You will need to create a little loader configuration file. These live inside /boot/efi/loader/entries.

Create a file named Windows.conf

with content:

    title Windows Boot Manager
    efi \EFI\Microsoft\Boot\bootmgfw.efi

The title can be anything, it appears on the menu at boot. The second line indeed has backwards slashes, just check that the file bootmgfw.efi is indeed in /boot/efi/EFI/Microsoft/Boot/

You can chose Linux on boot from the menu, or by holding L after POST.

\-------------------------------------------------------------------

DISCLAIMER: You do this at your own risk.

&#x200B;

Edit: Tips.

You can reboot from Pop to UEFI (firmware) settings by issuing:

    systemctl reboot --firmware-setup 

or (if you dual boot with Windows), you can reboot to Windows (straight after reboot, no other input required) by issuing:

    systemctl reboot --boot-loader-entry=auto-windows 

If you have multiple kernels you can also change the part after --boot-loader-entry= to do that.

Finally, if you want to boot to Windows after POST, you can just hold "**w**" rather than bring up the menu with **space** and select. For linux you just hold "**l**" (letter L).

&#x200B;

I hope this helps.

&#x200B;
