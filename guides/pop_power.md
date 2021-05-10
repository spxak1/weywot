Original post: https://www.reddit.com/r/pop_os/comments/n8b7f1/does_system76power_profile_change_cpu_tdp_on/

**Update at the end**

I've been trying to find a reference to what ```system76-power profile``` does when changing from ```performance``` to ```balanced``` to ```battery``` on **non** System76 computers.

The obvious changes can be tracked by simply issuing ```system76-power profile```, 

Here's a collection of the outputs of the different profiles on my ThinkPad T460p:

~~~
Power Profile: Performance
CPU: 50% - 100%, Turbo
Backlight intel_backlight: 604/937 = 64%
Keyboard Backlight tpacpi::kbd_backlight: 2/2 = 100%
~~~

~~~
Power Profile: Balanced
CPU: 22% - 100%, Turbo
Backlight intel_backlight: 374/937 = 39%
Keyboard Backlight tpacpi::kbd_backlight: 2/2 = 100%
~~~

~~~
Power Profile: Battery
CPU: 22% - 50%, No Turbo
Backlight intel_backlight: 93/937 = 9%
Keyboard Backlight tpacpi::kbd_backlight: 2/2 = 100%
~~~

I will leave the screen backlight out of this as it is well documented in discussions on github about how and why it decreases moving from performance to balanced to battery, but not increasing when changing "up" profiles. It's clear what is happening.

It is also evident that the CPU is bound by different frequency limits and boost status is changed. 

Obviously the keyboard backlight is ignored in my case (non-System 76 computer).

I can also check and the **CPU governor** is **not** changed. 

I know that with **System76** computers, the TDP of the CPU **and** the fan curves are also adjusted with different profiles. For the latter I have not evidence of the curve changing (I obviously check without tpfan or equivalent curve controlling scripts). 

So the question is really about the latter two, TDP and fan curves. Are thee changed in non System76 computers?

Any references on this are appreciated.

**Update**:
I have now ran a few tests and here are the conclusions for my **non** System76 laptop:

* The fan curve is not changed between profiles. It's the same curve my firmware has (and uses in any OS).

* The CPU TDP is not changed in different profiles. I use ```sudo turbostat --Summary --interval 5 --show Avg_MHz,Busy%,Bzy_MHz,IRQ,PkgTmp,PkgWatt,GFXWatt``` to see the power use (penultimate column) while running ```stress -c 4``` (and -c 8, same results) and the power doesn't change. Obviously in battery mode with the top frequency limited to 50% and no boost, that does change, but not because of a TDP change, but because the CPU is limited.

While my test is not thorough or complete, I think I can safely conclude that for **non** System76 computers, the power profiles only perform these changes:

1. Screen brightness is reduced
2. Top CPU speed is limited to 50% and boost is disabled in **battery** mode

The important changes in TDP and fan curves (as expected) only work with System76 computers.
