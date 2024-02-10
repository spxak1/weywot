# Mount external drives with BTRFS partition with compression

Compression on BTRFS requires a mount option, typically something like ```compress-force=zstd:3```.
Unlike ZFS where compression is default (and set during the creation of the filesystem), this option needs to be used when mounting the BTRFS partition.

With USB drives, Gnome automounts them with default mount options, and those don't include compression for BTRFS.

The solutions is simple: change the default mount options in the system that does the automounting: ```udisks```.

Information taken from [this post answer](https://forum.endeavouros.com/t/automomount-luks-partition-with-nautilus-and-special-btrfs-mount-options/32793/5)
In that answer a ```udev``` solution is also shown, not used here.

## Change udisks2 defaults

This is done simply by editing ```/etc/udisk2/mount_options.conf```

An ```.example``` file exists, copy it to create one.
You can read extensively whan can be done there. You can change defaults for *all* BTRFS drives, or for one drive. 
I choose to only change the defaults for that one drive, so I add:

~~~
[/dev/disk/by-label/BTRFS_320]
btrfs_defaults=compress-force=zstd:3
~~~

That's it. In addition to the defaults, it now adds this to the mount options of that drive. You can define the drive any way you want, UUID, Label, device etc.

You can confirm the mount option has been passed with a view at ```mount -v```. 

Done.
