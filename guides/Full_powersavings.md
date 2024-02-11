# Maximum Power savings.

## Using scripts for laptops
This is just a dump of the scripts:

```/usr/local/bin/on_battery.sh```

~~~
#!/usr/bin/bash

#Tune all tunables from: https://wiki.archlinux.org/title/Lenovo_ThinkPad_P14s_(AMD)_Gen_4
#Additional udev rules in: /etc/udev/rules.d/99-battery.rules

#SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/local/bin/on_battery.sh"
#SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/local/bin/on_ac.sh"

# Change Dirty Writeback Centisecs according to TLP / Powertop
echo "5000" | tee "/proc/sys/vm/dirty_writeback_centisecs";

# Change AMD Paste EPP energy preference
# Available profiles: performance, balance_performance, balance_power, power
#echo 'balance_power' | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference;
#For Intel set to lowest power and disable boost:
x86_energy_perf_policy --hwp-epp power -t 0;
#Legacy:
#sudo x86_energy_perf_policy power
#
echo "0" | tee "/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost";


#Reduce backlight
echo "800" | tee /sys/class/backlight/intel_backlight/brightness


# Change PCIe ASPM powersaving policy
# Available: default performance powersave [powersupersave]
echo "powersupersave" | tee "/sys/module/pcie_aspm/parameters/policy";

# If required, change cpu scaling governor
# Possible options are: conservative ondemand userspace powersave performance schedutil
cpupower frequency-set -g powersave;

# Platform Profiles Daemon will do this automatically, based on your settings in KDE / GNOME
# You can how ever, set this manually as well
# Possible profile options are: performance, powersave, low-power
echo "low-power" | tee "/sys/firmware/acpi/platform_profile";

# Radeon AMDGPU DPM switching does not seem to be supported.
# Possible options should be: battery, balanced, performance, auto
#echo 'battery' > '/sys/class/drm/card0/device/power_dpm_state'; 

# Should always be auto (TLP default = auto)
# Possible options are: auto, high, low
#For AMD
#echo 'auto' > '/sys/class/drm/card0/device/power_dpm_force_performance_level';
#For Intel options are: on (no powersaving), auto (powersaving)
echo "auto" | tee "/sys/class/drm/card1/device/power/control";


# Runtime PM for PCI Device to auto
find /sys/bus/pci/devices/*/power -name control -exec sh -c 'echo "auto" > "$1"' _ {} \;
for i in $(find /sys/devices/pci0000\:00/0* -maxdepth 3 -name control); do
    echo auto > $i;
done

systemctl stop tp-auto-kbbl.service
~~~

And:

```/usr/local/bin/on_ac.sh```

~~~
#!/usr/bin/bash
# Change Dirty Writeback Centisecs according to TLP / Powertop
echo "500" | tee "/proc/sys/vm/dirty_writeback_centisecs";

# Change AMD Paste EPP energy preference
# Available profiles: performance, balance_performance, balance_power, power
#echo 'balance_power' | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference;
#For Intel set to lowest power and disable boost:
x86_energy_perf_policy --hwp-epp performance -t 1;
#Legacy:
#sudo x86_energy_perf_policy power
#
echo "1" | tee "/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost";

# Change PCIe ASPM powersaving policy
# Available: default performance powersave [powersupersave]
echo "performance" | tee "/sys/module/pcie_aspm/parameters/policy";

# If required, change cpu scaling governor
# Possible options are: conservative ondemand userspace powersave performance schedutil
cpupower frequency-set -g performance;

# Platform Profiles Daemon will do this automatically, based on your settings in KDE / GNOME
# You can how ever, set this manually as well
# Possible profile options are: performance, powersave, low-power
echo "performance" | tee "/sys/firmware/acpi/platform_profile";

# Radeon AMDGPU DPM switching does not seem to be supported.
# Possible options should be: battery, balanced, performance, auto
#echo 'battery' > '/sys/class/drm/card0/device/power_dpm_state'; 

# Should always be auto (TLP default = auto)
# Possible options are: auto, high, low
#For AMD
#echo 'auto' > '/sys/class/drm/card0/device/power_dpm_force_performance_level';
#For Intel options are: on (no powersaving), auto (powersaving)
echo "on" | tee "/sys/class/drm/card1/device/power/control";


# Runtime PM for PCI Device to auto
find /sys/bus/pci/devices/*/power -name control -exec sh -c 'echo "on" > "$1"' _ {} \;
for i in $(find /sys/devices/pci0000\:00/0* -maxdepth 3 -name control); do
    echo on > $i;
done

systemctl start tp-auto-kbbl.service
~~~

Additional udev rules in: ```/etc/udev/rules.d/99-battery.rules```
~~~
#SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/local/bin/on_battery.sh"
#SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/local/bin/on_ac.sh"
~~~

## Using TuneD for servers

Here's my custom ```tunded.conf``` fore ```ceres```:
~~~
#
# tuned configuration
#

[main]
summary=Low power consumption on Ceres

[cpu]
#https://github.com/redhat-performance/tuned/blob/master/tuned/plugins/plugin_cpu.py
governor=ondemand|powersave
energy_perf_bias=powersave|power
energy_performance_preference=power
#force_latency=cstate.name:C6|cstate.id:4|10
#min_perf_pct=100
#no_turbo=1
#pm_qos_resume_latency_us=100

[acpi]
platform_profile=low-power|quiet

[eeepc_she]

[vm]

[audio]
timeout=10

[video]
radeon_powersave=dpm-battery, auto

[disk]
https://github.com/redhat-performance/tuned/blob/master/tuned/plugins/plugin_disk.py
# Comma separated list of devices, all devices if commented out.
# devices=sda
#Mine
#apm=128
#spindown=6


[net]
https://github.com/redhat-performance/tuned/blob/master/tuned/plugins/plugin_net.py
# Comma separated list of devices, all devices if commented out.
# devices=eth0
# dynamic=0

[scsi_host]
alpm=min_power

[sysctl]
vm.laptop_mode=5
vm.dirty_writeback_centisecs=1500
kernel.nmi_watchdog=0

[script]
script=${i:PROFILE_DIR}/script.sh

[sysfs]
/sys/module/pcie_aspm/parameters/policy = powersupersave
/sys/bus/pci/devices/0000:*/power/control = auto


[usb]
https://github.com/redhat-performance/tuned/blob/master/tuned/plugins/plugin_usb.py
#devices=1-3,1-4
#autosuspend=0
~~~

Info on tuned:

https://gist.github.com/v-fox/b7adbc2414da46e2c49e571929057429
https://github.com/redhat-performance/tuned/blob/master/profiles/realtime/tuned.conf
https://github.com/redhat-performance/tuned/blob/master/profiles/throughput-performance/tuned.conf


## HD-Idle (for ceres)

You can install the package ```hd-idle```. Its config is in ```/etc/sysconfig/hd-idle

It spins down disks after some time. Default is 600s.

See here poing 3.5 here for some info: https://wiki.archlinux.org/title/Hdparm
