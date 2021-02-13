# Review and configure the Logitech MX Keys for linux (Pop!_OS)

![The Logitech MX Keys - US ANSI Layout](../assets/logiMXKeys-us-ansi.png)

The MX Keys has a layout for Windows/Linux and Mac. Notable the left hand side of the keys show the Windows/Linux functions and the right hand side the Mac functions.

![Win/Mac](../assets/PC_layout.jpg) 

## Standard use

These are the keycodes of the keys. 

### Function keys

![Function Keys](../assets/fkeys.png)

#### In F-key mode

Keycodes from left to right:

| F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12 | Sound Up |
|----|----|----|----|----|----|----|----|----|----|-----|-----|-----|
| 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 87 | 88 | 115 |

#### In Media-key mode 

You can modify to Media-key/Navigation mode by holding the **Fn** key while pressing the **F-keys**. 
![Function Key](../assets/fn.png)

Alternatively, you can **switch** to that mode with **Fn+Escape** as noted on the escape key bottom right corner.
![Escape Key](../assets/esc.png)

From left to right:

| F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12 | Sound Up |
|----|----|----|----|----|----|----|----|----|----|-----|-----|-----|
|   |   | 125+15 | 125+30 | 125+32 |  |  | 165 | 164 | 163 | 113 | 114 | 115 |

The following keys have **no keycodes**, and only perform specific functions.

| Key | ![Screen brightness down](../assets/scrdn.png) | ![Screen brightness up](../assets/scrup.png) | ![Keyboard brightness down](../assets/kbdn.png) | ![Keyboard brightness up](../assets/kbup.png) | 
|---|----|----|----|----|
| Function | Screen Brigthness Down | Screen Brigthness Up | Keyboard Brigthness Down | Keyboard Brigthness Up | 

The **Sound Volume Up** key is not affected by the **Fn** key, and has the same keycode in either mode, **115**.
(![Sound Volume Up](../assets/sndup.png))

Rather **disappointingly** all three keys are hardware coded to (apparently) Windows specific shortcuts.

| Key | ![Task View](../assets/task.png) | ![Action](../assets/action.png) | ![Desktop View](../assets/desktop.png) | 
|----|----|----|----|
| Name | Mission Control/Task View| Dashboard Launchapd/Action Centre | Show Desktop |  
| Keycode | 125+15 | 125+30 | 125+32 |
| Shortcut | Super + Tab | Super + A | Super + D |

In standard gnome, these will actually work, but in Pop!_OS, *Super+d* is used **only in tiling mode** and as such that key doesn't do anything in normal mode. 
These keys cannot be changed with xinput, all that can be done is to use them and reshuffle the shortcuts from *gnome-settings*. 

However **solaar** is can make this keys perform other functions (see solaar section).

### Easy Switching keys

![Device Switch Keys](../assets/dekeys.png)

These are hardware keys and do not appear as keystrokes to the system. They are used to switch to different connected devices, as this keyboard can control three computers/tablets/phones via its **Unifying** USB dongle and/or **Bluetooth**.

These keys, may be used for other functions, however, using **solaar** (see solaar section).

### Numeric Keypad Top Row keys

![NumPad Top Row Keys](../assets/cornerkeys.png)

The proper names of these keys, from left to right are:

| Key | ![Calculator](../assets/calc.png) | ![Screenshot](../assets/screenshot.png) | ![Context](../assets/context.png) | ![Lock](../assets/lock.png) |
|---|----|----|----|----|
| Name | Calculator | Screen Capture/Print Screen | App Contextual Menu/Right Click | Lock PC | 
| Keycode | 140 | 99 | 127 | 125+38 |
| Shortcut |   |   |   | Super + L |  

Again, disappointingly he **lock** key is hardware coded to a Windows shortcut. This may work in standard gnome, but in Pop!_OS, lock has been moved to *Super+Esc*, so a new shortcut should be added in gnome-settings to make it work. 

Only  the **Context** key changes with **Fn** as follows:

| Fn+Context |
|----|
| 70 |

Again, **solaar** can change the functions of all these keys (see sollar section).

### Left and Right Control Keys

![Control, Super, Alt](../assets/leftkeys.png)

![Alt, Fn, Control](../assets/rightkeys.png)

Notably the **Fn** key has been **moved to the right side** of the spacebar. This can be a **big issue** for those who want to use this keyboard with a laptop that normally has the **Fn** on the left side and as such now they have to break muscle memory. Personally, this is a big problem.


## Solaar

Solaar is the driver that currently supports (most) of Logitech's proprietary HID extension and offers (most) of the features available in Windows.

You will need the **latest version of solaar** from github to have full access to this keyboard's abilities.

![Solaar](../assets/solaar0.png)

Solaar offers Control for:

* Backlight on/off
* F-Keys swap 
* Key diversion (full customisation)
* Disable specific keys
* Select OS operation (Windows/Linux or Mac, iOS or Android)
* Change of host (same function as the three Easy Switch keys)

### Disable Keys

![Solaar](../assets/solaar1.png)

The **scroll lock** key is accessed with **Fn+Context** and has keycode **70**. 

### Key Diversion

Key diversion is the complete key customisation feature. In Windows this is done typically from the **Options** software by clicking on a key and selecting its use from a drop down menu. 
Solaar offers the same (if not better) level of customisation, using **rules**, accessed by the **Rule Editor** at the bottom right corner of the window. It is not as easy as clicking a key and setting its function, but it is very simple to use, and much simpler than **Options** if you edit the config file directly. 

These are the keys available to customise.

![Solaar](../assets/solaar2.png)






