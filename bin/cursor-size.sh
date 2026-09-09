#!/bin/bash

# Read the current size
CURRENT_SIZE=$(kreadconfig6 --file kcminputrc --group Mouse --key cursorSize)

# Toggle between 24 and 48, using --notify
if [ "$CURRENT_SIZE" != "48" ]; then
    kwriteconfig6 --notify --file kcminputrc --group Mouse --key cursorSize 48
else
    kwriteconfig6 --notify --file kcminputrc --group Mouse --key cursorSize 24
fi

# Send the specific global settings signal to refresh input peripherals
dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:5 int32:0
