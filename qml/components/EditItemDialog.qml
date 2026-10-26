import QtQuick 2.15
import QtQuick.Controls 2.15

StyledDialog {
    id: dlg
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    closePolicy: Popup.CloseOnEscape

    // Generic "item editor" for { name, address }
    property string titleText: "Edit item"
    property string nameValue: ""
    property string addressValue: ""

    signal acceptedWith(string name, string address)

    title: titleText

    contentItem: Column {
        width: dlg.availableWidth
        spacing: 12

        Label {
            id: errorText
            width: parent.width
            visible: false
            text: "Заполни оба поля"
            color: Theme.danger
            wrapMode: Text.Wrap
        }

        InputField {
            id: nameField
            width: parent.width
            placeholderText: "Название"
            text: dlg.nameValue
            onTextChanged: {
                dlg.nameValue = text
                errorText.visible = false
            }
        }

        InputField {
            id: addrField
            width: parent.width
            placeholderText: "Адрес / место"
            text: dlg.addressValue
            onTextChanged: {
                dlg.addressValue = text
                errorText.visible = false
            }
        }

        Label {
            width: parent.width
            text: "Подсказка: можно вводить адрес, название места или координаты (например: 60.1699, 24.9384)."
            wrapMode: Text.Wrap
            color: Theme.muted
            font.pixelSize: 12
        }
    }

    onAboutToShow: errorText.visible = false

    onAccepted: {
        const n = (nameValue || "").trim()
        const a = (addressValue || "").trim()
        if (n.length === 0 || a.length === 0) {
            errorText.visible = true
            Qt.callLater(function() { dlg.open() })
            return
        }
        acceptedWith(n, a)
    }
}
