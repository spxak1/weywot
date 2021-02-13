## Review and configure the Logitech MX Keys for linux (Pop!_OS)

![The Logitech MX Keys - US ANSI Layout](../assets/logiMXKeys-us-ansi.png)

## Keys reported by showkey

### Function keys

![Function Keys](../assets/fkeys.png)

#### In F-key mode

Keycodes from left to right:

| F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12 | Sound Up |
|----|----|----|----|----|----|----|----|----|----|-----|-----|-----|
| 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 87 | 88 | 115 |

#### In Media-key mode

From left to right:

| F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12 | Sound Up |
|----|----|----|----|----|----|----|----|----|----|-----|-----|-----|
|   |   | 125+15 | 125+30 | 125+32 |  |  | 165 | 164 | 163 | 113 | 114 | 115 |

F1, F2, F6 and F7 are hardware keys only. Their purpose is as follows:

F1, F2: Adjust screen brightness (on laptops/supported monitors) To be tested.

F6, F7: Adjust the keyboards brightness (eight levels).

The **Sound Up** (last key in that row) is not affected by the **Fn** key, and has the same keycode in either mode.

The navigation keys (F3, F4, F5) are labeled as follows:
~~~
F3: Mission Control/Task View
F4: Dashboard Launchapd/Action Centre
F5: Show Desktop
~~~

Rather **disappointingly** all three keys are hardware coded to (apparently) Windows specific shortcuts.

| Key | Keycode | Shortcut |
|---|---|---|
| F3 | 125+15 | Super + Tab |
| F4 | 125+30 | Super + a |
| F5 | 125+32 | Super + d |

In standard gnome, these will actually work, but in Pop!_OS, *Super+d* is used only in tiling mode and as such that key doesn't do anything. 
These keys cannot be changed with xinput, all that can be done is to use them and reshuffle the shortcuts from *gnome-settings*. 

However **solaar** is here to save the day (see Solaar section later).

### Device switching keys

![Device Switch Keys](../assets/dekeys.png)

These are hardware keys and do not appear as keystrokes to the system. They are used to switch to different connected devices, as this keyboard can control three computers/tablets/phones via its **Unifying** USB dongle and/or **Bluetooth**.

These keys, may be used for other functions, however, using **solaar**.

### Numeric Keypad Top Row keys

![NumPad Top Row Keys](../assets/cornerkeys.png)

The proper names of these keys, from left to right are:

~~~
Calculator, Screen Capture/Print Screen, App Contextual Menu/Right Click, Lock PC
~~~

| Calculator | Screenshot | Context | Lock | 
|----|----|----|----|
| 140 | 99 | 127 | 125+38 |

Only  the **Context** key changes with **Fn** as follows:

| Fn+Context |
|----|
| 70 |







![Control, Super, Alt](../assets/leftkeys.png)

![Alt, Fn, Control](../assets/rightkeys.png)

