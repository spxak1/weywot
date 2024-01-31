# Install Pop_OS! with LUKS on a partition rather than the full drive
This is for those who want to share a drive with another OS (like Windows) and still want to keep LUKS encryption.
Currently Pop's installer only offers encryption when installing on the whole disk, and the custom installation where you can select partitions rather than the whole drive, does not provide a way to configure encryption with LUKS.

This guide uses as much GUI as possible, mainly because it's dead easy.

## Preparation

Boot from USB to the Pop installer. Go through the first steps to configure language, keyboard etc, but then click on the left bottom corner to just try Pop, **do NOT install**.

### Partitions

You need a minimum of 2 partitions to install Pop, but I use 3:
* The EFI System Partition (ESP), mounted on ```/boot/efi```. I use 2GB to have some space, and it **must** be FAT32.
* The ```/recovery``` partition. This is **not required** but it's one of Pop's nicest features so I always use it. You can skip this. It takes 4GB in FAT32.
* The ```/``` (root) partition. This is the one that will be encrypted. Use as much space as you want for this. I use 90GB and ```ext4```, the default filesystem for Pop. Guides with BTRFS are available, I will  also make one later.

### The ESP  
