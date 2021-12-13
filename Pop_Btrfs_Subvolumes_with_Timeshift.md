# Install Pop!_OS with **btrfs** and subvolumes

This is a guide to install Pop!_OS (version 20.10 at the time of writing this) with **btrfs** instead of **ext4** to allow the use of **subvolumes** and **timeshift** for continuous backup. 

## 1. Introduction

This guide has been adapted from **Willi Mutschler**'s excellent guide found [here](https://mutschler.eu/linux/install-guides/pop-os-btrfs/) that **also includes Luks encryption** using **LVM**. My version **does not** use encryption (as I use hardware encryption for my SSD), so if you need encryption, please follow his guide. All credit for this work belongs to [**Willi Mutschler**](https://mutschler.eu/).

### 1.1 Purpose

The use of **btrfs** allows snapshot backups of the file system with **timeshift**. These take minimal space and make it easy to restore to a previous state if needed. **Btrfs** appears to be mature enough for mainstream use, with minimal performance hit, and is offered by default during *Pop!_OS* installation.

### 1.2 Prerequisites

This quide requires the ability to perform tasks using the terminal. It also expects the user to have basic understaning of:

1. What is a filesystem
2. What is a partitions
3. A boot manager and a bootloader
4. What chroot does

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
Last sector, +/-sectors or +/-size{K,M,G,T,P} (1050624-976773134, default 976773134): +4096M <b>← type 4096M for the size required</b>

Created a new partition 2 of type 'Linux filesystem' and of size 4 GiB.

Command (m for help): <b>n</b>
Partition number (3-128, default 3): <b>← press enter</b>
First sector (9439232-976773134, default 9439232): <b>← press enter</b>
Last sector, +/-sectors or +/-size{K,M,G,T,P} (9439232-976773134, default 976773134): <b>← press enter to use all remaining space</b> 

Created a new partition 3 of type 'Linux filesystem' and of size 461.3 GiB.

Command (m for help): <b>p</b> <b>← to show the new partition layout</b>
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

Now you have your newly installed system mounted on `/mnt`. We are going to make 3 subvolumes:

1. **@** for root ```/```
2. **@home** for home ```/home```
3. **@swap** for, well, swap ```/swap```

Create subvolume '/mnt/@'
<pre>
root@pluto:/# btrfs subvolume create /mnt/@
</pre>

With the `@` subvolume created, we need to move all the data except for `/home` from the old `/` to the new `/`, under the `@` subvolume. __NB__ : We are not moving `/home` right now as we will copy it later into the proper subvolume.

<pre>
root@pluto:/# cd /mnt
root@pluto:/# ls | grep -v '@\|home' | xargs mv -t @
</pre>

The second command moved all files and folders, except the home directory, to `/mnt/@`.

If we check now in `/mnt`, there is nothing but the subvolume **@**. If you check inside of it you will find all installation data.

<pre>
root@pluto:/# ls /mnt/
 @
root@pluto:/# cd @
root@pluto:/# ls
 bin   dev  home  lib32  libx32  mnt  proc      root  sbin  swap  tmp  var
 boot  etc  lib   lib64  media   opt  recovery  run   srv   sys   usr
</pre>

Now for the other two subvolumes.

Create subvolume '/mnt/@home'
<pre>
root@pluto:/# btrfs subvolume create /mnt/@home
root@pluto:/# mv ./home/ ./@home 
</pre>
The second command ensured that all data from `/home` were written into `./@home`.

Create subvolume '/mnt/@swap'
<pre>
root@pluto:/# btrfs subvolume create /mnt/@swap
root@pluto:/# btrfs subvolume list /mnt
 ID 263 gen 66 top level 5 path @
 ID 264 gen 64 top level 5 path @home
 ID 265 gen 66 top level 5 path @swap
</pre>

Your ID numbers may differ.

We're almost done, except for the swap.

### 2.3.2 Create swap on btrfs subvolume

The ```@swap``` subvolume appears as a folder inside of the ```/mnt``` mount. In there we're creating the **swapfile**. For this example I'm using a 9GB swapfile (to allow for suspend-to-disk, aka hibernate -not covered in this guide).

Follow the series of commands:

<pre>
root@pluto:/# truncate -s 0 /mnt/@swap/swapfile
root@pluto:/# chattr +C /mnt/@swap/swapfile
root@pluto:/# btrfs property set /mnt/@swap/swapfile compression none
root@pluto:/# fallocate -l 9G /mnt/@swap/swapfile <b>← here you decide the size of the swapfile, 9G used for 9GB</b>
root@pluto:/# chmod 600 /mnt/@swap/swapfile
root@pluto:/# mkswap /mnt/@swap/swapfile
 Setting up swapspace version 1, size = 9 GiB (9663676416 bytes) 
 no label, UUID=a0fee436-e38a-4d60-bb40-680c221db376
