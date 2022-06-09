# Simple Pop_OS boot screen

This is a lazy guid to convert the grey boot screen to a OEM logo + Pop logo + progress bar boot screen. 
**Note**: I don't know two-step syntax for plymouth, so this is the result of a quick figuring out how it works. You may well improve on it.
**Note**: This adds a good 2-3 seconds to the boot time, compared to the grey screen.

## 1. Steps
Easy mod:
* Edit ```/usr/share/plymouth/themes/pop-basic/pop-basic.plymouth```
* Place the watermark picture (donwload from [here](https://github.com/spxak1/weywot/blob/main/assets/watermark.png) in the same folder.

![Pop Logo](../assets/watermark.png)

## 2. Execution
All steps require *root*, so **be careful**. Make a backup of any files you are going to edi, before editing them!

Here's my modified ```pop-basic.plymouth```.
~~~
  GNU nano 6.2 /usr/share/plymouth/themes/pop-basic/pop-basic.plymouth          
[Plymouth Theme]
Name=Pop Basic
Description=Re-Write of Pop!_OS decryption screen using two-step rather than pl>
ModuleName=two-step

[two-step]
Font=Fira Sans Regular 11
TitleFont=Fira Sans Regular 11
ImageDir=/usr/share/plymouth/themes/pop-basic
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.7
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.682
HorizontalAlignment=.5
VerticalAlignment=.83
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.8
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x36322f
BackgroundEndColor=0x36322f
ProgressBarBackgroundColor=0x606060
ProgressBarForegroundColor=0xffffff
DialogClearsFirmwareBackground=true
MessageBelowAnimation=true
MessageBelowAnimationDistance=10
CursorAnimation=breath
CursorAnimationSpeed=7

[boot-up]
UseEndAnimation=false
UseProgressBar=true
UseFirmwareBackground=true

[shutdown]
UseEndAnimation=false
UseFirmwareBackground=true


[reboot]
UseEndAnimation=false
UseFirmwareBackground=true

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Installing Updates...
SubTitle=Do not turn off your computer
UseFirmwareBackground=true

[system-upgrade]
SuppressMessages=false
ProgressBarShowPercentComplete=false
UseProgressBar=true

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading Firmware...
SubTitle=Do not turn off your computer
~~~

## 3. Changes

* Under **[two-step]** I have edited every part that includes the word **vertical**. That's that.
* Under **[boot]** I've added the last two lines.
* Under **[shutdown]** and **[reboot]** i've added the last line.

## 4. Update the initramfs

For the changes to work you need to finish off with ```update-initramfs -u``` (as root) and reboot to see the difference.



