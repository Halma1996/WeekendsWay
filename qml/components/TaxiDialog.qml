import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0

StyledDialog {
    id: dlg
    objectName: "taxiDialog"
    modal: true
    closePolicy: Popup.CloseOnEscape
    title: "Вызвать такси"

    Connections {
        target: Taxi
        function onRequested() {
            addressField.text = Taxi.destination
            dlg.open()
        }
        function onFinished() { dlg.close() }
    }
    onClosed: Taxi.cancel()

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
                text: "Проверьте адрес назначения. Для сети заведений укажите нужный филиал. Заказ подтверждается в Яндекс Go."
                color: Theme.muted
                wrapMode: Text.Wrap
                font.pixelSize: 13
            }
            InputField {
                id: addressField
                objectName: "taxiAddressField"
                Layout.fillWidth: true
                placeholderText: "Город, улица и дом"
                enabled: !Taxi.busy
                onAccepted: if (displayText.trim().length > 0) Taxi.search(displayText)
            }
            ActionButton {
                objectName: "searchTaxiAddressButton"
                Layout.fillWidth: true
                text: "Найти адрес"
                enabled: !Taxi.busy && addressField.displayText.trim().length > 0
                onClicked: Taxi.search(addressField.displayText)
            }
            Label {
                objectName: "taxiSearchingLabel"
                Layout.fillWidth: true
                visible: Taxi.busy
                text: "Ищем адрес…"
                color: Theme.muted
                wrapMode: Text.Wrap
            }
            Label {
                Layout.fillWidth: true
                visible: Taxi.candidates.length > 0
                text: "Выберите конечную точку:"
                color: Theme.text
                wrapMode: Text.Wrap
            }
            Repeater {
                model: Taxi.candidates
                delegate: ActionButton {
                    id: pointButton
                    objectName: "taxiDestination_" + index
                    Layout.fillWidth: true
                    Layout.preferredHeight: pointLabel.implicitHeight + 28
                    text: modelData.label
                    Accessible.name: "Открыть Яндекс Go: " + modelData.label
                    enabled: !Taxi.busy
                    contentItem: Label {
                        id: pointLabel
                        text: pointButton.text
                        font.pixelSize: 14
                        color: Theme.text
                        wrapMode: Text.Wrap
                    }
                    onClicked: Taxi.selectDestination(index)
                }
            }
            Label {
                objectName: "taxiErrorLabel"
                Layout.fillWidth: true
                visible: Taxi.error.length > 0
                text: Taxi.error
                color: Theme.danger
                wrapMode: Text.Wrap
                font.pixelSize: 13
            }
        }
    }
    footer: Item {
        implicitHeight: 68
        ActionButton {
            objectName: "cancelTaxiButton"
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 6
            anchors.bottomMargin: 10
            text: "Отмена"
            onClicked: Taxi.cancel()
        }
    }
}
