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

You can modify to Media-key/Navigation mode by holding the **Fn** key ![Function Key](../assets/fn.png) while pressing the **F-keys**.
Alternatively, you can **switch** to that mode with **Fn+Escape** as noted on the escape key bottom right corner ![Escape Key](../assets/esc.png).

From left to right:

| F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12 | Sound Up |
|----|----|----|----|----|----|----|----|----|----|-----|-----|-----|
|   |   | 125+15 | 125+30 | 125+32 |  |  | 165 | 164 | 163 | 113 | 114 | 115 |

The following keys have no keycodes, and only perform specific functions.

| Key | ![Screen brightness down](../assets/scrdn.png) | ![Screen brightness up](../assets/scrup.png) | ![Keyboard brightness down](../assets/kbdn.png) | ![Keyboard brightness up](../assets/kbup.png) | 
|---|----|----|----|----|
| Function | Screen Brigthness Down | Screen Brigthness Up | Keyboard Brigthness Down | Keyboard Brigthness Up | 

The **Sound Volume Up** key (![Sound Volume Up](../assets/sndup.png)) is not affected by the **Fn** key, and has the same keycode in either mode, **115**.

The navigation keys (F3, F4, F5) are labeled as follows:
Rather **disappointingly** all three keys are hardware coded to (apparently) Windows specific shortcuts.

| Key | ![Task View](../assets/task.png) | ![Action](../assets/action.png) | ![Desktop View](../assets/desktop.png) | 
|----|----|----|----|
| Name | Mission Control/Task View| Dashboard Launchapd/Action Centre | Show Desktop |  
| Keycode | 125+15 | 125+30 | 125+32 |
| Shortcut | Super + Tab | Super + A | Super + D |

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

| Key | ![Calculator](../assets/calc.png) | ![Screenshot](../assets/screenshot.png) | ![Context](../assets/context.png) | ![Lock](../assets/lock.png) |
|---|----|----|----|----|
| Name | Calculator | Screen Capture/Print Screen | App Contextual Menu/Right Click | Lock PC | 
| Keycode | 140 | 99 | 127 | 125+38 |
| Shortcut|  |  | Super + L |  

Only  the **Context** key changes with **Fn** as follows:

| Fn+Context |
|----|
| 70 |







![Control, Super, Alt](../assets/leftkeys.png)

![Alt, Fn, Control](../assets/rightkeys.png)

