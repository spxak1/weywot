# Kernel upgrade fails to run dracut, no initrd

**TL/DR**: Remove or rename ```/boot/loader```.

This has happened on a number of occasions. Typically if:

* you convert from grub to systemd-boot
* you remove ```/boot``` as a separate partition and put in the root

On the first kernel upgrade you get an error in the shape of:
~~~
Can't write to /boot/2069f29eee9b43b1b13f4dad9f35449e/6.8.10-300.fc40.x86_64: Directory /boot/2069f29eee9b43b1b13f4dad9f35449e/6.8.10-300.fc40.x86_64 does not exist or is not accessible.
/usr/lib/kernel/install.d/50-dracut.install failed with exit status 1.
~~~

Now what happens here is that once the new kernel is installed, it's placed in a folder like this ```/lib/modules/6.8.10-300.fc40.x86_64```.

Then, ```kernel-install``` runs to make the kernel and initrd available to boot. 

Typically a command like this does the job:
~~~
kernel-install add 6.8.10-300.fc40.x86_64 /lib/modules/6.8.10-300.fc40.x86_64/vmlinuz
~~~

```kernel-install``` is a script. [Its source is here](https://github.com/ivandavidov/systemd-boot/blob/master/project/src/kernel-install/kernel-install)

It has a number of other scripts as part of it:

~~~
kernel-install inspect
        Machine ID: 2069f29eee9b43b1b13f4dad9f35449e
 Kernel Image Type: pe
            Layout: bls
         Boot Root: /boot/efi
  Entry Token Type: machine-id
       Entry Token: 2069f29eee9b43b1b13f4dad9f35449e
   Entry Directory: /boot/efi/2069f29eee9b43b1b13f4dad9f35449e/6.8.11-300.fc40.x86_64
    Kernel Version: 6.8.11-300.fc40.x86_64
            Kernel: /usr/lib/modules/6.8.11-300.fc40.x86_64/vmlinuz
           Initrds: (unset)                                                          
  Initrd Generator: (unset)                                                          
     UKI Generator: (unset)                                                          
           Plugins: /usr/lib/kernel/install.d/20-grub.install
                    /usr/lib/kernel/install.d/50-depmod.install
                    /usr/lib/kernel/install.d/50-dracut.install
                    /usr/lib/kernel/install.d/51-dracut-rescue.install
                    /usr/lib/kernel/install.d/60-kdump.install
                    /usr/lib/kernel/install.d/90-loaderentry.install
                    /usr/lib/kernel/install.d/90-uki-copy.install
                    /usr/lib/kernel/install.d/92-crashkernel.install
                    /usr/lib/kernel/install.d/99-grub-mkconfig.install
Plugin Environment: LC_COLLATE=C.UTF-8
                    KERNEL_INSTALL_VERBOSE=0
                    KERNEL_INSTALL_IMAGE_TYPE=pe
                    KERNEL_INSTALL_MACHINE_ID=2069f29eee9b43b1b13f4dad9f35449e
                    KERNEL_INSTALL_ENTRY_TOKEN=2069f29eee9b43b1b13f4dad9f35449e
                    KERNEL_INSTALL_BOOT_ROOT=/boot/efi
                    KERNEL_INSTALL_LAYOUT=bls
                    KERNEL_INSTALL_INITRD_GENERATOR=
                    KERNEL_INSTALL_UKI_GENERATOR=
                    KERNEL_INSTALL_STAGING_AREA=/tmp/kernel-install.staging.XXXXXX
  Plugin Arguments: add|remove
                    6.8.11-300.fc40.x86_64
                    /boot/efi/2069f29eee9b43b1b13f4dad9f35449e/6.8.11-300.fc40.x86_64
                    /usr/lib/modules/6.8.11-300.fc40.x86_64/vmlinuz
                    [INITRD...]
~~~

Now, the script knows where to put the kernel ```vmlinuz```, as it is declared in ```/etc/kernel/install.conf```, and it's ```BOOT_ROOT=/boot/efi```.

However, in ```/usr/lib/kernel/install.d/50-dracut.install```, the location of the ```initrd``` ends up being in ```/boot```.

The reason for that is these lines in the scripti:

~~~
if [[ -d "$BOOT_DIR_ABS" ]]; then
    INITRD="initrd"
else
    # No layout information, use users --uefi/--no-uefi preference
    UEFI_OPTS=""
    if [[ -d $BOOT_DIR_ABS ]]; then
        IMAGE="initrd"
    else
        BOOT_DIR_ABS="/boot"
        IMAGE="initramfs-${KERNEL_VERSION}.img"
    fi
fi
~~~

The variable ```$BOOT_DIR_ABS``` in turn is assigned in the main part of the ```kernel-install``` script here:
~~~
if [[ -d /efi/loader/entries ]] || [[ -d /efi/$MACHINE_ID ]]; then
    BOOT_DIR_ABS="/efi/$MACHINE_ID/$KERNEL_VERSION"
elif [[ -d /boot/loader/entries ]] || [[ -d /boot/$MACHINE_ID ]]; then
    BOOT_DIR_ABS="/boot/$MACHINE_ID/$KERNEL_VERSION"
elif [[ -d /boot/efi/loader/entries ]] || [[ -d /boot/efi/$MACHINE_ID ]]; then
    BOOT_DIR_ABS="/boot/efi/$MACHINE_ID/$KERNEL_VERSION"
elif mountpoint -q /efi; then
    BOOT_DIR_ABS="/efi/$MACHINE_ID/$KERNEL_VERSION"
elif mountpoint -q /boot/efi; then
    BOOT_DIR_ABS="/boot/efi/$MACHINE_ID/$KERNEL_VERSION"
else
    BOOT_DIR_ABS="/boot/$MACHINE_ID/$KERNEL_VERSION"
fi
~~~

Now the problem is solved. The location is decided based on where the ```loader``` folder is.

If you install Fedora with grub, the ```loader``` folder is in ```/boot/loader```. So if you run ```kernel-install``` the location for the initrd becomes ```/boot/$MACHINE_ID```.

When you convert to ```systemd-boot``` the ```loader``` folder is copied in ```/boot/efi```, but clearly ```kernel-install``` looks for it **first``` inside of ```/boot```.

**You need to remove/rename** the ```/boot/loader``` folder, so that when ```kernel-install``` runs, it doesn't find it in ```/boot```, instead it finds it in ```/boot/efi``` and as such proceed to assign the location of the initrd in the **correct** folder, inside of ```/boot/efi``` rather than ```/boot```.

