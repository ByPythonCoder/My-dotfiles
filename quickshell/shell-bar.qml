import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."
import "bar"
import "popups"
import "osd"
import "components"
import "notification"

ShellRoot {
    Theme { id: theme }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData

            screen: modelData || null
            anchors.top: true
            anchors.left: true
            anchors.right: true

            implicitHeight: theme.barHeight

            color: "transparent"
            exclusiveZone: implicitHeight

            Rectangle {
                id: barSurface
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                height: parent.height
                color: theme.bgBar
                radius: theme.barRadius

                opacity: 0.0
                Component.onCompleted: slideIn.start()

                NumberAnimation {
                    id: slideIn
                    target: barSurface
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: theme.animDuration
                    easing.type: Easing.OutCubic
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.25; color: theme.archBlue }
                        GradientStop { position: 0.6; color: theme.archCyan }
                        GradientStop { position: 1.0; color: "transparent" }
                    }

                    opacity: 0.55
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: theme.border
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: theme.barPadding
                    anchors.rightMargin: theme.barPadding

                    Row {
                        id: leftSection
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.gap

                        Item {
                            id: logoParent
                            width: 22; height: 22
                            anchors.verticalCenter: parent.verticalCenter

                            property bool logoHovered: false

                            Grid {
                                anchors.centerIn: parent
                                columns: 3
                                spacing: 2

                                Repeater {
                                    model: 9
                                    Rectangle {
                                        width: 5; height: 5; radius: 1
                                        color: logoParent.logoHovered ? "#cba6f7" : "#74c7ec"
                                        opacity: 0.85

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -4
                                radius: 6
                                color: logoParent.logoHovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            HoverHandler {
                                onHoveredChanged: logoParent.logoHovered = hovered
                            }

                            TapHandler {
                                onTapped: launcherMod.toggleLauncher()
                            }
                        }

                        BarSep {}
                        Workspaces { id: wsMod; anchors.verticalCenter: parent.verticalCenter }
                        BarSep {}
                        Media { id: mediaMod; anchors.verticalCenter: parent.verticalCenter; popupManager: popupManager }

                        Clock {
                            id: clockMod
                            anchors.centerIn: parent
                            popupManager: popupManager
                        }
                    }

                    Row {
                        id: rightSection
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.gap

                        Volume     { id: volMod; anchors.verticalCenter: parent.verticalCenter; popupManager: popupManager }
                        BarSep {}
                        Brightness { id: brightMod; anchors.verticalCenter: parent.verticalCenter; popupManager: popupManager }
                        BarSep {}
                        Network {
                            id: netMod
                            anchors.verticalCenter: parent.verticalCenter
                            popupManager: popupManager
                        }
                        BarSep {}
                        PowerProfile {
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Tray {
                            anchorWindow: bar
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        BarSep {}
                        Power {
                            id: powerMod
                            anchors.verticalCenter: parent.verticalCenter
                            popupManager: popupManager
                        }
                    }
                }
            }

            Notifications {
                id: notifMod
            }

            AppLauncher {
                id: launcherMod
                targetItem: logoParent
            }

            // ── Popup Manager ──────────────────────────────
            PopupManager { id: popupManager }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    popupManager.handleEscape()
                    event.accepted = true
                }
            }

            Component.onCompleted: {
                popupManager.registerMajor("audio", volMod.audioPopup)
                popupManager.registerMajor("network", netMod.netPopup)
                popupManager.registerMajor("media", mediaMod.mediaPopupAlias)
                popupManager.registerMajor("workspace", wsMod.wsOverview)
                popupManager.registerMajor("power", powerMod.powerPopup)
                popupManager.registerMajor("calendar", clockMod.calPopup)
                popupManager.registerMajor("notifications", notifMod.centerPopup)
                popupManager.registerOsd("volume", volMod.osdPopup)
                popupManager.registerOsd("brightness", brightMod.osdPopup)
                popupManager.registerOsd("network", netMod.osdPopup)

                netMod.netPopup.requestSecureConnect.connect(function(ssid, security) {
                    netMod.netPopup.connectDialog.openFor(ssid, security)
                })
            }
        }
    }
}
