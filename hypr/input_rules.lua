-- =============================================================================
-- INPUT DEVICES (KLAVYE, FARE VE TOUCHPAD)
-- =============================================================================

hl.config({
    input = {
        kb_layout    = "tr",  -- Türkçe Klavye Düzeni
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",

        follow_mouse = 1,     -- Fare hangi penceredeyse odağı otomatik ona verir
        sensitivity  = 0,     -- Hassasiyet: -1.0 ile 1.0 arası (0 = Değişiklik yok)

        touchpad = {
            natural_scroll = false, -- Doğal kaydırma (Aşağı kaydırınca sayfanın yukarı gitmesi)
        },
    },
})

-- -----------------------------------------------------------------------------
-- TOUCHPAD PARMAK HAREKETLERI (GESTURES)
-- -----------------------------------------------------------------------------
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace"   -- 3 parmakla sağa sola çekerek çalışma alanları arası geçiş
})

-- -----------------------------------------------------------------------------
-- ÖZEL CİHAZ AYARLARI (PER-DEVICE)
-- -----------------------------------------------------------------------------
-- Belirli bir fare veya klavye için özel hassasiyet tanımlama.
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
