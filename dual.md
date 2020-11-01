Disclaimer: You do this at your own risk.

**What you want to achieve:**

Install Pop!\_OS after Windows on the same drive. You want a menu to pop up after POST so that you can select Pop or Windows.

**What is happening:**

Pop!\_OS uses systemd-boot to start up. This is not grub. It is simple once you get the concept.

**How to make the menu appear:**

First lets make the menu appear. Normally you need to press the spacebar after POST to make the menu appear. If you want the menu to appear every time, you need to add a timeout to the config file that controls the menu.

This is done by modifying  /boot/efi/loader/loader.conf file to add a timeout, so the file looks like this:

    default Pop_OS-current 
    timeout 5 

This menu will appear for 5 seconds (hint 5 in the line above). If you want to change the default, you know what to do.

If you reboot now, the menu will pop up, but the options you will see are only

* Pop\_OS-current kernel
* Pop\_OS-previous kernel
* UEFI menu

The last option just takes you to your systems UEFI (legacy BIOS not supported)

The two Pop entries are for redundancy. If a new kernel update breaks your system, you can always boot the old one and remove it.

**How to make Windows appear as an option:**

For Windows to appear as an option, systemd-boot requires its EFI files to be in the same partition as those of Pop. You cannot use Windows's EFI partition because it is too small, otherwise, during installation, you could just use that partition for Pop too.

So you will need to copy Windows EFI files onto Pop's EFI partition (that's why when installing its a good idea to make this large, 1GB to be safe).

Find Windows EFI partition and mount it under Pop! so you can copy the files. The Windows partition contains an EFI folder with two subfolders: "Boot" and "Microsoft".

Copy the Microsoft folder to  /boot/efi/EFI

This folder also contains  a "Pop\_OS-fe5b298c-b5ab-4b9d-8476-b5ff61d93baf" folder, along with Recovery, Linux, BOOT, and systemd. The long string after the Pop\_OS will be different in your system.

That's it.

Now the menu will appear as follows:

* Pop\_OS-current kernel
* Pop\_OS-previous kernel
* Windows
* UEFI menu

**What to set UEFI boot options to:**

Set your UEFI to boot from Pop. This will offer you the menu you just made at every boot, and you can boot Windows from it.

**How to make Windows the default boot option:**

You will need to create a little loader configuration file. These live inside /boot/efi/loader/entries.

Create a file named Windows.conf

with content:

    title Windows Boot Manager
    efi \EFI\Microsoft\Boot\bootmgfw.efi

The title can be anything, it appears on the menu at boot. The second line indeed has backwards slashes, just check that the file bootmgfw.efi is indeed in /boot/efi/EFI/Microsoft/Boot/

You can chose Linux on boot from the menu, or by holding L after POST.

\-------------------------------------------------------------------

DISCLAIMER: You do this at your own risk.

&#x200B;

Edit: Tips.

You can reboot from Pop to UEFI (firmware) settings by issuing:

    systemctl reboot --firmware-setup 

or (if you dual boot with Windows), you can reboot to Windows (straight after reboot, no other input required) by issuing:

    systemctl reboot --boot-loader-entry=auto-windows 

If you have multiple kernels you can also change the part after --boot-loader-entry= to do that.

Finally, if you want to boot to Windows after POST, you can just hold "**w**" rather than bring up the menu with **space** and select. For linux you just hold "**l**" (letter L).

&#x200B;

I hope this helps.

&#x200B;
