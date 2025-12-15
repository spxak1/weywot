# Conditional Howdy and Fingerprint authentication

## 1. Purpose
This is a guide on how to get your laptop to switch from Howdy+Fingerprint (then password) authentication to only password authentication when the lid is closed.
This is for those who use their laptop with a dock. 

### 1.1 Usecase

When your laptop is in laptop mode, the screen (lid) is open and the IR camera can see you and the fingerprint sensor is accessible. 
In this case you want Howdy to use the IR to authenticate you (gnome/GDM and sudo), and the fingerprint sensor to be next, as a fallback if Howdy for whatever reason fails/times out.
The standard password authentication is then third/last in case both Howdy and the fingerprint sensor fail.

When you laptop is connected to the dock, the lid is closed. As such you don't want to wait for Howdy to timeout, then the fingerprint sensor to timeout to type the password.
So you want the laptop to switch from one mode to another.

## 1.2 Method

A script is executed when a change in the state of the lid is detected.
The script enables/disables the fingerprint sensor.

This needs to be done when:
* Booting
* Resuming from suspend (waking)
* Resuming from hibernation 
* At any time the laptop's lid is changed (e.g when plugging the laptop to the dock while it's on, then you close the lid).

## 2. Not covered

Configuring Howdy, fprintd, hibernation are not covered. They are assumed to work before you start, although only howdy and fprintd with a working sensor are needed for this guide.

## 3. Tools

### 3.1 Howdy

This is the easy part. Howdy has a switch in its configuration which enables/disables based on the lid state. 

```sudo howdy config```

Then find the line with: 

~~~
# Disable Howdy if lid is closed
abort_if_lid_closed = true
~~~

I think the *default* is *true*, so possibly no need to change anything else. But check. Done.

### 3.2 Fingerprint sensor (fprintd)

I am choosing to do this the proper way rather than the easy way. 

#### 3.2.1 Mask/disable and unmask/enable fprintd

This is the proper way, toggling the fprintd daemon on and off when it is needed and when not. 

For the record, another *crude* way, but possibly creating fewer issues, would be to replace the two auth-files when moving from open to closed lid and vice versa. But that's for a different day...

### 3.3 Acpid and systemd

Acpid is used to sense the change, and triger a script, and systemd is used for the checks to run at boot up and resume. 

### 3.4 SElinux (Fedora)

This is a requirement as acpid cannot turn on an off services unless SElinux allows it. This was the most painful process as the permissions need to be set separately to:
* Start fprintd
* Stop fprintd
* Restart fprintd

## 4 The process

This is as follows: 
* Acpid checks for changes in the status of the lid
* Acpid runs a **script** which actually changes fprintd
* A systemd service runs the same script at startup and resuming from hibernation
* A systemd process is run at resume from suspend

### 4.1 The script

Place the script in ```/usr/local/bin/dock-manager.sh```

~~~
#!/bin/bash

# Give the kernel a moment to update the file after the event triggers
sleep 1

# 1. Check Lid State (verified LID0 path)
LID_STATE=$(grep -o "open\|closed" /proc/acpi/button/lid/LID0/state)

# 2. Log to journal so we know it ran
logger -t dock-manager "ACPI Event triggered. Current State: $LID_STATE"

# 3. Logic
if [[ "$LID_STATE" == "closed" ]]; then
    # Action: CLOSED
    nmcli radio wifi off
    systemctl mask --now fprintd.service
    logger -t dock-manager "Lid Closed: Wifi OFF, Fingerprint MASKED"

elif [[ "$LID_STATE" == "open" ]]; then
    # Action: OPEN
    nmcli radio wifi on
    systemctl unmask fprintd.service
    systemctl start fprintd.service
    logger -t dock-manager "Lid Open: Wifi ON, Fingerprint STARTED"
fi
~~~

Note: This script also enables/disables wifi. I do this because when the laptop is used with the lid down, it's connected to a USB-C dock of some sort which always has ethernet network. If you want to change this behaviour, remove the lines will ```nmcli``` in them.

The ```fprintd``` service cannot be merely stopped, it must be masked. Otherwise the sensor is still alive.

### 4.2 The acpid trigger

This is what monitors the change *when the laptop goes from open to closed lid while running*. 

You place this in ```/etc/acpi/events/lid-toggle```. Obviously ```acpid``` should be installed (```sudo dnf install acpid``` for Fedora). 
~~~
event=button/lid.*
action=/usr/local/bin/dock-manager.sh
~~~

Very simple, check for the change, run the script above.

### 4.3 The boot/resume from hibernation check using a systemd service

Put this in your ```/etc/systemd/system/dock-manager-boot.service```

~~~
[Unit]
Description=Run dock-manager check on boot
# Wait for the graphical environment so nmcli/systemctl commands work correctly
After=network.target graphical.target

[Service]
Type=oneshot
# A small delay to ensure GNOME/Services are fully initialized
ExecStartPre=/usr/bin/sleep 5
ExecStart=/usr/local/bin/dock-manager.sh

[Install]
WantedBy=multi-user.target
~~~

Then ```sudo systemctl enable --now dock-manager-boot.service``` to eanble it right away.

### 4.4 The systemd resume from sleep refresher

Put this in ```/usr/lib/systemd/system-sleep/dock-manager-refresh```

~~~
#!/bin/bash

# $1=pre/post, $2=suspend/hibernate/hybrid-sleep
case $1/$2 in
  post/*)
    # Wait 5 seconds to ensure hardware (and dock) are ready after deep sleep/hibernate
    sleep 5
    
    # Run the manager
    /usr/local/bin/dock-manager.sh
    ;;
esac
~~~

Simply runs the script when resuming, to check status of the lid and act accordingly.

This is in case you had suspended your laptop and then connected it to the dock and powerd it on with the lid closed. It suspended with the lid up (even if you triggered the suspend event by putting the lid down, this is not relevant), it wakes up with the lid closed, it must adapt accordingly.

## 5 SElinux whack-a-mole

Here's the trouble. Running the script manually works fine. ```fprintd``` can be stopped, masked, unmasked, started. Sadly when ```acpid``` runs the script, Selinux won't let it.

**This part is not well documented**

Boot your laptop with the lid open. Now, open the log and look for the output:

```sudo journalctl -f```. 

### 5.1 Trigger the failure

**Close** the lid: Observe the **red** output by Selinux. 

Once you see it, capture it into a module:

```sudo ausearch -c 'acpid' --raw | sudo audit2allow M acpid_fprintd```

Then install the module:

```sudo semodule -i acpid_fprintd.pp```

This allows acpid to turn the service off and mask it.

### 5.2 Repeat

**Open** the lid: Observe the **red** output by Selinux. 

Do the same. This time ausearch captures the new output. Everything appears the same but the contents of the module are different.

```sudo ausearch -c 'acpid' --raw | sudo audit2allow M acpid_fprintd```

Then install the module:

```sudo semodule -i acpid_fprintd.pp```

This allows to turn the service on and unmask it

### 5.3 Repeat again

**Close** the lid: Observe the **red** output by Selinux. 

Do the same. This time ausearch captures a third new output. Everything appears the same but the contents of the module are different.

```sudo ausearch -c 'acpid' --raw | sudo audit2allow M acpid_fprintd```

Then install the module:

```sudo semodule -i acpid_fprintd.pp```

This allows to restart the service on and unmask it

**Note**: If things still don't work, you haven't overcome SElinux so repeat the step above everytime you see the *red* output.

Done.





