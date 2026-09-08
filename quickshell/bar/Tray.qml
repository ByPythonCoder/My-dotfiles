import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property var anchorWindow: null

    readonly property var suppressedTrayIds: [
        "nm-applet", "connman",
        "blueman", "blueberry", "bluetooth",
        "pasystray", "volumeicon", "pnmixer", "pipewire", "pulseaudio"
    ]

    function isTrayDuplicate(id) {
        if (!id) return false
        var lower = String(id).toLowerCase()
        for (var i = 0; i < root.suppressedTrayIds.length; i++) {
            if (lower.indexOf(root.suppressedTrayIds[i]) >= 0)
                return true
        }
        return false
    }

    Theme { id: theme }

    implicitWidth: trayRow.implicitWidth
    implicitHeight: theme.barHeight

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: itemDelegate

                required property var modelData

                readonly property bool isDuplicate: root.isTrayDuplicate(modelData.id || modelData.title || "")

                width: isDuplicate ? 0 : 26
                height: isDuplicate ? 0 : 26
                visible: !isDuplicate

                property bool hovered: false

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: itemDelegate.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                Image {
                    anchors.centerIn: parent
                    source: itemDelegate.modelData.icon
                    width: 20
                    height: 20
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                HoverHandler {
                    onHoveredChanged: itemDelegate.hovered = hovered
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: itemDelegate.modelData.activate()
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: function(event) {
                        if (itemDelegate.modelData.hasMenu) {
                            let pos = itemDelegate.mapToItem(root.anchorWindow.contentItem, 0, itemDelegate.height)
                            menu.anchor.rect.x = pos.x
                            menu.anchor.rect.y = pos.y
                            menu.anchor.rect.width = itemDelegate.width
                            menu.anchor.rect.height = itemDelegate.height
                            menu.open()
                        } else {
                            itemDelegate.modelData.secondaryActivate()
                        }
                    }
                }

                QsMenuAnchor {
                    id: menu
                    menu: itemDelegate.modelData.menu
                    anchor.window: root.anchorWindow
                    anchor.rect.x: 0
                    anchor.rect.y: 0
                    anchor.rect.width: itemDelegate.width
                    anchor.rect.height: itemDelegate.height
                }
            }
        }
    }
}
