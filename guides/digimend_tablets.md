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

Here's another similar file for the Huion Q11 v2:

~~~
# Huion tablets  
Section "InputClass"  
    Identifier "Huion class"  
    MatchProduct "HUION"  
    MatchIsTablet "on"  
    MatchDevicePath "/dev/input/event*"  
    Driver "wacom"  
EndSection  

Section "InputClass"  
    Identifier "Huion buttons"  
    MatchProduct "HUION"  
    MatchIsKeyboard "on"  
    MatchDevicePath "/dev/input/event*"  
    Driver "evdev"  
EndSection  

Section "InputClass"  
    Identifier "Huion scroll"  
    MatchProduct "HUION"  
    MatchIsPointer "off"  
    MatchIsKeyboard "off"  
    MatchIsTouchpad "off"  
    MatchIsTablet "off"  
    MatchIsTouchscreen "off"  
    MatchDevicePath "/dev/input/event*"  
    Driver "evdev"  
EndSection
~~~

*Note*: My understanding of the syntax of these files is not yet great, I will improve and get back to explain the point of all these entries.

At this point a **reboot** will get X to see the input device.

## Configure the Tablet's buttons for use

All configuration is done with the ```xsetwacom``` command. Before the digimend driver was installed, the ```xsetwacom list``` command should come out empty.
Once the driver works, ```xsetwacom list``` should show all detected devices:

In my case: 

~~~
otheos@weywot:~$ xsetwacom list
HID 256c:006e Pen stylus        	id: 12	type: STYLUS    
HID 256c:006e Pad pad           	id: 13	type: PAD       
~~~

Each button needs each own command, so a script with all of them is apporpriate. 

Depending on the software used, the buttons can be mapped to keys and/or shortcuts. 

This is mine for my set of shortcuts for [kami](www.kamiapp.com]

~~~

xsetwacom set "HID 256c:006e Pen stylus" Button 2 "key 1" #pen to down stylus button
xsetwacom set "HID 256c:006e Pen stylus" Button 3 "key 2" #erase to up stylus button

xsetwacom set "HID 256c:006e Pad pad" Button 1 "key shift" #shift - draw straight
xsetwacom set "HID 256c:006e Pad pad" Button 2 "key ctrl z" #undo

xsetwacom set "HID 256c:006e Pad pad" Button 3 "key 3" #add shape
xsetwacom set "HID 256c:006e Pad pad" Button 8 "key 6" #hand tool

xsetwacom set "HID 256c:006e Pad pad" Button 9 "key 4" #box highlight
xsetwacom set "HID 256c:006e Pad pad" Button 10 "key 5" #select annotations


xsetwacom set "HID 256c:006e Pad pad" Button 11 "key ctrl +" #zoom in
xsetwacom set "HID 256c:006e Pad pad" Button 12 "key ctrl -" #zoom out

xsetwacom set "HID 256c:006e Pad pad" Button 13 "key +up" #up
xsetwacom set "HID 256c:006e Pad pad" Button 14 "key +pgup" #pgup

xsetwacom set "HID 256c:006e Pad pad" Button 15 "key +down" #down
xsetwacom set "HID 256c:006e Pad pad" Button 16 "key +pgdn" #pgdown

#keys on pad
# 1	2
# 3	8
# 9	10
# 11	12
# 13	14
# 15	16
#
~~~

The script can be turned executable with ```chmod +x``` and then (if desired) set to autostart using one of the usual ways, but it needs to start *after* X is up, so ideally from GDM, rather than cron.

Here's another such script with more features configured (this one for the Q11 v2)

~~~
#! /bin/bash  
# Setup HUION Q11 v2, after bridged to wacom driver with Digimend Kernel module.  
# License: CC-0/Public-Domain license  
# author: deevad  

# Tablet definition  
tabletstylus="HUION Huion Tablet stylus"  
tabletpad="HUION Huion Tablet Pad pad"  

# Reset  
xsetwacom --set "$tabletstylus" ResetArea  
xsetwacom --set "$tabletstylus" RawSample 4  

# Mapping  
# get maximum size geometry with:  
# xsetwacom --get "$tabletstylus" Area  
# 0 0 55880 34925  
tabletX=55880  
tabletY=34925  
# screen size:  
screenX=1920  
screenY=1080  
# map to good screen (dual nvidia)  
# xsetwacom --set "$tabletstylus" MapToOutput "HEAD-0"  
# setup ratio :  
newtabletY=$(( $screenY * $tabletX / $screenX ))  
xsetwacom --set "$tabletstylus" Area 0 0 "$tabletX" "$newtabletY"  


# Buttons  
# =======  
xsetwacom --set "$tabletstylus" Button 2 2   
xsetwacom --set "$tabletstylus" Button 3 3  
# ---------  
# | 12 |
# | -- |
# | 11 |
# | -- |
# | 10 |
# | -- |
# |  9 |
# |=======|  
# |  8 |
# | -- |
# |  3 |
# | -- |
# |  2 |
# | -- |
# |  1 |
# |=======| 


xsetwacom --set "$tabletpad" Button 12 "key +ctrl a" # Select all
xsetwacom --set "$tabletpad" Button 11 "key +ctrl shift a" # Deselect
xsetwacom --set "$tabletpad" Button 10 "key +ctrl r" # Selection tool
xsetwacom --set "$tabletpad" Button 9 "key t" # Transform tool
xsetwacom --set "$tabletpad" Button 8 "key b"  # Brush
xsetwacom --set "$tabletpad" Button 3 "key Shift_L" # Resize brush
xsetwacom --set "$tabletpad" Button 2 "key m" # Mirror 
xsetwacom --set "$tabletpad" Button 1 "key +ctrl z" # Undo 


# Xinput option  
# =============  
# for the list:  
# xinput --list  zz

# xinput list-props 'HUION Huion Tablet Pen Mouse' 
xinput list-props 'HUION Huion Tablet Touch Strip pad' "Evdev Middle Button Emulation" 0 
# xinput set-prop 'HUION Huion Tablet Pen' "Evdev Middle Button Emulation" 0  
# alternate way to map to a single screen  
# execute "xrander" in a terminal to get the screen name ( DVI-D-0 in this example )  
# xinput set-prop 'HUION' DVI-D-0
~~~

Many features can be configured, so check with ```xsetwacom```. 

Also check status with ```xinput list-props 'HID 256c:006e Pad pad'``` ```and xinput list-props 'HID 256c:006e Pen stylus'```

The name between the quotes is that which appears in the output of ```xsetwacom list```.

Plenty of resources, Arch Wiki, as always, great: https://wiki.archlinux.org/index.php/Wacom_tablet

This guide use material from [here](https://github.com/DIGImend/digimend-kernel-drivers/issues/510#issue-793499371)



