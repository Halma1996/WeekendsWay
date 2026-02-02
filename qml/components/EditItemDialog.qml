import QtQuick 2.15
import QtQuick.Controls 2.15

Dialog {
    id: dlg
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    // Generic "item editor" for { name, address }
    property string titleText: "Edit item"
    property string nameValue: ""
    property string addressValue: ""

    signal acceptedWith(string name, string address)

    title: titleText
    width: Math.min(420, parent ? parent.width * 0.92 : 420)

    Column {
        spacing: 12
        padding: 16

        Label {
            id: errorText
            visible: false
            text: "Заполни оба поля"
            color: "#B00020"
            wrapMode: Text.Wrap
        }

        TextField {
            id: nameField
            placeholderText: "Название"
            text: dlg.nameValue
            onTextChanged: {
                dlg.nameValue = text
                errorText.visible = false
            }
        }

        TextField {
            id: addrField
            placeholderText: "Адрес / место"
            text: dlg.addressValue
            onTextChanged: {
                dlg.addressValue = text
                errorText.visible = false
            }
        }

        Label {
            text: "Подсказка: можно вводить адрес, название места или координаты (например: 60.1699, 24.9384)."
            wrapMode: Text.Wrap
            opacity: 0.65
            font.pixelSize: 12
        }
    }

    onAccepted: {
        const n = (nameValue || "").trim()
        const a = (addressValue || "").trim()
        if (n.length === 0 || a.length === 0) {
            errorText.visible = true
            Qt.callLater(function(){ dlg.open() })
            return
        }
        acceptedWith(n, a)
    }
}
