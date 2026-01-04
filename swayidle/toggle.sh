#!/bin/bash
# Toggle swayidle on/off

if pgrep -x swayidle > /dev/null; then
    pkill swayidle
    notify-send -t 2000 "Auto-lock disabled" -i lock-screen-unlocked
else
    swayidle -w &
    notify-send -t 2000 "Auto-lock enabled" -i lock-screen
fi
