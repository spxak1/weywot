# Install Pop_OS! with LUKS on a partition rather than the full drive
This is for those who want to share a drive with another OS (like Windows) and still want to keep LUKS encryption.
Currently Pop's installer only offers encryption when installing on the whole disk, and the custom installation where you can select partitions rather than the whole drive, does not provide a way to configure encryption with LUKS.

This guide uses as much GUI as possible, mainly because it's dead easy.

A video version of this is found here: [https://youtu.be/fgYeXLUoBfI](https://youtu.be/fgYeXLUoBfI).

**Read the video description for a small eratum**.

**Update**: Luks with TPM (no password) at the end!

## Preparation

Boot from USB to the Pop installer. Go through the first steps to configure language, keyboard etc, but then click on the left bottom corner to just try Pop, **do NOT install**.

![2024-01-31_22-19](https://github.com/spxak1/weywot/assets/29977030/973d2a18-7609-429a-8fa5-a8684fe0cdaa)


### Partitions

You need a minimum of 2 partitions to install Pop, but I use 3:
* The EFI System Partition (ESP), mounted on ```/boot/efi```. I use 2GB to have some space, and it **must** be FAT32.
* The ```/recovery``` partition. This is **not required** but it's one of Pop's nicest features so I always use it. You can skip this. It takes 4GB in FAT32.
* The ```/``` (root) partition. This is the one that will be encrypted. Use as much space as you want for this. I use 90GB and ```ext4```, the default filesystem for Pop. Guides with BTRFS are available, I will  also make one later.

I find ```gparted``` the easiest for the first two, but I use ```gnome-disks``` for the third one, as it is simpler.

First I clear my drive. Only do this if you start from scratch. If you already have other OS installed and you are installing Pop alongside **do NOT do this**.

![2024-01-31_22-20](https://github.com/spxak1/weywot/assets/29977030/6445386f-f8c0-4ca4-a52a-9e6c937d4ac3)


### On gparted

Create the ESP.

![2024-01-31_22-21](https://github.com/spxak1/weywot/assets/29977030/d6035c7a-1274-4ca4-a01d-86828688434a)

Then, the recovery partition.

![2024-01-31_22-45](https://github.com/spxak1/weywot/assets/29977030/c536c266-d4c2-4d2c-bb77-098c51753a4a)

Apply the changes.

![2024-01-31_22-22](https://github.com/spxak1/weywot/assets/29977030/a099d541-d65a-4ca5-8208-8b35f3a07d4c)

End result.

![2024-01-31_22-22_1](https://github.com/spxak1/weywot/assets/29977030/53c28615-b833-4f1e-90c9-2bafc3aa3abb)


### On gnome-disks

Select the drive on the list on the left, then select the free space to highlight it. Click on the + symbol.

![2024-01-31_22-23_1](https://github.com/spxak1/weywot/assets/29977030/b41f8913-fdd0-4f18-a37e-cdddaa1e55a5)

Add a new partition, select the size (I chose 90GB).

![2024-01-31_22-23_2](https://github.com/spxak1/weywot/assets/29977030/0925472f-18dd-4e84-9c2b-c839f47278d2)

Click next, name the partition (I chose POPOS), and select ```ext4``` with encryption.

![2024-01-31_22-24](https://github.com/spxak1/weywot/assets/29977030/5eba80e1-0a60-4833-81b6-b87d4a89d63a)

Select a password you will **NEVER FORGET**, and apply.

![2024-01-31_22-25](https://github.com/spxak1/weywot/assets/29977030/ce725041-b95a-4223-9e64-b1858b097141)

## Install Pop

Fire up the installer from the dock, and select custom installation.

![2024-01-31_22-26](https://github.com/spxak1/weywot/assets/29977030/6b4d8973-21a2-4605-af39-64ab6d595ca7)

You are going to use the 3 partitions you created. That's what they look like. The pink one is the encrypted partition.

![2024-01-31_22-27](https://github.com/spxak1/weywot/assets/29977030/d067a96e-2ce1-413e-99e9-c8510cc6a304)

Click on the first one to set it to ```/boot/efi```.

![2024-01-31_22-27_1](https://github.com/spxak1/weywot/assets/29977030/6200b70f-509c-444a-8575-dc009a358cd7)

Click on the second one to set it to ```/recover```.

![2024-01-31_22-28](https://github.com/spxak1/weywot/assets/29977030/d2a2d231-de91-4c32-af08-c2a536eef88f)

Click on the pink partition to unlock it with the password you gave it in gnome-disks.

![2024-01-31_22-28_1](https://github.com/spxak1/weywot/assets/29977030/cc016660-b73b-45a9-b13a-baa67816acb7)

You can rename it from ```cryptdata``` to anything you want (but remember that name). I use ```popos``` (all small).

![2024-01-31_22-29](https://github.com/spxak1/weywot/assets/29977030/9d361896-3bf6-4045-bfa3-3eea90adcbe3)

The unlocked encryption appears. This is where you'll install your ```/```.

![2024-01-31_22-29_1](https://github.com/spxak1/weywot/assets/29977030/843feee1-ba8d-4d37-a857-fb9913947fa0)

Select the green partition to mount ```/``` on it.

![2024-01-31_22-30](https://github.com/spxak1/weywot/assets/29977030/5045976a-21d5-46a2-978f-3c86d36bfecf)

Click **Erase and Install** to proceed and complete the installation. Once done **DO NOT REBOOT**.

![2024-01-31_22-36](https://github.com/spxak1/weywot/assets/29977030/c6603952-a6f3-4f77-8882-82978c559a5f)


## Post installation configuration
This is where we are going to complete the configuration. Pop doesn't know there is encryption on its ```/```. 
So we will have to fix this. 

We are going to:
* Tell Pop there is an encrypted partition by adding it to ```/etc/crypttab``` so that it unlocks at boot
* ```chroot``` to the system to update the ```initramfs``` to add this change to the boot process.

### Mount the encrypted drive

When Pop finishes installation, the encrypted drive is still unlocked and can be accessed. 

Become ```root``` to avoid ```sudo``` in all commands.

~~~
pop-os@pop-os:~$ sudo -i
root@pop-os:~# 
~~~

Mount the encrypted partition to ```/mnt```. You should know what partition that is. Check with ```lsblk```. 
In the same step you can find out that partitions ```UUID``` too. We need this.

~~~
root@pop-os:~# lsblk -o +uuid
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS UUID
loop0         7:0    0   2.6G  1 loop  /rofs       
sda           8:0    1  14.8G  0 disk              
├─sda1        8:1    1  14.7G  0 part              51BA-0E7D
│ └─ventoy  252:0    0   2.9G  0 dm    /cdrom      
└─sda2        8:2    1    32M  0 part              2024-01-26-07-14-13-00
zram0       251:0    0    16G  0 disk  [SWAP]      
nvme0n1     259:0    0 476.9G  0 disk              
├─nvme0n1p3 259:1    0  83.8G  0 part              a634142c-8d5a-4476-8e5f-55403f9ad6e0
│ └─popos   252:1    0  83.8G  0 crypt             2287d8f6-ec12-4b9d-9e12-a7a692205737
├─nvme0n1p1 259:3    0     2G  0 part              8004-C286
└─nvme0n1p2 259:4    0     4G  0 part              8011-BBB2
~~~

Let's undestand the above. ```/dev/sda``` is the USB stick we are installing from. 
The only other drive here is ```/dev/nvme0n1```. That's the drive you have partitioned at the start.

More importantly, you can see that the third partition ```/mnt/nvme0n1p3``` has ```popos```, the encrypted unit, attached to it.

This is what we are after. It's ```UUID``` is ```a634142c-8d5a-4476-8e5f-55403f9ad6e0```. **Your ```UUID``` will be different to mine.
Be careful, you need the ```UUID``` of the device partition, **not** the encrypted unit (popos). 

Mount the enrcypted unit (**not the device partition**). Remember, that's where the data is, The device partition doesn't hold the data but the unit (popos) that has the data. So, mount the unit.

~~~
root@pop-os:~# mount /dev/mapper/popos /mnt
~~~

This has mounted it to ```/mnt```. 


### Edit crypttab

Be careful. You need to edit the ```crypttab``` file of the new installation. That is ```/mnt/etc/crypttab```. 
Be careful **not** to edit the file on the USB stick, which is found in ```/etc/crypttab```. 

So, 
~~~
root@pop-os:~# pico /mnt/etc/crypttab 
~~~
In there you should add:
~~~
popos  UUID=a634142c-8d5a-4476-8e5f-55403f9ad6e0 none luks```.
~~~
Note, this is the ```UUID``` you copied from the previous step, the ```UUID``` of the device ```/dev/nvme0n1p3```. Remember your ```UUID``` will be different to mine.

Here you declare that the encrypted unit ```popos``` is on the device with that ```UUID```, has ```none``` decryption files and uses ```luks```.

Save and exit (if on pico/nano, CTRL+X).

### Chroot

The process of ```chroot``` is as if you boot to the new system and act from within. 
Let's first mount the rest of the partitions of the new installation, as well as all the other filesystems required for a system to run (such as ```/dev``` and ```/sys``` and ```/proc``` and such).

~~~
root@pop-os:~# for i in /dev /dev/pts /proc /sys /run; do mount -B $i /mnt$i; done
~~~

There is no output here, so proceed with:
~~~
root@pop-os:~# chroot /mnt
~~~

Mount the ESP! You need this to access the boot files.

~~~
root@pop-os:/# mount -av
/boot/efi                : successfully mounted
/recovery                : successfully mounted
/                        : ignored
~~~
The *ignored* message is because ```/``` is already mounted.

Update the ```initramfs```:
~~~
root@pop-os:/# update-initramfs -c -k all
~~~

This has a long output. Here's mine:

~~~
root@pop-os:/# update-initramfs -c -k all
update-initramfs: Generating /boot/initrd.img-6.6.10-76060610-generic
W: Possible missing firmware /lib/firmware/amdgpu/ip_discovery.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/vega10_cap.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/sienna_cichlid_cap.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/navi12_cap.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/psp_14_0_0_ta.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/psp_14_0_0_toc.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/psp_13_0_6_ta.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/psp_13_0_6_sos.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/aldebaran_cap.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/gc_9_4_3_rlc.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/gc_9_4_3_mec.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/gc_11_0_0_toc.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/sdma_4_4_2.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/sdma_6_1_0.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/sienna_cichlid_mes1.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/sienna_cichlid_mes.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/navi10_mes.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/gc_11_0_3_mes.bin for module amdgpu
W: Possible missing firmware /lib/firmware/amdgpu/vcn_4_0_3.bin for module amdgpu
kernelstub.Config    : INFO     Looking for configuration...
EFI variables are not supported on this system.
kernelstub.NVRAM     : ERROR    Failed to retrieve NVRAM data. Are you running in a chroot?
Traceback (most recent call last):
  File "/usr/lib/python3/dist-packages/kernelstub/nvram.py", line 54, in get_nvram
    return subprocess.check_output(command).decode('UTF-8').split('\n')
  File "/usr/lib/python3.10/subprocess.py", line 421, in check_output
    return run(*popenargs, stdout=PIPE, timeout=timeout, check=True,
  File "/usr/lib/python3.10/subprocess.py", line 526, in run
    raise CalledProcessError(retcode, process.args,
subprocess.CalledProcessError: Command '['efibootmgr']' returned non-zero exit status 2.
kernelstub           : INFO     System information: 

    OS:..................Pop!_OS 22.04
    Root partition:....../dev/dm-1
    Root FS UUID:........2287d8f6-ec12-4b9d-9e12-a7a692205737
    ESP Path:............/boot/efi
    ESP Partition:......./dev/nvme0n1p1
    ESP Partition #:.....1
    NVRAM entry #:.......-1
    Boot Variable #:.....0000
    Kernel Boot Options:.quiet loglevel=0 systemd.show_status=false splash
    Kernel Image Path:.../boot/vmlinuz-6.6.10-76060610-generic
    Initrd Image Path:.../boot/initrd.img-6.6.10-76060610-generic
    Force-overwrite:.....False

kernelstub.Installer : INFO     Copying Kernel into ESP
kernelstub.Installer : INFO     Copying initrd.img into ESP
kernelstub.Installer : INFO     Setting up loader.conf configuration
kernelstub.Installer : INFO     Making entry file for Pop!_OS
kernelstub.Installer : INFO     Backing up old kernel
kernelstub.Installer : INFO     No old kernel found, skipping
~~~

Scroll all the way to the top to check the first line for possible errors about anything including ```crypt``` or ```popos```. If you have any such errors, you've done something wrong. Go back and check what you've missed, then try again.

You can **ignore** any ```Possible missing firmware``` messages, they are normal.
Further down **ignore** ```ERROR    Failed to retrieve NVRAM data. Are you running in a chroot?```. It's normal, you *are* running in ```chroot```!
Finally **ignore** this ```Command '['efibootmgr']' returned non-zero exit status 2```. It's also normal.

That's it. Exit chroot:
~~~
root@pop-os:/# exit
exit
~~~

You can go back to the window waiting after you installed, to press reboot. Or just reboot any way you want. 
Once the system momentarily turns of before it turns back on **remove the USB stick** and boot Pop to the LUKS password prompt.

Enjoy.

## Configure TPM to avoid typing the LUKS password at boot.
This is taken from [here](https://askubuntu.com/questions/1470391/luks-tpm2-auto-unlock-at-boot-systemd-cryptenroll). First answer.

Boot to your new installation of Pop.

### Required packages

Simply install them all with:
~~~
sudo apt -y install clevis clevis-tpm2 clevis-luks clevis-initramfs initramfs-tools tss2
~~~

Here's the command:
~~~
sudo clevis luks bind -d /dev/nvme0n1p3 tpm2 '{"pcr_bank":"sha256"}' <<< "LUKSKEY"
Warning: Value 512 is outside of the allowed entropy range, adjusting it.
~~~

Check **your partition** that has the encrypted unit is correct. Mine is, as above, ```/dev/nvme0n1p3```.
Also **change LUKSKEY** to ***your** LUKS password. **KEEP** the quotes.

The warning is fine.

That's it. Update the ```initramfs``` to inform the boot process.
~~~
sudo update-initramfs -u -k all
~~~

Done. Reboot.

**Note:** You will still **see** and be able to type the LUKS password at boot. If you don't type anything, after a couple of seconds the drive will unlock and the booting process will proceed. This method using ```clevis``` has **no way** to remove the password prompt. It's a safety feature, to avoid getting locked out if TPM is reset.















