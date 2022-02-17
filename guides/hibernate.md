# How to configure Hibernation in Pop 
This guid does **not** include encryption and uses a swap **file**.

## 0.0 Warning - Speed!
Writing all your RAM **to disk** and then reading it back **from disk** is not as fast as suspend/resume. This becomes even more of an issue **if you have a lot of RAM**, like 32GB or more , and **much, much worse** if you use an HDD or even a SATA SSD. Note that for a SATA SSD with 500MBps sequential speed, writing 32GB when you go to hibernatin takes 64 seconds! With a 3000MBps NVMe drive, this takes only 11 seconds. For an HDD with 140MBps, this will take almost 4 minutes!!! And just as much to resume. It is clearly faster to reboot, no matter what drive.

## 1.0 Sources
This guide is a shameless copy of this: https://abskmj.github.io/notes/posts/pop-os/enable-hibernate/
All credit goes to that author.

## 2.0 Principle of operation (very basic description)
When the computer suspends, the RAM is kept powered to maintain its content. So the rest of the system can be powered off, and when resumed, the OS is in the same state it was before suspension.

Hibernation, takes the contents of the RAM and dumps them to the disk. The disk is not volatile and the contents persist after a complete power off of the system.
Effectively the system, when powered back on, it goes through POST in the same way as whe it boots, but whe the kernel is loaded, rather than a fresh boot, the OS is instructed to read from the disk the contents of the RAM saved there previously, load them into RAM and as such appear in the same state it was before it was put in hibernation mode.

## 3.0 Steps
1. Check your kernel can do hibernation
2. Create a swapfile to dump the RAM conents to
3. Configure the swapfile as swap to the system
4. Configure the kernel to load the swap conents after resuming from hibernate
5. Add the function to hibernate to the system
6. Add a hibernate button to the power menu

Note: This list is longer than the actual steps, so don't fret.

### 3.1 Check your kernel can do it:

Issue:
~~~
otheos@kepler:~$ cat /sys/power/state
freeze mem disk
~~~
And look for the word ```disk``` in the output as above.

### 3.2 Create a swapfile

First check if you already use one:
~~~
otheos@kepler:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       4.0Gi       8.4Gi       735Mi       3.0Gi        10Gi
Swap:             0B          0B          0B
~~~

In my case, there is no swap as evidenced above.

