import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."
import ".."
import "../components"

FocusScope {
    id: root

    property string targetSsid: ""
    property string securityLabel: ""
    property bool visibleState: false
    property bool connecting: false
    property bool closing: false
    property string errorText: ""
    property string previousSsid: ""

    signal connected(string ssid)
    signal canceled()
    signal failed(string error)

    visible: visibleState || closing
    enabled: visibleState || closing
    focus: visibleState
    activeFocusOnTab: true

    function safeText(v, fallback) {
        return (v !== undefined && v !== null && String(v).length > 0) ? String(v) : fallback
    }

    function openFor(ssid, security) {
        targetSsid = safeText(ssid, "Wi‑Fi Network")
        securityLabel = safeText(security, "Secured")
        passwordField.text = ""
        connecting = false
        errorText = ""
        closing = false
        closeTimer.stop()
        visibleState = true
        focusTimer.restart()
    }

    function close() {
        visibleState = false
        connecting = false
        errorText = ""
        closing = true
        closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: closing = false
    }

    function focusInput() {
        root.forceActiveFocus()
        passwordField.forceActiveFocus()
        passwordField.cursorPosition = passwordField.text.length
    }

    function submit() {
        if (connecting) return
        if (passwordField.text.length === 0) {
            errorText = "Şifre girin"
            focusInput()
            return
        }
        errorText = ""
        connecting = true
        connectProc.ssid = targetSsid
        connectProc.password = passwordField.text
        connectProc.errorOutput = ""
        connectProc.running = true
    }

    function connectionSucceeded() {
        connecting = false
        connected(targetSsid)
        close()
    }

    function connectionFailed(message) {
        connecting = false
        errorText = (message && String(message).length > 0)
                    ? String(message)
                    : "Connection failed"
        failed(errorText)
        focusTimer.restart()
    }

    Process {
        id: connectProc
        property string ssid: ""
        property string password: ""
        property string errorOutput: ""
        command: ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        running: false

        stderr: SplitParser {
            onRead: line => {
                var trimmed = line.trim()
                if (trimmed.length > 0)
                    connectProc.errorOutput += (connectProc.errorOutput.length > 0 ? "\n" : "") + trimmed
            }
        }

        onStarted: errorOutput = ""

        onExited: function(exitCode, exitStatus) {
            if (!root.visibleState) return
            if (exitCode !== 0 || connectProc.errorOutput.length > 0) {
                root.connectionFailed(
                    connectProc.errorOutput.length > 0
                        ? connectProc.errorOutput
                    : "Bağlantı başarısız"
                )
            } else {
                root.connectionSucceeded()
            }
        }
    }
    Timer {
        id: focusTimer
        interval: 80
        repeat: false
        onTriggered: root.focusInput()
    }

    Keys.onReturnPressed: root.submit()
    Keys.onEnterPressed: root.submit()

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.canceled()
            root.close()
            event.accepted = true
        }
    }
    // clamps outside-card clicks
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => {
            var cp = mapToItem(card, mouse.x, mouse.y)
            if (!card.contains(cp)) {
                root.canceled()
                root.close()
                mouse.accepted = true
            }
        }
    }

    GlassPanel {
        id: card
        glassRadius: 14
        width: 268
        height: cardLayout.implicitHeight + 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.visibleState ? (parent.height - height) / 2 : (parent.height - height) / 2 + 20

        opacity: root.visibleState ? 1.0 : 0.0
        scale: root.visibleState ? 1.0 : 0.97

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Text {
                text: "Wi‑Fi Ağına Katıl"
                font.pixelSize: theme.fontSm
                font.weight: theme.weightMed
                color: theme.textMuted
            }

            Text {
                text: root.targetSsid
                font.pixelSize: theme.fontMd
                font.bold: true
                color: theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.securityLabel
                font.pixelSize: theme.fontSm
                color: theme.textDim
            }

            Rectangle {
                id: inputBg
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: passwordField.activeFocus
                              ? theme.accentActive
                              : Qt.rgba(1, 1, 1, 0.08)

                TapHandler {
                    onTapped: root.focusInput()
                }

                TextInput {
                    id: passwordField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    echoMode: TextInput.Password
                    font.pixelSize: theme.fontBase
                    color: theme.textPrimary
                    enabled: !root.connecting
                    focus: true
                    activeFocusOnTab: true

                    onAccepted: root.submit()
                    onTextEdited: root.errorText = ""
                    Keys.onReturnPressed: root.submit()
                    Keys.onEnterPressed: root.submit()
                }

                Text {
                    visible: passwordField.text.length === 0
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password"
                    font.pixelSize: theme.fontBase
                    color: theme.textDim
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.errorText.length > 0
                text: root.errorText
                wrapMode: Text.Wrap
                font.pixelSize: theme.fontSm
                color: theme.danger
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    visible: root.connecting
                    text: "Bağlanıyor…"
                    font.pixelSize: theme.fontSm
                    color: theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 60
                    height: 26
                    radius: 8
                    color: cancelMouse.pressed ? theme.bgHover : "transparent"
                    opacity: root.connecting ? 0.5 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "İptal"
                        font.pixelSize: theme.fontBase
                        color: theme.textMuted
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        enabled: !root.connecting
                        onClicked: {
                            root.canceled()
                            root.close()
                        }
                    }
                }

                Rectangle {
                    width: 68
                    height: 26
                    radius: 8
                    color: (passwordField.text.length > 0 && !root.connecting)
                           ? (joinTap.pressed ? Qt.rgba(0.54, 0.91, 1.0, 0.78) : theme.accentActive)
                           : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: root.connecting ? "Katılıyor…" : "Katıl"
                        font.pixelSize: theme.fontBase
                        font.bold: true
                        color: (passwordField.text.length > 0 && !root.connecting)
                               ? Qt.rgba(0.08, 0.09, 0.11, 0.95)
                               : theme.textDim
                    }

                    TapHandler {
                        id: joinTap
                        enabled: !root.connecting
                        onTapped: root.submit()
                    }
                }
            }
        }
    }
}
