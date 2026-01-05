#!/bin/bash
profile=$(powerprofilesctl get)
case "$profile" in
    performance) echo "󰓅" ;;
    balanced) echo "󰾅" ;;
    power-saver) echo "󰾆" ;;
    *) echo "?" ;;
esac
