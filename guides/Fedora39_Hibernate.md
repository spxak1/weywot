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

Then execute the compiled file. **Make your terminal as wide as possible for this**.

~~~
./btrfs_map_physical /path/to/swapfile
~~~

You need the last number from the first line with numbers, the *PHYSICAL OFFSET*. The output can be mingled so make sure you copy the number correctly. 

~~~
0	4096	0	regular	268435456	60255100928	268435456	1	60263489536
~~~

In my case it's *60263489536*.

Find the *pagesize* with
~~~
getconf PAGESIZE
~~~

Mine is *4096*, so the offset calculation is ```60263489536/4096=14712766```.

If you use **grub** you need to add the kernel option with ```grubby``` as so:

~~~
grubby --args="resume=UUID=b6b8fa59-92cc-4d03-8d8f-d66dab76d433
 resume_offset=14712766" --update-kernel=ALL
~~~

If you use **systemd-boot**, currently (F39) you need to add this line in all loaders. Hopefully with the next kernel install, the system will use the default for grub to write the new loaders with the correct options.

## Finish up.

You need to only use the swapfile for hibernation, not swap, so two services will do that.

~~~
cat <<-EOF | sudo tee /etc/systemd/system/hibernate-preparation.service
[Unit]
Description=Enable swap file and disable zram before hibernate
Before=systemd-hibernate.service

[Service]
User=root
Type=oneshot
ExecStart=/bin/bash -c "/usr/sbin/swapon /swap/swapfile && /usr/sbin/swapoff /dev/zram0"

[Install]
WantedBy=systemd-hibernate.service
EOF
~~~

and

~~~
systemctl enable hibernate-preparation.service
~~~

Then, 

~~~
cat <<-EOF | sudo tee /etc/systemd/system/hibernate-resume.service
[Unit]
Description=Disable swap after resuming from hibernation
After=hibernate.target

[Service]
User=root
Type=oneshot
ExecStart=/usr/sbin/swapoff /swap/swapfile

[Install]
WantedBy=hibernate.target
EOF
~~~

and

~~~
systemctl enable hibernate-resume.service
~~~

Systemd does memory checks on login and hibernation. In order to avoid issues when moving the memory back and forth between swapfile and zram disable some of them.

~~~
mkdir -p /etc/systemd/system/systemd-logind.service.d/
~~~
~~~
cat <<-EOF | sudo tee /etc/systemd/system/systemd-logind.service.d/override.conf
[Service]
Environment=SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK=1
EOF
~~~

~~~
mkdir -p /etc/systemd/system/systemd-hibernate.service.d/
~~~

~~~
cat <<-EOF | sudo tee /etc/systemd/system/systemd-hibernate.service.d/override.conf
[Service]
Environment=SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK=1
EOF
~~~

**Reboot.**

## Allow this through Selinux

Try to hibernate (as a user, not root).

~~~
systemctl hibernate
~~~

The following command will fail, returning you to a login prompt.

After you’ve logged in again check the audit log, compile a policy and install it. The -b option filters for audit log entries from last boot. The -M option compiles all filtered rules into a module, which is then installed using semodule -i.

As root,

~~~
audit2allow -b
#============= systemd_sleep_t ==============
allow systemd_sleep_t unlabeled_t:dir search;
cd /tmp
audit2allow -b -M systemd_sleep
semodule -i systemd_sleep.pp
~~~

Check that hibernation is working via systemctl hibernate again.

~~~
systemctl hibernate
~~~

That should now work.

Check that only ZRAM appears here:

~~~
swapon
NAME       TYPE      SIZE USED PRIO
/dev/zram0 partition   8G   0B  100
~~~

All is good.

## Finish off

You can add the **extension** to make the hibernation option appear in the power menu.
It's [Hibernation Status Button](https://github.com/arelange/gnome-shell-extension-hibernate-status).

(this part is copied from [the top comment here](https://askubuntu.com/questions/12383/how-to-go-automatically-from-suspend-into-hibernate)

Finally you can set the default behaviour when you close the lid, or set the default sleep option to **sleep-then-hibernate**.

Edit ```/etc/systemd/sleep.conf```

And change the line:
~~~
[Sleep]
HibernateDelaySec=3600
~~~

This configures the time before it goes to hibernation from sleep!

Test with:

~~~
sudo systemctl suspend-then-hibernate
~~~

Finally, you can set the default behaviour on closing the lid by editing ```/etc/systemd/logind.conf```.

You need to find option ```HandleLidSwitch=```, uncomment it and change to ```HandleLidSwitch=suspend-then-hibernate```.

Then you need to restart systemd-logind service (warning! you user session will be restarted) by the next command:

```sudo systemctl restart systemd-logind.service```

That's all! Now you can use this nice function.









