# Fedora 36/37 with systemd-boot and kernelstub

This is a simple guide and it does not remove grub.

This is on a clean install of Fedora 37 beta, but it works the same on 36.
An automatic partition has been used. 



Current disk layout:
~~~
[otheos@brahe ~]$ lsblk -o name,fstype,uuid,mountpoints
NAME   FSTYPE UUID                                 MOUNTPOINTS
sda                                                
├─sda1 vfat   EDD2-2B6B                            /boot/efi
├─sda2 ext4   e7a200bb-2c26-4fb4-b120-764fda7a5378 /boot
└─sda3 btrfs  acfa66bf-3738-4b70-86e8-7841a05b633c /home
                                                   /
zram0                                              [SWAP]
~~~


## Install systemd-boot
As root:
~~~
[root@brahe otheos]# bootctl install 
Created "/boot/efi/EFI/systemd".
Created "/boot/efi/loader".
Created "/boot/efi/loader/entries".
Created "/boot/efi/EFI/Linux".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi" to "/boot/efi/EFI/systemd/systemd-bootx64.efi".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi" to "/boot/efi/EFI/BOOT/BOOTX64.EFI".
Random seed file /boot/efi/loader/random-seed successfully written (32 bytes).
Created EFI boot entry "Linux Boot Manager".
~~~

This has created the required folders in the ESP, placed the systemd-boot efi stubs in there, and created a boot entry in the bios. 
You can now boot using systemd-boot by selecting "Linux Boot Manager" in your Bios. Fedora will still boot to grub, as per usual

Your ESP now looks like this:
~~~
[root@brahe otheos]# cd /boot/efi/EFI/
[root@brahe EFI]# ls
BOOT  fedora   Linux  systemd
~~~

The ```fedora``` folder is the original grub bootloader. ```systemd``` is what has been added. 


## Install kernelstub
Please find the project page here: https://github.com/isantop/kernelstub

~~~
otheos@brahe ~]$ mkdir git
[otheos@brahe ~]$ cd git
[otheos@brahe git]$ git clone https://github.com/isantop/kernelstub
Cloning into 'kernelstub'...
remote: Enumerating objects: 1307, done.
remote: Counting objects: 100% (6/6), done.
remote: Compressing objects: 100% (6/6), done.
remote: Total 1307 (delta 0), reused 5 (delta 0), pack-reused 1301
Receiving objects: 100% (1307/1307), 380.85 KiB | 2.82 MiB/s, done.
Resolving deltas: 100% (759/759), done.
~~~

