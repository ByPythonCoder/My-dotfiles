# My Dotfiles

Arch Linux + Hyprland (v0.56.2) + Quickshell (v0.3.1) için kişisel dotfiles deposu.

## İçerik

```
dotfiles/
├── hypr/                  # Hyprland konfigürasyonu (Lua)
│   ├── hyprland.lua       # Ana giriş — modülleri yükler
│   ├── monitors.lua       # Ekran çözünürlük / konum / scale
│   ├── env_vars.lua       # Wayland / Qt / XDG çevre değişkenleri
│   ├── programs.lua       # Varsayılan uygulamalar + autostart
│   ├── look_feel.lua      # Tema, dekorasyon, animasyonlar
│   ├── input_rules.lua    # Klavye / fare / touchpad / gesture
│   ├── binds.lua          # Tuş atamaları
│   ├── rules.lua          # Pencere & layer kuralları
│   ├── rec_toggle.sh      # Ekran kaydı toggle (wf-recorder)
│   └── scripts/
│       ├── force_close.sh # Aktif pencereyi SIGKILL ile kapat (Steam-aware)
│       └── mute.sh        # Aktif pencerenin PipeWire akışını mute/unmute
└── quickshell/            # Quickshell status bar (QML)
    ├── shell.qml          # Giriş noktası (symlink → shell-bar.qml / shell-pills.qml)
    ├── shell-bar.qml      # Klasik tam genişlik bar layout
    ├── shell-pills.qml    # Floating hap (pill) layout
    ├── Theme.qml          # Tasarım tokenları (renk, boyut, animasyon)
    ├── switch-layout.sh   # Layout değiştirici
    ├── .layout            # Aktif layout durumu (bar / pills)
    ├── bar/               # Bar widget'ları
    ├── osd/               # OSD popup'ları
    ├── popups/            # Diyalog & paneller
    ├── components/        # Yeniden kullanılabilir QML bileşenleri
    └── notification/      # Bildirim merkezi
```

`~/.config/hypr` ve `~/.config/quickshell` bu repoya symlink ile bağlıdır.

## Gereksinimler

| Paket | Amaç |
|-------|------|
| `hyprland` 0.56+ | Wayland compositor |
| `quickshell` 0.3+ | QML desktop shell |
| `kitty` | Varsayılan terminal (`programs.lua:6`) |
| `yazi` | Varsayılan dosya yöneticisi (opsiyonel) |
| `mpvpaper` | Video duvar kağıdı |
| `grim` + `slurp` + `wl-copy` | Ekran görüntüsü |
| `wf-recorder` | Ekran kaydı (VAAPI `h264_vaapi`) |
| `wpctl` (pipewire) + `wireplumber` | Ses kontrolü |
| `brightnessctl` | Parlaklık |
| `playerctl` | Medya tuşları |
| `NetworkManager` (`nmcli`) | WiFi |
| `jq` + `pactl` | `mute.sh` / `force_close.sh` |
| `catppuccin-mocha-light-cursors` | İmleç teması |

Arch'ta hızlı kurulum:

```bash
sudo pacman -S hyprland quickshell kitty thunar mpvpaper grim slurp wl-clipboard \
  wf-recorder pipewire wireplumber brightnessctl playerctl networkmanager jq
yay -S catppuccin-mocha-cursors  # veya hyprcursor paketi
```

## Kurulum / Kullanım

### 1. Klonla ve symlinkle

```bash
git clone https://github.com/ByPythonCoder/My-dotfiles.git ~/dotfiles

# Mevcut configleri yedekle
mv ~/.config/hypr ~/.config/hypr.bak 2>/dev/null
mv ~/.config/quickshell ~/.config/quickshell.bak 2>/dev/null

ln -s ~/dotfiles/hypr ~/.config/hypr
ln -s ~/dotfiles/quickshell ~/.config/quickshell
```

Alternatif: GNU Stow kullanıyorsan `stow hypr quickshell` de olur (repo kökü stow uyumlu değilse yukarıdaki symlink yöntemi tercih edilir).

### 2. Hyprland'i başlat

`hyprland.lua` otomatik olarak autostart yapar (`programs.lua:13`):

- `dbus-update-activation-environment` — systemd / Wayland entegrasyonu
- `quickshell &` — bar
- `mpvpaper DP-1 ... /home/qwerty/Videolar/Wallpaper/SelectedWallpaper/wallpaper.mp4` — video duvar kağıdı

> **Duvar kağıdı yolu sabittir.** Kendi videonu `~/Videolar/Wallpaper/SelectedWallpaper/wallpaper.mp4` yoluna koy veya `hypr/programs.lua:28` satırını düzenle.

