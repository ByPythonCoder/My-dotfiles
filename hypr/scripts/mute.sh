#!/usr/bin/env bash

# Aktif pencerenin PID'sini al
MAIN_PID=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid')

if [ -z "$MAIN_PID" ] || [ "$MAIN_PID" = "null" ] || [ "$MAIN_PID" = "0" ]; then
    exit 1
fi

# Aktif pencerenin PID'sine ait PipeWire sink-input'larını bul
MATCHED_IDS=$(
    pactl list sink-inputs |
    awk -v pid="$MAIN_PID" '
        /^Sink Input #[0-9]+/ {
            if (current_id != "" && current_pid == pid)
                print current_id

            current_id = $3
            sub(/^#/, "", current_id)
            current_pid = ""
        }

        /application\.process\.id =/ {
            current_pid = $0
            sub(/.*application\.process\.id = "/, "", current_pid)
            sub(/".*/, "", current_pid)
        }

        END {
            if (current_id != "" && current_pid == pid)
                print current_id
        }
    '
)

# Bulunan ses akışlarını mute/unmute et
if [ -n "$MATCHED_IDS" ]; then
    while read -r input_id; do
        [ -n "$input_id" ] || continue
        pactl set-sink-input-mute "$input_id" toggle
    done <<< "$MATCHED_IDS"
fi
