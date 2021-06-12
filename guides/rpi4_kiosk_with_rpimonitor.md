# Create a Raspberry Pi 4 kiosk

## Install and configure the Raspberry Pi with Raspbian OS

Donwload images from [here](https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit)
Currently the 32bit image is the better one.

Use ```dd``` to write the image to a microSD card.

Once the new partitions are mounted, go to ```/boot``` and set the flag for **ssh** with ```touch ssh```.
Then, still in ```/boot```, create the **wpa** file for the wifi:

```nano wpa_supplicant.conf```
~~~
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
country=GB
update_config=1

network={
 ssid="Sol"
 psk="wifipassword"
}
~~~

Boot the Raspberry Pi.

## Basic configuration

Once it boots, connect with **ssh** (you will need to find the IP from your router/dhcp server).
If your network has internal name resolution, you can do ```ssh pi@raspberrypi```

* Username: pi
* Password: raspberry

Once connected run the basic updates with:

```sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y```

You can check/upgrade the firmware with ```sudo rpi-update```

Once this is complete, run ```sudo raspi-config``` and change the following:

* System Options: Password, Hostname, Set Auto Login
* Performance Options: CPU Memory (set to 256MB)
* Advanced Options: Compositor (disable it)

At this point reboot to apply all changes.

You can further configure the Pi by editing its config file ```sudo nano /boot/config.txt```

You can add:
~~~
max_framebuffers=1
~~~
If on a single screen.

and 
~~~
arm_freq=1800
gpu_freq=700
over_voltage=6
~~~

For a mild overclock without any cooling. For 2.0GHz overclock active cooling is required. The GPU can be pushed to 750MHz.

Further configuration for the HDMI output, resolution, overscan can be done in this file too. 
Options can be found [here](https://www.raspberrypi.org/documentation/configuration/config-txt/)