### 3. Quickshell'i elle başlatma

```bash
quickshell -c ~/.config/quickshell/shell.qml
# veya config dizini vererek:
quickshell -c ~/.config/quickshell
```

Hyprland içinde zaten `exec-once` ile başlıyor; elle kill/restart için:

```bash
killall quickshell || quickshell -c ~/.config/quickshell &
```

## Hyprland Modülleri

| Dosya | Açıklama |
|-------|----------|
| `hyprland.lua:15-21` | Tüm modülleri sırayla `require` eder — ayar değiştirmek için ilgili dosyaya bak |
| `monitors.lua:6-11` | `DP-1` → `1920x1080@180`, `0x0`, scale `1` |
| `env_vars.lua` | `HYPRCURSOR_THEME/SIZE`, `GDK_BACKEND`, `QT_QPA_PLATFORM`, `SDL_VIDEODRIVER`, `XDG_*`, `QT_*` |
| `programs.lua` | `_G.terminal=kitty`, `_G.fileManager=thunar`, gsettings koyu tema, quickshell & mpvpaper autostart |
| `look_feel.lua:5-83` | `gaps_in=5`, `gaps_out=20`, `border_size=2`, `rounding=10`, blur, shadow, `dwindle` layout |
| `look_feel.lua:91-118` | Bezier + spring eğrileri, 17 animasyon tanımı |
| `input_rules.lua:6-20` | `kb_layout=tr`, `follow_mouse=1`, touchpad, 3-parmak yatay gesture → workspace |
| `binds.lua` | Tüm kısayollar (aşağıya bak) |
| `rules.lua` | `suppress-maximize`, XWayland drag fix, `hyprland-run` float |

## Tuş Atamaları (`hypr/binds.lua`)

`mainMod = SUPER` (Windows tuşu)

### Uygulama & Sistem

| Kısayol | Eylem |
|---------|-------|
| `SUPER + Q` | Terminal (`kitty`) |
| `SUPER + E` | Dosya yöneticisi (`thunar`) |
| `SUPER + R` | App Launcher (`quickshell ipc call launcher toggle`) |
| `SUPER + C` | Pencereyi kapat |
| `SUPER + SHIFT + C` | Force kill (`scripts/force_close.sh` — Steam için özel mantık) |
| `SUPER + V` | Float toggle |
| `SUPER + P` | Pseudo layout |
| `SUPER + J` | Dwindle split toggle |
| `SUPER + F` | Fullscreen toggle |
| `SUPER + B` | Quickshell restart (`killall quickshell \|\| quickshell`) |
| `SUPER + W` | Video duvar kağıdını yeniden başlat (mpvpaper) |
| `SUPER + N` | Aktif pencereyi mute/unmute (`scripts/mute.sh`) |

### Ekran Görüntüsü & Kayıt

| Kısayol | Eylem |
|---------|-------|
| `PRINT` | Alan seç → `~/Pictures/<tarih>_grim.png` olarak kaydet |
| `SHIFT + PRINT` | Alan seç → panoya kopyala (`wl-copy`) |
| `Pause` | Tüm ekran kaydı (sessiz) |
| `ALT + Pause` | Tüm ekran kaydı (sesli) |
| `SHIFT + Pause` | Alan kaydı (sessiz) |
| `SHIFT + ALT + Pause` | Alan kaydı (sesli) — tekrar basınca durur, `~/Videolar/recording_*.mp4` |

### Sistem Güç

| Kısayol | Eylem |
|---------|-------|
| `SUPER + M` | Hyprland'den çık (`hyprshutdown` varsa onu, yoksa `hyprctl dispatch exit`) |
| `SUPER + CTRL + M` | Kapat (`systemctl poweroff`) |
| `SUPER + SHIFT + M` | Yeniden başlat (`systemctl reboot`) |
| `SUPER + ALT + M` | Uyku (`systemctl sleep`) |

### Pencere & Workspace Navigasyonu

| Kısayol | Eylem |
|---------|-------|
| `SUPER + ←/→/↑/↓` | Odak yön değiştir |
| `SUPER + 1..0` | Workspace 1..10'a geç (0 = 10) |
| `SUPER + SHIFT + 1..0` | Pencereyi workspace 1..10'a taşı |
| `SUPER + S` | Scratchpad (`special:magic`) toggle |
| `SUPER + SHIFT + S` | Pencereyi scratchpad'e taşı |
| `SUPER + Scroll` | Workspace ileri/geri |
| `SUPER + Sol Sürükle` | Pencere taşı |
| `SUPER + Sağ Sürükle` | Pencere boyutlandır |

