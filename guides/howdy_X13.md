# Enable Howdy on Fedora 39
### For a ThinkPad X13 Yoga Gen3

This is based on the Copr guide and the comments there in at [this link](https://copr.fedorainfracloud.org/coprs/principis/howdy/)

## 1 Installation and configuration

Install the package on Fedora from corp:

~~~
sudo dnf copr enable principis/howdy
sudo dnf --refresh install howdy
~~~

Then define the IR camera. You can check how many devices are listed with:

~~~
ls /dev/video*
~~~

Probably this won't help to know which one it is, but you now have a range. 

Then edit the config file to set the camera:
~~~
sudo howdy config
~~~

Find the line with ```device_path``` and make it look like this:
~~~
device_path = /dev/video2
~~~

Test if that is the device with:
~~~
sudo howdy test
~~~

If not box with your camera output shows, and an error message concludes the terminal output, it's the wrond device. 
Change to another one and try until you get the B&W camera output. That's it then.

You can make howdy faster (but less secure/certain) by changing this line:
~~~
certainty = 4.2
~~~

Closer to 5 is less certain and faster, closer to 3 is more secure but slower.

## 2 Configure the user face data
~~~
sudo howdy add
~~~
This will add a new profile to the user who initicated the sudo command. You can add more for different angles. Just give them different names.

## 3 Configure sudo authorisation
Add the following line **to the top** of ```/etc/pam.d/sudo```:
~~~
auth       sufficient   pam_python.so /lib64/security/howdy/pam.py
~~~
That's it. Open a new terminal and type something like ```sudo ls``` and see the magic.

If you get an ```error 1``` output, this is because howdy cannot save the shot as it can't find the folder.
Just create it:
~~~
sudo mkdir /usr/lib64/security/howdy/snapshots
~~~

It should now work.


## 4 Configure gdm login
This requires a couple of steps. First the login itself.
Modify ```/etc/pam.d/gdm-password``` so it looks like this:
~~~
auth     [success=done ignore=ignore default=bad] pam_selinux_permit.so
auth        sufficient    pam_python.so /lib64/security/howdy/pam.py
auth        substack      password-auth
~~~

In that order, everything else already there, follows.
### 4.1 Configure SElinux

As root (```sudo su```) create ```howdy.te``` with this content:
~~~
module howdy 1.0;

require {
type lib_t;
type xdm_t;
type v4l_device_t;
type sysctl_vm_t;
type gconf_home_t;
class chr_file map;
class file { execute create getattr open read write };
class dir add_name;
}

#============= xdm_t ==============
allow xdm_t lib_t:dir add_name;
allow xdm_t gconf_home_t:file execute;
allow xdm_t lib_t:file { create write };
allow xdm_t sysctl_vm_t:file { getattr open read };
allow xdm_t v4l_device_t:chr_file map;
~~~

Then compile it with:
~~~
checkmodule -M -m -o howdy.mod howdy.te
semodule_package -o howdy.pp -m howdy.mod
semodule -i howdy.pp
~~~

I also did:
~~~
ausearch -c 'python3' --raw | audit2allow -M my-python3
semodule -X 300 -i my-python3.pp
~~~

And everything works. Follow the original link for more.

Finally, to get all the gnome "Authentication" prompts to use howdy, 
add to ```/etc/pam.d/polkit-1``` the same line:

~~~
auth        sufficient    pam_python.so /lib64/security/howdy/pam.py
~~~

You can add more profiles (glasses, no glasses, different hair, sitting position etc) with:
~~~
sudo howdy add
~~~

You can enable/disable howdy simply with:
~~~
sudo howdy disable 0/1
~~~

With 0 enabling and 1 disabling.




