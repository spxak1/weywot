# Unified Kernel - Automation (Fedora 40)

This is a newer version of making and using a unified kernel in Fedora.
Some assumptions are made here, and I use F40 installed with ```systemd-boot``` ready by using the Everything ISO and the sd.boot option.

With grub the paths to the kernel and initrd must be adjusted.

## Systemd-ukify

This is a new tool and it's beter than objcopy which [can no longer produce a working UKI](https://github.com/systemd/systemd/issues/28419).

Install ```systemd-ukify``` with ```sudo dnf install systemd-ukify```.

You can make a UKI simply with:

~~~
sudo ukify build --linux=./linux --initrd=./initrd --output=/boot/efi/EFI/Linux/Fedora.efi --cmdline=@/etc/kernel/cmdline --os-release=@/etc/os-release
~~~

This assumes you're in the location of the kernel and initrd. Otherwise change the paths to the ```--linux``` and ```--initrd```

Make sure your ```/etc/kernel/cmdline``` include **every** kernel option, including root paths etc.
Mine looks like this:
~~~
resume=UUID=8d970711-87ae-4ebf-8de8-96c65954631f rhgb quiet root=UUID=c972dff9-dec3-498f-afee-b554d3a8c79a rootflags=subvol=@
mitigations=off
zswap.enabled=1 zswap.max_pool_percent=25 zswap.compressor=lz4hc
hibernate=nocompress
workqueue.power_efficient=1
nmi_watchdog=0
i915.fastboot=1
rd.luks=0 rd.lvm=0 rd.md=0 rd.dm=0
~~~

Obviously mine caries some luggage, but the first line is the important one and usually the default after installation. 
Check your ```/proc/cmdline``` as a starting point.

More details are found (as always) at the [archwiki page for ukify](https://wiki.archlinux.org/title/Unified_kernel_image#ukify).

At this point, make a UFI. If you have ```systemd-boot``` installed, and so long as the UKI kernel is in ```/boot/efi/EFI/Linux```, it needs no config to appear in the boot menu.

## Booting straight to the UKI (without a boot manager)

You can write a boot entry into your bios nVRAM directly, to boot the UKI.

```sudo efibootmgr -c -d /dev/nvme0n1 -p 1 -L "Fedora Latest" -l /EFI/Linux/fedora.efi```

I use my nvme0n1 drive and its first partition, which is mounted on ```/boot/efi```.

## The post kernel intsall hook

All you need to get this process automatically done every time is to place a hook in ```/etc/kernel/postinst.d```.

I use [gdamjan's script from here](https://gist.github.com/gdamjan/ccdcda2c91119406a0f8d22f8b8f2c4a#file-zz-update-systemd-boot-L25) as a basis, but I have made changes to Fedora's kernel locations (for systemd-boot installations) and replaced ```objcopy``` with ```ukify```.

~~~
#!/bin/bash
#
# This is a simple kernel hook to populate the systemd-boot entries
# whenever kernels are added or removed.
#
       
# Our kernels.
KERNELS=()
FIND="find /boot/efi -maxdepth 3 -name 'linux*' -type f -print0 | sort -rz"
while IFS= read -r -u3 -d $'\0' LINE; do
    KERNEL=$(dirname "${LINE}")
    KERNELS+=("${KERNEL}")

#echo $KERNELS
done 3< <(eval "${FIND}")

# There has to be at least one kernel.
if [ ${#KERNELS[@]} -lt 1 ]; then
    echo -e "\e[2msystemd-boot\e[0m \e[1;31mNo kernels found.\e[0m"
    exit 1
fi


LATEST="${KERNELS[@]:0:1}"
echo -e "\e[2msystemd-boot\e[0m \e[1;32m${LATEST}\e[0m"

#echo -e "${LATEST}/linux"
mv /boot/efi/EFI/Linux/fedora.efi /boot/efi/EFI/Linux/fedora_old.efi
ukify build --linux=${LATEST}/linux --initrd=${LATEST}/initrd --output=/boot/efi/EFI/Linux/Fedora.efi --cmdline=@/etc/kernel/cmdline --os-release=@/etc/os-release

exit 0
~~~

I've save it as ```uki``` and ```chmod +x uki``` to make it executable. It works fine when run from the terminal.



