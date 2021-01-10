# Install Pop!_OS with **btrfs** and subvolumes

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

<pre>
Command (m for help): <b>n</b>
Partition number (1-128, default 1): <b>← press enter</b>
First sector (34-976773134, default 2048): <b>← press enter</b>
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-976773134, default 976773134): +512M <b>*← type 512M for the size required</b>       

Created a new partition 1 of type 'Linux filesystem' and of size 512 MiB.

Command (m for help): p <b>← type p to show partitions</b>
Disk /dev/sdc: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: MobileDataStar  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 7539C5AF-685B-42F6-BC85-27E26461002E

Device     Start     End Sectors  Size Type
/dev/sdc1   2048 1050623 1048576  512M Linux filesystem <b>← the new partition is here</b>

Command (m for help): 
</pre>

Create the other two in the same way.

<pre>
Command (m for help): <b>n</b>
Partition number (2-128, default 2): <b>← press enter</b>
First sector (1050624-976773134, default 1050624): <b>← press enter</b>
Last sector, +/-sectors or +/-size{K,M,G,T,P} (1050624-976773134, default 976773134): +4096M <b>*← type 4096M for the size required</b>

Created a new partition 2 of type 'Linux filesystem' and of size 4 GiB.

Command (m for help): <b>n</b>
Partition number (3-128, default 3): <b>← press enter</b>
First sector (9439232-976773134, default 9439232): <b>← press enter</b>
Last sector, +/-sectors or +/-size{K,M,G,T,P} (9439232-976773134, default 976773134): <b>← press enter to use all remaining space</b> 

Created a new partition 3 of type 'Linux filesystem' and of size 461.3 GiB.

Command (m for help): <b>p</b> <b>← pto show the new partition layoutr</b>
Disk /dev/sdc: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: MobileDataStar  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 7539C5AF-685B-42F6-BC85-27E26461002E

Device       Start       End   Sectors   Size Type
/dev/sdc1     2048   1050623   1048576   512M Linux filesystem
/dev/sdc2  1050624   9439231   8388608     4G Linux filesystem
/dev/sdc3  9439232 976773134 967333903 461.3G Linux filesystem

Filesystem/RAID signature on partition 1 will be wiped.
</pre>

Your three partitions are created, and the last warning is to remind you there was a filesystem on this drive that will be deleted as soon as you **write** the changes. **Do not write or exit fdisk yet**.

We need to set **partition type** for the **ESP** partition, so that the BIOS knows it is an **ESP** partition and try to boot from it.

Type **t** to change partition type, as follows.

<pre>
Command (m for help): <b>t</b>   
Partition number (1-3, default 3): <b>1</b> <b>← select the first partition</b> 
Partition type or alias (type L to list all): <b>1</b> <b>← select partition type 1, EFI System</b> 

Changed type of partition 'Linux filesystem' to 'EFI System'.

Command (m for help): <b>p</b>
Disk /dev/sdc: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: MobileDataStar  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 7539C5AF-685B-42F6-BC85-27E26461002E

Device       Start       End   Sectors   Size Type
/dev/sdc1     2048   1050623   1048576   512M EFI System
/dev/sdc2  1050624   9439231   8388608     4G Linux filesystem
/dev/sdc3  9439232 976773134 967333903 461.3G Linux filesystem

Filesystem/RAID signature on partition 1 will be wiped.
</pre>

You can see when we **p**rint the partition layout now, the partition type of the first partition is set to **EFI System**.

Let's finish off by adding **labels**. For this we need the **extra functionality** so type **x**. We name the second partition **RECOVERY** and the third partition **ROOT**.

<pre>
Command (m for help): <b>x</b>

Expert command (m for help): <b>n</b>
Partition number (1-3, default 3): <b>2</b>

New name: <b>RECOVERY</b>

Partition name changed from '' to 'RECOVERY'.

Expert command (m for help): <b>n</b>
Partition number (1-3, default 3): <b>3</b>

New name: <b>ROOT</b>

Partition name changed from '' to 'ROOT'.
</pre>

Now exit the **extra functionality** menu by typing **r**


<pre>
Expert command (m for help): <b>r</b>
</pre>

You can now **write** the new partition layout by typing **w**. This will exit fdisk.

## 2.2 Installing the system

You can now start the installer from the dash favourite menu. You will select **Custom (Advanced)**. Then you will select the partitions and proceed as follows:

1. Select the first partition, **Use partition**, **Format**, and set for **/boot/efi** and filesystem **fat32**.
2. Select the second partition, **Use partition**, **Format**, and set for **Custom** and type: ```/recovery``` and filesystem **fat32**.
3. Select the third partition, **Use partition**, **Format**, and set for **/** and filesystem **btrfs**  **← this is the main change!**

You do not need a **swap partition**, we will install a swapfile!

Now press **Erase and Install** and wait for it to finish. When done **DO NOT REBOOT**. Instead go back to your terminal.

Let me retype this **DO NOT REBOOT**

**Note**: At this point you could reboot and use your system as it is, but you would have **no subvolumes** and as such no access to **btrfs** main benefits.

## 2.3 Setting up subvolumes and finishing the installation

### 2.3.1 Create subvolumes

You're using the terminal, still in root interactive mode (```sudo -i```).

First mount the **ROOT** partition to ```/mnt```

```mount -o subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd /dev/sdc3 /mnt```

These options are suggested for better performance with **btrfs** (taken from Willi Mutschler site as they appear):

1. **ssd**: use SSD specific options for optimal use on SSD and NVME
2. **noatime**: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders
3. **space_cache**: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
4. **commit=120**: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro’s minimal iso)
5. **compress=zstd**: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms. Based on some Phoronix test cases, zstd seems to be the better performing candidate.

Now you have your newly installed system mounted on ```/mnt```.






~~~




