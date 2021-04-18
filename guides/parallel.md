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


### Install folding@home

~~~
sudo dnf install pygtk2 python2
~~~

Go to: https://foldingathome.org/start-folding/ 
and download the three packages:

~~~
mkdir folding && cd folding
wget https://download.foldingathome.org/releases/public/release/fahclient/centos-6.7-64bit/v7.6/fahclient-7.6.21-1.x86_64.rpm
wget https://download.foldingathome.org/releases/public/release/fahcontrol/centos-6.7-64bit/v7.6/fahcontrol-7.6.21-1.noarch.rpm
wget https://download.foldingathome.org/releases/public/release/fahviewer/centos-6.7-64bit/v7.6/fahviewer-7.6.21-1.x86_64.rpm
sudo rpm -i *
~~~

### Enrol
~~~
sudo FAHClient --configure
~~~

user: spxak1

team: 1061031

pass: newcar

Edit /etc/fahclient/config.xml:

~~~
<config>
  <!-- Folding Core -->
  <core-priority v='low'/>

  <!-- Folding Slot Configuration -->
  <cause v='ALZHEIMERS'/>
  <cpus v='2'/>

  <!-- HTTP Server -->
  <allow v='127.0.0.1 10.20.30.0/24'/>

  <!-- Network -->
  <proxy v=':8080'/>

  <!-- Remote Command Server -->
  <command-allow-no-pass v='127.0.0.1 10.20.30.0/24'/>

  <!-- Slot Control -->
  <pause-on-battery v='false'/>
  <power v='full'/>

  <!-- User Information -->
  <passkey v='9ac6c9c2ff7b95cd9ac6c9c2ff7b95cd'/>
  <team v='1061031'/>
  <user v='spxak1'/>

  <!-- Folding Slots -->
  <slot id='0' type='CPU'/>
</config>

~~~

