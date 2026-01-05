#!/bin/bash
# Power profile selector using walker dmenu

current=$(powerprofilesctl get)

options="󰓅  Performance
󰾅  Balanced
󰾆  Power Saver"

selected=$(echo -e "$options" | walker --dmenu --minheight 1 -p "Power Profile ($current)")

case "$selected" in
    *Performance*) powerprofilesctl set performance ;;
    *Balanced*) powerprofilesctl set balanced ;;
    *Power*) powerprofilesctl set power-saver ;;
esac
