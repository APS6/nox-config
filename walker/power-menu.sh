#!/bin/bash
# Power menu using walker dmenu mode

options="Lock\nSuspend\nLogout\nReboot\nShutdown"
chosen=$(echo -e "$options" | walker --dmenu --minheight 1 --placeholder "Power Menu")

case "$chosen" in
    "Lock") gtklock -d ;;
    "Suspend") systemctl suspend ;;
    "Logout") niri msg action quit --skip-confirmation ;;
    "Reboot") systemctl reboot ;;
    "Shutdown") systemctl poweroff ;;
esac
