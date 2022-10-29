https://kevinsaye.wordpress.com/2018/10/17/making-a-rtsp-server-out-of-a-raspberry-pi-in-15-minutes-or-less/


install Raspbian Stretch on the device (~6 minutes using Raspbian Lite)
2. log into the system and switch user to root
```su root```

3. update the system and install git and cmake
```apt update && apt install git cmake```

4. download the source for v412rtspserver
```git clone https://github.com/mpromonet/v4l2rtspserver.git```

5. make and install the code (~5 minutes)
```cd v4l2rtspserver && cmake . && make && make install```

6. add the following command to your /etc/rc.local
```v4l2rtspserver /dev/video0 &```

7. in VLC, open network stream to:  rtsp://{IPAddressOfYourPI}:8554/unicast

But, this is rtsp, not supported by servers, and even with:

# Playing HTTP streams
~~~
When v4l2rtspserver is started with '-S' arguments it also give access to streams through HTTP.  
These streams could be played :

	* for MPEG-DASH with :   
           MP4Client http://..../unicast.mpd   
	   
	* for HLS with :  
           vlc http://..../unicast.m3u8  
           gstreamer-launch-1.0 playbin uri=http://.../unicast.m3u8  

It is now possible to play HLS url directly from browser :

 * using Firefox installing [Native HLS addons](https://addons.mozilla.org/en-US/firefox/addon/native_hls_playback)
 * using Chrome installing [Native HLS playback](https://chrome.google.com/webstore/detail/native-hls-playback/emnphkkblegpebimobpbekeedfgemhof)

There is also a small HTML page that use hls.js and dash.js, but dash still not work because player doesnot support MP2T format.
~~~

This isn't great.

However, in the same document (**the README of v4l2rtspserver**) it also says:

~~~
Using Raspberry Pi Camera
------------------------- 
This RTSP server works with Raspberry Pi camera using :
- the opensource V4L2 driver bcm2835-v4l2

	sudo modprobe -v bcm2835-v4l2
	
- the closed source V4L2 driver for the Raspberry Pi Camera Module http://www.linux-projects.org/uv4l/

	sudo uv4l --driver raspicam --auto-video_nr --encoding h264
~~~

Which brings uv4l into the game.

https://www.linux-projects.org/uv4l/installation/

~~~
sudo rpi-update
echo /opt/vc/lib/ | sudo tee /etc/ld.so.conf.d/vc.conf
sudo ldconfig
##enable the Legacy Camera support from the Interface Options menu of the following system command and reboot:
sudo raspi-config
sudo reboot
~~~

Then
~~~
curl https://www.linux-projects.org/listing/uv4l_repo/lpkey.asc | sudo apt-key add -
echo "deb https://www.linux-projects.org/listing/uv4l_repo/raspbian/stretch stretch main" | sudo tee /etc/apt/sources.list.d/uv4l.list
sudo apt-get update
sudo apt-get install uv4l uv4l-raspicam  uv4l-raspicam-extras uv4l-server uv4l-uvc uv4l-xscreen uv4l-mjpegstream uv4l-dummy uv4l-raspidisp
~~~

**Note:** Make sure the camera is enabled and enough memory is reserved for the GPU (256MB or more is suggested) from this menu:
~~~
sudo raspi-config
~~~

To create a video device with the driver: 
```uv4l --driver raspicam --auto-video_nr --width 640 --height 480 --encoding jpeg```
See the output for /dev/video0 or so.
Capture a still: 
```dd if=/dev/video0 of=snapshot.jpeg bs=11M count=1```

To kill the device: 
```pkill uv4l```

To start an http server:
```uv4l --driver raspicam --auto-video_nr --width 1280 --height 962 --encoding h264 --server-option '--port=9000'```

Finally add the line above in ```/etc/rc.local``` with ```&``` at the end (before the exit line) to start at boot.
Note: There are ways to create a service etc for this. Not covered here, as ```rc.local``` works fine for the Raspberry Pi.

Access the feed at ```http://ip:9000/stream```

But you also have a number of features at ```http://ip:9000```

Enjoy
