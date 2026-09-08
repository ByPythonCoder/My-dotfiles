#!/usr/bin/env bash

# Klasör yoksa oluştur
mkdir -p ~/Videolar

FILENAME="$HOME/Videolar/recording_$(date +%Y%m%d_%H%M%S).mp4"

# Eğer çalışan bir wf-recorder varsa DURDUR
if pkill -INT wf-recorder; then
    notify-send -u low "Ekran Kaydı" "Kayıt durduruldu ve kaydedildi."
    exit 0
fi

# AMD GPU VAAPI ve Doğru Renk Parametreleri
ENC_ARGS="-c h264_vaapi -d /dev/dri/renderD128 -p nv12"

MODE="$1"

if [ "$MODE" = "full" ]; then
    notify-send -u low "Ekran Kaydı" "Tüm ekran kaydı başladı (Sessiz)..."
    wf-recorder $ENC_ARGS -f "$FILENAME"

elif [ "$MODE" = "fullaudio" ]; then
    notify-send -u low "Ekran Kaydı" "Tüm ekran kaydı başladı (Sesli)..."
    wf-recorder $ENC_ARGS --audio -f "$FILENAME"

elif [ "$MODE" = "area" ]; then
    notify-send -u low "Ekran Kaydı" "Lütfen alan seçin..."
    GEOM=$(slurp)
    if [ -n "$GEOM" ]; then
        notify-send -u low "Ekran Kaydı" "Alan kaydı başladı (Sessiz)..."
        wf-recorder $ENC_ARGS -g "$GEOM" -f "$FILENAME"
    fi

elif [ "$MODE" = "audio" ]; then
    notify-send -u low "Ekran Kaydı" "Lütfen alan seçin (Sesli)..."
    GEOM=$(slurp)
    if [ -n "$GEOM" ]; then
        notify-send -u low "Ekran Kaydı" "Alan kaydı başladı (Sesli)..."
        wf-recorder $ENC_ARGS -g "$GEOM" --audio -f "$FILENAME"
    fi
fi
