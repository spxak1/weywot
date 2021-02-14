# Add a Pop!_OS boot logo

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
