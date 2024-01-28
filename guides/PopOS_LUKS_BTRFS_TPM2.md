# Install PopOS on custom partition layout with LUKS, BTRFS with snapshot and TPM2
WIP

POP with LUKS and BTRFS with snapsot from here: https://mutschler.dev/linux/pop-os-btrfs-22-04/

Differences:
* No first install
* Manually partition 2GB ESP, 4GB RECOVERY, then from gnome-disks, 90GB ext4 with LUKS.
* You need to create crypttab after installation with the partitions (not the mapper) UUID.

LUKS wit TPM2 from here: https://askubuntu.com/questions/1470391/luks-tpm2-auto-unlock-at-boot-systemd-cryptenroll

With clevis.

Only downside: the LUKS password prompt still appears.

Full write up later. With and without BTRFS.


## Adapt timeshift-autosnap-apt to work with dnf in Fedora
Still to find out: how to work with dnf5.

This script: https://github.com/wmutschl/timeshift-autosnap-apt

Runs everytime after apt runs (in ubuntu/PopOS) to create a new timeshift snapshot.
Some instruction is included here: https://mutschler.dev/linux/pop-os-btrfs-22-04/

This is achieved by having an executable script (which runs as is in Fedora 39) and then the insruction to apt, to execute the script after apt is complete.
This is done in ubuntu/popos by installing a file ```80-timeshift-autosnap-apt``` in ```/etc/apt/apt.d```. 

In Fedora this ability is there for ```dnf``` but needs a bit of settin up.

First you need to install the package that runs the post-installation script.

This is it: https://packages.fedoraproject.org/pkgs/dnf-plugins-core/python3-dnf-plugin-post-transaction-actions/fedora-39-updates.html

Install with ```sudo dnf install python3-libdnf5-python-plugins-loader```

Inside ```/etc/dnf/plugins``` this will create a new folder ```post-transaction-actions.d``` and its conf file ```post-transaction-actions.conf``` with contents:

~~~      
[main]
enabled = 1
actiondir = /etc/dnf/plugins/post-transaction-actions.d/
~~~

Once this is done, you need to place an ```action``` file in there, which calls the post-transaction action. 

This, however, has a syntax. More here: https://dnf-plugins-core.readthedocs.io/en/latest/post-transaction-actions.html

Our file only needs to have:
~~~
*:any:/usr/bin/timeshift-autosnap-apt     
~~~
Save it in ```/etc/dnf/plugins/post-transaction-actions.d/``` as ```timeshift-autosnap-apt.action```. The filename doesn't matter but in **must** end with ```.action```.

Thats it. Obviously you'll still have messages including the word ```apt``` instead of ```dnf```, but if that bothers you, you can change it.
