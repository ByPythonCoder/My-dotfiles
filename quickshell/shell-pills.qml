//@ pragma UseQApplication
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "bar"
import "popups"
import "osd"
import "components"
import "notification"
import "."

ShellRoot {
    Theme { id: theme }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen:        modelData || null
            anchors.top:   true
            anchors.left:  true
            anchors.right: true
            implicitHeight: theme.barHeight + 14
            color:         "transparent"
            exclusiveZone: theme.barHeight + 6

            component Capsule: Rectangle {
                id: capsule
                radius: 16
                color:  theme.bgBar
                border.width: 0.5
                border.color: theme.border

                property bool show: true
                opacity: show ? 1.0 : 0.0
                y:       show ? parent.height/2 - height/2 : -(height)

                Behavior on opacity { NumberAnimation { duration: theme.animDuration; easing.type: Easing.OutCubic } }
                Behavior on y       { NumberAnimation { duration: theme.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

                Component.onCompleted: show = true

                Rectangle {
                    anchors.top:   parent.top
                    anchors.left:  parent.left
                    anchors.right: parent.right
                    anchors.margins: parent.radius * 0.4
                    height: 1
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: theme.archCyan }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    opacity: 0.4
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0.68, 0.64, 0.86, 0.08)
                }
            }

            Capsule {
                id: leftCap
                anchors.left:           parent.left
                anchors.leftMargin:     10
                anchors.verticalCenter: parent.verticalCenter
                height: theme.barHeight
                width:  leftRow.implicitWidth + 24

                Row {
                    id: leftRow
                    anchors.centerIn: parent
                    spacing: theme.gap

                    Item {
                        id: logoParent
                        width: 22; height: 22
                        anchors.verticalCenter: parent.verticalCenter

                        property bool logoHovered: false

                        Grid {
                            id: logoGrid
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
                }
            }

            Capsule {
                id: rightCap
                anchors.right:          parent.right
                anchors.rightMargin:    10
                anchors.verticalCenter: parent.verticalCenter
                height: theme.barHeight
                width:  rightRow.implicitWidth + 24

                Row {
                    id: rightRow
                    anchors.centerIn: parent
                    spacing: theme.gap

                    Clock {
                        id: centerClock
                        anchors.verticalCenter: parent.verticalCenter
                        popupManager: popupManager
                    }
                    BarSep {}
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
                popupManager.registerMajor("calendar", centerClock.calPopup)
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
