# Install Universal Kernel on Fedora (40)  

This is pretty much the info that appears on [Fedora's UKI support phase 2 page](https://fedoraproject.org/wiki/Changes/Unified_Kernel_Support_Phase_2).

## Prepare

~~~
sudo dnf install virt-firmware uki-direct
~~~

For UKI (the scripts) to work, the ```/``` partition needs to be identified by its GUID. 
There appears to be a bug and anaconda doesn't set up [discoverable partitions](https://www.freedesktop.org/wiki/Specifications/DiscoverablePartitionsSpec/).

The GUID of the ```/``` partition should be ```4f68bce3-e8cd-4db1-96e7-fbcaf984b709```.

You can check the current GUIDs with:
~~~
sudo lsblk -o +uuid,partuuid
~~~

It's the ```partuuid``` that shows the GUID. Since you're here, check the EFI partition has the correct GUID ```c12a7328-f81f-11d2-ba4b-00a0c93ec93b```.

You can change this manually using ```gdisk``` or  ```sfdisk``` (no instructions).

Or you can run the script Fedora has prepared to overcome this:

~~~
sudo sh /usr/share/doc/python3-virt-firmware/experimental/fixup-partitions-for-uki.sh
~~~

Reboot at this point as the kernel will complain it still uses the old GUID.

## Install the kernel

Now install the kernel. The UKI kernel lives in ```/boot/efi/EFI/Linux```  (not that it matters to you at this point).

~~~
sudo dnf install kernel-uki-virt
~~~

Once this is complete you can check the new boot option with:

~~~
kernel-bootcfg --show
~~~~

## Configure

This tool is similar to ```efibootmgr``` and I've still not found out any documentation for it. But in general it adds and removes UKI kernels to/from the NVRAM.

There is a script that calls this function to reverse engineer how it works, but I haven't found it yet. (**WIP**).

As far as I have understood (and tested), you can:

### Add a new kernel

~~~
kernel-bootcfg --add-uki /boot/efi/EFI/Linux/36855f3b063c43858884b9fedfa2c342-6.8.9-300.fc40.x86_64.efi --title "6.8.9" --boot-order 0 --cmdline "$(cat /etc/kernel/cmdline)"
~~~

### Remove a kernel

~~~
kernel-bootcfg --add-uki /boot/efi/EFI/Linux/36855f3b063c43858884b9fedfa2c342-6.8.9-300.fc40.x86_64.efi
~~~

That's where I am at this point. This works just fine. No real benefit to ```systemd-boot``` but there we are.
