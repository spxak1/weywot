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

## Create the kiosk script

All info from [here](https://pimylifeup.com/raspberry-pi-kiosk/)

Needed software:
~~~
sudo apt-get install xdotool unclutter sed
~~~

The ```kiosk.sh``` script looks like this:

~~~
#!/bin/bash
#https://pimylifeup.com/raspberry-pi-kiosk/
xset s noblank
xset s off
xset -dpms
unclutter -idle 0.5 -root &
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
/usr/bin/chromium-browser --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' --disable-infobars --kiosk --noerrordialogs http://tiny.cc/physics30 &
# https://www.youtube.com/embed/HeQX2HjkcNo?vq=720&cc_load_policy=1&autoplay=1&controls=0http://tiny.cc/physics30 &
# http://tiny.cc/physics30
# https://sites.google.com/ccoex.com/physiboard/home 
#"https://www.youtube.com/watch_popup?v=9Auq9mYxFEE&vq=hd720"
# Youtube options: https://www.youtube.com/embed/9Auq9mYxFEE?vq=720&cc_load_policy=1&autoplay=1&controls=0
# more here: https://developers.google.com/youtube/player_parameters
#sleep 30
xdotool keydown ctrl+r
xdotool keyup ctlr+r
# --disable-infobars --kiosk --noerrordialogs cc_load_policy=1&vq=hd720&
while true; do
   xdotool keydown ctrl+r; xdotool keyup ctlr+r;
#   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 570
done
~~~
Look for the original guide for explanations.

## Create the service to start up at boot

```sudo nano /lib/systemd/system/kiosk.service```

And add:

~~~
[Unit]
Description=Chromium Kiosk
Wants=graphical.target
After=graphical.target

[Service]
Environment=DISPLAY=:0.0
Environment=XAUTHORITY=/home/pi/.Xauthority
Type=simple
~~~

and enable it with ```sudo systemctl enable kiosk.service```

You can now start it and your kiosk will be running. ```sudo systemctl start kiosk.service```.

## Install rpimonitor

All information from [here](h)/xavierberger.github.io/RPi-Monitor-docs/11_installation.html)

~~~
sudo apt-get install dirmngr
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2C0D3C0F
sudo wget http://goo.gl/vewCLL -O /etc/apt/sources.list.d/rpimonitor.list
sudo apt-get update
sudo apt-get install rpimonitor
sudo /etc/init.d/rpimonitor update
~~~

The service is enabled immediately. You can access the web page on ```http://raspberry-ip:8888```

### Configure rpimonitor

You can enable three addons:

* Top 3
* Wifi
* Shellinabox

#### Top 3
In the current version, top 3 addon is enabled from the ```data.conf``` file in ```/etc/rpimonitor```.

Just uncomment:
~~~
web.addons.5.name=Top3
web.addons.5.addons=top3
~~~

then go to ```templates/cpu.conf``` 
and uncomment:
~~~
web.status.1.content.1.line.4=InsertHTML("/addons/top3/top3.html")
~~~

Finally add the cron job that collects the data by doing:

```sudo cp /usr/share/rpimonitor/web/addons/top3/top3.cron /etc/cron.d/top3```

Restart the service with ```sudo systemctl restart rpimonitor```. You're done.


#### WiFi

While the network addon is enabled by default, it only points to the ethernet use.
The wifi addon is enabled again in ```/etc/rpimonitor/data.conf``` by uncommenting:

~~~
include=/etc/rpimonitor/template/wlan.conf
~~~

Restart the service with ```sudo systemctl restart rpimonitor```. You're done.

#### Shellinabox

This will allow you to open a shell from within the website.

First install it:

``` sudo apt install shellinabox```

Now this is a bit old school. You need to start the service with ```sudo /etc/init.d/shellinabox  start```

The configuration file is minimal, most options are in the init script above and some are in ```/etc/default/shellinabox```. 

Nothing needs to be changed, just check it runs in the correct port:

```netstat -ntl``` should give you (among others):
~~~
tcp        0      0 0.0.0.0:4200            0.0.0.0:*               LISTEN     
~~~

Now enable it in rpimonitor, again from ```/etc/rpimonitor/data.conf``` by uncommenting:

~~~
web.addons.1.name=Shellinabox
web.addons.1.addons=shellinabox
~~~

Adding these underneath:

~~~
web.addons.1.url=https://raspberry-ip:4200/
web.addons.1.allowupdate=false
~~~

The above mighht not be necessary, try without first.

Note, **shellinabox** runs on http**s**. You can access it as standalone on ```https://raspberry-ip:4200```

or, once you restart rpiconfig, from the addons dropdown.

### Temperatures and CPU speed script

This is just a sidenote:
This script (```measure.sh```)
~~~
#!/bin/bash
cpur=`vcgencmd measure_clock 48 | cut -d "=" -f 2`
cpu=$(expr $cpur / 1000000)
temp=`vcgencmd measure_temp | cut -d "=" -f 2`


echo $cpu"MHz" $temp
~~~

This will give you CPU speed in MHz and temperature in C.

You can run ```watch -n 1 ./measure.sh``` to get a monitor of sorts.








