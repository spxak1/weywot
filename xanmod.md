# Xanmod installation/removal guide

Proceed with caution as this may ruin your system.

Disclaimer: I take no responsibility for this, try it at your own risk.

Background: I've been trying to get a simple way to remove xanmod without breaking my system for sometime. The common ending if things go wrong is for the xanmod kernel to stay AND the /boot/efi partition to disappear.

Try in a non production system to make sure this works before you do it in your main production rig.

&#x200B;

**Install as per normal (from** [xanmod's site.](https://xanmod.org/)**)**

    echo 'deb http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-kernel.list && wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key add -  
    
    sudo apt update && sudo apt install linux-xanmod 

This installs xanmod which now boots as Pop\_OS-current in the boot menu.

This means that vmlinuz.efi and initrd.img in /efi/EFI/Pop\_OS-XXXXXX/ are xanmod, and the config entry in /boot/efi/loader/entries/Pop\_OS-current.conf points to these files, and as such boots xanmod.

So no you have xanmod on "current" and the previous to new (5.8 today) onPop\_OS-oldkern.conf (along with the files this config points to, initrd.img-previous and vmlinuz-previous.efi).

All should work fine. Reboot. Ready with the new kernel.

**WARNING**

Note: At this point, every time you do "sudo apt upgrade" you will be told that a set of kernel files (linux-headers, linux-image, linux-modules and linux-modules-extra) can be removed because they are not used, with autoremove.

This will remove the kernel that before you installed xanmod would boot if the "oldkernel" was selected at boot time (spacebar at POST).

If you proceed with autoremove, this kernel will be removed and while you have xanmod installed,  you will have the (previously current, now old) kernel 5.8 (at the time of writing) to fall back to.

However, if you remove xanmod and go back to stock, there will be no OLD kernel to use for the oldkernel option and you will be left with a single bootable kernel in your system, something that is **not advisable.** So proceed with caution.

You can hide this kernel from autoremove, by doing:

    sudo apt-mark manual linux-headers-5.4.0-7625 linux-headers-5.4.0-7625-generic linux-image-5.4.0-7625-generic linux-modules-5.4.0-7625-generic linux-modules-extra-5.4.0-7625-generic

This will mark these packages for manual update/removal only. If you ever want them to reappear in the autoremove command (and handled automatically), you can "undo" the above command with:

    sudo apt-mark auto linux-headers-5.4.0-7625 linux-headers-5.4.0-7625-generic linux-image-5.4.0-7625-generic linux-modules-5.4.0-7625-generic linux-modules-extra-5.4.0-7625-generic

Obviously the kernel packages above are for the current (10/2020) state of affairs, replace in the future as required, don't just copy commands across.

**Uninstall as per normal**

    sudo apt remove --purge linux-xanmod linux-image-5.8.17-xanmod1 

(note: the linux-image name changes with newer versions of the kernel, look into /boot to find it and type it above).

And now for the crucial part: rebuild systemd-boot:

    sudo update-initramfs -u 

This will put the latest stock kernel (5.8 at this point) back to the "current entry". That's it.

Reboot. Back to stock as if nothing happened.

Nice and clean.

Note: This may well work with other kernels, but has only been tested with xanmod. Good luck.
