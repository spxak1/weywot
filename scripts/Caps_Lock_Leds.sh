#!/bin/bash
#/usr/bin/xdotool key alt+shift

capsled='sysfs/leds/input26::capslock'
echo $capsled
ledstat=$(light -s $capsled -G)
echo $ledstat

if [ $ledstat == 0.00 ]
then
echo was off now on
xdotool key alt+shift > /dev/null
light -s $capsled -S 100.00
elif [ $ledstat == 100.00 ]
then
echo was on now off
xdotool key alt+shift > /dev/null
light -s $capsled -S 0
fi

#xdotool key alt+shift
