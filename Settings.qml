import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    readonly property var mainInst: pluginApi?.mainInstance ?? null

    property bool valueEnabled: pluginApi?.pluginSettings?.enabled ?? true
    property string valueApiUrl: pluginApi?.pluginSettings?.apiUrl ?? ""
    property string valueApiKey: pluginApi?.pluginSettings?.apiKey ?? ""
    property string valueConfigPath: pluginApi?.pluginSettings?.configPath ?? ""
    property bool valueVerifyTls: pluginApi?.pluginSettings?.verifyTls ?? false
    property int valuePollIntervalMs: pluginApi?.pluginSettings?.pollIntervalMs ?? 10000
    property string valueLanguage: pluginApi?.pluginSettings?.language ?? "auto"
    property var valueFolderIds: {
        const raw = pluginApi?.pluginSettings?.folderIds ?? [];
        try {
            return Array.from(raw);
        } catch (e) {
            return [];
        }
    }

    property int _langVersion: 0

    Connections {
        target: pluginApi?.mainInstance ?? null
        function onTranslationVersionChanged() {
            root._langVersion++;
        }
    }

    function t(key) {
        if (_langVersion < 0) return undefined;
        return pluginApi?.mainInstance?.translate(key);
    }

    function sourceLabel(code) {
        return pluginApi?.mainInstance?.sourceLabel(code) ?? code;
    }

    function isFolderSelected(folderId) {
        return valueFolderIds.indexOf(folderId) >= 0;
    }

    function toggleFolder(folderId) {
        const updated = Array.from(valueFolderIds);
        const index = updated.indexOf(folderId);
        if (index >= 0) {
            updated.splice(index, 1);
        } else {
            updated.push(folderId);
        }
        valueFolderIds = updated;
    }

    function saveSettings(triggerRefresh) {
        if (!pluginApi) return;
        pluginApi.pluginSettings.enabled = valueEnabled;
        pluginApi.pluginSettings.apiUrl = valueApiUrl.trim();
        pluginApi.pluginSettings.apiKey = valueApiKey.trim();
        pluginApi.pluginSettings.configPath = valueConfigPath.trim();
        pluginApi.pluginSettings.verifyTls = valueVerifyTls;
        pluginApi.pluginSettings.pollIntervalMs = valuePollIntervalMs;
        pluginApi.pluginSettings.folderIds = Array.from(valueFolderIds);
        pluginApi.pluginSettings.language = valueLanguage;
        pluginApi.saveSettings();
        pluginApi?.mainInstance?.reloadLanguage(valueLanguage);
        if (triggerRefresh) {
            pluginApi?.mainInstance?.requestPoll(true);
        }
    }

    spacing: Style.marginM

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: t("settings.language")
            description: t("settings.language-desc")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Repeater {
                model: ["auto", "en", "pt"]

                delegate: Rectangle {
                    required property string modelData
                    readonly property string langCode: modelData
                    readonly property bool isSelected: root.valueLanguage === langCode
                    readonly property string langLabel: {
                        if (langCode === "auto") return root.t("settings.lang-auto");
                        if (langCode === "en") return root.t("settings.lang-en");
                        return root.t("settings.lang-pt");
                    }

                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Style.iRadiusM
                    color: isSelected ? Qt.alpha(Color.mPrimary, 0.15) : Color.mSurfaceVariant
                    border.color: isSelected ? Color.mPrimary : (langMouse.containsMouse ? Color.mOutline : "transparent")
                    border.width: isSelected ? 2 : 1

                    NText {
                        anchors.centerIn: parent
                        text: parent.langLabel
                        font.bold: parent.isSelected
                        color: parent.isSelected ? Color.mPrimary : Color.mOnSurface
                    }

                    MouseArea {
                        id: langMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.valueLanguage = parent.langCode;
                        }
                    }
                }
            }
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: t("settings.enabled")
        description: t("settings.enabled-desc")
        checked: root.valueEnabled
        onToggled: checked => root.valueEnabled = checked
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: t("settings.url")
            description: t("settings.url-desc")
        }

        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: Style.radiusM
            color: Color.mSurfaceVariant
            border.color: urlField.activeFocus ? Color.mPrimary : Color.mOutline
            border.width: 1

            TextInput {
                id: urlField
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Color.mOnSurface
                selectionColor: Color.mPrimary
                selectedTextColor: Color.mOnPrimary
                clip: true
                text: root.valueApiUrl
                onTextChanged: root.valueApiUrl = text

                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "http://127.0.0.1:8384"
                    visible: !urlField.text && !urlField.activeFocus
                    opacity: 0.4
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: t("settings.api-key")
            description: t("settings.api-key-desc")
        }

        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: Style.radiusM
            color: Color.mSurfaceVariant
            border.color: apiField.activeFocus ? Color.mPrimary : Color.mOutline
            border.width: 1

            TextInput {
                id: apiField
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Color.mOnSurface
                selectionColor: Color.mPrimary
                selectedTextColor: Color.mOnPrimary
                clip: true
                echoMode: TextInput.Password
                text: root.valueApiKey
                onTextChanged: root.valueApiKey = text

                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "X-API-Key"
                    visible: !apiField.text && !apiField.activeFocus
                    opacity: 0.4
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: t("settings.config-path")
            description: t("settings.config-path-desc")
        }

        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: Style.radiusM
            color: Color.mSurfaceVariant
            border.color: pathField.activeFocus ? Color.mPrimary : Color.mOutline
            border.width: 1

            TextInput {
                id: pathField
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Color.mOnSurface
                selectionColor: Color.mPrimary
                selectedTextColor: Color.mOnPrimary
                clip: true
                text: root.valueConfigPath
                onTextChanged: root.valueConfigPath = text

                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "~/.local/state/syncthing/config.xml"
                    visible: !pathField.text && !pathField.activeFocus
                    opacity: 0.4
                }
            }
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: t("settings.verify-tls")
        description: t("settings.verify-tls-desc")
        checked: root.valueVerifyTls
        onToggled: checked => root.valueVerifyTls = checked
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: t("settings.poll-interval") + ": " + Math.round(root.valuePollIntervalMs / 1000) + "s"
            description: t("settings.poll-interval-desc")
        }

        NSlider {
            Layout.fillWidth: true
            from: 2000
            to: 60000
            value: root.valuePollIntervalMs
            stepSize: 1000
            onMoved: root.valuePollIntervalMs = Math.round(value)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: t("settings.folders")
            description: t("settings.folders-desc")
        }

        Flow {
            Layout.fillWidth: true
            spacing: Style.marginS

            Repeater {
                model: mainInst?.availableFolders ?? []

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isSelected: root.isFolderSelected(modelData.id)

                    width: chipLabel.implicitWidth + 22
                    height: 30
                    radius: 15
                    color: isSelected ? Qt.alpha(Color.mPrimary, 0.15) : Color.mSurfaceVariant
                    border.color: isSelected ? Color.mPrimary : Color.mOutline
                    border.width: 1

                    NText {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        font.bold: parent.isSelected
                        color: parent.isSelected ? Color.mPrimary : Color.mOnSurface
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleFolder(parent.modelData.id)
                    }
                }
            }
        }

        NText {
            text: t("settings.no-folders")
            visible: (mainInst?.availableFolders?.length ?? 0) === 0
            wrapMode: Text.Wrap
            color: Qt.alpha(Color.mOnSurface, 0.65)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        Rectangle {
            Layout.preferredWidth: saveLabel.width + 24
            Layout.preferredHeight: 32
            radius: Style.radiusM
            color: saveMouse.containsMouse ? Qt.darker(Color.mPrimary, 1.1) : Color.mPrimary

            NText {
                id: saveLabel
                anchors.centerIn: parent
                text: t("settings.save")
                color: Color.mOnPrimary
            }

            MouseArea {
                id: saveMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.saveSettings(false);
                    saveStatus.text = root.t("settings.saved");
                    saveStatusTimer.restart();
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: refreshLabel.width + 24
            Layout.preferredHeight: 32
            radius: Style.radiusM
            color: refreshMouse.containsMouse ? Color.mOutline : Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: 1

            NText {
                id: refreshLabel
                anchors.centerIn: parent
                text: t("settings.refresh")
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.saveSettings(true);
                    saveStatus.text = root.t("settings.saved");
                    saveStatusTimer.restart();
                }
            }
        }

        NText {
            id: saveStatus
            text: ""
            opacity: 0.7
        }
    }

    Timer {
        id: saveStatusTimer
        interval: 2000
        onTriggered: saveStatus.text = ""
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        spacing: 4

        NText {
            text: t("settings.status")
            font.bold: true
        }

        NText {
            text: mainInst?.stateLabel(mainInst.enabled ? mainInst.state : "disabled") ?? ""
            color: mainInst ? mainInst.statusColor(mainInst.enabled ? mainInst.state : "disabled") : Color.mOutline
        }

        NText {
            text: mainInst?.statusSummary() ?? ""
            wrapMode: Text.Wrap
            color: Qt.alpha(Color.mOnSurface, 0.75)
        }

        NText {
            text: t("panel.url") + ": " + (mainInst?.resolvedUrl || "-")
            pointSize: Style.fontSizeS
            color: Qt.alpha(Color.mOnSurface, 0.6)
            elide: Text.ElideRight
        }

        NText {
            text: t("panel.api-source") + ": " + root.sourceLabel(mainInst?.apiKeySource ?? "none")
            pointSize: Style.fontSizeS
            color: Qt.alpha(Color.mOnSurface, 0.6)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        spacing: 4

        NText {
            text: t("settings.about")
            font.bold: true
        }

        NText {
            text: t("settings.developer")
            wrapMode: Text.Wrap
            color: Qt.alpha(Color.mOnSurface, 0.75)
        }

        NText {
            text: t("settings.translation-mode")
            wrapMode: Text.Wrap
            color: Qt.alpha(Color.mOnSurface, 0.6)
        }
    }
}
