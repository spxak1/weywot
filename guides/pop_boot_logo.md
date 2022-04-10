# Add a Pop!_OS boot logo

**UPDATE: Latest plymouth makes the pop-theme logo obsolete**
I keep this here for the relevant tools used, but this is no longer applicable.

[Watch it here in action](https://streamable.com/9mp1nl)

~~~
sudo apt install plymouth-theme-pop-logo
sudo update-alternatives --config default.plymouth
~~~

Select the pop-logo theme instead of the current pop-basic one, and update initramfs

~~~
sudo kernelstub -a splash
sudo kernelstub -v
sudo update-initramfs -u
~~~

Reboot.

**Note**: It adds about 5sec to boot time.

## Customise the boot logo
I prefer the logo to appear on a black background with the Lenovo (i.e manufacturer) logo in the centre and Pop logo at the bottom. 
This is similar to Windows and Ubuntu's spinner.

The steps are:
1. Turn background to black from brown
2. Enable the firwmare logo
3. Move the Pop logo at the bottom
4. Resize the Pop logo to fit better (optional)

### The pop-logo.plymouth file
Edit ```pop-logo.plymouth``` in ```/usr/share/plymouth/themes/pop-logo``` (make a backup of this folder before you start).

It originally looks like this:
~~~
[Plymouth Theme]
Name=Pop Logo
Description=Pop Logo
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/pop-logo
HorizontalAlignment=.5
VerticalAlignment=.5
Transition=merge-fade
TransitionDuration=.5
BackgroundStartColor=0x36322f
BackgroundEndColor=0x36322f
~~~

#### 1. Colour
Change **0x36322f** to **0x000000**. This is black. If you need another colour, google hex colours.

#### 2. Add firmware logo at boot, shtudown, reboot
Add at the end:
~~~
[boot-up]
UseEndAnimation=true
UseFirmwareBackground=true

[shutdown]
UseEndAnimation=false
UseFirmwareBackground=true

[reboot]
UseEndAnimation=false
UseFirmwareBackground=true
~~~

#### 3. Move the Pop logo at the bottom
Edit **VerticalAlignment=.5** to **VerticalAlignment=0.8**. Or more. Try it.

#### 4. Resize the Pop logo
This is more involving as the animation is made from a number of png files that all need to be reiszed. Have a backup of the original folder, do everything on the copy.

Originally all pngs are 250x250. This is too large. 60x60 is better.

**Note**: I'm old (fashioned) and my little script is in csh, not bash. You're welcome to modify it, or install ```tcsh``` to run this.
I am skipping steps about moving in and out of folders, if you don't know that is happening here, don't do anything!

```mkdir new```
~~~
#!/bin/csh
foreach file ( *.png )
set name=$file:r
set newname=$name.1.png
echo $file $newname
convert $file -resize 100x100 ./new/$file
end
~~~
```\mv ./new/* .```
The above overwrites originals.

### Set boot logo

Simply: ```sudo update-initramfs -u```

Reboot.

End result: https://www.youtube.com/watch?v=Fpt66GfmoY0

Enjoy.