~~~
[otheos@brahe kernelstub]$ sudo ./setup.py install > installed_files.txt
/usr/lib/python3.11/site-packages/setuptools/command/install.py:34: SetuptoolsDeprecationWarning: setup.py install is deprecated. Use build and pip and other standards-based tools.
  warnings.warn(
/usr/lib/python3.11/site-packages/setuptools/command/easy_install.py:144: EasyInstallDeprecationWarning: easy_install command is deprecated. Use build and pip and other standards-based tools.
  warnings.warn(
zip_safe flag not set; analyzing archive contents...
~~~

Check kernelstub has been installed:

~~~
[otheos@brahe ~]$ sudo kernelstub --help
usage: kernelstub [-h] [-p] [-e ESP,] [--esp-path ESP] [-r ROOT] [--root-path ROOT] [-k PATH,] [--kernel-path PATH] [-i PATH,]
                  [--initrd-path PATH] [-o "OPTIONS",] [--options "OPTIONS"] [-a "OPTIONS",] [--add-options "OPTIONS"] [-d OPTIONS]
                  [--delete-options "OPTIONS"] [-g LOG] [--log-file LOG] [-l | -n  -s | -m] [-f] [-v]

Automatic Kernel EFIstub manager
~~~

Find (and add) your kernel options.
~~~
otheos@brahe ~]$ cat /etc/kernel/cmdline 
root=UUID=acfa66bf-3738-4b70-86e8-7841a05b633c ro rootflags=subvol=root rhgb quiet
~~~
These are the minimum required options (default). You need those as default.

Find the kernel and initramfs:

~~~
[otheos@brahe ~]$ ls /boot
config-5.19.7-300.fc37.x86_64
efi
grub2
initramfs-0-rescue-e1228775572d405583e9bbee05d18a6b.img
initramfs-5.19.7-300.fc37.x86_64.img
loader
lost+found
symvers-5.19.7-300.fc37.x86_64.gz
System.map-5.19.7-300.fc37.x86_64
vmlinuz-0-rescue-e1228775572d405583e9bbee05d18a6b
vmlinuz-5.19.7-300.fc37.x86_64
~~~

There they are: ```vmlinuz-5.19.7-300.fc37.x86_64``` and ```initramfs-5.19.7-300.fc37.x86_64.img```

Prepare the command:

~~~
[otheos@brahe ~]$ sudo kernelstub -m -l -o "root=UUID=acfa66bf-3738-4b70-86e8-7841a05b633c ro rootflags=subvol=root rhgb quiet" -k /boot/vmlinuz-5.19.7-300.fc37.x86_64 -i /boot/initramfs-5.19.7-300.fc37.x86_64.img 
~~~

This has now done the following:

### Created a folder in the ESP. This is what your ESP looks now:

~~~
[root@brahe otheos]# cd /boot/efi/EFI/
[root@brahe EFI]# ls
BOOT  fedora  Fedora_Linux-acfa66bf-3738-4b70-86e8-7841a05b633c  Linux  systemd
~~~

The new entry is ```Fedora_Linux-acfa66bf-3738-4b70-86e8-7841a05b633c```. note the long string ```acfa66bf-3738-4b70-86e8-7841a05b633c``` is simply your root partition's UUID.
In this folder, kernelstub has copied the kernel, the initrd and the cmdline (options). 

~~~
[root@brahe EFI]# cd Fedora_Linux-acfa66bf-3738-4b70-86e8-7841a05b633c/
[root@brahe Fedora_Linux-acfa66bf-3738-4b70-86e8-7841a05b633c]# ls
cmdline  initrd.img  vmlinuz.efi
~~~

### Created the loader file (the entry to the menu)

This is found in ```/boot/efi/loader/entries```

~~~
[root@brahe ~]# cd /boot/efi/loader/entries/
[root@brahe entries]# ls
'Fedora_Linux-brahe(acfa66bf)-current.conf'
~~~

The contents of this file are:#

~~~
[root@brahe entries]# cat Fedora_Linux-brahe\(acfa66bf\)-current.conf 
title Fedora Linux (brahe)
linux /EFI/Fedora_Linux-acfa66bf-3738-4b70-86e8-7841a05b633c/vmlinuz.efi
initrd /EFI/Fedora_Linux-acfa66bf-3738-4b70-86e8-7841a05b633c/initrd.img
options root=UUID=acfa66bf-3738-4b70-86e8-7841a05b633c ro root=UUID=acfa66bf-3738-4b70-86e8-7841a05b633c ro rootflags=subvol=root rhgb quiet
~~~

### Created the kernelstub configuration file

This is found in ```/etc/kernelstub/configuration```

It looks like this.

~~~
[root@brahe kernelstub]# cat configuration 
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
      "root=UUID=acfa66bf-3738-4b70-86e8-7841a05b633c",
      "ro",
      "rootflags=subvol=root",
      "rhgb",
      "quiet"
    ],
    "esp_path": "/boot/efi",
    "setup_loader": true,
    "manage_mode": true,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3
  }
~~~

You can see the options you passed with ```-o``` are now saved in the user options and are used every time, no need to issue them again.
More importantly the ```setup_loader``` is also set to ```true``` in the user options (and that's sufficient), so you don't need the ```-l``` switch anymore.
This tells kernelstub to update the **loader** file everytime (you want that).
Finally the ```manage_mode``` is also set to ```true``` which means that kernelstub will **not** create a bios boot entry (this works too, but we're using systemd-boot instead). 

You are now ready for your first reboot. Remember to select **Linux Boot Manager** as the default option in your bios.

## Maintenance - after a kernel upgrade

This is still Work in progress.

The benefit of using kernelstub is that when a new kernel is added, it moves the old one in to a second boot entry, named *oldkern*, and then copies the new one.

In order to do this, kernelstub looks to backup the older kernel, but it looks for it with a specific name, that is the original, with an extension ```.old```.

In distributions with kernelstub (PopOS) a script runs after a kernel upgrade, which creates links and moves the old links to the ```.old``` place so that kernelstub can do its thing. 

Work in Progress! 






