# How to add a boot option in your bios menu (UEFI) for any OS.

## See alternative (if applicable) at the end!

It is frequent for some motherboards bios to lose entries to boot operatiing systems. This may happen on disconnection and reconnection of drive that contains the operating system (and the EFI partition. It may also happen when a new operating system is added along side an existing one.

## Process

### 1. Find where the EFI partition is located with ```lsblk```

~~~
sudo lsblk -o name,size,fstype,parttype,partuuid
~~~

There is some excess information here, but better have it.

This is a sample output:

~~~
NAME     SIZE FSTYPE PARTTYPE                             PARTUUID
sda    465.8G                                             
├─sda1     2G vfat   c12a7328-f81f-11d2-ba4b-00a0c93ec93b 697685f3-e003-4cd4-a7be-b07bbcf4497e
├─sda2     4G vfat   ebd0a0a2-b9e5-4433-87c0-68b6b72699c7 a9fbe686-9f08-487c-9bc9-db094845b8c2
├─sda3  88.8G ext4   0fc63daf-8483-4772-8e79-3d69d8477de4 63b38b7c-c4d9-4452-9403-127034ea8ebd
├─sda4  92.3G ntfs   ebd0a0a2-b9e5-4433-87c0-68b6b72699c7 f4e2f022-d94d-4c43-aca2-064d4d7c9c73
├─sda5   503M ntfs   de94bba4-06d1-4d40-a16a-bfd50179d6ac ebd981cd-0726-4340-866f-66d1cfd8d93a
├─sda6  92.8G ext4   0fc63daf-8483-4772-8e79-3d69d8477de4 edf80ad9-2a9f-449e-b4da-5808931b6242
├─sda7  92.8G ext4   0fc63daf-8483-4772-8e79-3d69d8477de4 27166423-7ae0-41dc-a493-8a26c68b80ff
└─sda8  92.8G ext4   0fc63daf-8483-4772-8e79-3d69d8477de4 6e43e0bf-306d-4559-b293-440003d5c044
~~~

The first partition, ```/dev/sda1``` is the EFI partition. 

You can tell by the fact it's VFAT, and mainly because the partition type is ```c12a7328-f81f-11d2-ba4b-00a0c93ec93b``` (see [here](https://en.wikipedia.org/wiki/EFI_system_partition)).

### 2. Use efibootmgr to create the new entry

~~~
sudo efibootmgr -c -d /dev/sda -p 1 -L PopOS -l \\EFI\\systemd\\systemd-bootx64.efi
~~~

This points to the proper disk (```-d /dev/sda```) and the proper partition on that disk (```-p 1```), gives a label (```-L PopOS```) and locates the bootable stub (```-l \\EFI\\systemd\\systemd-bootx64.efi```)

Things to note:

1. This boots the systemd-boot stub (i.e the default Pop_OS boot menu)
2. The location of the stub file needs **double** ``\\```.
3. The EFI partition is vfat, so capitals/small letters don't matter, you can type locations with either, mix, whatever.
4. The location of the stub is absolute in terms of the partition, but relative when the partition is mounted in ```/boot/efi```.

## Other distributions (with grub)

Same process, only this time you will need the bootable stub for grub.

Typically if you look into your ```/boot/efi``` folder (for your installation), you will find a folder named after your distribution.

Here's an example of an EFI partition that holds many distributions:

~~~
drwx------ 2 root root 4096 Oct 15 09:12 BOOT
drwx------ 2 root root 4096 Oct  1 09:14 fedora
drwx------ 2 root root 4096 Jan  1  2021 Linux
drwx------ 2 root root 4096 Jan  1  2021 Manjaro
drwx------ 4 root root 4096 Jan  1  2021 Microsoft
drwx------ 2 root root 4096 Oct 18 10:17 Pop_OS-f925d79c-a485-43cf-8cd2-2d24cdea718b
drwx------ 2 root root 4096 Jan 10  2021 Recovery-7827-FA9E
drwx------ 6 root root 4096 Oct 20 19:14 refind
drwx------ 2 root root 4096 Oct 15 09:12 systemd
drwx------ 2 root root 4096 Oct 20 16:51 tools
drwx------ 2 root root 4096 Jan  1  2021 ubuntu
~~~

### Ubuntu

Replace the location of the file with ```\\EFI\\ubuntu\\grubx64.efi```

### Fedora

Replace the location of the file with ```\\EFI\\FEDORA\\shimx64.efi```

### Manjaro 

Replace the location of the file with ```\\EFI\manjaro\\grubx64.efi```

### Windows

Replace the location of the file with ```\\EFI\\Microsoft\\Boot\\bootmgfw.efi```


## Troubleshooting

If you can see the boot entry in the bios after this, but still fail to boot, check the contents of your EFI partition to confirm the locations of the stub files are correct.

## Alternative

Most motherboard UEFIs will look for a folder named ```boot``` in the (only) partition they can read on the drive, and in particular inside ```/boot/efi/EFI```.

Boot off a live USB, mount ```/boot/efi/EFI``` and check if there is a ```boot``` folder in there, and inside it a ```bootx64.efi``` file. That's the absolute default the UEFI looks for to boot from if there is no entry.

That's how it boots off the Live USB (which obviously has no entry in the UEFI). 

If you have not ```boot``` folder with that file in there, you just copy your distributions folder. 

* For Pop_OS you copy ```systemd``` to ```boot``` and then rename ```boot/systemd-bootx64.efi``` to ```/boot/bootx64.efi``` (actually that's what the default is).
* For grub basaed distributions, you can either copy your distributions folder (e.g. fedora) and inside of it rename the ```shimx64.efi``` file to ```bootx64.efi```. Or you can create ```boot``` and copy ```shimx64.efi``` and rename it to ```bootx64.efi```.

Reboot. 

For Pop_OS, once you boot to your installation you can run ```sudo bootctl --path=/boot/efi install```. Most of it is redundand as it just performs what you just did above, but in addition it creates the UEFI boot entry (under the name ```Linux Boot Manager```). Or you can do it yourself as described furher up with ```efibootmgr```.

For other (grub based) distros, you need to add the boot entry manually with ```efibootmgr``` as discribed further up.


