import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 340 * Style.uiScaleRatio
    property real contentPreferredHeight: 380 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    readonly property var mainInst: pluginApi?.mainInstance ?? null

    property int _langVersion: 0

    Connections {
        target: mainInst
        function onTranslationVersionChanged() {
            root._langVersion++;
        }
    }

    function t(key) {
        if (_langVersion < 0) return undefined;
        return mainInst?.translate(key);
    }

    function folderStateText(folder) {
        if (!mainInst) return "";
        if (folder.state === "syncing" && folder.needItems > 0) {
            return t("panel.folder-state").arg(mainInst.stateLabel(folder.state)).arg(folder.needItems);
        }
        return mainInst.stateLabel(folder.state);
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NBox {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM
                    clip: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NIcon {
                            icon: "exchange"
                            pointSize: Style.fontSizeL
                            color: mainInst ? mainInst.statusColor(mainInst.enabled ? mainInst.state : "disabled") : Color.mOutline
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            NText {
                                text: t("panel.title")
                                pointSize: Style.fontSizeL
                                font.bold: true
                                color: Color.mOnSurface
                            }

                            NText {
                                text: mainInst?.stateLabel(mainInst.enabled ? mainInst.state : "disabled")
                                pointSize: Style.fontSizeS
                                color: Qt.alpha(Color.mOnSurface, 0.7)
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: refreshLabel.width + 22
                            Layout.preferredHeight: 30
                            radius: Style.radiusM
                            color: refreshMouse.containsMouse ? Qt.darker(Color.mPrimary, 1.1) : Color.mPrimary

                            NText {
                                id: refreshLabel
                                anchors.centerIn: parent
                                text: t("panel.refresh")
                                color: Color.mOnPrimary
                            }

                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mainInst?.requestPoll(true)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: mainInst ? mainInst.statusColor(mainInst.enabled ? mainInst.state : "disabled") : Color.mOutline
                        }

                        NText {
                            text: mainInst?.statusSummary() ?? ""
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: Style.marginS
                        rowSpacing: Style.marginS

                        Repeater {
                            model: [
                                {
                                    "label": t("panel.devices"),
                                    "value": (mainInst?.connectedDevices ?? 0) + "/" + (mainInst?.configuredDevices ?? 0)
                                },
                                {
                                    "label": t("panel.folders"),
                                    "value": String(mainInst?.monitoredFolders ?? 0)
                                },
                                {
                                    "label": t("panel.pending"),
                                    "value": (mainInst?.needItems ?? 0) > 0
                                        ? String(mainInst?.needItems ?? 0)
                                        : (mainInst ? mainInst.formatBytes(mainInst.needBytes) : "0 B")
                                }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 68
                                radius: Style.iRadiusM
                                color: Color.mSurfaceVariant

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    NText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.value
                                        font.bold: true
                                        pointSize: Style.fontSizeM
                                        color: Color.mOnSurface
                                    }

                                    NText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        pointSize: Style.fontSizeS
                                        color: Qt.alpha(Color.mOnSurface, 0.6)
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: t("panel.folders")
                            font.bold: true
                            color: Color.mOnSurface
                        }

                        Repeater {
                            model: mainInst?.folders ?? []

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 46
                                radius: Style.iRadiusM
                                color: Color.mSurfaceVariant
                                border.color: Qt.alpha(mainInst?.statusColor(modelData.state) ?? Color.mOutline, 0.5)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Style.marginS
                                    spacing: Style.marginS

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: mainInst?.statusColor(modelData.state) ?? Color.mOutline
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        NText {
                                            text: modelData.label
                                            font.bold: true
                                            color: Color.mOnSurface
                                            elide: Text.ElideRight
                                        }

                                        NText {
                                            text: root.folderStateText(modelData)
                                            pointSize: Style.fontSizeS
                                            color: Qt.alpha(Color.mOnSurface, 0.65)
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        NText {
                            text: t("panel.no-folders")
                            visible: (mainInst?.folders?.length ?? 0) === 0
                            color: Qt.alpha(Color.mOnSurface, 0.6)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: !!(mainInst?.detail ?? "")

                        NText {
                            text: t("panel.details")
                            font.bold: true
                        }

                        NText {
                            text: mainInst?.detail ?? ""
                            wrapMode: Text.Wrap
                            color: mainInst?.hasProblem ? Color.mError : Qt.alpha(Color.mOnSurface, 0.75)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        NText {
                            text: t("panel.last-check") + ": " + (mainInst?.formatCheckedAt(mainInst?.checkedAt ?? "") ?? "-")
                            pointSize: Style.fontSizeS
                            color: Qt.alpha(Color.mOnSurface, 0.65)
                        }

                        NText {
                            text: t("panel.url") + ": " + (mainInst?.resolvedUrl || "-")
                            pointSize: Style.fontSizeS
                            color: Qt.alpha(Color.mOnSurface, 0.65)
                            elide: Text.ElideRight
                        }

                        NText {
                            text: t("panel.config-path") + ": " + (mainInst?.resolvedConfigPath || "-")
                            pointSize: Style.fontSizeS
                            color: Qt.alpha(Color.mOnSurface, 0.65)
                            elide: Text.ElideMiddle
                        }

                        NText {
                            text: t("panel.api-source") + ": " + (mainInst ? mainInst.sourceLabel(mainInst.apiKeySource) : "-")
                            pointSize: Style.fontSizeS
                            color: Qt.alpha(Color.mOnSurface, 0.65)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: (mainInst?.recentErrors?.length ?? 0) > 0

                        NText {
                            text: t("panel.recent-errors")
                            font.bold: true
                            color: Color.mOnSurface
                        }

                        Repeater {
                            model: mainInst?.recentErrors ?? []

                            delegate: NText {
                                required property var modelData
                                Layout.fillWidth: true
                                text: modelData.message
                                wrapMode: Text.Wrap
                                pointSize: Style.fontSizeS
                                color: Qt.alpha(Color.mOnSurface, 0.75)
                            }
                        }
                    }
                }
            }
        }
    }
}
