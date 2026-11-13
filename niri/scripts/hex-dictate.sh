#!/usr/bin/env bash
set -e

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hex_mpris_was_playing"

# Dictation input source: phone vs headphones
DICT_SRC=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/dictation_source" 2>/dev/null || echo "headphones")

# Query hex recording status
CAPTURE_STATE=$(hex status --json 2>/dev/null | jq -r '.capture.state // empty')

# Find connected bluetooth audio card if any
BT_CARD=$(pactl list cards short 2>/dev/null | grep 'bluez_card' | awk '{print $2}' | head -n 1)

resume_mpris() {
    # If using phone mic, music was never paused!
    if [ "$DICT_SRC" = "phone" ]; then
        rm -f "$STATE_FILE"
        return 0
    fi

    if [ -f "$STATE_FILE" ]; then
        PLAYERS=$(cat "$STATE_FILE")
        rm -f "$STATE_FILE"
        if [ -n "$PLAYERS" ]; then
            (
                # Wait for A2DP profile and sink to be ready
                if [ -n "$BT_CARD" ]; then
                    for _ in $(seq 1 30); do
                        CURR=$(pactl list cards 2>/dev/null | grep -A 25 "$BT_CARD" | grep "Active Profile" | awk '{print $NF}')
                        if echo "$CURR" | grep -q "a2dp"; then
                            break
                        fi
                        sleep 0.05
                    done
                    sleep 0.15
                    # Unsuspend A2DP sink if suspended
                    for s in $(pactl list sinks short 2>/dev/null | grep 'bluez_output' | awk '{print $2}'); do
                        pactl suspend-sink "$s" 0 2>/dev/null || true
                    done
                fi

                # Settle, then verify playback resumption
                for delay in 0.2 0.5 0.9; do
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
}

# Handle Cancel
if [ "$1" = "cancel" ]; then
    hex dictation cancel 2>/dev/null || true
    superwhisper cancel 2>/dev/null || true
    sleep 0.2
    if [ -n "$BT_CARD" ]; then
        pactl set-card-profile "$BT_CARD" a2dp-sink 2>/dev/null || true
    fi
    resume_mpris
    exit 0
fi

if [ "$CAPTURE_STATE" = "recording" ] || [ "$CAPTURE_STATE" = "recording dictation" ]; then
    # Stop dictation
    hex dictation toggle

    if [ "$DICT_SRC" != "phone" ]; then
        # Give Hex 0.4s to finish audio capture and close recording buffers
        sleep 0.4

        # Restore Bluetooth to high-quality A2DP stereo
        if [ -n "$BT_CARD" ]; then
            pactl set-card-profile "$BT_CARD" a2dp-sink 2>/dev/null || true
        fi

        # Resume players
        resume_mpris
    fi
else
    if [ "$DICT_SRC" != "phone" ]; then
        # Record and PAUSE which players are actively playing BEFORE starting dictation
        rm -f "$STATE_FILE"
        for player in $(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.ListNames 2>/dev/null | grep -oP "(?<=')org\.mpris\.MediaPlayer2\.[^']+"); do
            STATUS=$(gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 --method org.freedesktop.DBus.Properties.Get "org.mpris.MediaPlayer2.Player" "PlaybackStatus" 2>/dev/null || true)
            if echo "$STATUS" | grep -q "Playing"; then
                echo "$player" >> "$STATE_FILE"
                gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 --method org.mpris.MediaPlayer2.Player.Pause >/dev/null 2>&1 || true
            fi
        done

        # If Bluetooth headset is connected, cleanly transition to HFP
        if [ -n "$BT_CARD" ]; then
            # Suspend active A2DP sink to cleanly flush transport
            for s in $(pactl list sinks short 2>/dev/null | grep 'bluez_output' | awk '{print $2}'); do
                pactl suspend-sink "$s" 1 2>/dev/null || true
            done
            sleep 0.05

            CURRENT_PROFILE=$(pactl list cards 2>/dev/null | grep -A 25 "$BT_CARD" | grep "Active Profile" | awk '{print $NF}')
            if [ "$CURRENT_PROFILE" != "headset-head-unit-cvsd" ] && [ "$CURRENT_PROFILE" != "headset-head-unit" ]; then
                pactl set-card-profile "$BT_CARD" headset-head-unit-cvsd 2>/dev/null || pactl set-card-profile "$BT_CARD" headset-head-unit 2>/dev/null || true
                for _ in $(seq 1 30); do
                    CURR=$(pactl list cards 2>/dev/null | grep -A 25 "$BT_CARD" | grep "Active Profile" | awk '{print $NF}')
                    if [ "$CURR" = "headset-head-unit-cvsd" ] || [ "$CURR" = "headset-head-unit" ]; then
                        break
                    fi
                    sleep 0.05
                done
                sleep 0.1
            fi
        fi
    fi

    # Start dictation once the mic hardware is guaranteed alive
    hex dictation toggle
fi
