# How to pair the same device on Windows and Linux without the need to repair when you switch OS

This is adapted from [the ArchWiki](https://wiki.archlinux.org/index.php/Bluetooth#Dual_boot_pairing)

## 1.0 Prerequisites

Install **chntpw**, a registry editor. 

```sudo apt install chntpw```

## 2.0 Working principle

When BT devices pair with a computer they create unique keys. Once a device is connected, it links that key to the MAC address of the host (the computer). 
When two operating systems exist on that computer, then pairing that device to the computer in Windows creates one key for that computer's MAC address.
Then pairing the same device to Linux, creates a different key for that MAC address, which overwrites the old one.

While BT devices can be paired with a large number of computers/hosts, they can only hold **one** such key for every MAC (host) address. Since Windows and Linux
use the same hardware and as such the same MAC address, once a BT device is paired to Windows and to Linux, the device will only work (connect) to the OS to which it was paired last
as this OS has the key stored in the device.

## 3.0 Workaround

The solution to this problem is to make both operating systems **use the same key**. For this the device is **paired to linux first, then paired to Windows**.
At this point the device can connect to Windows, but not linux. We need to **copy the key from Windows to Linux**, as it is easier to edit that in linux than in Windows.

## 4.0 Obtain the key from the Windows pairing

From linux, mount your Windows partition to a known path, then navigate to ```/path/to/Windows/Windows/System32/config```

In this folder type: ```chntpw -e SYSTEM```
You can see a prompt (**>**) to navigate Window's registry.

Go to the BT keys:
~~~
> cd ControlSet001\Services\BTHPORT\Parameters\Keys
~~~

At this point you need to know your BT adapter's MAC address. Find out from a **different terminal** by doing:

~~~
otheos@weywot:~$ bluetoothctl list
Controller 5C:80:B6:8E:78:ED weywot [default]
~~~

The MAC address is the string starting with 5C.

Back to your other terminal, 

List available devices:

~~~
> ls
~~~

This should give you an ouput that looks like this:

~~~
(...)\Services\BTHPORT\Parameters\Keys> ls
Node has 3 subkeys and 0 values
  key name
  <5c80b68e78ed>
  <645d8692e2d9>
  <d8f88336850c>
~~~

The first entry (subkey) is the same as the MAC we found for the computer's adapter. So move in, **and list the contents again**:

~~~
(...)\Services\BTHPORT\Parameters\Keys> cd 5c80b68e78ed

(...)\BTHPORT\Parameters\Keys\5c80b68e78ed> ls
Node has 3 subkeys and 5 values
  key name
  <4c4feede0f16>
  <58cb5283e253>
  <da5b4a88508b>
  size     type              value name             [value if type DWORD]
    16  3 REG_BINARY         <58cb5283e253>
    16  3 REG_BINARY         <88c626d49a70>
    16  3 REG_BINARY         <MasterIRK>
    16  3 REG_BINARY         <4c4feede0f16>
    16  3 REG_BINARY         <104fa875c82e>
~~~

Here you can see some connexted devices (keys) and then some Binaries. This is what we're after.

## 5.0 Finding the Windows Key. Example: BT Headphones

I have already paired my BT headphones to both Linux and Windows as described in section 3.0, and they work fine in Windows, but not in linux.

You can find the MAC of your headphones from linux using:

~~~
otheos@weywot:~$ bluetoothctl devices
Device 77:52:36:05:2E:03 77-52-36-05-2E-03
Device DA:5B:4A:88:50:8C MX Anywhere 3
Device 00:02:72:CC:0B:6B Belkin SongStream BT HD
Device 44:16:22:A4:FC:30 Xbox Wireless Controller
Device 1C:91:9D:A4:5F:C0 Mi True Wireless EBs Basic_L
Device 88:C6:26:D4:9A:70 H800 Logitech Headset
Device 10:4F:A8:75:C8:2E h.ear (MDR-100ABN)
~~~

My headphones are the last device (MDR-100ABN), with a MAC starting with 10:4F.

Back to the terminal with the Windows registry, I can see the last **REG_BINARY** has the same value name as the MAC address.

In that terminal type:

~~~
(...)\BTHPORT\Parameters\Keys\5c80b68e78ed> hex 104fa875c82e
Value <104fa875c82e> of type REG_BINARY (3), data length 16 [0x10]
:00000  54 80 E3 E3 01 49 3A E3 E4 8C 5A 74 18 E8 25 54 T....I:...Zt..%T
~~~
 
We have just read the key, the long string starting with **54** and endint with **54** (by coincidence). 