### Medya & Fonksiyon Tuşları

Ses (`wpctl`), parlaklık (`brightnessctl`), medya (`playerctl`) — ekran kilitliyken de çalışır (`locked=true`):

`XF86AudioRaiseVolume/LowerVolume/Mute/MicMute`, `XF86MonBrightnessUp/Down`, `XF86AudioNext/Prev/Play/Pause`

## Quickshell Bar

Detaylı dokümantasyon için `quickshell/README.md` dosyasına bak.

### İki Layout

| Layout | Dosya | Açıklama |
|--------|-------|----------|
| **Bar** | `shell-bar.qml` | Üstte tam genişlik tek şerit |
| **Pills** | `shell-pills.qml` | İki yüzen hap — sol (logo + workspaces + media), sağ (clock + stats + ses + batarya + ağ) |

Aktif layout `shell.qml` symlink'i ve `.layout` dosyasıyla takip edilir.

**Layout değiştir:**

```bash
~/.config/quickshell/switch-layout.sh
# veya Hyprland içinden: SUPER + B
```

Script quickshell'i öldürür, `.layout`'ı çevirir (`bar` ↔ `pills`), symlink'i günceller ve yeniden başlatır.

### Widget'lar (`bar/`)

`Workspaces`, `Clock`, `Media`, `SysStats`, `Volume`, `Brightness`, `Battery`, `Network`, `Power`, `PowerProfile`, `Tray`, `BarSep`

### Popup & OSD (`popups/` + `osd/`)

Network (WiFi scan/connect), WiFi Connect Dialog, Bluetooth, Media, Audio, Calendar, Power Menu, Workspace Overview, Volume/Brightness/Network/Battery/Media/Calendar OSD'leri — hepsi `components/PopupManager.qml` üzerinden yönetilir (`ESC` ile kapanır).

### Tema (`Theme.qml`)

Tüm renk/boyut/animasyon tokenları `Theme.qml` içinde merkezi. Catppuccin Mocha paleti, `archBlue=mauve`, `archCyan=sapphire`, `animDuration=320ms OutCubic`, `fontFamily=monospace`.

Özelleştirmek için `Theme.qml` içindeki `readonly property` değerlerini düzenle — örn. fontu değiştirmek için `Theme.qml:111`.

## Özelleştirme İpuçları

- **Monitör:** `hypr/monitors.lua:6-11` — kendi çıkış adını `hyprctl monitors` ile öğren, `mode`/`position`/`scale` güncelle.
- **Klavye:** `hypr/input_rules.lua:7` — `kb_layout` (örn. `us,tr`), `kb_variant`, `kb_options` (örn. `caps:escape`).
- **Görsel:** `hypr/look_feel.lua:9-23` — `gaps_in/out`, `border_size`, `rounding`, `active_border` renkleri.
- **Animasyon:** `hypr/look_feel.lua:91-118` — eğrileri / hızları değiştir veya `animations.enabled=false` ile kapat.
- **Varsayılan uygulamalar:** `hypr/programs.lua:6-7` — `_G.terminal` / `_G.fileManager`.
- **Duvar kağıdı:** `hypr/programs.lua:28` ve `hypr/binds.lua:26` içindeki `mpvpaper` yolunu kendi dosyanla değiştir.

## Scriptler

- `hypr/rec_toggle.sh [full|fullaudio|area|audio]` — `wf-recorder` ile VAAPI `h264_vaapi` kayıt, `~/Videolar/recording_*.mp4`. Çalışıyorsa `pkill -INT` ile durdurur.
- `hypr/scripts/force_close.sh` — `hyprctl activewindow -j | jq .pid` → `kill -9`; Steam ise child process'ler dahil öldürür.
- `hypr/scripts/mute.sh` — Aktif pencerenin `sink-input`'larını `pactl` ile toggle mute (`SUPER+N`).

## Sorun Giderme

- **Bar görünmüyor:** `quickshell -c ~/.config/quickshell` çıktısına bak; `Theme.qml` / QML import hatalarını kontrol et.
- **Video duvar kağıdı yok:** `mpvpaper` yüklü mü, video yolu doğru mu (`ls ~/Videolar/Wallpaper/SelectedWallpaper/`), `DP-1` yerine `hyprctl monitors` çıktısındaki ismi kullan.
- **Ses/parlaklık tuşları çalışmıyor:** `wpctl`, `brightnessctl`, `playerctl` yüklü mü, `groups` içinde `video`/`input` var mı kontrol et.
- **Ekran görüntüsü panoya yapışmıyor:** `wl-copy` (wl-clipboard) yüklü mü.
