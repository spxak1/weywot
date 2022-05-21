# Dual Boot Pop!_OS with Windows using systemd-boot
### The ultimate guide for any combination

**EXTREMEY SHORT TL:DR**: If you know what you're doing - The absolute quickest:

1. ```sudo apt install os-prober```
2. ```sudo os-prober```. The output is ```/dev/sdb1@/efi/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager:Windows:efi```
3. ```sudo mount /dev/sdb1 /mnt``` (you can find your drive in the first part of the os-prober's output)
4. ```sudo cp -ax /mnt/EFI/Microsoft /boot/efi/EFI``` (you can find the folder after the word ```efi``` in os-prober's output. It's always ```Microsoft``` but you need capital ```EFI``` when copying.
5. Reboot. Spam your spacebar for the menu. Select with arrows, add timeout with "t" or reduce with "T" (+/- also work), select default with "d". Hold "l" to boot linux after POST or "w" to boot Windows after POST without visiting the menu.


**TL:DR**: Dual boot from the same drive with Windows and Pop!_OS already installed: See **4. TL:DR** at the end of this document.

## Abstract
To dual boot Windows and Pop!_OS with a menu, both operating systems' EFI files need to be in the same FAT32 partition. This guide elaborates on how to either install OS's using the same EFI partition or **copy Windows's EFI ```Microsoft``` folder into Pop!_OS's ```/boot/efi/EFI```**. 

## 1. Introduction
Pop!_OS uses **systemd-boot** as its boot manager. Most new users don't know how **systemd-boot** works and the fact that it is mostly transparent to the user (as a boot-manager should be), makes it hard for some users to understand. As such a common advice when new users want to dual boot with Windows is to install **grub**. Grub is better known as it is commonly used by other distributions, namely **Ubuntu** and has a visible menu at boot, which new users grow to expect. As such it is common *advice* between new users to install **grub** in order to dual boot Pop!_OS with Windows. This, is **totally unecessary** as not only it removes the ease and simplicity of **systemd-boot** and replaces it with the rather complex configuration of **grub**, but also **grub** has the tendency to break with **Windows updates**, while **systemd-boot** does not. 

Check your system is in UEFI mode with ```mount | grep efivars``` and expect an ouput of ```efivarfs on /sys/firmware/efi/efivars type efivarfs (rw,nosuid,nodev,noexec,relatime)```. 

### 1.1 Purpose
The purpose of this guide is to make it easy to install Pop!_OS and Windows in a system and easily select the OS to boot at start up. It covers:

1. Dual boot using a single drive
2. Dual boot using two drives with each OS on its own storage device
3. Installing Pop!_OS first, then Windows
4. Installing Windows first, then Pop!_OS

### 1.2 Disclaimer
While this is a guide tested many times, the procedures followed include creating/deleting/changing partitions, and as such your data, if you get something wrong, can be lost. Make sure you **backup your data** before you start, and you understand **you do this at your own risk**.

### 1.3 Prerequisites

Some basic skills are required before you move on. You need to be apt enough in **linux** to complete the following tasks:

1. Use ```lsblk``` 
2. Mount a partition
3. Copy files **and** folders from the terminal
4. Create Live USB sticks from Windows and Linux
5. Install Pop!_OS and Windows from USB
6. Understand the difference between **mbr** and **gpt** and how to use ```fdisk``` to change disks from one type to the other
7. Understand the difference between **UEFI** and **legacy** modes in BIOS and use your system's bios to check/modify
8. Use your system's bios to change the boot order
9. Use your system's bios to disable **secure boot** and enable AHCI for storage

While these will all be used in this guide, they will be handy when setting up and/or troubleshooting your installation. 

### 1.4 Not covered
This guide does not cover how to install Pop!_OS, Windows, how to create partitions on either OS, how to resize partitions. 
**This guide does not cover installation on Legacy/Bios systems. This is for UEFI only**.

### 1.5 Basic concept
**Systemd-boot** is simple. It will boot any OS that has an EFI entry (with the boot file) in ```/boot/efi```. All this guide does is describe the process of copying such files. 

### 1.6 Basic use of systemd-boot menu
Here are all the options you have at the **menu** of **systemd-boot** at start-up. To bring the menu up at boot, you need to **spam** or **hold** the **spacebar** during **POST** (that's when your PC's logo appears on the screen. Once the menu appears you can press:

* **d**: this changes the **default** boot option. A ```=>``` sign appears in front of the selection to show it's default.
* **e**: edit the boot parameters (if you want to add kernel parameters) and see the boot instruction.
* **t**: increase the menu **timeout**.
* **T**: decrease the menu **timeout** (Shift+T).
* **v**: shows the version of systemd-boot

Finally you can supersede the boot order and choose to boot Windows or Pop!_OS by holding or spamming at POST:

* **w**: this will boot Windows
* **l**: this will boot Linux (Pop!_OS)

## 2. Dual booting with separate drives
This is the simplest case. Each operating system is installed separately on its own drive. This requires a minimum of two drives (obviously) and the order of installation does not matter. It is *advisable* to only have one drive installed at a time of installing each OS, so that you avoid confusion. However with Pop!_OS not using **systemd-boot** rather than **grub**, there is no danger of misplacing the boot loader, so both drives can be connected while installing Pop!_OS, just make sure you select only the drive you want Pop!_OS installed before you install Pop!_OS.

### 2.1 OS installation
Install each OS to its own drive. At this point you can boot each OS by selecting the boot device from your BIOS.
At this point Pop!_OS may **or** many **not** provide you with a **menu**. But there is one:

With Pop!_OS selected to boot, when your system shows the manufacturers logo (i.e. during POST), you **spam** or **hold** the **spacebar**. This will bring up the **menu**. This menu does **not** include an option for Windows (yet).

### 2.2 How to add an option for Windows in Pop!_OS boot menu

This is the easiest case. All you need to do is to copy the EFI files of Windows to Pop!_OS's EFI partition.

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

In the example above, ```/dev/sda``` is the drive with Pop!_OS and ```/dev/sdb``` is the drive with Windows. You can tell from the mounted partitions of Pop!_OS on ```/dev/sda```. You can also see here that Pop!_OS's EFI partition is mounted at ```/boot/efi``` and its EFI files are located in ```/boot/efi/EFI```. 

4. Identify the EFI partition of Windows. This is typically around 100MB for starnard installations and is typically the first partition in the drive. In the example above, this is partition ```/dev/sdb1```. Alternatively, you can run ```sudo os-prober``` (install it first with ```sudo apt install os-prober```) and that will give you a line of where Window's EFI is, such as ```/dev/sdb1@/efi/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager:Windows:efi```. You can see that ```/dev/sdb1``` is Windows EFI partition, and specifically the files you need are in the ```Microsoft``` folder inside ```efi``` (note, this is ```EFI``` but in fat32 is not case sensitive).
5. Mount the EFI partition of Windows. Typically you can type ```sudo mount /dev/sdb1 /mnt```. 
6. Copy the EFI files of Windows to Pop!_OS's EFI partition. The EFI files of Windows are in the folder ```/mnt/EFI/Microsoft```. You will need the **complete** ```Microsoft``` folder copied in ```/boot/efi/EFI```. So:
~~~
otheos@pop-os:~$ sudo mount /dev/sdb1 /mnt
otheos@pop-os:~$ cd /mnt
otheos@pop-os:/mnt$ ls
EFI
otheos@pop-os:/mnt$ cd EFI
otheos@pop-os:/mnt/EFI$ ls
Boot  Microsoft
otheos@pop-os:/mnt/EFI$ sudo cp -ax Microsoft /boot/efi/EFI
~~~
At this point you are done. You can check the folder is where it should be:
~~~
otheos@pop-os:/mnt/EFI$ sudo ls /boot/efi/EFI
BOOT   Microsoft				    Recovery-8138-A6FE
Linux  Pop_OS-eeacf7ce-54c4-47ac-a595-2c701aa28e2c  systemd
~~~
Note: You can only see the contents of this folder as *root* as such ```sudo``` is required. You can see the ```Microsoft``` folder is now present. 

7. You are done. You can now reboot your system and check in the **menu** that there is an option named **Windows Boot Manager**. Select it and you can boot to Windows.

**Note**: Your bios may re-read the EFI options offered in the boot manager and may place the new EFI entry for Windows first. If your system boots straight to Windows after restart, reboot to Bios and select **Pop!_OS** as the first choice to boot.

## 3. Dual booting from the same drive

### 3.1 Install Pop!_OS first, Windows second (easiest and recommended)

See my video here: https://www.youtube.com/watch?v=Fw3fQQmlXEs

If you're installing on a fresh drive, installing Pop!_OS first is the easiest option. Follow these steps to get a **dual boot menu**.

1. Install Pop!_OS as per normal. You can partition the drive before installation and do a custom installation. This will have the space for Windows alocated at this point and you do not need to move and resize partitions after. But you may end up without a recovery partition. Practice, see what works for you. 
2. If you installed the default way, **do not reboot**.
3. Start ```gparted``` and resize/move as required to make space for Windows. The Windows installer will have to find empty space to install to. You can format that space to NTFS or leave it unformatted. If formatted, you get the benefit of Windows **not** creating the smaller partitions and as such you can then adjust space between Pop and Windows. If you don't format, Windows will create two more smaller partitions which are impossible to move and as such you cannot adjust the space afterwards. See the video with formatting [here](https://www.youtube.com/watch?v=Fw3fQQmlXEs) and without formatting [here](https://www.youtube.com/watch?v=Fw3fQQmlXEs).
4. Start the Windows installation, and select the empty space to install to. Windows will **by default** install its EFI folder in the pre-existing EFI partition that Pop!_OS uses. This means that all EFI files will now be in the same place as required for systemd-boot to show Windwos in the **menu**. 
5. Upon reboot (Windows requires several) you will need to manually select Windows. Either fire up the menu and make Windows default (see introduction), or hold **w** on every reboot, or make Windows the default in your bios at this stage.
6. If you already have Pop!_OS as your only OS and want to install Windows, you will need to **boot from USB** and start at **step 3** above.
7. Once the Windows installation is complete, adjust your boot order in the bios to Pop!_OS, and use the **menu** as required.

### 3.2 Install Pop!_OS second, Windows installed first (most common case for people adding Pop to their systems)
This is the most common case for new users, and as such I will spend some time explaining with more detail. 

#### 3.2.1 Starting without OS
If you start with a clean drive, I would strongly suggest installing Pop!_OS first and follow the according steps. If you **have** to install Windows first, you have two options.

##### 3.2.1.1. Install Windows with **planning** for Pop!_OS (hard and redundant as you should install Pop first)

All the **planning** is, is to install Windows with a **larger** EFI partition so that you can use it also for Pop!_OS. Windows's EFI partition is by default only 100MB and it is as a result too small for more than OS to store its EFI files. If you make this larger, say 512MB (I would advise 1GB for extra space), you can then use this partition for all your OS's. You can do that following [this guide here](https://www.ctrl.blog/entry/how-to-esp-windows-setup.html). 

Once you have Windows installed with a large EFI partition you can install Pop!_OS. Simple steps include:
1. Boot from Live USB.
2. Go through the step by step screens.
3. Select custom and resize/move partitions to make as much room as needed for Pop!_OS. 
4. Go back to the installer and select partitions. Select **the EFI partition of Windows** and set it to ```/boot/efi``` but **DO NOT FORMAT**. 
5. Select your ```/``` partition and install. If you need a recovery partition see the note in the next case.
6. Complete and reboot, you should have a menu with **Windows** as an option.
7. Adjust your Bios to set Pop!_OS as the first boot option.

##### 3.2.2.2. Install Windows without planning for Pop!_OS (easier and most common for users already having Windows installed)

Here you will end up with two separate EFI partitions and as such the procedure is similar to having two separate drives. 

1. Install Windows as normal
2. Boot from Live USB
3. Make space for Pop!_OS. You will need two* partition, a 512MB FAT32 partition and the rest as ext4 (or use as many partitions as you want for your custom installation). *You can addd a 4096MB FAT32 partition for the recovery (this is recommended but not required)
4. Select the 512MB FAT32 partition as ```/boot/efi``` partition and the rest as your ```/``` partition (or any other layout you want, but this is the minimum). If you added a partition for Recovery, then select it, set it to custom and type ```/recovery``` for the mount point (make sure fat32 is selected).
5. Install.
6. Now you have two installations each with its own EFI partition. 
7. Follow the process used for dual booting from two drives to make your menu include **Windows**.


## 4. TL:DR Dual boot from the same drive with Windows and Pop!_OS already installed

Note: See the very short TL:DR at the very top if you know what you're doing.

If you have managed to install Windows and Pop!_OS, read the introduction before you proceed. 

To make Windows appear in the boot menu, you will need to copy its EFI folder to where Pop!_OS's EFI folder is.

Steps:
1. Boot Pop!_OS
3. In the terminal, use ```lsblk``` to identify Windows's EFI partition. Typically it will be a partition with 100MB size.
~~~
otheos@pop-os:~$ lsblk
NAME          MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda             8:0    0 119.2G  0 disk 
├─sda1          8:17   0   100M  0 part  
├─sda2          8:18   0    16M  0 part  
├─sda3          8:19   0 111.2G  0 part  
└─sda4          8:20   0   505M  0 part 
├─sda5          8:1    0   498M  0 part  /boot/efi
├─sda6          8:3    0 110.8G  0 part  / 
~~~
Note: My Pop!_OS installation is on ```/dev/sda5``` and ```/dev/sda6```. I do **not** have a recovery, **nor** a swap partition as I don't use these, but your installation might be different. The important part here is ```/dev/sda1``` as it has **100MB** size and looks like the EFI partition of Windows.

4. Mount the EFI partition of Windows. Typically you can type ```sudo mount /dev/sda1 /mnt```. 
5. Check that this partition actually has the EFI files of Windows: ```cd /mnt``` and then ```ls``` and look for a folder ```EFI``` in there.
6. Copy the EFI files of Windows to Pop!_OS's EFI partition. The EFI files of Windows are in the folder ```/mnt/EFI/Microsoft```. You will need the **complete** ```Microsoft``` folder copied in ```/boot/efi/EFI```. In detail:
~~~
otheos@pop-os:~$ sudo mount /dev/sda1 /mnt
otheos@pop-os:~$ cd /mnt
otheos@pop-os:/mnt$ ls
EFI
otheos@pop-os:/mnt$ cd EFI
otheos@pop-os:/mnt/EFI$ ls
Boot  Microsoft
otheos@pop-os:/mnt/EFI$ sudo cp -ax Microsoft /boot/efi/EFI
~~~
At this point you are done. You can check the folder is where it should be:
~~~
otheos@pop-os:/mnt/EFI$ sudo ls /boot/efi/EFI
BOOT   Microsoft				    Recovery-8138-A6FE
Linux  Pop_OS-eeacf7ce-54c4-47ac-a595-2c701aa28e2c  systemd
~~~
Note: You can only see the contents of this folder as *root* as such ```sudo``` is required. You can see the ```Microsoft``` folder is now present. 

7. You are done. You can now reboot your system and check in the **menu** that there is an option named **Windows Boot Manager**. Select it and you can boot to Windows.

**Note**: Your bios may re-read the EFI options offered in the boot manager and may place the new EFI entry for Windows first. If your system boots straight to Windows after restart, reboot to Bios and select **Pop!_OS** as the first choice to boot.

### 4.1 From Windows

This is **work in progress** but here it goes as a placeholder until completed (so use with caution):

You can copy Windows' boot files to the new ESP from Windows. The steps are:

1. Give Pop's ESP a drive letter (this will be changed after some more work is done)
2. Run the ```bcdboot``` command

For the first part, you cannot do it using Windows Disk Management, so you will need the command line (as administrator)

~~~
diskpart
select disk 0
select partition 5
assign letter=y
exit
~~~

Assuming the drive and partitions are 0 and 5 respectively. This needs to adjusted for your case.
Then issue the command:

~~~
bcdboot c:\Windows /s y:
~~~

That's it. Windows now copied the files to the new ESP.  The best part about this method is now Windows doesn't use the old ESP ever again, so technically you can remove it. (Work in progress as this has so far worked erratically). 
