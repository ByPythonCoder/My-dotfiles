import QtQuick

QtObject {
    id: root

    // -- Catppuccin Mocha Colors --

    readonly property color rosewater:   "#f5e0dc"
    readonly property color flamingo:    "#f2cdcd"
    readonly property color pink:        "#f5c2e7"
    readonly property color mauve:       "#cba6f7"
    readonly property color red:         "#f38ba8"
    readonly property color maroon:      "#eba0ac"
    readonly property color peach:       "#fab387"
    readonly property color yellow:      "#f9e2af"
    readonly property color green:       "#a6e3a1"
    readonly property color teal:        "#94e2d5"
    readonly property color sky:         "#89dceb"
    readonly property color sapphire:    "#74c7ec"
    readonly property color blue:        "#89b4fa"
    readonly property color lavender:    "#b4befe"

    readonly property color text:        "#cdd6f4"
    readonly property color subtext1:    "#bac2de"
    readonly property color subtext0:    "#a6adc8"
    readonly property color overlay2:    "#9399b2"
    readonly property color overlay1:    "#7f849c"
    readonly property color overlay0:    "#6c7086"
    readonly property color surface2:    "#585b70"
    readonly property color surface1:    "#45475a"
    readonly property color surface0:    "#313244"
    readonly property color base:        "#1e1e2e"
    readonly property color mantle:      "#181825"
    readonly property color crust:       "#11111b"

    // -- Mapped Colors --

    readonly property color archBlue:     mauve
    readonly property color archCyan:     sapphire
    readonly property color archDim:      blue
    readonly property color accentActive: teal

    readonly property color bgBar:        crust
    readonly property color bgSurface:    surface0
    readonly property color bgHover:      surface1
    readonly property color bgActive:     surface2
    readonly property color bgOverlay:    overlay0

    readonly property color textPrimary:  text
    readonly property color textMuted:    overlay1
    readonly property color textDim:      overlay0
    readonly property color textAccent:   sapphire

    readonly property color border:       Qt.rgba(0.68, 0.64, 0.86, 0.18)
    readonly property color borderHover:  Qt.rgba(0.68, 0.64, 0.86, 0.45)
    readonly property color borderActive: mauve

    readonly property color glowLine:     Qt.rgba(0.68, 0.64, 0.86, 0.25)
    readonly property color shimmerL:     mauve
    readonly property color shimmerR:     sapphire

    readonly property color warning:      yellow
    readonly property color danger:       red
    readonly property color success:      green

    // -- Layout --

    readonly property int barHeight:      44
    readonly property int barPadding:     12
    readonly property int barMargin:      0
    readonly property int barRadius:      0

    readonly property int gap:            6
    readonly property int gapSm:          3
    readonly property int gapLg:          10
    readonly property int pillPaddingH:   10
    readonly property int pillPaddingV:   4
    readonly property int pillRadius:     20
    readonly property int widgetRadius:   8
    readonly property int sepWidth:       1
    readonly property int sepHeight:      16

    readonly property color panelBg:       Qt.rgba(0.12, 0.12, 0.18, 0.90)
    readonly property color panelBorder:   Qt.rgba(1, 1, 1, 0.06)
    readonly property color divider:       Qt.rgba(1, 1, 1, 0.05)
    readonly property color accentBg:      Qt.rgba(0.68, 0.64, 0.86, 0.20)

    readonly property int radiusPanel:     18
    readonly property int radiusPill:      12

    readonly property color popupUtilityBg:       Qt.rgba(0.12, 0.12, 0.18, 0.85)
    readonly property color popupUtilityBorder:   Qt.rgba(1, 1, 1, 0.08)
    readonly property int radiusPopupUtility:     14

    readonly property int wsWidth:        28
    readonly property int wsHeight:       24
    readonly property int wsRadius:       6

    readonly property int miniBarWidth:   30
    readonly property int miniBarHeight:  4
    readonly property int miniBarRadius:  2

    readonly property int batWidth:       18
    readonly property int batHeight:      11
    readonly property int batRadius:      2
    readonly property int batTipWidth:    3
    readonly property int batTipHeight:   5

    // -- Typography --

    readonly property string fontFamily:  "monospace"
    readonly property int    fontSm:      10
    readonly property int    fontBase:    11
    readonly property int    fontMd:      12
    readonly property int    fontLg:      14
    readonly property int    weightNormal: Font.Normal
    readonly property int    weightMed:   Font.Medium

    // -- Animation --

    readonly property int animDuration:   320
    readonly property int animFast:       150
    readonly property int animMed:        250
    readonly property int animNormal:     200
    readonly property int animPress:       80
    readonly property int animSlow:       600

    // -- Poll intervals (ms) --

    readonly property int clockInterval:  1000
    readonly property int statsInterval:  2000
    readonly property int battInterval:   5000
    readonly property int brightInterval: 500
    readonly property int netInterval:    5000

    // -- Hardware --

    readonly property string backlightDevice: "intel_backlight"
    readonly property int brightStep:     5

    readonly property int batWarnLevel:   20
    readonly property int batCritLevel:   5

    // -- Media --

    readonly property int mediaTitleMax:  18
    readonly property int mediaMarqueeMs: 4000

    // -- Units --

    readonly property string ramUnit:    "GB"

    // -- Helpers --

    function batteryColor(level) {
        if (level <= batCritLevel)  return danger
        if (level <= batWarnLevel)  return warning
        return sapphire
    }

    function cpuColor(percent) {
        if (percent >= 90) return danger
        if (percent >= 70) return warning
        return sapphire
    }

    function clamp(val, lo, hi) {
        return Math.max(lo, Math.min(hi, val))
    }

    function formatRam(bytes) {
        var gb = bytes / (1024 * 1024 * 1024)
        if (gb >= 1.0) return gb.toFixed(1) + "G"
        var mb = bytes / (1024 * 1024)
        return Math.round(mb) + "M"
    }
}
