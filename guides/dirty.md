# Tuning (?) the write caching (for USB devices)

This is not a guide, just a collection of info. This started by trying to stop needing ```sync``` after copying data to a USB stick, or stop the need to ```eject``` the drive (same effect).

The idea is that if you unplug the USB stick once *it appears* writing is finished, you may end up with currupted data, as most of it was still flushing from the system's write cache (RAM).

In the most basic descritpion, when data is copied to the USB stick, it is read to the write cache, and then copied to the USB stick.

How much data is on the actual USB stick and how much stil in the write cache before the system *declares* the write complete, I don't know. Probably this is specified somewhere.

This is apparently a [well known issue that is difficult to address](https://lwn.net/Articles/572911/).

## Tunables

Things an be tuned on two levels. How the filesystem is mounted, and how the write cache works.
Mounting the filesystem of a USB stick is done by the system if a DE is used, but there are default options that control this.

### Mounting USB sticks

For DE usage, there are default options for each filesystem that is mounted by the system (```udisk2```).

These can be found [at udisk2's documentation](http://storaged.org/doc/udisks2-api/latest/mount_options.html).

Locally on the disk, you can find those in ```/etc/udisks2/mount_options.conf.example```.
You can change them by copying this file to a new, remove the ```.example``` and edit it.

For edits to work you need to remove the hash from the ```[defaults]``` declaration at the top.

For example:

~~~
sudo cat /etc/udisks2/mount_options.conf | grep -v \#
[defaults]
exfat_defaults=uid=$UID,gid=$GID,iocharset=utf8,errors=remount-ro,sync
exfat_allow=uid=$UID,gid=$GID,dmask,errors,fmask,iocharset,namecase,umask,sync
~~~

It's a good idea to only remove the hash of the lines you want to change and leave the rest as is.

You can always check how filesystems have been mounted with ```cat /proc/mounts```.

In the above example I've changed the default for **exfat** filesystems by adding the ```sync``` option. This means that all writes will be done straight on the USB stick, effectively removing write caching.
This works, in that once the write is shown as complete, all the data is on the stick and you can just pull it out.
**However this makes things EXTREMELY SLOW**. 

FAT32 (VFAT) has the ```flush``` option by default, but sadly ```exfat``` doesn't yet. [This discussion on storaged github page](https://github.com/storaged-project/udisks/issues/1177) has more on this.

As such, currently for ```exfat``` USB sticks while this solves the issue, it makes things very slow, so it's not advisable. 

### Changing write caching options

Now this needs a lot of testing, benchmarking and even then it won't be conclusive.
A starting point about what sysfs files control these tunables is on [this OpenSuse memory management doc](https://documentation.suse.com/sles/15-SP3/html/SLES-all/cha-tuning-memory.html).

More details can be found [in the kernel docs](https://www.kernel.org/doc/Documentation/sysctl/vm.txt).

Effectively the two main tunables are:
~~~
/proc/sys/vm/dirty_background_ratio
/proc/sys/vm/dirty_ratio
~~~

The defaults are 10 and 20 (% of available RAM). 

You can find all values with ```sysctl -a```, so ```sysctl -a | grep dirty``` will show these (and more).

These can be changed simply with:
~~~
sysctl vm.dirty_background_ratio=10
~~~
More options are listed [here](https://www.cyberciti.biz/faq/howto-set-sysctl-variables/).

Or more basic:
~~~
echo 1 > /proc/sys/vm/dirty_background_ratio
echo 1 > /proc/sys/vm/dirty_ratio
~~~

These will reset back to 10 and 20 after a reboot. To make them persistent you need to change thme in ```sysctl.d```, with a new file such as:
~~~
/etc/sysctl.d/60-local-dirty-bytes.conf
~~~
Containinng simply:
~~~
vm.dirty_ratio = 10
~~~

Note: spaces before and after the ```=```. 

As I said changing these two quantities have an effect, but it's not easy to say what works better.

## Benchmarks

I copied Ubuntu's ISO (6GB) to a USB stick. The command used:
~~~
time cp ubuntu-24.04-desktop-amd64.iso /run/media/otheos/Ventoy/ && time sync
~~~

### First: Defaults
~~~
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10
~~~
~~~
real	2m13.310s
user	0m0.117s
sys	0m10.254s

real	12m57.282s
user	0m0.002s
sys	0m0.013s
~~~

A total of 15+ minutes

### Second: 1%
~~~
vm.dirty_ratio = 1
vm.dirty_background_ratio = 1
~~~
~~~
real	10m48.098s
user	0m0.216s
sys	0m24.284s

real	0m9.548s
user	0m0.003s
sys	0m0.006s
~~~

A total of 11 minutes

### Third: 1% - 10%
~~~
vm.dirty_ratio = 1
vm.dirty_background_ratio = 10
~~~
~~~
real	10m32.971s
user	0m0.232s
sys	0m22.737s

real	0m8.850s
user	0m0.000s
sys	0m0.007s
~~~

About 11 minutes.

So probably reducing ```vm.dirty_ratio = 1``` helps. So here's what I'll do:

## Reduce dirty ratio for USB sticks

This idea was discussed in [this thread here](https://unix.stackexchange.com/questions/714267/how-to-change-the-default-bdi-max-ratio-and-or-min-ratio-for-all-devices)
And also on [this thread](https://discussion.fedoraproject.org/t/mounting-removable-storage-devices-in-gnome/91274/2)

But the command below is used verbatim from [this reddit thread](https://www.reddit.com/r/linuxquestions/comments/1d3kk48/comment/l683dxz/?utm_source=share&utm_medium=web2x&context=3).

Effectively a ```udev``` rule changes the ```dirty_ratio``` for all filesystems on a USB drive.

Creat the rule in ```/etc/udev/rules.d/usbsync.rules``` (the extension is required).
~~~
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{removable}=="1", ATTR{bdi/max_ratio}="1"
~~~

Restart ```udev``` with 
~~~
udevadm control --reload-rules && udevadm trigger
~~~

You can check this value for the specific device in ```/sys/devices/virtual/bdi```.

More specifically with:
~~~
cat /sys/devices/virtual/bdi/8\:0/max_ratio
~~~

Your device will be different to mine ```8:0```, so unplug and replug to find what appears and disappears in ```/sys/devices/virtual/bdi```.

That's it.



