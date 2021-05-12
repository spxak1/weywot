# Control system LED's/Light from the terminal.

Install ```light``` with ```sudo apt install light```.

Then do:
~~~
otheos@weywot:~$ light -L
Listing device targets:
	sysfs/backlight/intel_backlight
	sysfs/backlight/auto
	sysfs/leds/platform::mute
	sysfs/leds/phy0-led
	sysfs/leds/tpacpi::thinklight
	sysfs/leds/tpacpi::power
	sysfs/leds/input3::numlock
	sysfs/leds/tpacpi::standby
	sysfs/leds/input3::capslock
	sysfs/leds/tpacpi::thinkvantage
	sysfs/leds/input3::scrolllock
	sysfs/leds/tpacpi::kbd_backlight
	sysfs/leds/platform::micmute
	util/test/dryrun
~~~

You need ```sudo``` to make changes:

```sudo light -s sysfs/backlight/intel_backlight -T 0.5```

The ```-T``` switch multiples.

Do ```man light``` for more options.

```sudo light -s sysfs/leds/tpacpi::power -S 0```

The ```-S``` switch sets a value, in this case ```0``` for the power LED on the power button.

