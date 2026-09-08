-- =============================================================================
-- KEYBINDINGS (KLAVYE VE FARE KISAYOLLARI)
-- =============================================================================

-- Ana Değiştirici Tuş: "SUPER" (Windows / Amblem Tuşu)
local mainMod = "SUPER" 

-- -----------------------------------------------------------------------------
-- TEMEL UYGULAMA VE SİSTEM KISAYOLLARI
-- -----------------------------------------------------------------------------
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(_G.terminal))      -- Terminali Aç (Kitty)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))-- Uygulama Menüsünü Aç

hl.bind(mainMod .. " + C", hl.dsp.window.close())           -- Aktif Pencereyi Kapat
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("~/.config/hypr/scripts/force_close.sh"))


hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" })) -- Pencereyi Yüzen (Float) Moda Al
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())          -- Pseudo Layout Modu
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- Yatay/Dikey Bölünme Değiştir (Dwindle)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("killall quickshell || quickshell")) --Quickshell

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd([[sh -c "killall mpvpaper; mpvpaper DP-1 -o 'loop no-audio hwdec=auto-safe vo=gpu demuxer-max-bytes=10M framedrop=vo' /home/qwerty/Videolar/Wallpaper/SelectedWallpaper/wallpaper.mp4"]]))


hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("/home/qwerty/.config/hypr/scripts/mute.sh"), { locked = true })

-- 2. EKRAN GÖRÜNTÜSÜ (SS) KISAYOLLARI
-- PRINT tuşuna basınca: Bölge seç, SS al ve ~/Pictures/ altında tarihli olarak KAYDET
hl.bind("PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/$(date +'%Y-%m-%d-%H%M%S_grim.png')"))

-- SHIFT + PRINT tuşuna basınca: Bölge seç, SS al ama KAYDETMEDEN doğrudan PANEYE KOPYALA
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

-- 3 EKRAN KAYDI
hl.bind("Pause", hl.dsp.exec_cmd("/home/qwerty/.config/hypr/rec_toggle.sh full"))
hl.bind("ALT + Pause", hl.dsp.exec_cmd("/home/qwerty/.config/hypr/rec_toggle.sh fullaudio"))
hl.bind("SHIFT + Pause", hl.dsp.exec_cmd("/home/qwerty/.config/hypr/rec_toggle.sh area"))
hl.bind("SHIFT + ALT + Pause", hl.dsp.exec_cmd("/home/qwerty/.config/hypr/rec_toggle.sh audio"))

-- Güvenli Çıkış Kısayolu
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + CONTROL + M", hl.dsp.exec_cmd("systemctl poweroff"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("systemctl reboot"))
hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd("systemctl sleep"))

-- -----------------------------------------------------------------------------
-- PENCERE ODAK YÖNETİMİ (Yön Tuşları İle)
-- -----------------------------------------------------------------------------
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- -----------------------------------------------------------------------------
-- ÇALIŞMA ALANLARI (WORKSPACES) & DÖNGÜ (LOOP)
-- -----------------------------------------------------------------------------
-- Lua gücü: Tek tek 10 satır yazmak yerine döngü kullanarak 1-10 arası bindingleri oluşturuyoruz.
for i = 1, 10 do
    local key = i % 10 -- 10. alan '0' tuşuna atanır.
    
    -- SUPER + [1-0]: İlgili çalışma alanına geçiş yapar
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    -- SUPER + SHIFT + [1-0]: Aktif pencereyi ilgili çalışma alanına gönderir
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- -----------------------------------------------------------------------------
-- ÖZEL ÇALIŞMA ALANI (SCRATCHPAD)
-- -----------------------------------------------------------------------------
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))       -- Gizli alanı aç/kapat
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" })) -- Pencereyi gizli alana at

-- Fare Tekerleği İle Çalışma Alanlarında Gezinme (SUPER + Scroll)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- -----------------------------------------------------------------------------
-- FARE İLE PENCERE TAŞIMA / BOYUTLANDIRMA
-- -----------------------------------------------------------------------------
-- SUPER + Sol Tık sürükleme -> Taşıma | SUPER + Sağ Tık sürükleme -> Boyutlandırma
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- -----------------------------------------------------------------------------
-- MULTİMEDYA VE FONKSİYON TUŞLARI (Ses, Parlaklık vb.)
-- -----------------------------------------------------------------------------
-- `locked = true`: Ekran kilitliyken de çalışır. `repeating = true`: Basılı tutulduğunda tekrarlar.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Medya Oynatıcı Kontrolleri (playerctl gerekir)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