mkdir /mnt/@/swap
</pre>

The last command has created a `swap` folder inside the `/` root. We will mount the `@swap` subvolume to that folder to make it a appear as a swap partition to the filesystem.

### 2.3.3 Editing mount points

For that we need to edit `/etc/fstab`. The new one, not the one on the system we currently use (which is the live environement. 

To edit the **new** fstab file do `nano /mnt/@/etc/fstab`

Remember: The installation is now found in the `@` subvolume which is accessible from the `/mnt/@` point. As such the `/etc` folder of the new installation is there `/mnt/@/etc`.

It is helpful to have the ***UUID*** of the partition your **btrfs** system lives. For that do `lsblk -f`.

<pre>
NAME   FSTYPE FSVER LABEL                 UUID                                
sdb                                                                                           
├─sdc1 vfat   FAT32                       0BAC-7FA8                               
├─sdc2 vfat   FAT32                       7827-FA9E                               
├─sdc3 btrfs                              78c9787f-1d36-42e8-89bd-7b94b501afaf 
</pre>

In the case above the **UUID** is **78c9787f-1d36-42e8-89bd-7b94b501afaf**. Normally this should already be in your **fstab**, but have it handy in case you need it.

Now have your `/mnt/@/etc/fstab` look like this:

<pre>
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system>  <mount point>  <type>  <options>  <dump>  <pass>
PARTUUID=697685f3-e003-4cd4-a7be-b07bbcf4497e   /boot/efi       vfat    umask=0077      0  0
PARTUUID=a9fbe686-9f08-487c-9bc9-db094845b8c2   /recovery       vfat    umask=0077      0  0
UUID=78c9787f-1d36-42e8-89bd-7b94b501afaf       /               btrfs   defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd      0  0
UUID=78c9787f-1d36-42e8-89bd-7b94b501afaf       /home           btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd  0  0
UUID=78c9787f-1d36-42e8-89bd-7b94b501afaf       /swap           btrfs   defaults,subvol=@swap,compress=no 0 0
/swap/swapfile                                  none            swap    defaults        0  0
</pre>

Note that the **UUID** is the same for all system mounts except for the ```/boot/efi``` and the ```/recovery``` that use their **PARTUUID**, and you **do not change these**.

### 2.3.4 Configure the bootloader

The bootloader **does not** expect the root ```/``` to be on a subvolume. We need to tell it where to find it. 
*Pop!_OS* uses **systemd_boot** and this makes things very simple. 

First, mount the new ```/boot/efi``` to edit the configuration files. We need to mount this in its proper location, so:

~~~
mount /dev/sdc1 /mnt/@/boot/efi
~~~

Now, the main change is in the **entry** file that boots *Pop!_OS*
That file is ```/mnt/@/boot/efi/loader/entries/Pop_OS-current.conf```

Edit it with ```nano``` and at the end of the last line (that starts with **options**) add: ```rootflags=subvol=@```

The complete file should look like this:

<pre>
title Pop!_OS
linux /EFI/Pop_OS-78c9787f-1d36-42e8-89bd-7b94b501afaf/vmlinuz.efi
initrd /EFI/Pop_OS-78c9787f-1d36-42e8-89bd-7b94b501afaf/initrd.img
options root=UUID=78c9787f-1d36-42e8-89bd-7b94b501afaf ro quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@ 
</pre>

Look at the very last item of the last line (scroll right to see it).

Now that the bootloader knows where to find ```/```, we need to make sure that when an update re-writes the bootloader, it doesn't remove that option.

For that we need to make that option the **default** everytime the bootloader is configured by the system **or** wen we run ```kernestub``` (the bootmanager manager -word manager appears twice here).

For that we need to edit the configuration of ```kernelstub``` that is found in the system's ```/etc/kernelstub/configuration``` file.

So edit this file with ```nano /mnt/@/etc/kernelstub/configuration```.

We need to find the **user** section, that ends with ```"splash"```. We need to add ```"rootflags=subvol=@"``` after it.

Be careful, since we add one more entry to this section, the previous entry, ```"splash"``` now needs to end with a **comma**.

So the complete file will look like this:

<pre>
{
  "default": {
    "kernel_options": [
      "quiet",
      "splash"
    ],
    "esp_path": "/boot/efi",
    "setup_loader": false,
    "manage_mode": false,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3
  },
  "user": {
    "kernel_options": [
      "quiet",
      "loglevel=0",
      "systemd.show_status=false",
      "splash", <b>← here is the comma added</b>
      "rootflags=subvol=@" <b>← here is the new option added</b>
    ],
    "esp_path": "/boot/efi",
    "setup_loader": true,
    "manage_mode": true,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3
  }
 </pre>
 
 The configuration is done. Now we need to rebuild the bootloader for the new configuration.
 
 ### 2.3.5 Rebuild the bootloader
 
 For this we need to ```chroot```. This is taken from System76 website [here](https://support.system76.com/articles/bootloader/) for UEFI systems.
 
 We will first umount everything from ```/mnt``` with ```cd /``` to move out of the mounted folder and then ```umount -l /mnt```.
 
 Now we will remount the new system (in its subvolumes) to ```/mnt``` again.
 
```mount -o defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd /dev/sdc3 /mnt```

Note the above mounts the ```subvol=@```, that is the root, to ```/mnt```. It's a different command to the one we used earlier.

Now mount the required system partitions:

~~~
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo cp /etc/resolv.conf /mnt/etc/
sudo chroot /mnt
~~~

If ```/etc/resolv.conf``` complains they're identical, it's fine. You need this line to have access to the internet after ```chroot```.

Check everything is mounted as they should with:

~~~
root@pluto:/# mount -av
 /boot/efi                : successfully mounted
 /recovery                : successfully mounted
 /                        : ignored
 /home                    : successfully mounted
 /swap                    : successfully mounted
~~~

(Don't worry about the *ignored* statement, that's what it should be).

First install ```btrfs-progs``` to the new installation (most probably already installed) with ```apt install -y btrfs-progs```.

If not and they install, you will see that this simple apt command had the bootloader updated and had we not changed the default configuration of ```kernelstub``` our kernel option would be gone.

Now lets update once more manually with ```update-initramfs -c -k all```.

We're done. Type ```exit``` to leave **chroot** and then ```reboot now``` to restart to the new installation.


## 3. Checks and Timeshift configuration

Once in the new installation, do a quick check with:

<pre>
otheos@pluto:~$ sudo mount -av
 /boot/efi                : already mounted
 /recovery                : already mounted
 /                        : ignored
 /home                    : already mounted
 /swap                    : already mounted
 none                     : ignored
</pre>

then,

<pre>
otheos@pluto:~$ sudo cat /etc/fstab 
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system>  <mount point>  <type>  <options>  <dump>  <pass>
PARTUUID=697685f3-e003-4cd4-a7be-b07bbcf4497e	/boot/efi	vfat	umask=0077	0  0
PARTUUID=a9fbe686-9f08-487c-9bc9-db094845b8c2	/recovery	vfat	umask=0077	0  0
UUID=78c9787f-1d36-42e8-89bd-7b94b501afaf	/		btrfs	defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd	0  0
UUID=78c9787f-1d36-42e8-89bd-7b94b501afaf	/home		btrfs	defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd	0  0
UUID=78c9787f-1d36-42e8-89bd-7b94b501afaf	/swap		btrfs	defaults,subvol=@swap,compress=no 0 0
/swap/swapfile					none		swap	defaults	0  0
</pre>

then,

<pre>
otheos@pluto:~$ sudo swapon
 NAME           TYPE SIZE USED PRIO
 /swap/swapfile file   9G   0B   -2
</pre>

then,

<pre>
otheos@pluto:~$ sudo btrfs filesystem show /
 Label: none  uuid: 78c9787f-1d36-42e8-89bd-7b94b501afaf
	Total devices 1 FS bytes used 13.82GiB
	devid    1 size 88.75GiB used 18.02GiB path /dev/sdb3
</pre>

and 

<pre>
otheos@pluto:~$ sudo btrfs subvolume list /
 ID 263 gen 230 top level 5 path @
 ID 264 gen 230 top level 5 path @home
 ID 265 gen 72 top level 5 path @swap
</pre>


Then update your system as you would a new installation:

~~~
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
sudo apt autoclean
~~~
 
Finally install ```timeshift``` with ```sudo apt install -y timeshift```

The following is taken from Willi Mutschler's website,
    
1. Select “BTRFS” as the “Snapshot Type”; continue with “Next”
2. Choose your BTRFS system partition as “Snapshot Location”; continue with “Next” (even if timeshift does not see a btrfs system in the GUI it will still work, so continue (I already filed a bug report with timeshift))
3. “Select Snapshot Levels” (type and number of snapshots that will be automatically created and managed/deleted by Timeshift), my recommendations:
    *    Activate “Monthly” and set it to 1
    *    Activate “Weekly” and set it to 3
    *    Activate “Daily” and set it to 5
    *   Deactivate “Hourly”
    *    Activate “Boot” and set it to 3
    *    Activate “Stop cron emails for scheduled tasks”
        continue with “Next”
    *    I also include the @home subvolume (which is not selected by default). Note that when you restore a snapshot Timeshift you get the choise whether you want to restore it as well (which in most cases you don’t want to).
    *    Click “Finish”
 4. “Create” a manual first snapshot & exit Timeshift
 
 You can find your backups in ```/run/timeshift/backup```.
 
 * To be added:  timeshift-autosnap-apt to backup before every apt udate.





