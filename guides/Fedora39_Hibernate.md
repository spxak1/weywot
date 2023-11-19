# Hibernation on Fedora 39

This guide is mostly a copy of [the guide for Fedora 36 on the Fedora Magazine](https://fedoramagazine.org/hibernation-in-fedora-36-workstation/).

## Create the swap file
(all commands as root)

Create a place to put it.
~~~
btrfs subvolume create /swap
~~~

To create the file, you need to know how much RAM you have and use. You need to be able to store the contents of the RAM + your zram drive. 

Fedora Magazine's exact quote is:
~~~
In this example the machine has 16G of RAM and a 8G zram device. ZRAM stores roughly double the amount of system RAM compressed in a portion of your RAM. Let that sink in for a moment. This means that in total the memory of this machine can hold 8G * 2 + 8G of RAM which equals 24G uncompressed data. Create and configure the swapfile using the following commands.
~~~

Find ZRAM:
~~~
swapon
NAME       TYPE      SIZE USED PRIO
/dev/zram0 partition   8G   0B  100
~~~

In my case, for 32GB of RAM and 8GB of zram I used 38GB. 
I used the old and tried RAM + sqrt(RAM), and not what Fedora Mag said, and I may have done this wrong.
My understanding is this:
ZRAM stores double the amount of RAM allocated. So 8+8GB = 16GB. And then you got the left over from your RAM.
In my case, 32-8=24GB, so the total should be 16+24=40GB. Probably this is better and I should change it from 38GB. 
It's not like I'm saving much anyway.

Create the file.
~~~
touch /swap/swapfile
# Disable Copy On Write on the file
chattr +C /swap/swapfile
fallocate --length 40G /swap/swapfile
chmod 600 /swap/swapfile 
mkswap /swap/swapfile
~~~~

You now need the module ```resume``` in ```initramfs```.

~~~
cat <<-EOF | sudo tee /etc/dracut.conf.d/resume.conf
add_dracutmodules+=" resume "
EOF

dracut -f
~~~

Now we need a kernel option for when we reboot from hibernation, so that the system knows where to read the contents of the swapfile. For that we need the UUID of the partition where the file is located on.

~~~
findmnt -no UUID -T /swap/swapfile
b6b8fa59-92cc-4d03-8d8f-d66dab76d433
~~~

And the offset. This is the tricky part for BTRFS.
Download the [source of the btrfs_map_physical tool](https://github.com/osandov/osandov-linux/blob/master/scripts/btrfs_map_physical.c) and compile it:

Run gcc where the downloaded file is:

~~~
gcc -O2 -o btrfs_map_physical btrfs_map_physical.c
~~~

Then execute the compiled file. @@Make your terminal as wide as possible for this@@.

~~~
./btrfs_map_physical /path/to/swapfile
~~~





