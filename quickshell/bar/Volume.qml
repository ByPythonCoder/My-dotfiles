import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".."
import "../osd"
import "../popups"

Item {
    id: root
    Theme { id: theme }

    property var popupManager: null

    implicitWidth: pillBg.width
    implicitHeight: theme.barHeight

    property bool hovered: false
    property bool _sinkReady: false

    PwObjectTracker {
        id: sinkTracker
        objects: [ Pipewire.defaultAudioSink ]
    }

    readonly property var sink: Pipewire.defaultAudioSink

    onSinkChanged: {
        if (sink)
            Qt.callLater(function() { root._sinkReady = true })
    }

    readonly property real maxPct: 150.0

    property real volumeVisual: 0
    property int _lastSetPct: -1

    property int volumePct: (sink && sink.audio) ? backendVolumeToPct(sink.audio.volume) : 0
    property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    property string deviceName: sink ? sink.description : "Ses"

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function pctToGain(pct) {
        var p = clamp(pct, 0, 100)
        return p / 100.0
    }

    function pctToBackendVolume(pct) {
        var p = clamp(pct, 0, maxPct)
        if (p <= 100)
            return pctToGain(p)
        return 1.0 + ((p - 100.0) / 50.0) * 0.5
    }

    function backendVolumeToPct(vol) {
        var v = Math.max(0.0, vol)
        if (v <= 1.0)
            return Math.round(v * 100.0)
        return Math.round(100 + ((v - 1.0) / 0.5) * 50.0)
    }

    readonly property color barColor:
        (muted || volumePct === 0) ? theme.textDim
                                   : volumePct > 100 ? theme.warning
                                                     : theme.archCyan

    function setVol(pct) {
        if (!sink || !sink.audio)
            return

        var p = clamp(Math.round(pct), 0, maxPct)
        _lastSetPct = p
        sink.audio.volume = pctToBackendVolume(p)

        if (sink.audio.muted && p > 0)
            sink.audio.muted = false
    }

    function stepVolume(deltaPct) {
        if (!sink || !sink.audio)
            return

        var base = _lastSetPct >= 0 ? _lastSetPct : volumePct
        var nextPct = clamp(base + deltaPct, 0, maxPct)
        setVol(nextPct)
    }

    function toggleMute() {
        if (!sink || !sink.audio)
            return
        sink.audio.muted = !sink.audio.muted
    }

    onVolumePctChanged: {
        volumeVisual = volumePct
        popup.volume = volumePct
        if (_sinkReady) popupManager.showOsd("volume")
    }

    onMutedChanged: {
        popup.isMuted = muted
        if (_sinkReady) popupManager.showOsd("volume")
    }

    onDeviceNameChanged: {
        popup.deviceName = deviceName
        if (_sinkReady) popupManager.showOsd("volume")
    }

    Connections {
        target: sink && sink.audio ? sink.audio : null

        function onVolumeChanged() {
            popup.volume = root.volumePct
        }

        function onMutedChanged() {
            popup.isMuted = root.muted
        }
    }

    VolumeOSD {
        id: popup
        volume: root.volumePct
        isMuted: root.muted
        deviceName: root.deviceName
        targetItem: pillBg
    }

    AudioPopup {
        id: audioPopup
        targetItem: pillBg
    }

    property var audioPopup: audioPopup
    property var osdPopup: popup

    Behavior on volumeVisual {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: pillBg
        anchors.verticalCenter: parent.verticalCenter

        width: root.hovered ? iconOnly.width + theme.miniBarWidth + 5 + expandText.width + theme.pillPaddingH * 2 : iconOnly.width + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius

        color: root.hovered ? theme.bgHover : theme.bgSurface
        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 5

            Text {
                id: iconOnly
                text: (root.muted || root.volumePct === 0) ? "\uF026" : root.volumePct < 50 ? "\uF027" : "\uF028"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: (root.muted || root.volumePct === 0) ? theme.textDim : theme.archCyan
            }

            Item {
                width: theme.miniBarWidth
                height: theme.miniBarHeight
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hovered
                opacity: root.hovered ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Rectangle {
                    anchors.fill: parent
                    radius: theme.miniBarRadius
                    color: Qt.rgba(1, 1, 1, 0.07)
                }

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.min(1.0, root.volumeVisual / 100)
                    radius: theme.miniBarRadius
                    color: root.barColor
                    opacity: (root.muted || root.volumePct === 0) ? 0.3 : 1.0
                }
            }

            Text {
                id: expandText
                text: (root.muted || root.volumePct === 0) ? "sessiz" : root.volumePct + "%"
                font.family: theme.fontFamily
                font.pixelSize: theme.fontBase
                color: (root.muted || root.volumePct === 0) ? theme.textDim : theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hovered
                opacity: root.hovered ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        anchors.fill: pillBg
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onContainsMouseChanged: root.hovered = containsMouse

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (popupManager)
                    popupManager.toggleMajor("audio")
            } else if (mouse.button === Qt.RightButton) {
                root.toggleMute()
            }
        }

        onWheel: (event) => {
            root.stepVolume(event.angleDelta.y > 0 ? 5 : -5)
            event.accepted = true
        }
    }
}