To create a swap yo need to decide the correct size first. It needs to be a bit larger than the RAM.
See the section **How much swap do I need** in this (Ubuntu link)[https://help.ubuntu.com/community/SwapFaq].

According to it, for  16GB or RAM I need 20GB Swap. So 20GB it is. 

Create the file:

~~~
otheos@kepler:~$ sudo fallocate -l 20G /swapfile
~~~

This will create the file named ```swapfile``` in the ```/``` parition. Adjust as needed.

Change the read/write (no exectute) permissions for root only:
~~~
otheos@kepler:~$ sudo chmod 600 /swapfile
~~~

Now format it as swap:
~~~
otheos@kepler:~$ sudo mkswap /swapfile
Setting up swapspace version 1, size = 20 GiB (21474832384 bytes)
no label, UUID=bc1bbdf7-1e5d-4492-8d72-e36e82724b51
~~~

The file has its own filesystem (swap) and **UUID**. 

### 3.3 Set the swapfile as the system swap

First activate the swap:
~~~
otheos@kepler:~$ sudo swapon /swapfile
~~~

You can check now, again with to see if it worked:ou 

~~~
otheos@kepler:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       4.0Gi       8.4Gi       687Mi       3.0Gi        10Gi
Swap:           19Gi          0B        19Gi
~~~

There it is, all 20GB appearing as ```19GiB```. Not an issue.

Now make it work after every reboot by adding it to ```/etc/fstab```.

~~~
otheos@kepler:~$ echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
/swapfile none swap defaults 0 0
~~~

Check it worked with ```cat /etc/fstab```

~~~
# /etc/fstab: static file system information.
...
/swapfile none swap defaults 0 0
~~~

Done. You now have a (large) swap.

Check it's there once more:
~~~
otheos@kepler:~$ cat /proc/swaps
Filename				Type		Size		Used		Priority
/swapfile                               file		20971516	0		-2
~~~

All done.

### 3.4 Configure the kernel options

You need to tell the kernel where to read the contents of the RAM form, after the system resumes from hibernation. 
So you need to tell the kernel on which partition is the swap file. You need the **UUID** of the **/** partition. **NOT** the UUID of the swapfile itself. 

Note: If you use a swap partition, you need the UUID of the swap partition here.

Let's find the UUID of the partition on which the swapfile is. This is the UUID of the ```/``` partition. You can find it in ```/etc/fstab```, or with ```lsblk``` or with ```blkid``` if you know what  to look for. 

Here's a certain method, though:
~~~
otheos@kepler:~$ findmnt -no UUID -T /swapfile
f639405e-c5a9-4472-93fa-a39edda16e4c
~~~

There it is: **f639405e-c5a9-4472-93fa-a39edda16e4c**

Here's the crucial part. We need to know where, on that partition, the swap file is. So we need the **offset** of the file on the ```/``` partition.

~~~
otheos@kepler:~$ sudo filefrag -v /swapfile | awk '{ if($1=="0:"){print $4} }'
9021440..
~~~

Here it is: **9021440**

Almost there, now we need to add the kernel option:

~~~
otheos@kepler:~$ sudo kernelstub -a "resume=UUID=f639405e-c5a9-4472-93fa-a39edda16e4c resume_offset=9021440"
~~~

See the **UUID** and the **offset** how they were used above? You use your own.

Note: If you use a swap partition, there is no offset, as the whole partition is the swap. So you don't add the ```resume_offset``` part.

Finish it off by updating your initramfs with (this takes a minute):

~~~
otheos@kepler:~$ sudo update-initramfs -u
update-initramfs: Generating /boot/initrd.img-5.15.15-76051515-generic
kernelstub.Config    : INFO     Looking for configuration...
kernelstub           : INFO     System information: 

    OS:..................Pop!_OS 21.10
    Root partition:....../dev/nvme0n1p3
    Root FS UUID:........f639405e-c5a9-4472-93fa-a39edda16e4c
    ESP Path:............/boot/efi
    ESP Partition:......./dev/nvme0n1p1
    ESP Partition #:.....1
    NVRAM entry #:.......-1
    Boot Variable #:.....0000
    Kernel Boot Options:.quiet splash loglevel=0 mitigations=off systemd.show_status=false pci=nocrs resume=UUID=f639405e-c5a9-4472-93fa-a39edda16e4c resume_offset=9021440
    Kernel Image Path:.../boot/vmlinuz-5.15.15-76051515-generic
    Initrd Image Path:.../boot/initrd.img-5.15.15-76051515-generic
    Force-overwrite:.....False

kernelstub.Installer : INFO     Copying Kernel into ESP
kernelstub.Installer : INFO     Copying initrd.img into ESP
kernelstub.Installer : INFO     Setting up loader.conf configuration
kernelstub.Installer : INFO     Making entry file for Pop!_OS
kernelstub.Installer : INFO     Backing up old kernel
kernelstub.Installer : INFO     Making entry file for Pop!_OS
~~~

You're good to go. Now of to enable the hibernation function at the OS level.

### 3.5 Enable Hibernation

First check it works. Save all your work!

~~~
otheos@kepler:~$ sudo systemctl hibernate
~~~

Your system should hibernate, then on manual power on, it will resume.

To enable it, edit ```/etc/systemd/sleep.conf``` and uncomment the line with:
~~~
HibernateDelaySec=1min
~~~
This tells the system how long to wait on suspend before it goes to hibernate.

Test it with:
~~~
otheos@kepler:~$ sudo systemctl suspend-then-hibernate
~~~

Because I've set the timeout to only 1 minute, if you power on your laptop within a minute, the laptop should resume straight into the lock screen (or session if you have disabled the lock screen).

Try it again. Now wait for more than 1 minute. Power the laptop on, and you should see it going throuhg POST now, then going to your lock screen. 

These two show the system works fine. First it goes to suspend (to RAM) and after the time set it goes to hibernation (suspend to disk).

You want this behaviour when: 

1. you press the power button
2. close the lid
3. idle

Note: Source: https://askubuntu.com/questions/12383/how-to-go-automatically-from-suspend-into-hibernate

You need to edit ```/etc/systemd/logind.conf```

#### For the 1st, edit the line:
~~~
#HandlePowerKey=poweroff
~~~
to
~~~
HandlePowerKey=suspend-then-hibernate
~~~

If your laptop has more keys for suspend etc, look furtherdown the list and enable acccordingly.

#### For the 2nd, edit the line:
~~~
#HandleLidSwitch=suspend
~~~
to
~~~
HandleLidSwitch=suspend-then-hibernate
~~~

This is also when you set different behaviour when on dock or on charger. Typically you'd want on such occasions to forego hibernation and stick to suspend-to-ram. Adjust according to your needs.


#### For the 3rd, edith the lines
~~~
#IdleAction=ignore
#IdleActionSec=30min
~~~
to
~~~
IdleAction=suspend-then-hibernate
IdleActionSec=10min
~~~

Note: I haven't tested if the latter setting superseeds that from gnome settings to suspend on idle. There may be a conflict, I haven't tested, but I remember there is a dconf command to do the same as above. I will update as needed.

### 3.6 Add a hibernate in the power menu

Source: https://www.how2shout.com/linux/how-to-hibernate-ubuntu-20-04-lts-focal-fossa/


Create this file as root ```/etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla```

With this content:
~~~
[Re-enable hibernate by default in upower]
Identity=unix-user:*
Action=org.freedesktop.upower.hibernate
ResultActive=yes

[Re-enable hibernate by default in logind]
Identity=unix-user:*
Action=org.freedesktop.login1.hibernate;org.freedesktop.login1.handle-hibernate-key;org.freedesktop.login1;org.freedesktop.login1.hibernate-multiple-sessions;org.freedesktop.login1.hibernate-ignore-inhibit
ResultActive=yes

Reboot. Do[Re-enable hibernate by default in upower]
Identity=unix-user:*
Action=org.freedesktop.upower.hibernate
ResultActive=yes

[Re-enable hibernate by default in logind]
Identity=unix-user:*
Action=org.freedesktop.login1.hibernate;org.freedesktop.login1.handle-hibernate-key;org.freedesktop.login1;org.freedesktop.login1.hibernate-multiple-sessions;org.freedesktop.login1.hibernate-ignore-inhibit
ResultActive=yes
~~~

Reboot. 

Test as required, and then **remember to change from 1 minute** to something sensible, at the begining of step 3.5.





