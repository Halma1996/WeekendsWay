import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0

StyledDialog {
    id: dlg
    objectName: "mapChoiceDialog"
    modal: true
    closePolicy: Popup.CloseOnEscape
    title: Navigator.choosingDefaultMap ? "Карты по умолчанию" : "Открыть в картах"

    Connections {
        target: Navigator
        function onMapChoiceRequested() {
            rememberChoice.checked = false
            dlg.open()
        }
        function onMapChoiceFinished() { dlg.close() }
    }
    onClosed: Navigator.cancelMapChoice()

    contentItem: ScrollView {
        id: scroll
        implicitHeight: choices.implicitHeight
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: choices
            width: scroll.availableWidth
            spacing: 10
            Label {
                Layout.fillWidth: true
                text: Navigator.choosingDefaultMap
                    ? "Выберите приложение для маршрутов и поиска мест."
                    : Navigator.mapChoiceDestination
                color: Theme.muted
                font.pixelSize: 14
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            Label {
                objectName: "noMapAppsLabel"
                Layout.fillWidth: true
                visible: Navigator.mapApps.length === 0
                text: "Нет доступных приложений карт. Установите или включите Яндекс Карты, Google Maps или 2ГИС."
                color: Theme.text
                wrapMode: Text.Wrap
            }
            Repeater {
                model: Navigator.mapApps
                delegate: ActionButton {
                    id: mapButton
                    objectName: "chooseMap_" + modelData.id
                    Layout.fillWidth: true
                    Layout.preferredHeight: labels.implicitHeight + 26
                    tone: Navigator.choosingDefaultMap && Navigator.defaultMapApp === modelData.id ? "primary" : "secondary"
                    text: modelData.name
                    Accessible.name: modelData.name
                    contentItem: Item {
                        implicitWidth: 180
                        implicitHeight: labels.implicitHeight
                        Column {
                            id: labels
                            width: parent.width
                            spacing: 5
                            Label {
                                width: parent.width
                                text: modelData.name + (Navigator.defaultMapApp === modelData.id ? " · по умолчанию" : "")
                                color: mapButton.filled ? Theme.accentText : Theme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                wrapMode: Text.Wrap
                            }
                            Label {
                                width: parent.width
                                visible: modelData.note.length > 0
                                text: modelData.note
                                color: Theme.muted
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                    onClicked: Navigator.selectMapApp(modelData.id, rememberChoice.checked)
                }
            }
            CheckBox {
                id: rememberChoice
                objectName: "rememberMapChoice"
                Layout.fillWidth: true
                visible: !Navigator.choosingDefaultMap && Navigator.mapApps.length > 0
                text: "Использовать по умолчанию"
                font.pixelSize: 13
            }
            ActionButton {
                objectName: "alwaysAskMapButton"
                Layout.fillWidth: true
                visible: Navigator.choosingDefaultMap
                text: "Всегда спрашивать"
                tone: Navigator.defaultMapApp.length === 0 ? "primary" : "secondary"
                onClicked: Navigator.alwaysAskForMap()
            }
            Label {
                Layout.fillWidth: true
                visible: Navigator.mapChoiceError.length > 0
                text: Navigator.mapChoiceError
                color: Theme.danger
                font.pixelSize: 13
                wrapMode: Text.Wrap
            }
        }
    }
    footer: Item {
        implicitHeight: 68
        ActionButton {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 6
            anchors.bottomMargin: 10
            text: "Отмена"
            onClicked: Navigator.cancelMapChoice()
        }
    }
}
