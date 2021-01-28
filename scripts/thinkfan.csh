#!/bin/csh

set test6 =  /sys/devices/platform/coretemp.0/hwmon/hwmon6/temp1_input
set test5 =  /sys/devices/platform/coretemp.0/hwmon/hwmon5/temp1_input
set test4 =  /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input
set think6 = /etc/thinkfan.conf.6
set think5 = /etc/thinkfan.conf.5
set think4 = /etc/thinkfan.conf.4
set think = /etc/thinkfan.conf
if -e $test6 then
echo "Thinkfan 6 in place"
\cp $think6 $think
else
if -e $test5 then
echo "Thinkfan 5 in place"
\cp $think5 $think
else
if -e $think4 then
\cp $think4 $think
echo "Thinkfan 4 in place"
endif
endif
endif
systemctl start thinkfan
