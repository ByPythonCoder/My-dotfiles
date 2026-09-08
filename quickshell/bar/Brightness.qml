import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../osd"

Item {
    id: root
    Theme { id: theme }

    implicitWidth: pillBg.width
    implicitHeight: theme.barHeight

    property bool hovered: false
    property bool _ready: false

    property var popupManager: null

    property int currentPct: 0

    onCurrentPctChanged: {
        brightnessVisual = currentPct
        osd.brightness = currentPct
        if (_ready && popupManager) popupManager.showOsd("brightness")
    }
    property int savedPct: 50

    property real brightnessVisual: currentPct

    readonly property bool isFullBright: currentPct >= 99
    readonly property real rayScale: 0.55 + (brightnessVisual / 100) * 0.45

    Behavior on brightnessVisual {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Process {
        id: readProc

        command: ["sh", "-c", "ddcutil getvcp 10 2>/dev/null"]

        property var output: ""

        stdout: SplitParser {
            onRead: (line) => {
                readProc.output += line + "\n"
            }
        }

        onStarted: output = ""

        onExited: {
            if (root._setting) return
            var match = output.match(/current value\s*=\s*(\d+)/)
            if (match) {
                var pct = parseInt(match[1], 10)
                if (!isNaN(pct) && pct !== root.currentPct)
                    root.currentPct = pct
            }

            if (!root._ready)
                Qt.callLater(function() { root._ready = true })
        }
    }

    property bool _setting: false

    Timer {
        id: cooldownTimer
        interval: 300
        repeat: false
        onTriggered: root._setting = false
    }

    Timer {
        interval: 800
        running: true
        repeat: true

        onTriggered: {
            if (root._setting || readProc.running || setProc.running) return
            readProc.running = true
        }
    }

    Component.onCompleted: {
        readProc.running = true
    }

    Process {
        id: setProc
    }

    function setBrightness(pct) {
        const c = Math.max(1, Math.min(100, pct))
        root.currentPct = c
        root._setting = true
        cooldownTimer.restart()
        setProc.command = ["ddcutil", "setvcp", "10", String(c)]
        setProc.running = true
    }

    function toggleFull() {
        if (root.isFullBright) {
            setBrightness(root.savedPct > 0 ? root.savedPct : 50)
        } else {
            root.savedPct = root.currentPct
            setBrightness(100)
        }
    }

    BrightnessOSD {
        id: osd
        targetItem: pillBg
        brightness: root.currentPct
    }

    property var osdPopup: osd

    Rectangle {
        id: pillBg

        anchors.verticalCenter: parent.verticalCenter

        width: root.hovered ? brightIcon.width + theme.miniBarWidth + 5 + brightPctText.width + theme.pillPaddingH * 2 : brightIcon.width + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius

        color: root.hovered ? theme.bgHover : theme.bgSurface

        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: theme.animFast } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 5

            Item {
                id: brightIcon
                width: 16
                height: 16

                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent

                    width: 8
                    height: 8
                    radius: 4

                    color: theme.archCyan
                }

                Repeater {
                    model: 8

                    Rectangle {
                        property real rayLen: 2.5 * root.rayScale

                        anchors.centerIn: parent

                        width: 1.2
                        height: rayLen
                        radius: 0.6

                        color: theme.archCyan

                        opacity: 0.5 + (root.brightnessVisual / 100) * 0.5

                        transform: [
                            Translate { y: -5.5 },
                            Rotation {
                                origin.x: 0.6
                                origin.y: rayLen / 2
                                angle: (index / 8) * 360
                            }
                        ]

                        Behavior on height {
                            NumberAnimation {
                                duration: theme.animMed
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: theme.animMed
                            }
                        }
                    }
                }
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
                    width: parent.width * (root.brightnessVisual / 100)
                    radius: theme.miniBarRadius
                    color: root.currentPct < 20 ? theme.archDim : theme.archCyan

                    Behavior on width { NumberAnimation { duration: theme.animMed; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: theme.animMed } }
                }
            }

            Text {
                id: brightPctText
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentPct + "%"
                font.family: theme.fontFamily
                font.pixelSize: theme.fontBase
                font.weight: Font.Medium
                color: root.isFullBright ? theme.archCyan : theme.textPrimary
                visible: root.hovered
                opacity: root.hovered ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: theme.animFast } }
            }
        }
    }

    property int _stepSize: theme.brightStep ? theme.brightStep : 5

    MouseArea {
        anchors.fill: pillBg
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onContainsMouseChanged: root.hovered = containsMouse

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.toggleFull()
            } else if (mouse.button === Qt.MiddleButton) {
                root.setBrightness(50)
            }
        }

        onWheel: (event) => {
            root.setBrightness(
                root.currentPct +
                (event.angleDelta.y > 0
                    ? root._stepSize
                    : -root._stepSize)
            )
            event.accepted = true
        }
    }
}
