# Configure top button of Lenovo Active Pen 2
This is a blatant rip off of [this](https://forum.manjaro.org/t/activepen2-top-button/54556), so all credit goes to the author of that post. 
I have made changes to the script so that I understand it.


## The pen
Lenovo's Active Pen 2, has a top button which connects bia BT. This is completely separate from the other two buttons that appear as part of the laptop's touchscreen (stylus and eraser respectively).

The pen has the following part numbers: GX80N07825 and 4X80N95873 and FRU01FJ170. It must be the same device, but only Lenovo knows. 
Mine had the FRU on the sticker on the pen, and the second P/N on the box (but no FRU). Go figure.

## The top button
Holding the top button for a few seconds makes the led blink and you can now pair with your laptop's BT. Once this is done, everytime the top button is pressed once, it connects to the laptop, it gives a set of keypresses, and then disconnects. It is **not** always connected and that's a problem (also a good thing for the battery).

I Windows, the Lenovo app, allows you to customise the top button for a single and double press. A similar pen (from HP) can be seen configured in Windows [here](https://youtu.be/h5R8GoPceCE?t=36)
Because of the connect-disconnect process there is lag, so expect a good 2 seconds before you see a reaction.

In linux the top button is not supported by anything really, although there was a request a couple of years ago on gnome, [here](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/638).

## What the OS sees

```xinput --list``` sees **nothing**.

On the log (```sudo dmesg -w```) you aslo see nothing.

Nothing is reported by ```xev``` or ```showkey``` on tty.

The only thing you can see is the connection-reconnection in udev.

~~~
otheos@kepler:~$ udevadm monitor
monitor will print the received events for:
UDEV - the event which udev sends out after rule processing
KERNEL - the kernel uevent

KERNEL[739.647635] add      /devices/pci0000:00/0000:00:14.0/usb1/1-7/1-7:1.0/bluetooth/hci0/hci0:3586 (bluetooth)
UDEV  [739.653193] add      /devices/pci0000:00/0000:00:14.0/usb1/1-7/1-7:1.0/bluetooth/hci0/hci0:3586 (bluetooth)
KERNEL[740.802324] remove   /devices/pci0000:00/0000:00:14.0/usb1/1-7/1-7:1.0/bluetooth/hci0/hci0:3586 (bluetooth)
UDEV  [740.803659] remove   /devices/pci0000:00/0000:00:14.0/usb1/1-7/1-7:1.0/bluetooth/hci0/hci0:3586 (bluetooth)
~~~

So that's all there is to work with.

## The concept
Create a service that keeps an eye on ```udevadm monitor``` and intercepts the connection`. When it does, it executes a command, in this case using ```xte```, to emulate a keypress.

## The service

~~~
otheos@kepler:~$ cat /etc/systemd/system/active-pen2.service 
[Unit]
Description=active-pen2 top-button
After=graphical-session-pre.target
After=auto-rotate.service
Wants=graphical-session-pre.target

[Service]
Environment=DISPLAY=:0
ExecStartPre=/bin/sleep 10
ExecStart=/usr/local/bin/active-pen2
Restart=on-failure
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

[Install]
WantedBy=default.target
~~~


## The (executable) script

~~~
otheos@kepler:~$ cat /usr/local/bin/active-pen2 
#!/bin/bash
DISPLAY=:0
export DISPLAY
#SERVICE="xournalpp"
udevadm monitor | while read -r line
#echo $line >> /home/otheos/line
do
    if [[ $line == "KERNEL"*"add"*"hci0:358"*"bluetooth"* ]]; then
     #   if pgrep -x "$SERVICE" >/dev/null
     #   then
            #xournal  is running wannt to open the sidebar in xournal(shortcute f12)
            echo "YESSSS" | systemd-cat -t ActivePen2 -p emerg
            sudo -u otheos xte "keydown Control_L" "key z" "keyup Control_L"
#       else
#	    echo "Nope" | systemd-cat -t ActivePen2 -p emerg
     
       #xournal not running open it now
     #       sudo -u otheos xournalpp &>/dev/null &
      #  fi
    fi
done
exit 0
~~~

Some crap above, but I left my debugging in for reference.

My script "presses" ```Control+Z```. You can make it do anything, obviously.

Until there is proper support, that's the best we can do.

## Note

These pens have also another limitation in linux, in that the bottom button only works with a tap. In Windows you can change that but I'm still looking how to make that pen work well in linux. TBC.



  
