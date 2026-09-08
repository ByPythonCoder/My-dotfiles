-- =============================================================================
-- WINDOW AND LAYER RULES (PENCERE VE KATMAN KURALLARI)
-- =============================================================================
-- Belirli uygulamaların nasıl davranacağını, nerede açılacağını belirler.

-- -----------------------------------------------------------------------------
-- PENCERE KURALLARI (WINDOW RULES)
-- -----------------------------------------------------------------------------

-- Uygulamaların tam ekran (maximize) olma isteklerini engeller.
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" }, -- Tüm uygulamaları kapsar
    suppress_event = "maximize",
})

-- XWayland kullanan eski uygulamalardaki sürükleme/bırakma sorunlarını çözer.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- `hyprland-run` pencerelerini otomatik olarak ekranın altına taşır ve yüzen moda alır.
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})


hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- -----------------------------------------------------------------------------
-- LAYER RULES (KATMAN KURALLARI)
-- -----------------------------------------------------------------------------
-- QuickShell layer surfaces'larına blur uygulanmıyor

-- -----------------------------------------------------------------------------
-- "AKILLI BOŞLUKLAR" (SMART GAPS) - OPSİYONEL
-- -----------------------------------------------------------------------------
-- Eğer ekranda sadece TEK BİR PENCERE varsa kenar boşluklarını sıfırlamak istersen 
-- aşağıdaki satırların başındaki yorum satırlarını (`--`) kaldırabilirsin.

-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
