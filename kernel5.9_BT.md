# PSA: Kernel 5.9, Bluetooth (LE) and Logitech MX Mice fail to reconnect after reboot.

There appears to be a problem with the 5.9 kernel and some bluetooth (LE) adapters, mainly the Intel ax200 (BT5.0). 

When booting the 5.9 kernel mice made by Logitech of the MX series connected via bluetooth, fail to reconnect and need to be paired anew. The problem exists also if the mouse is turned off and on, or if the system suspends and wakes up.

It is a known problem and a bug has been filed [here](https://bugzilla.kernel.org/show_bug.cgi?id=209745)

There is a patch already waiting for newer versions but currently the problem remains. If you have **xanmod**'s custom kernel which recently upgraded to 5.9 you might experience this problem in Pop/Ubuntu.

There is a workaround (thanks to the excellent Arch Wiki) [here](https://wiki.archlinux.org/index.php/Bluetooth#Problems_with_all_BLE_devices_on_kernel_5.9+).

Specifically the workaround is this:

Open ````/var/lib/bluetooth/<adapter mac>/<device mac>/info````, remove the following lines, and restart ```bluetooth.service``` or reboot:

~~~
[IdentityResolvingKey]
Key=...
~~~

Although I have never used Arch for more than a month at a time, I am very grateful it offers such a great wiki, with such a knowledgeable and supportive community. Thank you.
