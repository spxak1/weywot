# How to configure Hibernation in Pop 
This guid does **not** include encryption and uses a swap **file**.

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
6. Add a hibernate button to the power meny

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

You're good to go. Now of to enable the hibernation function at the OS level.











