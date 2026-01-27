#!/bin/bash

# Capture a screenshot of the focused window geometry using Niri and save it
focused_geometry=$(niri msg --json focused-window | jq -r '.geometry | "\(.x),\(.y) \(.width)x\(.height)"')
grim -g "$focused_geometry" - | satty --filename -