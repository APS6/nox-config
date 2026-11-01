#!/usr/bin/env bash
set -e

if hex annotate status 2>/dev/null | grep -q "Capturing"; then
    hex annotate stop
else
    hex annotate start
fi
