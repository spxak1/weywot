#connect usb
#adb tcpip 5555
#adb connect 10.20.30.11
#disconnect USB
#good to go
#adb kill-server to restart
#scrcpy -b2M -m700 --max-fps 15 -S --window-title Pixel --window-x 10 --window-y 10 &

adb kill-server
adb connect 10.20.30.13:5555
scrcpy -b3M -m1000 --max-fps 15 -S --window-title Makemake --window-x 10 --window-y 10 &
