# Boot to an OS on an NVME drive on systems that don't support booting from NVME

**Update**: Read at the end.

This guide is for older systems (Intel gen 6 or older CPUs) which can use NVME drives in their PCI slot but the bios won't see them and as such you can't boot from them.

With information from [here](https://ntzyz.space/post/load-nvme-driver-in-uefi-shell/).

## 1.0 Prerequisites
You need a drive to boot from. This can be a SATA drive or a USB drive. It will only hold your bootloader/manager, typically what you'd mount on ```/boot/efi```.
I assume you can do a manual installation and configure your EFI partition (ESP) on the USB or SATA drive.

Obviously this requires linux, but the issue is not with linux, as it is as simple as putting your ESP on the bootable drive and the rest works fine.
The issue is with Windows. Windows won't install on a system where you expect it to use a USB drive as a boot drive. Possibly it will if you use a SATA drive (haven't tried it), but Windows requires you to have already setup that drive as an ESP (format to FAT32, set ESP flag on gparted).

So, some aptitude needed for this.

## 2.0 How it works

EFI can load drivers. It's as simple as this. So the process is this:
1. Bios boots to EFI shell
2. EFI shell loads script
3. Script contains instructions to load NVME driver, then remap all drives, then load the boot manager

Let's make it

## 3.0 The EFI shell

### 3.1 Install the EFI shell

On Fedora just install the EFI OVMF tools ```sudo dnf install edk2-ovmf```.
Then copy the shell from its location to the **EFI root** which is ```/boot/efi``` (note: *not* ```/boot/efi/EFI```).
~~~
sudo su
cd /usr/share/edk2/ovmf/
cp Shell.efi /boot/efi/shellx64.efi
~~~
Once the shell is installed in the correct location, ```systemd-boot``` will add an option to boot to it automatically.

### 3.2 Download the EFI NVME driver

You can find the driver [at the clover driver's list](https://github.com/MatthewPierson/Hackintosh_Files/blob/master/Ryzen%203600%20AB350-GAMING-3%201060%203GB%20CLOVER/EFI/CLOVER/drivers/UEFI/NvmExpressDxe.efi)
Download it and copy it to the **EFI root**.

### 3.3 Write the startup script

Inside the **EFI root** write the script ```startup.nsh``` with the following contents:
~~~
load -nc fs0:\NvmExpressDxe.efi
connect -r
map -u
fs0:\EFI\systemd\systemd-bootx64.efi
~~~

The first line loads the driver, the second connects to the new data in the nVRAM, the third remaps all drives and the fourth loads the boot manager. I use ```systemd-boot```, and it's already installed.

Note that ```fs0:``` is the USB drive. Yours may be different. 
Also note it's advisable to boot to the shell and play around with the commands to see how they work.

### 3.4 Create the boot entry to the shell

For this you need ```efibootmgr```. It's a single line command. I assume you know how to use it.

```sudo efibootmgr -c -d /dev/sda1 -p 1 -L NVME_Boot -l \\shellx64.efi```

You can then use combinations of my other guides to boot to Windows (or replace the line with ```systemd-boot``` in the script to the Windows EFI stub.

## Update

OK, in theory the above works just fine. Only it doesn't. Once the bios boots to the EFI shell, the startup script runs and the nvme driver is loaded and the boot manager appears, the EFI shell cannot be loaded again, which means you cannot boot to Windows using a script.

Note: You cannot boot to Windows with the automatic ```systemd-boot``` option which appears when you just copy over the EFI files of Windows to the ESP (the USB drive). So you need an EFI shell script like I explain in my method [here](https://github.com/spxak1/weywot/blob/main/guides/efishelldualboot.md).

So here's the solution: You change the whole thing around:

1. Boot to ```systemd-boot``` as per normal from the Bios
2. Make a Windows option that loads the EFI shell **and** runs a script to load the driver and boot Windows

This actually works pretty well as there is no delay on the screen, no text etc.
Also, you don't need a new ```efibootmgr``` entry at all. It's atually better than the initial plan.

You only need to make a *loader* file for Windows in ```/boot/efi/loader/entries```:
~~~
title  Windows 11
efi     /shellx64.efi
options -nointerrupt -noconsolein -noconsoleout windows.nsh
~~~

And then create the ```windows.nsh``` script in the **EFI root** with the following content:
~~~
load -nc fs0:\NvmExpressDxe.efi
connect -r
map -u
FS2:\EFI\Microsoft\Boot\Bootmgfw.efi
~~~

The last line just boots Windows once the nvme driver is loaded. Done.

You can modicy the ```startup.nsh``` script to remove the last line to load the boot manager. 



