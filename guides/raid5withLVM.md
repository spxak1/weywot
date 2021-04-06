## Create a RAID 5 with LVM

### 1. Prepare the drives

You will need the drives to have a partition table and a partition. It is partitions that will be used.


### 2. Create the volume group

This combines the partitions into one group you can then convert to whatever kind of grouped storage you need.

Some names to identify: 

The volume group name: **old320s**

This is as simple as:

```sudo vgcreate  old320s /dev/sdj1 /dev/sdk1 /dev/sdl1 /dev/sdm1```

Now you can check your volume group with

~~~
[root@ceres /]# vgdisplay
  --- Volume group ---
  VG Name               old320s
  System ID             
  Format                lvm2
  Metadata Areas        4
  Metadata Sequence No  9
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                4
  Act PV                4
  VG Size               1.16 TiB
  PE Size               4.00 MiB
  Total PE              305240
  Alloc PE / Size       305240 / 1.16 TiB
  Free  PE / Size       0 / 0   
  VG UUID               9xyC5z-ZcYp-FK0e-ExRX-5UYP-Qqqp-J1NfXO
~~~

The 4 drives are 320GB each and as such the volume group has a total storage of 4x 320GB = 1280GB which is reported above as 1.16TiB.

### 3. Create the logical volume

Now to create **logical volume**. This is what is going to be the final "drive".

Here's where you decide how to use those drives. You can various types of RAID, see [here](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/raid_volumes#create-raid).

For a **RAID5**, I want 3 drives for storage and 1 drive for parity. 

The logical volume name: **raid5**

This is done with:

~~~
lvcreate --type raid5 -i 3 -l 100%FREE -n raid5 old320s
~~~

The key point here is the ```-i 3``` option which means (from the [manual](https://linux.die.net/man/8/lvcreate)):

~~~
-i, --stripes Stripes
Gives the number of stripes. This is equal to the number of physical volumes to scatter the logical volume. When creating a RAID 4/5/6 logical volume, the extra devices which are necessary for parity are internally accounted for. Specifying '-i 3' would use 3 devices for striped logical volumes, 4 devices for RAID 4/5, and 5 devices for RAID 6.
~~~

So in my case, 3 drives are striped, and since this is a RAID5, the fourth on (of the volume group) is going to be parity.

You can check your new volume group with:

~~~
[root@ceres /]# lvs
 LV    VG           Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
raid5 old320s      rwi-aor--- <894.25g                                    100.00
~~~

### 4. Create the filesystem

That's the easy part.

~~~
[root@ceres /]# mkfs.ext4 /dev/old320s/raid5 
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 234421248 4k blocks and 58605568 inodes
Filesystem UUID: 648abd62-153b-4aa6-b451-7da97244831a
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
	4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968, 
	102400000, 214990848

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done 
~~~

Mount as per normal and it's ready to use. You can also create a label and/or add to fstab (later).

### 5. Remove the RAID

You can remove the logical volume and keep the volume group do do something else with it, or remove the volume group too. 

To remove the **logical group**

~~~
lvremove raid5 old320s
~~~

This will remove the volume group named *raid5* from the volume group named *old320s*.

To also remove the **volume group**

~~~
vgremove old320s
~~~


### 6. Mounting at boot

You can mount at boot by including the raid device in ```/etc/fstab```.

It is wise, to list the device with its **UUID** rather than the raw ```/dev/old320s/raid5``` device.

To find the UUID (that would be of the final formatted partitioned device. **Not** the vg, **nor** the lv.

Because RAID in LVM actually runs based on **mdadm**, as soon as the logical volume is created as a RAID array, the **real** device created is a **dm** device.

To find the **UUID** you neeed to find the **true** device name.

~~~
[root@ceres ~]# ls -l /dev/old320s/raid5 
lrwxrwxrwx. 1 root root 8 Apr  6 17:44 /dev/old320s/raid5 -> ../dm-10
~~~

So we're looking for the UUID of ```/dev/dm-10```.

~~~
root@ceres ~]# ls -l /dev/disk/by-uuid
total 0
lrwxrwxrwx. 1 root root 15 Apr  6 17:47 1354-ACB9 -> ../../nvme0n1p1
lrwxrwxrwx. 1 root root 10 Apr  3 08:51 1d3dd9d5-0452-4775-a8c6-5520e6fdb2d3 -> ../../sdh1
lrwxrwxrwx. 1 root root 10 Apr  6 17:28 379b46a0-bf93-432d-b103-c38f5919734f -> ../../dm-0
lrwxrwxrwx. 1 root root 15 Apr  6 17:47 37af34bb-475f-4fd2-8452-94973b34e1c3 -> ../../nvme0n1p2
lrwxrwxrwx. 1 root root 10 Apr  3 08:51 64624e0c-b6db-47db-bed5-ee1db00109e7 -> ../../sdg1
lrwxrwxrwx. 1 root root 11 Apr  6 17:44 648abd62-153b-4aa6-b451-7da97244831a -> ../../dm-10
~~~

You can see **648abd62-153b-4aa6-b451-7da97244831a -> ../../dm-10** is what you're after.

So in ```/etc/fstab``` you enter at the end:

~~~
UUID=648abd62-153b-4aa6-b451-7da97244831a /raid auto defaults 0 0
~~~

to mount at boot at ```/raid```.


Source: https://blog.programster.org/create-raid-with-lvm






