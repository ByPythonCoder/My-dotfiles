-- =============================================================================
-- DEFAULT PROGRAMS & AUTOSTART
-- =============================================================================

-- Küresel Değişkenler
_G.terminal    = "kitty"
_G.fileManager = "thunar"

-- -----------------------------------------------------------------------------
-- SİSTEM VE BAŞLANGIÇ AYARLARI
-- -----------------------------------------------------------------------------

hl.on("hyprland.start", function () 
    -- 1. D-Bus ve Wayland Değişkenlerini Güncelle
    -- Bu komut, Wayland oturumunun systemd ile düzgün konuşmasını sağlar.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    
	hl.env("QT_QPA_PLATFORM", "wayland;xcb")
	hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
    
    -- 2. Quickshell Başlatma
    hl.exec_cmd("quickshell &")

    -- 3.Duvar Kağıdı
    hl.exec_cmd("mpvpaper DP-1 -o 'loop no-audio hwdec=auto-safe vo=gpu demuxer-max-bytes=10M framedrop=vo' /home/qwerty/Videolar/Wallpaper/SelectedWallpaper/wallpaper.mp4")

	-- 4.Cursor
	--hl.exex_cmd("hyprctl setcursor catppuccin-mocha-light-cursors 24")
    
end)
