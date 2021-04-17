# Create 5 Fedora Boxes to run Boinc

## 1.0 Install Fedora

Change host name to ```brahe```
```hostnamectl set-hostname brahe```

### Install sshd

```sudo dnf install openssh-server```
```sudo systemctl enable sshd```
```sudo systemctl start sshd````
```sudo systemctl disable gdm```

Restart

~~~
sudo dnf update -y

sudo dnf install boinc-*

sudo dnf install lm_sensors htop glances cockpit
~~~

### Set Timezone

```sudo timedatectl set-timezone Europe/London```
