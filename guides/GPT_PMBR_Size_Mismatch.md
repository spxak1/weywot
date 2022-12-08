### Specifics
This is a guide to solve a very specific issue. I have shanked a couple of 14TB WD Elements USB drives and I wanted to re-purpose the USB enclosures, left over after taking the drives out.
I have a couple of 8TB Seagate Archive drives which I wanted ot put in there.
However, upon connection of the drive to the USB enclosure (the USB to SATA adapter), I was greeted with "empty space" and an error titled:

**GPT PMBR Size Mismatch**

This issue has many manifestations, but in my case, it was the following: 
The partition table inside the USB enclosure was reported a few MB shorter. As such the header was not accessible by the kernel, and the drive appeard empty. And everything complained.

# Recreating the issue

Here's a recreation of the issue. 

## On SATA
This drive has been partitioned and a filesystem has been created while connected on SATA:

~~~
[otheos@brahe ~]$ sudo fdisk -l /dev/sdc
Disk /dev/sdc: 298.09 GiB, 320072933376 bytes, 625142448 sectors
Disk model: ST3320820AS     
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: AE4876BF-118A-8042-940E-861EA1650EF3

Device     Start       End   Sectors   Size Type
/dev/sdc1   2048 625141759 625139712 298.1G Linux filesystem
~~~

Note that the available secors are **625142448**. 

Mounting this ext4 partition gives an output on ```dmesg``` of:

~~~
[ 4594.957324]  sdc: sdc1
[ 4715.916024] EXT4-fs (sdc1): mounted filesystem with ordered data mode. Quota mode: none.
~~~

Everything is fine!

Disconnect the drive from the SATA connector (a reboot is required to do that) and reconnect it with the USB Enclosure.

## On USB

Check with ```lsblk```:
~~~
[otheos@brahe ~]$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 298.1G  0 disk 
~~~

The drive appears to have no partitions. 
Check with ```fdisk```:
~~~
[otheos@brahe ~]$ sudo fdisk -l /dev/sda
GPT PMBR size mismatch (625142447 != 625076223) will be corrected by write.
Disk /dev/sda: 298.06 GiB, 320039026688 bytes, 625076224 sectors
Disk model: Elements 25A3   
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x00000000

Device     Boot Start       End   Sectors   Size Id Type
/dev/sda1           1 625076223 625076223 298.1G ee GPT
~~~

**There it is!** Let me make it more obvious:

~~~
GPT PMBR size mismatch (625142447 != 625076223) will be corrected by write.
~~~

Also note that there does appear to be a partition, but the Start, End, Sectors, ID and Type are messed up. 
The kernel doesn't see a partition (as shown in ```lsblk```). 

**I can't fix this from here.***

## Identify the issue

However, notice the discrepancy: The disk when inside the enclosure reports **625076224** sectors (see end of line starting with ```/disk/sda```), while when connected internally (SATA) it reported **625142448**.
The mismatch is referenced clearly in the error message:
~~~
625142447 != 625076223
~~~

Note: Minus 1 for the first sector. 

So the drive appears smaller inside the enclosure by 625142447-625076223=**66224** sectors.
With a sector size of 512B, that's 66224x512=**33906688** bytes, or almost 33MB!

The kernel cannot access the header of the partition, typically stored at the end (I may be wrong about the specifics here, but I explain later why I think this is the case), so the drive is reported empty for most purposes. 
But it is **not empty**. So do not format/touch anything.

Instead, reconnect the drive internally on SATA.

''



