#!/bin/bash
#https://pimylifeup.com/raspberry-pi-kiosk/
xset s noblank
xset s off
xset -dpms
unclutter -idle 0.5 -root &
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
/usr/bin/chromium-browser --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' --disable-infobars --kiosk --noerrordialogs "https://www.youtube.com/embed/9Auq9mYxFEE?autoplay=1&cc_load_policy=1&vq=hd720" &
sleep 30
xdotool keydown ctrl+r
xdotool keyup ctlr+r
# --disable-infobars --kiosk --noerrordialogs cc_load_policy=1&vq=hd720&
while true; do
   xdotool keydown ctrl+r; xdotool keyup ctlr+r;
#   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 600
done

