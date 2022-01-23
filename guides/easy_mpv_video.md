# How to play online videos on MPV the easiest possible way

This is a very simple trick. I started using it eversince video hardware acceleration on Chrome was removed. ```mpv``` has it, so not only you get a video in a popup, but it's hardware accelerated.

## What we want:
* **Copy the link or highlight the link with the mouse**
* **Press a keyboard shortcut to start playback**


## Steps to copy the link

The copying part is easy. This has been tested with:
* Youtube (highlight link address on browser, or copy link with right mouse click)
* Twitter (right mouse click and copy link)
* Faceboot (highlight address of video on browser)


## Steps to playback

The command to playback comes simple from ```mpv http://.....```. So let's set up ```mpv``` first.

### Install mpv

```sudo apt install mpv```.

This will also install the youtube downloader, ```youtube-dl```. However I find this is not working well, and creates choppy playback. As such I replace it.

#### Replace youtube-dl with yt-dlp

First uninstall ```youtube-dl``` with:

```sudo apt remove youtube-dl```.

Then install ```yt-dlp``` with ```pip```.

Install ```pip``` if not installed already:

```sudo apt install pip```.

Then

```pip install -U yt-dlp```.

Because ```mpv``` still looks for the ```youtube-dl``` binary, make a soft link and place it in the path.

```ln -sf ~/.local/bin/yt-dlp ~/.local/bin/youtube-dl```

Done

### Install xclip

```xclip``` is what reads the contents of **both** the PRIMARY (what text you highlight with your mouse and paste with middle click) and the CLIPBOARD (what text you select and do ```ctrl+c``` or copy with right click then copy, and paste with ```ctrl+v```).

```sudo apt install xclip```


### Make the script

This is just putting the command together and saving it as a little bash script with the following contents:

~~~
#!/usr/bin/bash
mpv $(xclip -o)
~~~

Save the script as (e.g) ```youpv```, then do ```chmod +x youpv``` and place it in your path (or copy it to a known path with, e.g ```sudo cp ./youpv /usr/loca/bin```).

### Create the keyboard shortcut

Whatever DE you use, make a shortcut for that script. In Gnome, go to Setting,s Keyboards, Shortcuts, Custom, and make one for ```/usr/local/bin/youpv``` when you press e.g. ```ctrl+shift+v```.

## Use it

You're done.

Copy a link using your mouse (highlight or copy or whatever), then press ```ctrl+shift+v```. **Wait a few seconds** for playback to start on its own window.

Enjoy!


