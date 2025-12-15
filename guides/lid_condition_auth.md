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

#### 3.1 Mask/disable and unmask/enable fprintd

This is the proper way, toggling the fprintd daemon on and off 
