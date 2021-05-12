#!/bin/csh
set testcmd = `/usr/bin/lsusb | grep 17ef:100f | awk '/Bus/ {print $6}'`
#echo $testcmd
if ($testcmd == "17ef:100f") then 
echo "Dock Detected: Disabling Large fonts" | systemd-cat -t Accessibility -p emerg
sudo -u otheos DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" /usr/bin/gsettings reset org.gnome.desktop.interface text-scaling-factor
else 
#echo $testcmd "Haha"
echo "Laptop mode: Enabling Large fonts" | systemd-cat -t Accessibility -p emerg
sudo -u otheos DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" /usr/bin/gsettings set org.gnome.desktop.interface text-scaling-factor 1.25
endif
