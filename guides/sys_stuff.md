# Various things you can change through /sys

## Trackpoint sensitivity:
To adjust the sensitivity (0-255) of TrackPoint:
~~~
echo "64" | sudo tee "/sys/devices/platform/i8042/serio1/sensitivity"
~~~

Check slee mode:
~~~
$ cat /sys/power/mem_sleep
[s2idle] shallow deep
~~~
