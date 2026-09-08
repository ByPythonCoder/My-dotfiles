-- =============================================================================
-- LOOK AND FEEL (TEMA, ANIMASYONLAR VE DÜZENLER)
-- =============================================================================

hl.config({
    -- -------------------------------------------------------------------------
    -- Genel Tasarım Ayarları
    -- -------------------------------------------------------------------------
    general = {
        gaps_in     = 5,        -- Pencerelerin kendi arasındaki boşluk (İç)
        gaps_out    = 20,       -- Pencerelerin ekran kenarına olan boşluğu (Dış)
        border_size = 2,        -- Pencere kenarlık kalınlığı

        col = {
            -- Aktif pencerenin kenarlık renkleri (Gradyan geçişli, 45 derece açı)
            active_border   = { colors = {"rgba(e0e0e0ee)", "rgba(b0b0b0ee)"}, angle = 45 },
            -- Arka plandaki inaktif pencerelerin kenarlık rengi
            inactive_border = "rgba(444444aa)",
        },

        resize_on_border = false, -- Kenarlıklardan tutup sürükleyerek boyutlandırma
        allow_tearing    = false, -- Ekran yırtılması (Tearing) izni (Oyunlar için gerekebilir)
        layout           = "dwindle", -- Varsayılan pencere yerleşim düzeni
    },

    -- -------------------------------------------------------------------------
    -- Pencere Dekorasyonları (Golgeler, Bulanıklık, Yuvarlama)
    -- -------------------------------------------------------------------------
    decoration = {
        rounding       = 10,    -- Pencere köşelerinin yuvarlanma yumuşaklığı
        rounding_power = 2,     -- Köşe yumuşatma eğrisi kuvveti

        active_opacity   = 1.0, -- Odaklanılmış pencerenin opaklığı (%100)
        inactive_opacity = 1.0, -- Arka plandaki pencerenin opaklığı (%100)

        -- Gölgelendirme Ayarları
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        -- Arka Plan Bulanıklaştırma (Blur)
        blur = {
		enabled = true,
        size = 7,
        passes = 3,
        new_optimizations = true,
        ignore_opacity = true,
        },
    },

    -- -------------------------------------------------------------------------
    -- Animasyon Anahtarı
    -- -------------------------------------------------------------------------
    animations = {
        enabled = true,
    },

    -- -------------------------------------------------------------------------
    -- Pencere Düzen Modüllerinin Detayları (Layouts)
    -- -------------------------------------------------------------------------
    dwindle = {
        preserve_split = true, -- Pencereleri bölerken mevcut düzeni korur (Tavsiye edilen)
    },

    master = {
        new_status = "master",
    },

    scrolling = {
        fullscreen_on_one_column = true,
    },

    -- -------------------------------------------------------------------------
    -- Çeşitli Sistem Ayarları (Misc)
    -- -------------------------------------------------------------------------
    misc = {
        force_default_wallpaper = -1,    -- Anime maskot duvar kağıtlarını yönetir (0 veya 1 kapatır)
        disable_hyprland_logo   = false, -- Açılıştaki Hyprland logosunu/anime kızını kapatır
    },
})

-- -----------------------------------------------------------------------------
-- ANIMASYON EĞRİLERİ VE TANIMLAMALARI (ANIMATIONS)
-- -----------------------------------------------------------------------------
-- Bezier ve Spring (Yay) efektleri ile pencerelerin akıcılığını ayarlar.

-- Bezier Eğrileri (Hızlanma ve yavaşlama grafikleri)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Spring (Yay simülasyonu, pencereler yerine otururken hafifçe esner)
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- Animasyonların Tetikleneceği Alanlar ve Hızları
hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })


