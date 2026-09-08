#!/bin/bash

# Aktif pencerenin PID'sini al
pid=$(hyprctl activewindow -j | jq -r '.pid')

if [ -z "$pid" ] || [ "$pid" = "null" ] || [ "$pid" = "0" ]; then
    exit 0
fi

# Aktif pencerenin process adını al
process=$(ps -p "$pid" -o comm=)

# ---------------------------------------------------------
# STEAM
# ---------------------------------------------------------
if [[ "$process" == "steam" || "$process" == "steamwebhelper" ]]; then

    # Ana Steam process'ini bul
    steam_pid=$(pgrep -o -x steam)

    if [ -n "$steam_pid" ]; then
        # Önce Steam'in child process'lerini öldür
        pkill -9 -P "$steam_pid" 2>/dev/null

        # Sonra ana Steam process'ini öldür
        kill -9 "$steam_pid" 2>/dev/null
    fi

    exit 0
fi

# ---------------------------------------------------------
# DİĞER UYGULAMALAR
# ---------------------------------------------------------

kill -9 "$pid" 2>/dev/null

