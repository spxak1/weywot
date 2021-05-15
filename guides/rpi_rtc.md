# Configure an RTC for the Raspberry Pi

For I use a Raspberry Pi 2 and the Adafruit PiRTC - PCF8523 Real Time Clock as sold [here](https://thepihut.com/products/adafruit-pirtc-pcf8523-real-time-clock-for-raspberry-pi).

The guide used to configure it can be found [here](https://learn.adafruit.com/adding-a-real-time-clock-to-raspberry-pi/set-rtc-time).

## Steps

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
