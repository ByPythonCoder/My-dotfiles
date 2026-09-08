import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    property bool dndEnabled: false
    readonly property int notifCount: server.trackedNotifications.values.length
    property var centerPopup: centerWindow

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: function(notification) {
            notification.tracked = true
            if (!root.dndEnabled) {
                toastModel.insert(0, {
                    nId: notification.id,
                    nSummary: notification.summary,
                    nBody: notification.body,
                    nAppName: notification.appName,
                    nAppIcon: notification.appIcon,
                    nUrgency: notification.urgency,
                    nTime: Qt.formatDateTime(new Date(), "HH:mm"),
                    nActions: []
                })
                toastDismissTimer.restart()
            }
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.toggleCenter() }
        function show(): void { root.openCenter() }
        function hide(): void { root.closeCenter() }
        function dismiss_all(): void {
            var vals = server.trackedNotifications.values
            for (var i = 0; i < vals.length; i++)
                vals[i].dismiss()
        }
        function toggle_dnd(): void { root.toggleDnd() }
    }

    function toggleCenter() {
        if (centerWindow.visibleState) closeCenter()
        else openCenter()
    }

    function openCenter() {
        centerWindow.visibleState = true
    }

    function closeCenter() {
        centerWindow.visibleState = false
    }

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled
    }

    function urgencyColor(urgency) {
        if (urgency === NotificationUrgency.Critical) return theme.danger
        if (urgency === NotificationUrgency.Low) return theme.warning
        return theme.border
    }

    // ── Toast notifications ──────────────────────────────

    ListModel { id: toastModel }

    PanelWindow {
        id: toastWindow
        anchors { top: true; right: true }
        margins { top: 8; right: 8 }
        implicitWidth: 370
        implicitHeight: Math.max(1, toastColumn.implicitHeight)
        color: "transparent"
        exclusiveZone: 0

        ColumnLayout {
            id: toastColumn
            width: parent.width
            spacing: 6

            Repeater {
                model: toastModel

                delegate: Rectangle {
                    id: toastCard
                    required property var modelData
                    property int modelIndex: index

                    Layout.fillWidth: true
                    Layout.preferredHeight: toastContent.implicitHeight + 24
                    radius: theme.widgetRadius
                    color: theme.bgSurface
                    border.width: 1
                    border.color: urgencyColor(modelData.nUrgency)

                    opacity: 0.0
                    x: 40

                    Component.onCompleted: {
                        opacity = 1.0
                        x = 0
                    }

                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Timer {
                        running: modelData.nUrgency !== NotificationUrgency.Critical
                        interval: 5000
                        repeat: false
                        onTriggered: {
                            toastCard.opacity = 0.0
                            toastCard.x = 40
                            toastRemoveTimer.restart()
                        }
                    }

                    Timer {
                        id: toastRemoveTimer
                        interval: 200
                        onTriggered: toastModel.remove(toastCard.modelIndex)
                    }

                    RowLayout {
                        id: toastContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.06)
                            visible: toastIcon.status === Image.Ready

                            Image {
                                id: toastIcon
                                anchors.fill: parent
                                anchors.margins: 4
                                fillMode: Image.PreserveAspectFit
                                source: modelData.nAppIcon || ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.nAppName || "Bildirim"
                                color: theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSm
                                font.weight: theme.weightMed
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.nSummary
                                color: theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontMd
                                font.weight: theme.weightMed
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: modelData.nBody !== ""
                                text: modelData.nBody
                                color: theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSm
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: modelData.nTime
                            color: theme.textDim
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSm
                            Layout.alignment: Qt.AlignTop
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            toastCard.opacity = 0.0
                            toastCard.x = 40
                            toastRemoveTimer.restart()
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    Timer {
        id: toastDismissTimer
        interval: 6000
        onTriggered: toastModel.clear()
    }

    // ── Notification center ──────────────────────────────

    PopupWindow {
        id: centerWindow

        property bool visibleState: false

        color: "transparent"
        grabFocus: true
        implicitWidth: 380
        implicitHeight: Math.max(1, centerPanel.implicitHeight + 28)
        visible: visibleState || centerPanel.opacity > 0.001

        anchor {
            edges: Edges.Top | Edges.Right
            gravity: Edges.Top | Edges.Right
            margins.top: 54
            margins.right: 8
        }

        function open() { visibleState = true }
        function close() { visibleState = false }

        MouseArea {
            anchors.fill: parent
            onPressed: function(mouse) {
                var cp = mapToItem(centerPanel, mouse.x, mouse.y)
                if (!centerPanel.contains(cp))
                    centerWindow.close()
                else
                    mouse.accepted = false
            }
        }

        GlassPanel {
            id: centerPanel
            width: 360
            glassRadius: 14
            glassColor: Qt.rgba(0.12, 0.12, 0.18, 0.85)
            glassBorder: Qt.rgba(1, 1, 1, 0.08)
            anchors.horizontalCenter: parent.horizontalCenter

            opacity: centerWindow.visibleState ? 1.0 : 0.0
            scale: centerWindow.visibleState ? 1.0 : 0.97
            y: centerWindow.visibleState ? 14 : -20

            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            height: Math.min(screen.height - 120, centerContent.implicitHeight + 28)

            Rectangle {
                anchors.fill: parent
                radius: centerPanel.glassRadius
                clip: true
                color: centerPanel.glassColor
                layer.enabled: true

                ColumnLayout {
                    id: centerContent
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // ── Header ──────────────────────────────

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            Text {
                                text: "\uf0f3"
                                font.family: "Font Awesome 6 Free"
                                font.pixelSize: 14
                                color: theme.archCyan
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: "Bildirimler"
                                    font.family: theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Qt.rgba(1, 1, 1, 0.94)
                                }

                                Text {
                                    text: root.dndEnabled ? "Rahatsız Etme açık" : server.trackedNotifications.values.length + " aktif"
                                    font.family: theme.fontFamily
                                    font.pixelSize: 10
                                    color: root.dndEnabled ? theme.warning : Qt.rgba(1, 1, 1, 0.42)
                                }
                            }

                            // DND toggle
                            Rectangle {
                                id: dndTrack
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                width: 38
                                height: 20
                                radius: 10
                                color: root.dndEnabled ? theme.archCyan : Qt.rgba(1, 1, 1, 0.10)
                                scale: dndTap.pressed ? 0.97 : 1.0

                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Qt.rgba(1, 1, 1, 0.95)
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: root.dndEnabled ? 20 : 2

                                    Behavior on x {
                                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                    }
                                }

                                TapHandler {
                                    id: dndTap
                                    onTapped: root.toggleDnd()
                                }
                            }


                        }
                    }

                    // ── Divider ─────────────────────────────

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    // ── Notification container ────────────────────

                    Rectangle {
                        id: notifContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: notifContainerContent.implicitHeight + 20
                        radius: 10
                        color: theme.bgSurface
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        visible: server.trackedNotifications.values.length > 0
                        clip: true

                        opacity: server.trackedNotifications.values.length > 0 ? 1.0 : 0.0
                        scale: server.trackedNotifications.values.length > 0 ? 1.0 : 0.97
                        y: server.trackedNotifications.values.length > 0 ? 0 : -8

                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            id: notifContainerContent
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Flickable {
                                id: notifFlick
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(notifColumn.implicitHeight, screen.height - 260)
                                contentHeight: notifColumn.implicitHeight
                                clip: true
                                interactive: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: notifColumn
                                    width: parent.width
                                    spacing: 6

                                    Repeater {
                                        model: server.trackedNotifications

                                delegate: Rectangle {
                                    id: card
                                    required property var modelData

                                    width: notifColumn.width
                                    height: cardInner.implicitHeight + 24
                                    radius: theme.widgetRadius
                                    color: theme.bgSurface
                                    border.width: 1
                                    border.color: cardMa.containsMouse
                                        ? Qt.rgba(1, 1, 1, 0.12)
                                        : urgencyColor(modelData.urgency)

                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    opacity: 0.0
                                    x: 20

                                    Component.onCompleted: {
                                        opacity = 1.0
                                        x = 0
                                    }

                                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        id: cardInner
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        // App icon
                                        Rectangle {
                                            Layout.preferredWidth: 32
                                            Layout.preferredHeight: 32
                                            Layout.alignment: Qt.AlignTop
                                            radius: 8
                                            color: Qt.rgba(1, 1, 1, 0.06)
                                            visible: cardIcon.status === Image.Ready

                                            Image {
                                                id: cardIcon
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                fillMode: Image.PreserveAspectFit
                                                source: modelData.appIcon || ""
                                            }
                                        }

                                        // Content
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            // App name + dismiss
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text {
                                                    text: modelData.appName || "Bildirim"
                                                    color: theme.textMuted
                                                    font.family: theme.fontFamily
                                                    font.pixelSize: theme.fontSm
                                                    font.weight: theme.weightMed
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: modelData.expireTimeout > 0
                                                        ? Math.round(modelData.expireTimeout / 1000) + "s"
                                                        : ""
                                                    color: theme.textDim
                                                    font.family: theme.fontFamily
                                                    font.pixelSize: 9
                                                    visible: text !== ""
                                                }

                                                Text {
                                                    text: "\uf00d"
                                                    font.family: "Font Awesome 6 Free"
                                                    font.pixelSize: 10
                                                    color: cardMa.containsMouse
                                                        ? theme.textPrimary
                                                        : "transparent"

                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                }
                                            }

                                            // Summary
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.summary
                                                color: theme.textPrimary
                                                font.family: theme.fontFamily
                                                font.pixelSize: theme.fontMd
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            // Body
                                            Text {
                                                Layout.fillWidth: true
                                                visible: modelData.body !== ""
                                                text: modelData.body
                                                color: theme.textMuted
                                                font.family: theme.fontFamily
                                                font.pixelSize: theme.fontSm
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 4
                                                elide: Text.ElideRight
                                            }

                                            // Action buttons
                                            Row {
                                                Layout.fillWidth: true
                                                spacing: 6
                                                visible: modelData.actions.length > 0

                                                Repeater {
                                                    model: modelData.actions

                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        width: actionText.implicitWidth + 16
                                                        height: 26
                                                        radius: 6
                                                        color: actionMa.containsMouse
                                                            ? Qt.rgba(1, 1, 1, 0.10)
                                                            : Qt.rgba(1, 1, 1, 0.04)

                                                        Behavior on color { ColorAnimation { duration: 100 } }

                                                        Text {
                                                            id: actionText
                                                            anchors.centerIn: parent
                                                            text: modelData.text
                                                            font.family: theme.fontFamily
                                                            font.pixelSize: theme.fontSm
                                                            font.weight: theme.weightMed
                                                            color: actionMa.containsMouse
                                                                ? theme.archCyan
                                                                : theme.textMuted
                                                        }

                                                        HoverHandler { id: actionMa }

                                                        TapHandler {
                                                            onTapped: modelData.invoke()
                                                            cursorShape: Qt.PointingHandCursor
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: cardMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton)
                                                modelData.dismiss()
                                        }
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }

                        // Scrollbar
                        Rectangle {
                            id: scrollTrack
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 1
                            width: 5
                            radius: 2.5
                            color: Qt.rgba(1, 1, 1, 0.05)
                            visible: notifFlick.contentHeight > notifFlick.height
                            opacity: notifFlick.moving ? 1.0 : 0.25

                            Behavior on opacity {
                                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                height: Math.max(12, notifFlick.visibleArea.heightRatio * notifFlick.height)
                                radius: 2.5
                                y: notifFlick.visibleArea.yPosition * (notifFlick.height - height)
                                color: notifFlick.moving
                                    ? Qt.rgba(1, 1, 1, 0.45)
                                    : Qt.rgba(1, 1, 1, 0.20)

                                Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                            // Clear All button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 8
                                color: clearAllBtnMa.containsMouse
                                    ? Qt.rgba(0.97, 0.31, 0.29, 0.15)
                                    : Qt.rgba(1, 1, 1, 0.04)
                                visible: server.trackedNotifications.values.length > 0
                                opacity: server.trackedNotifications.values.length > 0 ? 1.0 : 0.0

                                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "\uf1f6"
                                        font.family: "Font Awesome 6 Free"
                                        font.pixelSize: 11
                                        color: clearAllBtnMa.containsMouse ? theme.danger : theme.textMuted
                                    }

                                    Text {
                                        text: "Temizle"
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSm
                                        font.weight: theme.weightMed
                                        color: clearAllBtnMa.containsMouse ? theme.danger : theme.textMuted
                                    }
                                }

                                HoverHandler { id: clearAllBtnMa }

                                TapHandler {
                                    onTapped: {
                                        var vals = server.trackedNotifications.values
                                        for (var i = 0; i < vals.length; i++)
                                            vals[i].dismiss()
                                    }
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }

                    // ── Empty state ─────────────────────────

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        visible: server.trackedNotifications.values.length === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 40
                                height: 40
                                radius: 20
                                color: Qt.rgba(1, 1, 1, 0.04)

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf0f3"
                                    font.family: "Font Awesome 6 Free"
                                    font.pixelSize: 16
                                    color: theme.textDim
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.dndEnabled ? "Rahatsız Etme açık" : "Bildirim yok"
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSm
                                color: theme.textDim
                            }

			    Text {
				Layout.alignment: Qt.AlignHCenter
				text: root.dndEnabled
				? "Bildirimler sessize alındı"
				: "Burada görünecek"
				font.family: theme.fontFamily
				font.pixelSize: 9
				color: Qt.rgba(1, 1, 1, 0.25)
			    }
			}
		    }
		}
	    }
	}
    }
}
}
