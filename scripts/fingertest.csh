#!/bin/csh
set testcmd = `/usr/bin/lsusb | grep 17ef:100f | awk '/Bus/ {print $6}'`
#echo $testcmd
if ($testcmd == "17ef:100f") then 
echo "Dock Detected: Disabling fingerprint authentication" | systemd-cat -t FingerprintTest -p emerg
\cp /etc/pam.d/common-auth.nofinger /etc/pam.d/common-auth
else 
echo "Laptop mode: Enabling fingerprint authentication" | systemd-cat -t FingerprintTest -p emerg
\cp /etc/pam.d/common-auth.finger /etc/pam.d/common-auth
endif
