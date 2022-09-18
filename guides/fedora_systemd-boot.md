# How to make Fedora (36/37) use systemd-boot (WIP)

Some info from here: https://kowalski7cc.xyz/blog/systemd-boot-fedora-32

This is on a dual boot with Pop, so systemd-boot stub is already installed, and the ESP already has the expected layout. this is:

~~~
[root@galileo efi]# tree
.
├── EFI
│   ├── 6b2ace2249194d7abf60d6f185ced47c
│   │   ├── initramfs-5.19.9-300.fc37.x86_64.img
│   │   └── vmlinuz-5.19.9-300.fc37.x86_64
│   ├── BOOT
│   │   ├── BOOTIA32.EFI
│   │   ├── BOOTX64.EFI
│   │   ├── fbia32.efi
│   │   └── fbx64.efi
│   ├── fedora
│   │   ├── BOOTIA32.CSV
│   │   ├── BOOTX64.CSV
│   │   ├── gcdia32.efi
│   │   ├── gcdx64.efi
│   │   ├── grub.cfg
│   │   ├── grubia32.efi
│   │   ├── grubx64.efi
│   │   ├── mmia32.efi
│   │   ├── mmx64.efi
│   │   ├── shim.efi
│   │   ├── shimia32.efi
│   │   └── shimx64.efi
│   ├── Pop_OS-e7903666-0208-4fc3-9c3c-d3862ab6a447
│   │   ├── cmdline
│   │   ├── initrd.img
│   │   ├── initrd.img-previous
│   │   ├── vmlinuz.efi
│   │   └── vmlinuz-previous.efi
│   ├── Recovery-54D3-B654
│   │   ├── initrd.gz
│   │   └── vmlinuz.efi
│   ├── shellx64.efi
│   └── systemd
│       └── systemd-bootx64.efi
├── loader
│   ├── entries
│   │   ├── 6b2ace2249194d7abf60d6f185ced47c-5.19.9-300.fc37.x86_64.conf
│   │   ├── Fedora_37.conf
│   │   ├── Fedora.conf
│   │   ├── Pop_OS-current.conf
│   │   ├── Pop_OS-oldkern.conf
│   │   └── Recovery-54D3-B654.conf
│   ├── entries.srel
│   ├── loader.conf
│   └── random-seed
├── mach_kernel
├── shellx64.efi
├── System
│   └── Library
│       └── CoreServices
│           └── SystemVersion.plist
└── System Volume Information
~~~

The above tree already includes the folder I made, at the very top ```6b2ace2249194d7abf60d6f185ced47c``` 

## Principle

For systemd-boot to work you need:
### The systemd-boot stub

Typically in ```systemd```. This is already in place. Pop put it there. But this is easy to install with ```sudo bootctl install```. 
This also puts a boot entry in the bios, typically named Linux Boot or similar.


### The kernel and initramfs

This, you need to do manually! That's where the ```6b2ace2249194d7abf60d6f185ced47c``` comes it.

### A loader entry file

This, you copy from Fedora's own, and modify

## Put Fedora's kernel and initramfs in the ESP

Systemd-boot can only read files on the ESP. Nowhere else, regardless of filesystem. So you need to create a folder to host the files.

I use the machine-id. I assume you're root (```sudo su```) and already at the ESP (```/boot/efi```) and inside the ```EFI``` folder.
So your path should be ```/boot/efi/EFI```.

 ```mkdir $(cat /etc/machine-id)```

This creates the ```6b2ace2249194d7abf60d6f185ced47c``` for me. It can probably be any name you want, but haven't tried.

Now you need the kernel and initramfs. These are found in ```/boot```. 

~~~
[root@galileo efi]# cd /boot/
[root@galileo boot]# ls
config-5.19.7-300.fc37.x86_64                            symvers-5.19.7-300.fc37.x86_64.gz
config-5.19.8-300.fc37.x86_64                            symvers-5.19.8-300.fc37.x86_64.gz
config-5.19.9-300.fc37.x86_64                            symvers-5.19.9-300.fc37.x86_64.gz
efi                                                      System.map-5.19.7-300.fc37.x86_64
grub2                                                    System.map-5.19.8-300.fc37.x86_64
initramfs-0-rescue-6b2ace2249194d7abf60d6f185ced47c.img  System.map-5.19.9-300.fc37.x86_64
initramfs-5.19.7-300.fc37.x86_64.img                     vmlinuz-0-rescue-6b2ace2249194d7abf60d6f185ced47c
initramfs-5.19.8-300.fc37.x86_64.img                     vmlinuz-5.19.7-300.fc37.x86_64
initramfs-5.19.9-300.fc37.x86_64.img                     vmlinuz-5.19.8-300.fc37.x86_64
loader                                                   vmlinuz-5.19.9-300.fc37.x86_64
~~~

