# Install Pop!_OS with **btrfs* and subvolumes

This is a guide to install Pop!_OS (version 20.10 at the time of writing this) with **btrfs** instead of **ext4** to allow the use of **subvolumes** and **timeshift** for continuous backup. 

## 1. Introduction

This guide has been adapted from **Willi Mutschler**'s excellnt guide found [here](https://mutschler.eu/linux/install-guides/pop-os-btrfs/) that **also includes Luks encryption** using **LVM**. My version **does not** use encryption (as I use hardware encryption for my SSD), so if you need encryption, please follow his guide. All credit for this work belongs to [**Willi Mutschler**](https://mutschler.eu/).

### 1.1 Purpose

The use of **btrfs** allows snapshot backups of the file system with **timeshift**. These take minimal space and make it easy to restore to a previous state if needed. **Btrfs** appears to be mature enough for mainstream use, with minimal performance hit, and is offered by default during *Pop!_OS* installation.

### 1.2 Prerequisites

This quide requires the ability to perform tasks using the terminal. It also expects the user to have basic understaning of:

1. What is a filesystem
2. What is a partitions
3. A boot manager and a boot loade

and ability to:

1. Boot a PC from USB
2. Create and edit partitions using various tools (parted, gparted or fdisk)
3. Install Pop!_OS in advance mode
4. Edit files using **nano** or other editors (**vim** or graphically **gedit**)

This guide expects a **UEFI** system so please check as soon as you have your USB live system running, from a terminal with ```mount | grep efivars``` and expect an output like

> efivarfs on /sys/firmware/efi/efivars type efivarfs (rw,nosuid,nodev,noexec,relatime)

This means the system is in UEFI mode. If not, change your Bios settings to UEFI and start over.


## 2. Installation

The installation is done in **three parts**. Preparing the system, installing the system, configuring the system. All are done **from within the USB Live environment**. As such the first step is to **boot the system from USB to *Pop!_OS* Live Environment**. Once the system is up, go through the stages to select keyboard and languange, and then **exit the installer** by selecting **Try Demo Mode**.

### 2.1 Prepare the partitions

Open a terminal (Super+T) and change to interactive root with ```sudo -i```. Keep this terminal **open at all times**.
To install *Pop!_OS* we will need **three partitions** (including the **recovery**).

1. A 512MB Fat32 partition for ```/boot/efi```
2. A 4096MB Fat32 partition for ```/recovery```
3. A linux partition (no filesystem yet) for ```/```

Type ```lsblk``` to see your storage devices and partitions.

~~~
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sdc      8:32   0 465.8G  0 disk 
└─sdc1   8:33   0 465.8G  0 part 
~~~

The above shows my device, a 500GB SSD that currently has a single partition. I will use this as an example for this guide. Yours might be different of course.
To start partitioning this device, start ```fdisk```. 
**Note: All data on this drive will be deleted**

~~~
root@pluto:~# fdisk /dev/sdc

Welcome to fdisk (util-linux 2.36).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.


Command (m for help): 
~~~

Now enter **p** to **print** the current layout.

~~~
Disk /dev/sdc: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: MobileDataStar  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 7539C5AF-685B-42F6-BC85-27E26461002E

Device     Start       End   Sectors   Size Type
/dev/sdc1   2048 976773134 976771087 465.8G Linux filesystem

Command (m for help): 
~~~ 

We first need to delete the current partition to start fresh. For that I type **d** for **delete**

~~~
Disk /dev/sdc: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: MobileDataStar  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 7539C5AF-685B-42F6-BC85-27E26461002E

Device     Start       End   Sectors   Size Type
/dev/sdc1   2048 976773134 976771087 465.8G Linux filesystem

Command (m for help): 
~~~

Time to start partitioning.

First partition is the **ESP** partition (**E**FI **S**ystem **P**artition), as stated above. Type **n** to create **new** partition.

~~~
Command (m for help): **n**
Partition number (1-128, default 1): **← press enter**
First sector (34-976773134, default 2048): **← press enter**
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-976773134, default 976773134): +512M **← type 512M for the size required**       

Created a new partition 1 of type 'Linux filesystem' and of size 512 MiB.

Command (m for help): p **← type p to show partitions**
Disk /dev/sdc: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: MobileDataStar  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 7539C5AF-685B-42F6-BC85-27E26461002E

Device     Start     End Sectors  Size Type
/dev/sdc1   2048 1050623 1048576  512M Linux filesystem **← the new partitino is here**

Command (m for help): 
~~~



