I wanted to be able to keep my distro hoping without changing my productivity system. This is how I installed Manjaro next to Pop.

# Disclaimer

This method worked on my system and I cannot see why it won't work with yours. It does involve performing some tasks that if executed poorly **you may lose all your data**. This involves resizing partitions, so it is **dangerous**. Also this process involves messing with the EFI partition which, if done poorly, **may make your system unbootable**. So, use at your own risk.

# Prerequisites

* Pop\_OS (20.10 in this case) installed first on SSD.
* 512MB /boot/efi default partition is enough for this (but not if you want to triple boot).
* Manjaro can be installed on the same SSD or on a separate SSD, makes no difference here where the **"/"** partition of Manjaro goes. If on separate SSD, you can just install normally and chose boot from your BIOS (or from efibootmgr).

# Prepare the SSD

**Skip this if you installing on a separate SSD**

You will need free space on the SSD. If your Pop\_OS takes it all up, you will need to resize. This is NOT done from Pop\_OS as **gparted** cannot resize a mounted partition.

Instead boot from USB or from recovery, run **gparted** and make some free space.
If it is not installed, open a terminal and do:

    sudo apt install gparted

# Start Manjaro from USB

Prepare your Manjaro USB, or, if you are like me, you can use [ventoy](https://www.ventoy.net/en/index.html) keep multiple bootable images on your stick.

In any event, start the installation process as per usual, and when asked where to install, select **manual**.

# Select partitions

You will only select **two** partitions: One for */boot/efi* and one for *"/"*.

## For **/boot/efi**

The important thing is to select the partition that Pop\_OS uses for its EFI (/boot/efi), and use it (**NOT FORMAT IT**) for Manjaro's /boot/efi. Typically this should be a FAT32 512MB partition. It should be easy to find.

Also mark it as boot in the options.

## For **"/"**

Here you select the free space you made earlier, or, if you're installing on a separate SSD, a partition on that SSD. I normally go with ext4 and no encryption. Up to you.

# First boot

As soon as the installation process completes, you will see Manjaro's grub loader where it **should** also list your Pop\_OS installation. Let it boot to Manjaro to make sure it all works fine.

# Boot option 1: You like grub

At this point you can keep it as it is, with Manjaro's grub bootloader talking over. You can customize grub **from within Manjaro** to make Pop\_OS your first choice if you want. [Grub customizer](https://launchpad.net/grub-customizer) can be installed in Manjaro and used for that purpose if you find editing files in the terminal hard. Whatever works for you.

# Boot option 2: You prefere systemd-boot

This is my preferred method as I find it cleaner, easier, faster and it is part of Pop\_OS which I really like.

For this, you need to reboot to Pop\_OS. Use Manjaro's grub screen, select Pop\_OS, let it boot.

Once in Pop you need to get systemd-boot to **see** Manjaro.

Look in **/boot/efi/EFI** and there will be a Manjaro folder there. It only contains one file, the grub boot image **grubx64.efi**.

You will need to add this to systemd-boot's loader. This is a simple config (txt) file that should be placed in **/boot/efi/loader/entries**.

# Create the Manjaro entry file

You will need to work as root for this and **sudo** is cumbersome as it won't allow you to see files and locations as you type. So instead, do:

    sudo su

Now you're **root**. Be **extra careful**.

In **/boot/efi/loader/entries** you need to create a file, call it **Manjaro.conf**. In it you need three lines:

    title Manjaro 
    linux /EFI/Manjaro/grubx64.efi 
    options root=UUID=XXXXXXXX-XXXX-XXXX-XXXXXXXXXXXXXXX ro loglevel=0 splash

## The first line

It's the title. Call it what you like. Manjaro is the obvious choice.

## The second line

This gives the location of the boot image. This is a **relative** path, so you give it as it appears inside **/boot/efi**. That is, you do not need the /boot/efi part of this path, as it would have been the case if this was an absolute path.

## The third line

This is the partition, as identified with its UUID, where the system (that is **"/"** is). So you will need to find the UUID of your Manjaro **"/"** partition. It is a long number in the format of this XXXXXXXX-XXXX-XXXX-XXXXXXXXXXXXXXX placeholder.

## Find the UUID of Manjaro's "/" partition

On your terminal, type:

    lsblk -f 

and see which partition is the one you've installed Manjaro. Normally it should be the one with ext4 that is not mounted. For example, mine is **/dev/sda4**

From the output of the above command, you can also see the UUID. You copy and paste it in Manjaro.conf.

Your configuration is complete.

## Make the menu appear at boot

Although I personally don't need the menu, at this point it helps if you can see the menu so that you can check everything works.

You need to edit **/boot/efi/loader/loader.conf**. This will normally have just:

    default Pop\_OS-current

You need to add:

    timeout 10

For the menu to stay up for 10 seconds (way to long, but we only do this for checking, adjust now or later as required). To remove the menu again, just remove the timeout line you just added.

Save and reboot.

## Booting from systemd-boot

On reboot you will see the simple menu with options for Manjaro, Pop\_OS current and old kernel, and UEFI settings. You might see other stuff there if you have configured this for it (Windows etc).

* Select Pop, and boot to make sure it works. Reboot
* Select Manjaro. This should take you to grub (where you can still select Pop). Boot Manjaro see that everything works. Done

## Remove the menu

As a reminder, if you remove the menu, you can still access it by holding the spacebar at POST.

## Other distributions

This could potentially work with any grub based distribution, but it has only been tested with Manjaro. Have fun.
