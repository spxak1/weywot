#!/bin/bash
#a very primitive script that (1) collects i/o requests from the block device, (2) collects
#w/r sectors from it; (3) waits DT-seconds; (4) repeats all collection (storing that in other
#vars (5) subtracts old from new state (6) if the result is above threshold, blinks the led.

#this is the dt, or a collection interval. Note that the shorter the dt, the higher CPU load
#will this script exert. 
DT=0.2

while :; do
    #(1)requests
    or=`awk '{print $1}' /sys/block/nvme0n1/stat`;
    ow=`awk '{print $5}' /sys/block/nvme0n1/stat`;
    orw=$(($or+$ow))
    #(2)sectors
    sor=`awk '{print $3}' /sys/block/nvme0n1/stat`;
    sow=`awk '{print $7}' /sys/block/nvme0n1/stat`;
    sorw=$(($sor+$sow))
    #(3)collect data here=============================
    sleep $DT
    #(4)refresh requests
    nr=`awk '{print $1}' /sys/block/nvme0n1/stat`;
    nw=`awk '{print $5}' /sys/block/nvme0n1/stat`;
    nrw=$(($nr+$nw))
    #refresh sectors
    snr=`awk '{print $3}' /sys/block/nvme0n1/stat`;
    snw=`awk '{print $7}' /sys/block/nvme0n1/stat`;
    snrw=$(($snr+$snw))
    #(5)
    reads=$(($nrw-$orw))
    sect=$(($snrw-$sorw))
    #echo testing got reqests: $reads sectors: $sect
    #(6)
    if [ $reads -gt 5 -o $sect -gt 1023 ];
    then
	#will blink $reads times. This is not optimal: we can get a 1-6 reqest burst that
	#would write 50k sectors (the if above catches this) but that'll only blink once.
	for i in `seq 1 $reads`;
	do
	    #(7)
	    echo 1 | tee /sys/class/leds/input3::capslock/brightness 2> /dev/null 1>&2;
	    echo 0 | tee /sys/class/leds/input3::capslock/brightness 2> /dev/null 1>&2;
#           echo 1 | tee /sys/class/leds/input3::capslock/brightness 2> /dev/null 1>&2;
#           echo 0 | tee /sys/class/leds/input3::capslock/brightness 2> /dev/null 1>&2;

	done
    fi
    done
