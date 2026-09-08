-- =============================================================================
-- SCREEN & MONITOR CONFIGURATION
-- =============================================================================
-- Ekran çözünürlüklerini, yenileme hızlarını (Hz) ve konumlarını ayarlar.

hl.monitor({
    output   = "DP-1",          -- Ekran çıkış portu
    mode     = "1920x1080@180", -- Çözünürlük ve Yenileme Hızı (180Hz)
    position = "0x0",           -- Ekranın koordinat düzlemindeki yeri
    scale    = "1",             -- Ölçeklendirme oranı (1.0 = %100)
})
