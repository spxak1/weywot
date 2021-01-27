# How to make a Huion tablet work in Pop!_OS

This is valid for many but not all Huion tablets. The principle behind this is to make the tablet appear to the **wacom** driver. For that we need another driver to make the connection.
This is the [**digimend** driver](https://github.com/DIGImend/digimend-kernel-drivers). 

This guide is for the Gaomon M106K, which is a rebranded Huion with **USB Device ID** 256c:006e. Many Huion tablets use the same device ID but not all. Other tablets will work in the same way.

## Install digimend driver

We need some dependencies: 

```sudo apt install dkms git-core```

and then install from source:

~~~
sudo git clone https://github.com/DIGImend/digimend-kernel-drivers.git /usr/src/digimend-6
sudo dkms build digimend/6
sudo dkms install digimend/6
~~~

*Note: Not sure what the *-6* and the */6* point to, as the latest version should be **9**. Will correct later if needed.

Once the driver is installed, a reboot is required, then

```xinput --list``` should display:

~~~
otheos@weywot:~/Git/weywot$ xinput list
⎡ Virtual core pointer                    	id=2	[master pointer  (3)]
⎜   ↳ Virtual core XTEST pointer              	id=4	[slave  pointer  (2)]
⎜   ↳ Logitech K780                           	id=10	[slave  pointer  (2)]
⎜   ↳ Logitech MX Master 3                    	id=11	[slave  pointer  (2)]
⎜   ↳ SynPS/2 Synaptics TouchPad              	id=17	[slave  pointer  (2)]
⎜   ↳ TPPS/2 IBM TrackPoint                   	id=18	[slave  pointer  (2)]
⎜   ↳ HID 256c:006e Pen stylus                	id=12	[slave  pointer  (2)]
⎜   ↳ HID 256c:006e Pad pad                   	id=13	[slave  pointer  (2)]
⎣ Virtual core keyboard                   	id=3	[master keyboard (2)]
    ↳ Virtual core XTEST keyboard             	id=5	[slave  keyboard (3)]
    ↳ Power Button                            	id=6	[slave  keyboard (3)]
    ↳ Video Bus                               	id=7	[slave  keyboard (3)]
    ↳ Video Bus                               	id=8	[slave  keyboard (3)]
    ↳ Sleep Button                            	id=9	[slave  keyboard (3)]
    ↳ Integrated Camera: Integrated C         	id=14	[slave  keyboard (3)]
    ↳ Logitech StreamCam                      	id=15	[slave  keyboard (3)]
    ↳ AT Translated Set 2 keyboard            	id=16	[slave  keyboard (3)]
    ↳ ThinkPad Extra Buttons                  	id=19	[slave  keyboard (3)]
    ↳ Logitech K780                           	id=20	[slave  keyboard (3)]
    ↳ Logitech MX Master 3                    	id=21	[slave  keyboard (3)]
~~~

The tablet is **id12** and **id13**.

A quick check to see the driver is running with ```dkms status``` should show **digimend** (note: currently in my system it doesn't, but everything works. I will investigate).

## Configure X11

Tablets current only work on X, not on Wayland. So X11 needs to be informed of the input device, to pass it on to the **wacom** kernel.

We add a file in ```/usr/share/X11/xorg.conf.d/50-digimend.conf``` (the filename is not important but the number *50* is, as in needs to go before the existing wacom file that starts with *70*)

The contents are like this:

~~~

# InputClass sections for some tablets supported by the DIGImend kernel
# drivers. Organized into separate InputClass sections based on (one of) the
# advertised brands. Mostly because the MatchUSBID options would become too
# long otherwise.
#
Section "InputClass"
        Identifier "Huion tablets with Wacom driver"
        MatchUSBID "5543:006e|256c:006e"
        MatchDevicePath "/dev/input/event*"
        Driver "wacom"
EndSection

Section "InputClass"
        Identifier "Ugee/XP-Pen tablets with Wacom driver"
        MatchUSBID "28bd:007[145]|28bd:0094|28bd:0042|5543:004[57]|5543:0081|5543:0004|5543:3031"
        # Exclude the original WP5540U which PID is reused by Ugee M540
        NoMatchProduct "MousePen"
        MatchDevicePath "/dev/input/event*"
        Driver "wacom"
EndSection

Section "InputClass"
        Identifier "Ugtizer tablets with Wacom driver"
        MatchUSBID "2179:0053"
        MatchDevicePath "/dev/input/event*"
        Driver "wacom"
EndSection

Section "InputClass"
        Identifier "Yiynova tablets with Wacom driver"
        MatchUSBID "5543:004d"
        MatchDevicePath "/dev/input/event*"
        Driver "wacom"
EndSection
~~~

The first entry is the one that supports the Huion tablets.
