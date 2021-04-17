# Create 5 Fedora Boxes to run Boinc

## 1.0 Install Fedora

Change host name to ```brahe```

```hostnamectl set-hostname brahe```

### Install sshd

~~~
sudo dnf install openssh-server
sudo systemctl enable sshd
sudo systemctl start sshd
sudo systemctl disable gdm
~~~

Restart

~~~
sudo dnf install lm_sensors htop glances cockpit boinc-* neofetch
sudo systemctl enable cockpit.socket 
sudo systemctl start cockpit

sudo dnf update -y
~~~

### Set Timezone and ntp

~~~
sudo timedatectl set-timezone Europe/London
sudo timedatectl set-ntp yes
~~~
