# A few notes on swap, zram, zswap and hibernation (Fedora).

A swap is no longer a requirement for most uses, so most intsallers don't even create one (e.g. Fedora).
Instead ZRAM is used by default by many distributions, Fedora and PopOS, the two I use, do that.

A swap, however, is usefull if you want to hibernate. [Fedora magazine](https://fedoramagazine.org/hibernation-in-fedora-36-workstation/) offers a way to enable hibernation by adding a swap.
This method, however, uses a systemd service to disable the swap in normal use, enabled when the system goes to hibernation and disables it as soon as it resumes.

In [this Reddit discussion](https://www.reddit.com/r/linuxquestions/comments/1c7hjs7/comment/l09kybe/?utm_source=share&utm_medium=web2x&context=3) it has been pointed out that this method is not very efficient.
The reason is that ZRAM does not offload anything to the swap if fully used, and the swap just sits there as empty space until hibernation is used.
Also, compression and recompression takes place, which is slow and inefficient. 

## Swap partitions

Now, Fedora doesn't create a swap partition anymore. However, as documented in the [discoverable partitions spec](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/):

> All swap partitions on the disk containing the root partition are automatically enabled.

A swap partition is identified by its GUID, ```0657fd6d-a4ab-43c4-84e5-0933c84b4f4f```.

You can find all partitions GUID with ```sudo lsblk -o +PARTTYPE```. 
All GUIDs are listed with ```systemd-id128 show```.

This means that a swap partition on the same device as the root ```/``` does **not** need to be included in ```/etc/fstab``` to be used.

To disalbe auto discrovered swap partitions, you need to do that through ```systemd```, as documented in [this post](https://serverfault.com/a/684778)
Try ```systemctl disable dev-sdXX.swap``` or ```systemctl mask dev-sdXX.swap```.

My **WIP** is to identify, however, how to stop using it.

As the installer picks up the swap partition and uses it anyway, it adds by defautl the ```resume=UUID=``` kernel parameter in the boot option.
This is **all that is needed for hibernation to work**. 

## Moving from ZRAM to ZSWAP

Zswap, as [documented in the kernel docs](https://docs.kernel.org/admin-guide/mm/zswap.html) is a system that uses RAM compression as a swap and then, it seletively moves pages to the disk swap.

Fedora [opted to go with ZRAM](https://fedoraproject.org/wiki/Changes/SwapOnZRAM#Why_not_zswap?) instead, but changing to zswap is not that difficult.

So if you want hibenation, changing from ZRAM to ZSWAP makes sense, as you keep all the benefits of ZRAM, and add the swap as an extension to it, as neded.
This makes more sense, and also avoids the "hack" that Fedora Magazine uses to enable/disable the swap before and after hibernation.

Evidently, [ZRAM should not be combined with ZSWAP](https://fedoraproject.org/wiki/Changes/SwapOnZRAM#Why_not_zswap?), (as it should not be used with swap either).

So the simplest thing is to just change from ZRAM to ZSWAP. That is very simple.

According to [Fedora Wiki](https://fedoraproject.org/wiki/Zsw) the steps are simple.

### Have a swap partition that is used already. 

Check with swapon. Mine looks like this:
~~~
NAME           TYPE      SIZE USED PRIO
/dev/nvme0n1p2 partition  24G   0B   -2
~~~

### Create an initrd that contains the compression drivers

Create the file ```/etc/dracut.conf.d/lz4hc.conf``` containing:
~~~
add_drivers+=" lz4hc "
add_drivers+=" lz4hc_compress "
~~~
Note: The spaces before and after the quotes are necessary.

Then create the new initrd with:
~~~
sudo dracut --regenerate-all --force
~~~

### Enable ZSWAP permanently 

You should add the boot option:
~~~
zswap.enabled=1 zswap.max_pool_percent=25 zswap.compressor=lz4hc
~~~
Note, the value ```25``` is configurable for the percentage of RAM used.
Note, this requires configuring grub or systemd-boot, not covered here.

A **lot** more info is [here](https://docs.kernel.org/admin-guide/mm/zswap.html) and of course at the [Arch Wiki](https://wiki.archlinux.org/title/zswap).

### Disable ZRAM

Zram is enabled using a file ```/etc/systemd/zram-generator.conf``` *with some content*. 
If there is **no** such file, create an empty one. This will disable it in the next boot

**Reboot**


      
  
