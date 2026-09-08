import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

PopupWindow {
    id: rootPopup

    property var targetItem: null
    property bool visibleState: false
    property string _confirmAction: ""
    property bool _cooldown: false

    readonly property var powerActions: [
        { action: "lock",     icon: "\uf023", label: "Kilitle",     needsConfirm: false },
        { action: "logout",   icon: "\uf2f5", label: "Oturumu Kapat",   needsConfirm: false },
        { action: "suspend",  icon: "\uf252", label: "Beklet",  needsConfirm: false },
        { action: "reboot",   icon: "\uf01e", label: "Yeniden Başlat",   needsConfirm: true  },
        { action: "shutdown", icon: "\uf011", label: "Kapat", needsConfirm: true  }
    ]

    color: "transparent"
    implicitWidth: 240
    implicitHeight: 240
    visible: visibleState || container.opacity > 0.001

    anchor {
        item: rootPopup.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
        margins.top: 10
    }

    function open() {
        visibleState = true
    }

    function close() {
        visibleState = false
    }

    function handleAction(action, needsConfirm) {
        if (_cooldown) return

        if (needsConfirm && _confirmAction !== action) {
            _confirmAction = action
            confirmTimer.restart()
            return
        }

        _confirmAction = ""
        confirmTimer.stop()
        _cooldown = true
        cooldownTimer.restart()

        var cmd
        switch (action) {
            case "lock":     cmd = ["hyprlock"]; break
            case "logout":   cmd = ["sh", "-c", "loginctl terminate-user $(whoami)"]; break
            case "suspend":  cmd = ["systemctl", "suspend"]; break
            case "reboot":   cmd = ["systemctl", "reboot"]; break
            case "shutdown": cmd = ["systemctl", "poweroff"]; break
        }

        if (cmd) {
            proc.command = cmd
            proc.running = true
        }
    }

    Process {
        id: proc
        running: false
    }

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: rootPopup._confirmAction = ""
    }

    Timer {
        id: cooldownTimer
        interval: 1500
        onTriggered: rootPopup._cooldown = false
    }

    GlassPanel {
        id: container
        width: 220
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: rootPopup.visibleState ? 1.0 : 0.0
        scale: rootPopup.visibleState ? 1.0 : 0.95
        y: rootPopup.visibleState ? 14 : -20

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.02 } }
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        height: contentCol.implicitHeight + 12

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: rootPopup.powerActions

                delegate: Rectangle {
                    id: btnBg
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 8

                    required property var modelData
                    property bool confirming: rootPopup._confirmAction === modelData.action
                    property bool disabled: rootPopup._cooldown

                    color: {
                        if (disabled) return Qt.rgba(1, 1, 1, 0.02)
                        if (confirming) return Qt.rgba(0.97, 0.31, 0.29, 0.12)
                        if (btnHov.hovered) return Qt.rgba(1, 1, 1, 0.05)
                        return "transparent"
                    }

                    Behavior on color { ColorAnimation { duration: 100 } }

                    scale: btnTap.pressed && !disabled ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: confirming ? "\uf071" : modelData.icon
                            font.pixelSize: 13
                            color: {
                                if (disabled) return Qt.rgba(1, 1, 1, 0.15)
                                if (confirming) return "#f38ba8"
                                return Qt.rgba(1, 1, 1, 0.60)
                            }
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: confirming ? "Onayla?" : modelData.label
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: {
                                if (disabled) return Qt.rgba(1, 1, 1, 0.15)
                                if (confirming) return "#f38ba8"
                                return Qt.rgba(1, 1, 1, 0.75)
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    HoverHandler { id: btnHov }

                    TapHandler {
                        id: btnTap
                        onTapped: rootPopup.handleAction(modelData.action, modelData.needsConfirm)
                    }
                }
            }
        }
    }
}
