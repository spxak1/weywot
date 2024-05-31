# Post F40 - My installation

## Make pico link to nano

~~~
sudo ln -s /usr/bin/nano /usr/local/bin/pico
~~~

## Configure DNF

Taken from [this Medium post](https://medium.com/@KarolDanisz/things-to-do-after-installing-fedora-39-workstation-cc8eb4090dd1)

~~~
sudo nano /etc/dnf/dnf.conf
~~~

Add:
~~~
max_parallel_downloads=10
fastestmirror=True
deltarpm=True
defaultyes=True
~~~

Then ```sudo dnf upgrade --refresh``` and reboot.



## Reduce timeouts -- Changed in F40

~~~
sudo nano /etc/systemd/system.conf
~~~

Then change as following:
~~~
DefaultTimeoutStartSec=15s
DefaultTimeoutStopSec=15s
~~~


## Update firwmare

~~~
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update
~~~

## RPM Fusion and codecs

Taken from [rpmfusion docs](https://rpmfusion.org/Howto/Multimedia)

~~~
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
~~~

Then:

~~~
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
sudo dnf groupupdate multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf groupupdate sound-and-video
~~~

For intel:
~~~
sudo dnf install intel-media-driver
~~~

Some firwmares
~~~
sudo dnf install rpmfusion-nonfree-release-tainted
#sudo dnf --repo=rpmfusion-nonfree-tainted install "*-firmware"
~~~

Complete with:

~~~
sudo dnf group update core
~~~

## Install and configure syncthing

~~~
sudo dnf install syncthing
sudo systemctl enable --now syncthing@[user].service
~~~

Then login to [http://localhost:8384](http://localhost:8384) to complete the configuration.

## Install ZFS (in needed)

Taken from the [OpenZFS documentation](https://openzfs.github.io/openzfs-docs/Getting%20Started/Fedora/index.html)

Remove zfs-fuse if installed, then install. This takes time, be patient.

~~~
sudo rpm -e --nodeps zfs-fuse
sudo dnf install -y https://zfsonlinux.org/fedora/zfs-release-2-5$(rpm --eval "%{dist}").noarch.rpm
sudo dnf install -y kernel-devel
sudo dnf install zfs
sudo modprobe zfs
~~~

By default ZFS kernel modules are loaded upon detecting a pool. To always load the modules at boot:
~~~
sudo nano /etc/modules-load.d/zfs.conf
~~~

Add ```zfs``` in there. Exit.

## Install some apps

Open Gnome Apps to enable external repos (including Google's Chrome)

~~~
sudo dnf install dnf5 ncdu fastfetch google-chrome-stable vlc gparted gnome-tweaks tilix qalculate-gtk -y
flatpak install flathub com.mattjakeman.ExtensionManager com.spotify.Client ca.desrt.dconf-editor io.gitlab.adhami3310.Converter io.typora.Typora md.obsidian.Obsidian org.gnome.World.PikaBackup io.github.realmazharhussain.GdmSettings
~~~

## Add keyboard layouts and set alt+shift to change

~~~
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'gb'), ('xkb', 'gr')]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Alt>Shift_L']"
~~~

## Make middle click minimize

~~~
gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'minimize'
~~~

## Configure Hibernation

Taken from [my guide](https://github.com/spxak1/weywot/blob/main/guides/Fedora39_Hibernate.md)

### Create a swap file

All commands as root:

~~~
sudo su
btrfs subvolume create /swap
~~~

**Create the file**
~~~
touch /swap/swapfile
# Disable Copy On Write on the file
fallocate --length 16G /swap/swapfile
chmod 600 /swap/swapfile 
mkswap /swap/swapfile
~~~

For use with zswap (see later), you need to add it to your ```/etc/fstab```.

~~~
/swap/swapfile swap swap defaults 0 0
~~~


**Update initramfs to support resume**
~~~
cat <<-EOF | sudo tee /etc/dracut.conf.d/resume.conf
add_dracutmodules+=" resume "
EOF
~~~
~~~
dracut -f
~~~

## Add the kernel options

We need to find these two:
~~~
resume=UUID=
resume_offset=
~~~

The first is easy:
~~~
findmnt -no UUID -T /swap/swapfile
648bd14e-b0c0-46ee-b19a-57a9ba8f7082
~~~
That's it. Your's will be different.

The second is more difficult.

Download (open link then download) [this file](https://github.com/osandov/osandov-linux/blob/main/scripts/btrfs_map_physical.c)

Compile it and run:
~~~
gcc -O2 -o btrfs_map_physical btrfs_map_physical.c
./btrfs_map_physical /swap/swapfile
~~~

Find the first raw with numbers, starting with 0 4096 and get the last number. 
Mine is 10016854016

Find the *pagesize* with ```getconf PAGESIZE```, commonly 4096, then calculate the block: **10016854016/4096=9782084**

Now complete the values for the kernel option. I use ```systemd-boot``` so I need to edit ```/etc/kernel/cmdline```.

~~~
rootflags=subvol=@
resume=UUID=648bd14e-b0c0-46ee-b19a-57a9ba8f7082 resume_offset=9782084
~~~

Also add this to the current boot entry file in ```/boot/efi/loader/entries/36855f3b063c43858884b9fedfa2c342-6.8.8-300.fc40.x86_64.conf```.

At the end of the ```options``` line, add:

~~~
resume=UUID=648bd14e-b0c0-46ee-b19a-57a9ba8f7082 resume_offset=9782084
~~~