There they are. Only the latest are needed: 

The kernel: ```vmlinuz-5.19.9-300.fc37.x86_64```
The initramfs: ```initramfs-5.19.9-300.fc37.x86_64.img```

Copy these two files in the new folder:

```[root@galileo boot]# cp vmlinuz-5.19.9-300.fc37.x86_64 initramfs-5.19.9-300.fc37.x86_64.img /boot/efi/EFI/6b2ace2249194d7abf60d6f185ced47c/```

Done

## Copy the loader file over

In the ESP there is a ```loader``` folder and inside it an ```entries``` folder. This is the target. 
That's where systemd-boot finds all the entries to its menu.

Fedora has a loader file that it uses with grub. This will do. It's found in ```/boot/loader/entries``` 

Note this is not the same as the target, ```/boot/efi/loaders/entries```. These not only are nested folders, but ```/boot/efi``` is a *different partition*.

~~~
[root@galileo entries]# pwd
/boot/loader/entries
[root@galileo entries]# ls
6b2ace2249194d7abf60d6f185ced47c-0-rescue.conf                6b2ace2249194d7abf60d6f185ced47c-5.19.8-300.fc37.x86_64.conf
6b2ace2249194d7abf60d6f185ced47c-5.19.7-300.fc37.x86_64.conf  6b2ace2249194d7abf60d6f185ced47c-5.19.9-300.fc37.x86_64.conf
~~~

The loader for the kernel we use has the same name. The firs part is the machine-id, same as the one I used for the folder where we stored the kernel and initramfs.
Then the kernel number. So for ```5.19.9-300.fc37.x86_64``` which we copied, we need ```6b2ace2249194d7abf60d6f185ced47c-5.19.9-300.fc37.x86_64.conf```.

Copy it over to the ESP loader entries folder: ```[root@galileo entries]# cp 6b2ace2249194d7abf60d6f185ced47c-5.19.9-300.fc37.x86_64.conf /boot/efi/loader/entries
```

Now, go to the **copied** file and edit it. Here what mine looks like:

~~~
title Fedora Linux (5.19.9-300.fc37.x86_64) 37 (Workstation Edition Prerelease)
version 5.19.9-300.fc37.x86_64
linux /root/boot/vmlinuz-5.19.9-300.fc37.x86_64
initrd /root/boot/initramfs-5.19.9-300.fc37.x86_64.img
options root=UUID=b6b8fa59-92cc-4d03-8d8f-d66dab76d433 ro rootflags=subvol=root resume=UUID=fb661671-97dc-45db-b720-062acdcf095e>
grub_users $grub_users
grub_arg --unrestricted
grub_class fedora
~~~

All we need to change is the path to kernel and initrd. So look for the lines starting with ```linux``` and ```initrd```.

### Kernel

Before:
~~~
linux /root/boot/vmlinuz-5.19.9-300.fc37.x86_64
~~~

And after:
~~~
linux /EFI/6b2ace2249194d7abf60d6f185ced47c/vmlinuz-5.19.9-300.fc37.x86_64
~~~

### Initrd

Before
~~~
initrd /root/boot/initramfs-5.19.9-300.fc37.x86_64.img
~~~

After
~~~
initrd /EFI/6b2ace2249194d7abf60d6f185ced47c/initramfs-5.19.9-300.fc37.x86_64.img
~~~

That's it. Reboot. You'll find the new entry named ```title Fedora Linux (5.19.9-300.fc37.x86_64) 37 (Workstation Edition Prerelease)```. Select and watch it boot.

**This is work in progress**. 
I will add:
* installation without Pop.
* maintenance (how to keep two kernels available, how to automate copying kernels/intird and editing entry loaders)
* possible use of kernelstub






