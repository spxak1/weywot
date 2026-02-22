# Add custom battery thresholds on Upower (and as such Gnome)

Gnome for sometime now includes a setting in it's Power menu for the battery chargning, when there is hardware support.
The options are:

* Maximise Charge
* Preserve battery health

The top option sets thresholds to 0 for lower and 100 for upper.
The bottom one sets thresholds as given by Upower.

## Upower thresholds

If you run ```upower -d``` you can see the thresholds reported are 75% for lower and 80% for upper.
These are merely part of the default configuration and can be changed.

Here's the output of my ```upower -d``` on my Thinkpad X13 Yoga Gen 3 (all ThinkPads should show the same thresholds).
~~~
Device: /org/freedesktop/UPower/devices/battery_BAT0
  native-path:          BAT0
  vendor:               LGC
  model:                5B11A14635
  serial:               2129
  power supply:         yes
  updated:              Sun 22 Feb 2026 11:51:25 GMT (15 seconds ago)
  has history:          yes
  has statistics:       yes
  battery
    present:             yes
    rechargeable:        yes
    state:               pending-charge
    warning-level:       none
    energy:              42.49 Wh
    energy-empty:        0 Wh
    energy-full:         54.38 Wh
    energy-full-design:  52.8 Wh
    voltage-min-design:  11.61 V
    capacity-level:      Normal
    energy-rate:         0 W
    voltage:             11.664 V
    charge-cycles:       42
    percentage:          78%
    capacity:            100%
    technology:          lithium-polymer
    charge-start-threshold:        75%
    charge-end-threshold:          80%
    charge-threshold-supported:    yes
    icon-name:          'battery-full-charging-symbolic'
~~~

You can clearly see the 75%-80% mentioned at the bottom.

### Add custom thresholds

This is done simply by adding a file in the udev hwdb.
~~~
sudo nano /etc/udev/hwdb.d/61-upower-battery.hwdb
~~~

And inside add:
~~~
# Custom upower charge limits
battery:*:*:dmi:*
 CHARGE_LIMIT=60,80
~~~
Here, 60 is the lower 80 is the upper. That's what I use and my X13 is still at 100% health aver 5 years and it spends a lot of time on AC.

At this point you can restart things:
* Update the hwdb: ```sudo systemd-hwdb update```
* Restart the service: ```sudo systemctl restart upower```

Or reboot. 

Once the thresholds work, you can check:
~~~
grep -H . /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold
/sys/class/power_supply/BAT0/charge_control_start_threshold:60
/sys/class/power_supply/BAT0/charge_control_end_threshold:80
~~~

They work. So now you can ditch the Battery Health Charging extension or any other tool, and use the default settings of Gnome.

## Gnome settings

Now when you set "Preserve Battery Health", Gnome will set the thresholds set above. 
If you want a full charge, just click "Maximise Charge". Just don't forget to revert back to save your battery.

## Hardware specific

Obviously your hardware **must** support battery thresholds **and** expose them to the sysfs through kernel driver support (e.g. thinkpad_acpi driver for ThinkPads).
Some laptops (Asus) have the support, it is exposed but not in the usual way. They also lack software support (i.e. extensions) and **tlp** doesn't work for them.
You can try the method with upower above and see if it works.

### Laptops with only upper (stop) threshold

Some laptops only offer a stop threshold. My Thinkbook does that. This is a severe limitation as it doesn't allow the battery to completely stop charging
when on AC, but it's still better than no thresholds at all.

For such laptops with only a stop (upper) thresholds, you can add the custom setting in your ```/etc/udev/hwdb.d/61-upower-battery.hwdb```
with the following text:
~~~
# Custom upower charge limits
battery:*:*:dmi:*
 CHARGE_LIMIT=_,80
~~~
So in place of the lower threshold, you get an underscore. I believe upower already has 80 as the upper (stop) threshold on such laptops anyway.
