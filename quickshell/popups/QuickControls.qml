import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "."
import "../components"

PopupWindow {
    id: rootPopup

    property var popupManager: null
    property var targetItem: null
    property bool visibleState: false
    property var notifMod: null

    property bool wifiEnabled: true

    readonly property bool dndEnabled: notifMod ? notifMod.dndEnabled : false
    readonly property int notifCount: notifMod ? notifMod.notifCount : 0

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audioSource: Pipewire.defaultAudioSource

    function linearToDisplay(lin) {
        return lin !== undefined ? Math.round(Math.pow(lin, 1/3) * 100) : 100
    }

    function displayToLinear(disp) {
        return Math.pow(Math.max(0, Math.min(100, disp)) / 100, 3)
    }

    color: "transparent"
    grabFocus: true
    implicitWidth: 420
    implicitHeight: 620
    visible: visibleState || container.opacity > 0.001

    anchor {
        item: rootPopup.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
        margins.top: 10
    }

    function open() {
        visibleState = true
        if (anchor && anchor.updateAnchor)
            anchor.updateAnchor()
        wifiStateProc.running = true
    }

    function toggle() {
        if (visibleState) close()
        else open()
    }

    function close() {
        visibleState = false
    }

    function toggleDnd() {
        if (notifMod) notifMod.toggleDnd()
    }

    function setVolume(val) {
        if (audioSink && audioSink.audio)
            audioSink.audio.volume = displayToLinear(val)
    }

    function toggleMute() {
        if (audioSink && audioSink.audio)
            audioSink.audio.muted = !audioSink.audio.muted
    }

    function setMicVolume(val) {
        if (audioSource && audioSource.audio)
            audioSource.audio.volume = displayToLinear(val)
    }

    function toggleMicMute() {
        if (audioSource && audioSource.audio)
            audioSource.audio.muted = !audioSource.audio.muted
    }

    function toggleBluetooth() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
    }

    function toggleWifi() {
        wifiToggleProc.enabledTarget = !wifiEnabled
        wifiToggleProc.running = true
    }

    // WiFi

    Process {
        id: wifiToggleProc
        property bool enabledTarget: true
        command: ["nmcli", "radio", "wifi", enabledTarget ? "on" : "off"]
        running: false
        onExited: rootPopup.wifiEnabled = enabledTarget
    }

    Process {
        id: wifiStateProc
        command: ["sh", "-c", "nmcli radio wifi"]
        property string value: ""
        stdout: SplitParser {
            onRead: line => wifiStateProc.value = line.trim().toLowerCase()
        }
        onStarted: value = ""
        onExited: rootPopup.wifiEnabled = value === "enabled"
    }

    // click-outside-to-close

    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) {
            var cp = mapToItem(container, mouse.x, mouse.y)
            if (!container.contains(cp))
                rootPopup.close()
            else
                mouse.accepted = false
        }
    }

    // Glass Panel

    GlassPanel {
        id: container
        width: 390
        height: 590
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: rootPopup.visibleState ? 1.0 : 0.0
        scale: rootPopup.visibleState ? 1.0 : 0.95
        y: rootPopup.visibleState ? 14 : -20

        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.02 } }
        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 0

            // Header

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    Text {
                        text: "\uf013"
                        font.pixelSize: 18
                        color: theme.textPrimary
                    }

                    Text {
                        text: "Hızlı Kontroller"
                        font.pixelSize: theme.fontMd
                        font.weight: theme.weightMed
                        color: theme.textPrimary
                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.preferredWidth: notifCountBadge.visible ? 100 : 80
                        Layout.preferredHeight: 32

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.06)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "\uf0f3"
                                    font.pixelSize: 14
                                    color: theme.textPrimary
                                }

                                Text {
                                    id: notifLabel
                                    text: "Bildirimler"
                                    font.pixelSize: theme.fontSm
                                    font.weight: theme.weightMed
                                    color: theme.textPrimary
                                }

                                Rectangle {
                                    id: notifCountBadge
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: theme.archCyan
                                    visible: rootPopup.notifCount > 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: rootPopup.notifCount > 99 ? "99+" : rootPopup.notifCount
                                        font.pixelSize: 10
                                        font.weight: theme.weightMed
                                        color: "#000000"
                                    }
                                }
                            }
                        }

                        TapHandler {
                            onTapped: {
                                rootPopup.close()
                                if (notifMod) notifMod.openCenter()
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
                Layout.topMargin: 8
            }

            // Quick Toggles

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.topMargin: 10
                Layout.bottomMargin: 6

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    QuickToggle {
                        label: "Rahatsız Etme"
                        icon: "\uf1f6"
                        active: rootPopup.dndEnabled
                        onToggled: rootPopup.toggleDnd()
                    }

                    QuickToggle {
                        label: "Wi-Fi"
                        icon: "\uf1eb"
                        active: rootPopup.wifiEnabled
                        onToggled: rootPopup.toggleWifi()
                    }

                    QuickToggle {
                        label: "BT"
                        icon: "\uf293"
                        active: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                        onToggled: rootPopup.toggleBluetooth()
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            // Volume

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.topMargin: 8
                Layout.bottomMargin: 4

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    Text {
                        text: "Volume"
                        font.pixelSize: theme.fontMd
                        font.weight: theme.weightMed
                        color: theme.textMuted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Slider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: rootPopup.linearToDisplay(audioSink && audioSink.audio ? audioSink.audio.volume : 1)
                            onMoved: rootPopup.setVolume(value)
                            focusPolicy: Qt.NoFocus
                            leftPadding: 0
                            rightPadding: 0
                            topPadding: 0
                            bottomPadding: 0
                            implicitHeight: 20

                            background: Rectangle {
                                x: 0
                                y: parent.height / 2 - height / 2
                                width: parent.width
                                height: 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.08)

                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 4
                                    visible: width > 0
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: theme.archBlue }
                                        GradientStop { position: 1.0; color: theme.archCyan }
                                    }
                                    opacity: audioSink && audioSink.audio && audioSink.audio.muted ? 0.3 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: theme.animFast } }
                                }
                            }

                            handle: Rectangle {
                                x: volumeSlider.visualPosition * parent.width - width / 2
                                y: parent.height / 2 - height / 2
                                width: 4
                                height: 14
                                radius: 2
                                color: audioSink && audioSink.audio && audioSink.audio.muted ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.9)
                                Behavior on color { ColorAnimation { duration: theme.animFast } }
                            }
                        }

                        Text {
                            text: rootPopup.linearToDisplay(audioSink && audioSink.audio ? audioSink.audio.volume : 1) + "%"
                            font.pixelSize: theme.fontSm
                            color: theme.textMuted
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            text: audioSink && audioSink.audio && audioSink.audio.muted ? "\uf026" : "\uf028"
                            font.pixelSize: 16
                            color: audioSink && audioSink.audio && audioSink.audio.muted ? Qt.rgba(1, 1, 1, 0.35) : theme.textPrimary
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: theme.animFast } }
                            TapHandler { onTapped: rootPopup.toggleMute() }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            // Microphone

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.topMargin: 8
                Layout.bottomMargin: 4

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    Text {
                        text: "Mikrofon"
                        font.pixelSize: theme.fontMd
                        font.weight: theme.weightMed
                        color: theme.textMuted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Slider {
                            id: micSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: rootPopup.linearToDisplay(audioSource && audioSource.audio ? audioSource.audio.volume : 1)
                            onMoved: rootPopup.setMicVolume(value)
                            focusPolicy: Qt.NoFocus
                            leftPadding: 0
                            rightPadding: 0
                            topPadding: 0
                            bottomPadding: 0
                            implicitHeight: 20

                            background: Rectangle {
                                x: 0
                                y: parent.height / 2 - height / 2
                                width: parent.width
                                height: 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.08)

                                Rectangle {
                                    width: micSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 4
                                    visible: width > 0
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: theme.archBlue }
                                        GradientStop { position: 1.0; color: theme.archCyan }
                                    }
                                    opacity: audioSource && audioSource.audio && audioSource.audio.muted ? 0.3 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: theme.animFast } }
                                }
                            }

                            handle: Rectangle {
                                x: micSlider.visualPosition * parent.width - width / 2
                                y: parent.height / 2 - height / 2
                                width: 4
                                height: 14
                                radius: 2
                                color: audioSource && audioSource.audio && audioSource.audio.muted ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.9)
                                Behavior on color { ColorAnimation { duration: theme.animFast } }
                            }
                        }

                        Text {
                            text: rootPopup.linearToDisplay(audioSource && audioSource.audio ? audioSource.audio.volume : 1) + "%"
                            font.pixelSize: theme.fontSm
                            color: theme.textMuted
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            text: audioSource && audioSource.audio && audioSource.audio.muted ? "\uf131" : "\uf130"
                            font.pixelSize: 16
                            color: audioSource && audioSource.audio && audioSource.audio.muted ? Qt.rgba(1, 1, 1, 0.35) : theme.textPrimary
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: theme.animFast } }
                            TapHandler { onTapped: rootPopup.toggleMicMute() }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            // Brightness

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.topMargin: 8
                Layout.bottomMargin: 4

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    Text {
                        text: "Parlaklık"
                        font.pixelSize: theme.fontMd
                        font.weight: theme.weightMed
                        color: theme.textMuted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Slider {
                            id: brightSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: rootPopup.brightnessPercent !== undefined ? rootPopup.brightnessPercent : 50
                            onMoved: rootPopup.setBrightness(value)
                            focusPolicy: Qt.NoFocus
                            leftPadding: 0
                            rightPadding: 0
                            topPadding: 0
                            bottomPadding: 0
                            implicitHeight: 20

                            background: Rectangle {
                                x: 0
                                y: parent.height / 2 - height / 2
                                width: parent.width
                                height: 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.08)

                                Rectangle {
                                    width: brightSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 4
                                    visible: width > 0
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: theme.archBlue }
                                        GradientStop { position: 1.0; color: theme.archCyan }
                                    }
                                }
                            }

                            handle: Rectangle {
                                x: brightSlider.visualPosition * parent.width - width / 2
                                y: parent.height / 2 - height / 2
                                width: 4
                                height: 14
                                radius: 2
                                color: Qt.rgba(1, 1, 1, 0.9)
                            }
                        }

                        Text {
                            text: rootPopup.brightnessPercent + "%"
                            font.pixelSize: theme.fontSm
                            color: theme.textMuted
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            text: "\uf185"
                            font.pixelSize: 16
                            color: theme.textMuted
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
            }
        }
    }

    // Brightness

    property int brightnessPercent: 50

    Process {
        id: brightGetProc
        command: ["sh", "-c", "brightnessctl get"]
        property string result: ""
        stdout: SplitParser {
            onRead: line => brightGetProc.result = line.trim()
        }
        onStarted: result = ""
        onExited: brightGetMaxProc.running = true
    }

    Process {
        id: brightGetMaxProc
        command: ["sh", "-c", "brightnessctl max"]
        property string result: ""
        stdout: SplitParser {
            onRead: line => brightGetMaxProc.result = line.trim()
        }
        onStarted: result = ""
        onExited: function(exitCode, exitStatus) {
            var current = parseInt(brightGetProc.result, 10)
            var maxVal = parseInt(result, 10)
            if (!isNaN(current) && !isNaN(maxVal) && maxVal > 0)
                rootPopup.brightnessPercent = Math.round((current / maxVal) * 100)
        }
    }

    Process {
        id: brightSetProc
        property int percent: 50
        command: ["brightnessctl", "set", percent + "%"]
        running: false
    }

    function setBrightness(val) {
        var pct = Math.max(0, Math.min(100, Math.round(val)))
        brightnessPercent = pct
        brightSetProc.percent = pct
        brightSetProc.running = true
    }
}
