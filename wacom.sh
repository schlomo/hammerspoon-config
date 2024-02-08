#!/usr/bin/env bash

# load and unload everyting Wacom
#
# the Wacom drivers exhibit high CPU usage and battery drain when no Wacom device
# is connected, I needed a quick way to shut them down completely when I'm on the road

wacom_procs=($(pgrep -if wacom))
wacom_proc_count=${#wacom_procs[*]}

launchctl_domain="gui/$(id -u)"
wacom_launchctl_services=($(
    launchctl print $launchctl_domain | grep -i '".*wacom.*"' | cut -d \" -f 2
))

if ((wacom_proc_count > 0)) && [[ "$1" != "start" ]]; then
    echo "$wacom_proc_count Wacom procs running"

    for service in "${wacom_launchctl_services[@]}"; do
        service=$launchctl_domain/$service
        echo "disable and stop $service"
        launchctl disable $service
        launchctl kill TERM $service
    done
else
    echo "No Wacom procs running or start given"

    for service in ${wacom_launchctl_services[@]}; do
        service=$launchctl_domain/$service
        echo "enable $service"
        launchctl enable $service
    done
fi
