#!/usr/bin/env bash
set -uo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/superwhisper_mpris_was_playing"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/superwhisper-dictate.lock"
DICT_SRC_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dictation_source"

# Handle Paste Last immediately without taking the dictation lock
if [ "${1:-}" = "paste-last" ]; then
    LAST_TEXT=$(superwhisper history list --limit 1 2>/dev/null | jq -r '.items[0].metadata.result // empty' 2>/dev/null || true)
    if [ -n "$LAST_TEXT" ]; then
        wl-copy "$LAST_TEXT"
        wtype -M ctrl v -m ctrl
    fi
    exit 0
fi

# Prevent overlapping rapid invocations from racing on STATE_FILE or BT profile
exec 9>"$LOCK_FILE"
if ! flock -w 3 9; then
    exit 0
fi

get_bt_card() {
    pactl list cards short 2>/dev/null | awk '/bluez_card/ {print $2; exit}'
}

get_bt_profile() {
    local card="$1"
    [ -n "$card" ] || return 0
    pactl -f json list cards 2>/dev/null \
        | jq -r --arg c "$card" '.[] | select(.name == $c) | .active_profile // empty' 2>/dev/null || true
}

set_bt_a2dp() {
    local card="$1"
    [ -n "$card" ] || return 0
    pactl set-card-profile "$card" a2dp-sink 2>/dev/null \
        || pactl set-card-profile "$card" a2dp-sink-sbc_xq 2>/dev/null \
        || pactl set-card-profile "$card" a2dp-sink-sbc 2>/dev/null \
        || true
}

set_bt_hfp() {
    local card="$1"
    [ -n "$card" ] || return 0
    pactl set-card-profile "$card" headset-head-unit-cvsd 2>/dev/null \
        || pactl set-card-profile "$card" headset-head-unit 2>/dev/null \
        || true
}

# Verify phone mic is ACTUALLY live (prevents split-brain if phone-rig-mic died/unplugged)
check_phone_mic_or_heal() {
    local dict_src
    dict_src=$(cat "$DICT_SRC_FILE" 2>/dev/null || echo "headphones")
    if [ "$dict_src" != "phone" ]; then
        return 1
    fi

    if systemctl --user is-active --quiet phone-rig-mic \
        && pactl list sources short 2>/dev/null | awk '{print $2}' | grep -qx "OverheadPhoneMic" \
        && [ "$(pactl get-default-source 2>/dev/null || true)" = "OverheadPhoneMic" ]; then
        return 0
    fi

    # Split-brain detected: phone mic configured but not running. Auto-heal to headphones/fallback!
    local fallback_mic
    fallback_mic=$(pactl list sources short 2>/dev/null | awk 'tolower($2) ~ /bluez_input/ {print $2; exit}')
    if [ -z "$fallback_mic" ]; then
        fallback_mic=$(pactl list sources short 2>/dev/null | awk '$2 ~ /^alsa_input\./ && $2 ~ /Mic1/ {print $2; exit}')
    fi
    if [ -n "$fallback_mic" ]; then
        pactl set-default-source "$fallback_mic" 2>/dev/null || true
        superwhisper audio select "$fallback_mic" >/dev/null 2>&1 || true
    fi
    echo "headphones" > "$DICT_SRC_FILE" 2>/dev/null || true
    return 1
}

list_mpris_players() {
    gdbus call --session \
        --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -oP "(?<=')org\.mpris\.MediaPlayer2\.[^']+" || true
}

pause_mpris() {
    rm -f "$STATE_FILE"
    local player status
    while IFS= read -r player; do
        [ -n "$player" ] || continue
        status=$(gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 \
            --method org.freedesktop.DBus.Properties.Get "org.mpris.MediaPlayer2.Player" "PlaybackStatus" 2>/dev/null || true)
        if [[ "$status" == *"Playing"* ]]; then
            printf '%s\n' "$player" >> "$STATE_FILE"
            gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 \
                --method org.mpris.MediaPlayer2.Player.Pause >/dev/null 2>&1 || true
        fi
    done < <(list_mpris_players)
}

