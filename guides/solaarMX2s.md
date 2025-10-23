# Configure the Logitech MX Master 2S for Volume up/down with the thumbwheel
The MX Master 2S doesn't present its thumbwheel as a button that can be diverted like the MX3/s.
Instead it presents it as a gesture. So it needs special configuration to divert it to anything other than the default horizontal scroll.

**BUG WARNING**
Solaar 1.1.14 and older versions have a bug. The Gesture under which the Thumb Wheel is controlled is Gesture 2. 
Selecting Gesture 2, however from the list of Features (in Actions) in the rule editor, will instead give "None". 
This an be "fixed" by *typing* GESTURE in the search field, and GESTURE will appear and in the rule it will present itself as GESTURE (6500). Then continue typing GESTURE_2 (with the underscore).
This will make GESTURE 2 (6501) appear properly in the rule. 
However, this will not survive a Solaar restart and needs to be applied again. 
No edit in the ```rules.yaml``` file can fix that.

In version 1.1.15 and newer this bug is fixed. The simplest way to get a newer version, if your distro is still on 1.1.14, is to download the zip (clone the Git) from [solaar's git page](https://github.com/pwr-Solaar/Solaar) and replace the binary in ```/usr/bin/solaar``` with the one in ```Solaar-Master/bin/solaar```.

## The rule
Paste this in your ```~/.config/solaar/rules.yaml```
~~~
%YAML 1.3
---
- Feature: GESTURE 2
- TestBytes: [2, 3, 3, 3]
- Rule:
  - TestBytes: [3, 4, 1, 127]
  - KeyPress:
    - XF86_AudioRaiseVolume
    - click
- Rule:
  - TestBytes: [3, 4, -128, -1]
  - KeyPress:
    - XF86_AudioLowerVolume
    - click
...
~~~

Or in the rule editor:

![Solaar](../assets/Screenshot%20From%202025-10-24%2000-44-25.png)

