With info from:
https://linuxconfig.org/automatically-mount-usb-external-drive-with-autofs
https://unix.stackexchange.com/questions/39370/how-to-reload-udev-rules-without-reboot
https://wiki.debian.org/AutoFs

## Process
Change stadnard /dev/sda names to unique names so that you can mount them regardless of their random name allocation.

## Find your drive's model names
Identify your drives first (all commands use root or sudo). 

Quick way is with ```fdisk -l```:
~~~
Disk /dev/sdk: 3.64 TiB, 4000752599040 bytes, 7813969920 sectors
Disk model: My Passport 25E2
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 0D8BACFD-0C6F-4CC3-A89E-9A0841752191

Device     Start        End    Sectors  Size Type
/dev/sdk1   2048 7813969886 7813967839  3.6T Linux filesystem


Disk /dev/sdi: 12.73 TiB, 14000486088704 bytes, 27344699392 sectors
Disk model: Elements 25A3   
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 42E8FEDB-F64D-4918-A48E-29025D788965

Device     Start         End     Sectors  Size Type
/dev/sdi1   2048 27344697343 27344695296 12.7T Linux filesystem
The backup GPT table is corrupt, but the primary appears OK, so that will be used.


Disk /dev/sdj: 7.28 TiB, 8001563221504 bytes, 15628053167 sectors
Disk model: Backup+ Hub BK  
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 6E13FDDD-CA43-402F-9CC9-A71511809F5B

Device     Start         End     Sectors  Size Type
/dev/sdj1   2048 15628053134 15628051087  7.3T Linux filesystem
~~~

So I need drives:
~~~
/dev/sdk
/dev/sdi
/dev/sdj
~~~

Each has one partition only.

For udev rules you need to find the ```model``` attribute first:
~~~
[root@ceres etc]# udevadm info --query=all --path=/block/sdi --attribute-walk | grep model
    ATTRS{model}=="Elements 25A3   "
[root@ceres etc]# udevadm info --query=all --path=/block/sdk --attribute-walk | grep model
    ATTRS{model}=="My Passport 25E2"
[root@ceres etc]# udevadm info --query=all --path=/block/sdj --attribute-walk | grep model
    ATTRS{model}=="Backup+ Hub BK  "
~~~

Now let's build the udev rule to change the names to unique ones on connection:

Create the file : ```/etc/udev/rules.d/custom.rules```
~~~
SUBSYSTEMS=="scsi", ATTRS{model}=="Backup+ Hub BK  ", SYMLINK+="archive%n"
SUBSYSTEMS=="scsi", ATTRS{model}=="My Passport 25E2", SYMLINK+="orange%n"
SUBSYSTEMS=="scsi", ATTRS{model}=="Elements 25A3   ", SYMLINK+="oort%n"
~~~

For example the first line will name all the partitions on ```/dev/sdj``` to ```/dev/archive1, /dev/archive2```, etc