resume_mpris() {
    local bt_card="$1"
    [ -f "$STATE_FILE" ] || return 0

    local now mtime
    now=$(date +%s)
    mtime=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
    if [ $(( now - mtime )) -gt 1800 ]; then
        rm -f "$STATE_FILE"
        return 0
    fi

    local players
    players=$(cat "$STATE_FILE")
    rm -f "$STATE_FILE"
    [ -n "$players" ] || return 0

    (
        set +e
        if [ -n "$bt_card" ]; then
            local i curr
            for i in $(seq 1 40); do
                curr=$(pactl -f json list cards 2>/dev/null \
                    | jq -r --arg c "$bt_card" '.[] | select(.name == $c) | .active_profile // empty' 2>/dev/null || true)
                if [[ "$curr" == a2dp* ]] && pactl list sinks short 2>/dev/null | grep -q 'bluez_output'; then
                    break
                fi
                if [ $(( i % 5 )) -eq 0 ]; then
                    pactl set-card-profile "$bt_card" a2dp-sink 2>/dev/null \
                        || pactl set-card-profile "$bt_card" a2dp-sink-sbc_xq 2>/dev/null \
                        || pactl set-card-profile "$bt_card" a2dp-sink-sbc 2>/dev/null || true
                fi
                sleep 0.05
            done

            local s
            for s in $(pactl list sinks short 2>/dev/null | awk '/bluez_output/ {print $2}'); do
                pactl suspend-sink "$s" 0 2>/dev/null || true
            done
            sleep 0.15
        fi

        local delay player status alive_names stable_count=0 all_playing
        for delay in 0 0.25 0.45 0.7 1.0; do
            [ "$delay" != "0" ] && sleep "$delay"
            alive_names=$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus \
                --method org.freedesktop.DBus.ListNames 2>/dev/null || true)
            all_playing=1
            while IFS= read -r player; do
                [ -n "$player" ] || continue
                [[ "$alive_names" == *"'$player'"* ]] || continue
                status=$(gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 \
                    --method org.freedesktop.DBus.Properties.Get "org.mpris.MediaPlayer2.Player" "PlaybackStatus" 2>/dev/null || true)
                if [[ "$status" != *"Playing"* ]]; then
                    gdbus call --session --dest "$player" --object-path /org/mpris/MediaPlayer2 \
                        --method org.mpris.MediaPlayer2.Player.Play >/dev/null 2>&1 || true
                    all_playing=0
                fi
            done <<< "$players"

            if [ "$all_playing" -eq 1 ]; then
                stable_count=$(( stable_count + 1 ))
                if [ "$stable_count" -ge 2 ]; then
                    break
                fi
            else
                stable_count=0
            fi
        done
    ) </dev/null >/dev/null 2>&1 &
    disown
}

BT_CARD=$(get_bt_card)
USING_PHONE_MIC=0
if check_phone_mic_or_heal; then
    USING_PHONE_MIC=1
fi

# Handle Cancel
if [ "${1:-}" = "cancel" ]; then
    superwhisper cancel >/dev/null 2>&1 || true
    hex dictation cancel >/dev/null 2>&1 || true
    sleep 0.2
    if [ "$USING_PHONE_MIC" -eq 0 ]; then
        set_bt_a2dp "$BT_CARD"
        resume_mpris "$BT_CARD"
    else
        rm -f "$STATE_FILE"
    fi
    exit 0
fi

PHASE=$(superwhisper status 2>/dev/null | jq -r '.phase // empty' 2>/dev/null || true)

if [ "$PHASE" = "recording" ]; then
    superwhisper stop >/dev/null 2>&1 || superwhisper record >/dev/null 2>&1 || true

    if [ "$USING_PHONE_MIC" -eq 0 ]; then
        sleep 0.2
        for _ in $(seq 1 25); do
            p=$(superwhisper status 2>/dev/null | jq -r '.phase // empty' 2>/dev/null || true)
            if [ "$p" != "recording" ]; then
                break
            fi
            sleep 0.05
        done
        sleep 0.1

        set_bt_a2dp "$BT_CARD"
        resume_mpris "$BT_CARD"
    fi
else
    if [ "$USING_PHONE_MIC" -eq 0 ]; then
        pause_mpris

        if [ -n "$BT_CARD" ]; then
            for s in $(pactl list sinks short 2>/dev/null | awk '/bluez_output/ {print $2}'); do
                pactl suspend-sink "$s" 1 2>/dev/null || true
            done
            sleep 0.05

            CURRENT_PROFILE=$(get_bt_profile "$BT_CARD")
            if [ "$CURRENT_PROFILE" != "headset-head-unit-cvsd" ] && [ "$CURRENT_PROFILE" != "headset-head-unit" ]; then
                set_bt_hfp "$BT_CARD"
                for _ in $(seq 1 30); do
                    CURR=$(get_bt_profile "$BT_CARD")
                    if { [ "$CURR" = "headset-head-unit-cvsd" ] || [ "$CURR" = "headset-head-unit" ]; } \
                        && pactl list sources short 2>/dev/null | grep -qi 'bluez_input'; then
                        break
                    fi
                    sleep 0.05
                done
                sleep 0.1
            fi
        fi
    fi

    superwhisper start >/dev/null 2>&1 || superwhisper record >/dev/null 2>&1 || true
fi
