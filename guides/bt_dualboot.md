# How to pair the same device on Windows and Linux without the need to repair when you switch OS

This is adapted from [the ArchWiki](https://wiki.archlinux.org/index.php/Bluetooth#Dual_boot_pairing), so all credit goes to the Arch community.

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

So, steps:
* Pair the device in linux first
* Reboot to Windows, pair the device in Windows. Reboot to linux.

## 4.0 View the Windows registry from Linux

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

## 6.0 Replacing the Linux key with the one from Windows. Example: BT Headphones

In a new terminal gain root access with ```sudo su```. **Be careful, you are root, you can damage your system**

Then, navigate tot the config files for your BT adapter, enter the adapter's folder, then enter's the device's folder

~~~
root@weywot:/home/otheos# cd /var/lib/bluetooth/
root@weywot:/var/lib/bluetooth# ls
total 8.0K
4.0K 5C:80:B6:8E:78:ED  4.0K 64:5D:86:92:E2:D9
root@weywot:/var/lib/bluetooth# cd 5C\:80\:B6\:8E\:78\:ED/
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED# ls
total 32K
4.0K 00:02:72:CC:0B:6B  4.0K 44:16:22:A4:FC:30  4.0K DA:5B:4A:88:50:8C
4.0K 10:4F:A8:75:C8:2E  4.0K 88:C6:26:D4:9A:70  4.0K settings
4.0K 1C:91:9D:A4:5F:C0  4.0K cache
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED# cd 10\:4F\:A8\:75\:C8\:2E/
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED/10:4F:A8:75:C8:2E# ls
total 4.0K
4.0K info
~~~
We have found that config file, it's the **info** file we need to edit. Use ```nano```.
Find the section with:

~~~
[LinkKey]
Key=32E5D212A8D5E2E35512E1348E25D431
Type=4
PINLength=0
~~~

Now replace the ```Key``` line with a line with the new key. This needs to be **in capital, no spaces**.

Your final product should look like this:

~~~
[LinkKey]
Key=5480E3E301493AE3E48C5A7418E82554
Type=4
PINLength=0
~~~

Save and exit with **ctrl+x**. 

That's it. The headphones should work on both Operating systems.


## 7.0 Finding the Windows Key and connecting a BT mouse (Logitech MX Anywhere 3)

With mice, the pairing involves a couple more steps. Pair the mice to Linux first, then reboot to Windows, pair it again with Windows.

Note for MX users: Use the same device number (button at the bottom of mouse). If you use different numbers, you don't need this guide (but you have to change from one device to the other using the button in different operating systems). 


First find the mouse's BT MAC address.

~~~
otheos@weywot:~$ bluetoothctl devices
Device 77:52:36:05:2E:03 77-52-36-05-2E-03
Device DA:5B:4A:88:50:8B MX Anywhere 3
Device 00:02:72:CC:0B:6B Belkin SongStream BT HD
Device 44:16:22:A4:FC:30 Xbox Wireless Controller
Device 1C:91:9D:A4:5F:C0 Mi True Wireless EBs Basic_L
Device 88:C6:26:D4:9A:70 H800 Logitech Headset
Device 10:4F:A8:75:C8:2E h.ear (MDR-100ABN)
~~~

The mouse has a MAC address starting with DA:5B:4A:88:50:8C (second device on that list). Note it ends with **8B**.

Back to the terminal with the Window's registry we find that MAC address when we look inside the adapter's MAC address:

~~~
(...)\BTHPORT\Parameters\Keys\5c80b68e78ed> ls
Node has 3 subkeys and 5 values
  key name
  <4c4feede0f16>
  <58cb5283e253>
  <da5b4a88508c>
  size     type              value name             [value if type DWORD]
    16  3 REG_BINARY         <58cb5283e253>
    16  3 REG_BINARY         <88c626d49a70>
    16  3 REG_BINARY         <MasterIRK>
    16  3 REG_BINARY         <4c4feede0f16>
    16  3 REG_BINARY         <104fa875c82e>
~~~

It's the third one down. There is no **REG_BINARY** here, like for the headphones, because the mouse involves more data in its pairing. 

Also note, the MAC address ends up with **8c**. This is because some mice have a rolling (changing) MAC address, and everytime you pair them anew, the MAC addres changes (the last bit anyway). 

So what has happened is, we paired the mouse to linux, and it used the **8B** ending MAC. Then we paired it with Windows and it changed its MAC to the one ending with **8C**. So currently the mouse is using the **8C** MAC address, the last one used.

Clearly this means that Linux not only has the **wrong keys** but aslo the **wrong MAC address**. We need to fix the MAC address first.

If your MAC address is the same, you don't need this step. Jump straight to section **7.2**. 

### 7.1 Make both OS's use the same MAC address, the current used by the mouse

For that you go onto your local (root) terminal and you rename it as follows:

~~~
root@weywot:/home/otheos# cd /var/lib/bluetooth/5C\:80\:B6\:8E\:78\:ED/
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED# ls
total 32K
4.0K 00:02:72:CC:0B:6B  4.0K 44:16:22:A4:FC:30  4.0K DA:5B:4A:88:50:8B
4.0K 10:4F:A8:75:C8:2E  4.0K 88:C6:26:D4:9A:70  4.0K settings
4.0K 1C:91:9D:A4:5F:C0  4.0K cache
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED# 
~~~

So you just do:

~~~
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED# mv DA\:5B\:4A\:88\:50\:8B/ DA\:5B\:4A\:88\:50\:8C
~~~

and now the name of the folder (which corresponds to the MAC address of the mouse) has changed to the correct (current) one.

See,

~~~
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED# ls
total 32K
4.0K 00:02:72:CC:0B:6B  4.0K 44:16:22:A4:FC:30  4.0K DA:5B:4A:88:50:8C
4.0K 10:4F:A8:75:C8:2E  4.0K 88:C6:26:D4:9A:70  4.0K settings
4.0K 1C:91:9D:A4:5F:C0  4.0K cache
~~~

Changed!

### 7.2 Changing the key

Back to the registry editor terminal, to get the keys.

So, move onto the mouse's MAC address to see what other data is there:

~~~
(...)\BTHPORT\Parameters\Keys\5c80b68e78ed> cd da5b4a88508c

(...)\Parameters\Keys\5c80b68e78ed\da5b4a88508c> ls
Node has 0 subkeys and 9 values
  size     type              value name             [value if type DWORD]
    16  3 REG_BINARY         <LTK>
     4  4 REG_DWORD          <KeyLength>                0 [0x0]
     8  b REG_QWORD          <ERand>
     4  4 REG_DWORD          <EDIV>                     0 [0x0]
    16  3 REG_BINARY         <IRK>
     8  b REG_QWORD          <Address>
     4  4 REG_DWORD          <AddressType>              1 [0x1]
     4  4 REG_DWORD          <MasterIRKStatus>          1 [0x1]
     4  4 REG_DWORD          <AuthReq>                 45 [0x2d]
~~~

With an ```ls``` in that folder you can see there are quite a few data, some are **REG_BINARY** others are different. We only care about the former. But which?

On your **root** terminal, go to the mouse's folder:

~~~
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED# cd DA\:5B\:4A\:88\:50\:8C/
root@weywot:/var/lib/bluetooth/5C:80:B6:8E:78:ED/DA:5B:4A:88:50:8C# ls
total 8.0K
4.0K attributes  4.0K info
~~~

Here there are two files, we're still interested in the **info** file. Open it with nano and now you can see, among other things there are **two keys**:

~~~
[IdentityResolvingKey]
Key=667912001ECEBA977D807D259A9FBD70

[SlaveLongTermKey]
Key=2BC324CDC98F3308526610C36A28E5C4
Authenticated=2
EncSize=16
EDiv=0
~~~

The keys are identified as: **IdentityResolvingKey**, or (acronym) **IRK** and **SlaveLongTermKey** or (acronym) **LTK**.

Now look back at your **REG_BINARY** entries in the registry terminal. There is an **LTK** at the top, and an **IRK**, fourth one down. These are the ***only*** **REG_BINARY** entries, so they're easy to spot. 

Now read their content in hexadecimal:

~~~
...)\Parameters\Keys\5c80b68e78ed\da5b4a88508c> hex IRK
Value <IRK> of type REG_BINARY (3), data length 16 [0x10]
:00000  53 78 9B 41 FE 80 DA D0 C9 F1 8C E2 E4 0D 9D 94 Sx.A............


(...)\Parameters\Keys\5c80b68e78ed\da5b4a88508c> hex LTK
Value <LTK> of type REG_BINARY (3), data length 16 [0x10]
:00000  AA 7A 73 A6 BF A1 FE 7E 24 70 31 C1 31 E3 38 0B .zs....~$p1.1.8.
~~~

These are you two keys. Back to that **info** file to replace the old ones, and the final product should look like:

~~~
[IdentityResolvingKey]
Key=53789B41FE80DAD0C9F18CE2E40D9D94

[SlaveLongTermKey]
Key=AA7A73A6BFA1FE7E247031C131E3380B
Authenticated=2
EncSize=16
EDiv=0
~~~

Save and exit with **ctrl+x** (if using nano). 

As soon as the file is saved your mouse becomes available. Or restart BT with ```sudo systemctl restart bluetooth```.
Enjoy using the same device on both your operating systems without repairing.





