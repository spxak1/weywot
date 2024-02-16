# Make solaar rules work in Wayland

Solaar installs and works fine in Xorg, by using a udev rule to enable the user to write on uinput.

Solaar lists on their [github page](https://github.com/pwr-Solaar/Solaar) two slightly different rules.

[The first one](https://github.com/pwr-Solaar/Solaar/blob/master/rules.d-uinput/42-logitech-unify-permissions.rules)

~~~
# This rule was added by Solaar.
#
# Allows non-root users to have raw access to Logitech devices.
# Allowing users to write to the device is potentially dangerous
# because they could perform firmware updates.
KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"

ACTION != "add", GOTO="solaar_end"
SUBSYSTEM != "hidraw", GOTO="solaar_end"

# USB-connected Logitech receivers and devices
ATTRS{idVendor}=="046d", GOTO="solaar_apply"

# Lenovo nano receiver
ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="6042", GOTO="solaar_apply"

# Bluetooth-connected Logitech devices
KERNELS == "0005:046D:*", GOTO="solaar_apply"

GOTO="solaar_end"

LABEL="solaar_apply"

# Allow any seated user to access the receiver.
# uaccess: modern ACL-enabled udev
TAG+="uaccess"

# Grant members of the "plugdev" group access to receiver (useful for SSH users)
#MODE="0660", GROUP="plugdev"

LABEL="solaar_end"
# vim: ft=udevrules
~~~

And [the second one](https://github.com/pwr-Solaar/Solaar/blob/master/rules.d/42-logitech-unify-permissions.rules)

~~~
# This rule was added by Solaar.
#
# Allows non-root users to have raw access to Logitech devices.
# Allowing users to write to the device is potentially dangerous
# because they could perform firmware updates.

ACTION != "add", GOTO="solaar_end"
SUBSYSTEM != "hidraw", GOTO="solaar_end"

# USB-connected Logitech receivers and devices
ATTRS{idVendor}=="046d", GOTO="solaar_apply"

# Lenovo nano receiver
ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="6042", GOTO="solaar_apply"

# Bluetooth-connected Logitech devices
KERNELS == "0005:046D:*", GOTO="solaar_apply"

GOTO="solaar_end"

LABEL="solaar_apply"

# Allow any seated user to access the receiver.
# uaccess: modern ACL-enabled udev
TAG+="uaccess"

# Grant members of the "plugdev" group access to receiver (useful for SSH users)
#MODE="0660", GROUP="plugdev"

LABEL="solaar_end"
# vim: ft=udevrules
~~~

The difference is this one line:
~~~
KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"
~~~
At the top. This means **the first rule works, the second doesn't**.

Both are named ```42-logitech-unify-permissions.rules``` and should be in ```/etc/udev/rules.d/```.

I have found this to work:
~~~
SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", MODE="0666"
KERNEL=="uinput", MODE="0660", GROUP="otheos", OPTIONS+="static_node=uinput"
~~~

And if everything fails, ```sudo setfacl -m u:${USER}:rw /dev/uinput```.



