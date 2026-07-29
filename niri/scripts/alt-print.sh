#!/bin/bash
tmpfile=$(mktemp /tmp/niri-screenshot-XXXXXX.png)
niri msg action screenshot-window --path "$tmpfile" --show-pointer false
while [ ! -s "$tmpfile" ]; do sleep 0.05; done
satty --filename "$tmpfile"
rm -f "$tmpfile"
