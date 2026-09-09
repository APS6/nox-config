#!/bin/bash

pgrep -f "alacritty --class Screensaver" && exit 0

focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
  hyprctl dispatch focusmonitor $m
  hyprctl dispatch exec -- \
    alacritty --class Screensaver \
    --config-file ~/.local/share/omarchy/default/alacritty/screensaver.toml \
    -e ~/.local/bin/party-cmd
done

hyprctl dispatch focusmonitor $focused
