#! /bin/sh
# -------This files are used to achieve auto power switching in pop os-------
# /sys/class/power_supply/BAT0/status
# /sys/class/power_supply/BAT0/capacity
# ---------------------------------------------------------------------------
second=60
discharging="Discharging"
charging="Charging"
unknown="Unknown"
limitc=20 # Limit to go to max powersave when charging
limitd=50 # Limit to go to max powersave when dischargin
while true; do
    status=$(cat /sys/class/power_supply/BAT0/status) || exit
    if [ "$status" = "$charging" ]; then # if machine is on charging mode then, switch to performance or battery profile according to capacity
        capacity=$(cat /sys/class/power_supply/BAT0/capacity) || exit
        if [ "$capacity" -lt "$limitc" ]; then # if battery capacity is less than 20 but its charging then, switch to battery profile
            system76-power profile battery
        else # if battery capacity is more than 20 but its charging then, switch to performance profile
            system76-power profile performance
        fi
    fi
    if [ "$status" = "$discharging" ]; then # if machine is on discharging mode then, switch to battery profile
                capacity=$(cat /sys/class/power_supply/BAT0/capacity) || exit
        if [ "$capacity" -lt "$limitd" ]; then # if battery capacity is less than 20 but its charging then, switch to battery profile
            system76-power profile battery
        else # if battery capacity is more than 20 but its charging then, switch to performance profile
            system76-power profile balanced
        fi
     fi
    if [ "$status" = "$unknown" ]; then # if machine is on charging mode then, switch to performance or battery profile according to capacity
        capacity=$(cat /sys/class/power_supply/BAT0/capacity) || exit
        if [ "$capacity" -lt "$limitc" ]; then # if battery capacity is less than 20 but its charging then, switch to battery profile
            system76-power profile battery
        else # if battery capacity is more than 20 but its charging then, switch to performance profile
            system76-power profile performance
        fi
    fi
    sleep $second
done
