# Make the X13 Yoga Gen3 Touchscreen identified by Gnome 45
This was done on Fedora 39, but should work for most other Gnome based distributions.

## Identify the issue
Opening Gnome Settings under "Wacom Tablet" shows "No tablet".

This can be confirmed by issuing
~~~
libwacom-list-local-devices 
~~~

It 
