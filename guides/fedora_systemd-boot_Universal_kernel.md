## This requires systemd-boot installed

# Universal kernel (this is incomplete, but it's the preferred way)

A universal kernel is one that includes the initrd (low effort explanation). Dracut makes it with the correcet arguments and places it directly onto ```/boot/efi/EFI/Linux```.

**That's it**. With ```systemd-boot``` picking up and offering to load anything from Linux, you don't need anything else (loader menus etc).

## To build a Universal kernel:

```sudo dracut -fvM --uefi --hostonly-cmdline --kernel-cmdline "root=UUID=b6b8fa59-92cc-4d03-8d8f-d66dab76d433 ro rootflags=subvol=root resume=UUID=fb661671-97dc-45db-b720-062acdcf095e rhgb quiet mitigations=off"```

The part after ```--kernel-cmdline``` is just the command line (kernel options).

Find cmdline at ```/proc/cmdline``` or ```/etc/kernel/cmdline```. See above for what is needed (and what not).

Add ```--kver``` for a different kernel version. The number following this is what appears in ```/lib/modules```.

E.g

~~~
otheos@kepler ~]$ ls /lib/modules/
5.18.16-200.fc36.x86_64  5.18.5-200.fc36.x86_64  5.18.6-200.fc36.x86_64
~~~
So if you want to build for a different kernel, you add, e.g. ```--kver 5.18.5-200.fc36.x86_64```.

This littke script should take care of it:
~~~
#!/bin/bash
newkern=$(ls -t -1 /lib/modules | head -1)
echo $newkern
cmdline=$(cat /proc/cmdline)
echo $cmdline
sleep 5
sudo dracut -fvM --uefi --hostonly-cmdline --kernel-cmdline "$cmdline" --kver $newkern
~~~

## Maintenance
Needs to build a new universal kernel after every kernel upgrade. Or make the above script run after each kernel upgrade to "automate the process".
