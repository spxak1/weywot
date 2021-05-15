# Configure an RTC for the Raspberry Pi

For I use a Raspberry Pi 2 and the Adafruit PiRTC - PCF8523 Real Time Clock as sold [here](https://thepihut.com/products/adafruit-pirtc-pcf8523-real-time-clock-for-raspberry-pi).

The guide used to configure it can be found [here](https://learn.adafruit.com/adding-a-real-time-clock-to-raspberry-pi/set-rtc-time).

## 1. Install and configure the RTC module

1. Connect the RTC on the board
2. Power the Rpi and run ```sudo raspi-config```
3. Select **3. Interface Options** and go to **P5. I2C** and enable it
4. Install i2c-tools with ```sudo apt install python-smbus i2c-tools```
5. Check that the RTC is identified correctly with ```sudo i2cdetect -y 1```. The output should be:
~~~
pi@pihole:~ $ sudo i2cdetect -y 1
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: -- -- -- -- -- -- -- -- 68 -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- --  
~~~
That **68** means the RTC is properly identified. 
6. Configure the kernel module at boot up by editing ```/boot/config.txt```
7. Add at the bottom: ```dtoverlay=i2c-rtc,pcf8523```
8. Save and reboot
9. Test the kernel module loaded properly by running ```sudo i2cdetect -y 1``` again. The output now should be:
~~~
pi@pihole:~ $ sudo i2cdetect -y 1
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: -- -- -- -- -- -- -- -- UU -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- -- 
~~~
The **68** has now changed to **UU**. This is how it should be.

## 2. Configure the RTC to provide the time

Without an RTC t he RPi uses a fake HW clock. This is a simple service that reads the time at boot from an NTP server and presents it to the system as if it's the time of the HW clock. It also saves that time to ```etc/fake-hwclock.data```before reboot so that the system will read it back again when it starts as a best estimate of the realtime.

This is no longer needed, so remove the service altogether.

1. Remove fake-hwclock with ```sudo apt remove fake-hwclock```
2. Update the scripts with ```sudo update-rc.d -f fake-hwclock remove```
3. Disable the service ```sudo systemctl disable fake-hwclock```
4. Enable the HW clock by telling the system not to skip it. To do this, edit ```/lib/udev/hwclock-set```
5. ```sudo nano /lib/udev/hwclock-set``` and comment **out** these lines, like so:
~~~
#if [ -e /run/systemd/system ] ; then
#    exit 0
#fi
~~~
6. Further down comment **out** these lines:
~~~
#    /sbin/hwclock --rtc=$dev --systz --badyear
...
#    /sbin/hwclock --rtc=$dev --systz
~~~
7. Save, exit and reboot
8. The RTC is ready to work, but it needs to be configured with the correct time. This only needs to be done once.
9. First check the time of the system with ```date```. If the system is connected to the internet, it will have picked up the right time/date from an NTP. Otherwise the output will be wrong. Once the output of date is correct (manually or from the internet), you can **write** that time to the RTC with ```sudo hwclock -w```.
10. Read the time back with ```sudo hwclock -r``` or use ```sudo hwclock -r --verbose``` for more info.
11. That's it. Reboot and check the time is correct at boot with ```journalctl -b 0```. If not in the first boot, the reboot again. Done. 
