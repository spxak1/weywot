# Add alt+shift to change keyboards:
~~~
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Alt>Shift_L']"
~~~
[Link](https://forum.manjaro.org/t/i-have-to-press-alt-shift-twice-for-switching-keyboard-layout/106637)

This means there is no need for ```gnome-tweaks``` which has the problem of having to press alt+shift twice to get out of English (see link above).

## Add Caps lock to change key, both shift to enable caps lock shift to disable it:

~~~
settings set org.gnome.desktop.input-sources xkb-options "['grp:caps_toggle', 'shift:both_capslock_cancel']"
~~~

You can instal gnome-tweaks, open dconf-editor and view what the options do.

# STILL NEED TO FIND

How to have: Caps lock to change keyboard **and** turn the LED on!
Then, shift caps to enable/disable caps lock.
