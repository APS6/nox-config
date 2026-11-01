#!/usr/bin/env bash
set -e

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hex_mpris_was_playing"

# Query hex recording status
CAPTURE_STATE=$(hex status --json 2>/dev/null | jq -r '.capture.state // empty')

# Find connected bluetooth audio card if any
BT_CARD=$(pactl list cards short 2>/dev/null | grep 'bluez_card' | awk '{print $2}' | head -n 1)

# Handle Cancel
if [ "$1" = "cancel" ]; then
    hex dictation cancel 2>/dev/null || true
    if [ -n "$BT_CARD" ]; then
        pactl set-card-profile "$BT_CARD" a2dp-sink 2>/dev/null || true
    fi
    if [ -f "$STATE_FILE" ]; then
        PLAYERS=$(cat "$STATE_FILE")
        rm -f "$STATE_FILE"
        if [ -n "$PLAYERS" ]; then
            (
                for delay in 0.5 0.7; do
                    sleep "$delay"
                    ALL_RESUMED=true
                    for player in $PLAYERS; do
                        STATUS=$(gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 --method org.freedesktop.DBus.Properties.Get "org.mpris.MediaPlayer2.Player" "PlaybackStatus" 2>/dev/null || true)
                        if ! echo "$STATUS" | grep -q "Playing"; then
                            gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 --method org.mpris.MediaPlayer2.Player.Play >/dev/null 2>&1 || true
                            ALL_RESUMED=false
                        fi
                    done
                    if [ "$ALL_RESUMED" = "true" ]; then
                        break
                    fi
                done
            ) & disown
        fi
    fi
    exit 0
fi

if [ "$CAPTURE_STATE" = "recording" ] || [ "$CAPTURE_STATE" = "recording dictation" ]; then
    # Stop dictation
    hex dictation toggle

    # Restore Bluetooth to high-quality A2DP stereo immediately
    if [ -n "$BT_CARD" ]; then
        pactl set-card-profile "$BT_CARD" a2dp-sink 2>/dev/null || true
    fi

    # Resume ONLY players that were playing when dictation started
    if [ -f "$STATE_FILE" ]; then
        PLAYERS=$(cat "$STATE_FILE")
        rm -f "$STATE_FILE"
        if [ -n "$PLAYERS" ]; then
            (
                # Give A2DP sink time to settle, with retry verification
                for delay in 0.5 0.7; do
                    sleep "$delay"
                    ALL_RESUMED=true
                    for player in $PLAYERS; do
                        STATUS=$(gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 --method org.freedesktop.DBus.Properties.Get "org.mpris.MediaPlayer2.Player" "PlaybackStatus" 2>/dev/null || true)
                        if ! echo "$STATUS" | grep -q "Playing"; then
                            gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 --method org.mpris.MediaPlayer2.Player.Play >/dev/null 2>&1 || true
                            ALL_RESUMED=false
                        fi
                    done
                    if [ "$ALL_RESUMED" = "true" ]; then
                        break
                    fi
                done
            ) & disown
        fi
    fi
else
    # Record which players are actively playing BEFORE starting dictation
    rm -f "$STATE_FILE"
    for player in $(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.ListNames 2>/dev/null | grep -oP "(?<=')org\.mpris\.MediaPlayer2\.[^']+"); do
        STATUS=$(gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 --method org.freedesktop.DBus.Properties.Get "org.mpris.MediaPlayer2.Player" "PlaybackStatus" 2>/dev/null || true)
        if echo "$STATUS" | grep -q "Playing"; then
            echo "$player" >> "$STATE_FILE"
        fi
    done

    # Switch Bluetooth to headset profile and wait until the mic node is ready
    if [ -n "$BT_CARD" ]; then
        pactl set-card-profile "$BT_CARD" headset-head-unit-cvsd 2>/dev/null || true
        for i in $(seq 1 8); do
            if pactl list sources short 2>/dev/null | grep -q "bluez_input"; then
                break
            fi
            sleep 0.05
        done
        sleep 0.05
    fi

    # Start dictation once the mic hardware is guaranteed alive
    hex dictation toggle
fi
