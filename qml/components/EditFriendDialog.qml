import QtQuick 2.15
import QtQuick.Controls 2.15

Dialog {
    id: dlg
    modal: true
    title: titleText
    standardButtons: Dialog.Ok | Dialog.Cancel
    closePolicy: Popup.CloseOnEscape
    width: Math.min(440, parent ? parent.width * 0.94 : 440)

    property string titleText: "Добавить друга"
    property string nameValue: ""
    property string addressValue: ""
    property string intercomValue: ""
    property string floorValue: ""
    property string apartmentValue: ""

    signal acceptedWith(string name, string address, string intercom, string floor, string apartment)

    contentItem: Flickable {
        implicitHeight: Math.min(fields.implicitHeight + 24, 390)
        contentHeight: fields.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: fields
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 10

            Label {
                id: errorText
                width: parent.width
                visible: false
                color: "#B00020"
                text: "Укажи имя и адрес"
            }
            TextField {
                width: parent.width
                placeholderText: "Имя *"
                text: dlg.nameValue
                onTextChanged: { dlg.nameValue = text; errorText.visible = false }
            }
            TextField {
                width: parent.width
                placeholderText: "Адрес *"
                text: dlg.addressValue
                onTextChanged: { dlg.addressValue = text; errorText.visible = false }
            }
            TextField {
                width: parent.width
                placeholderText: "Ключ от домофона / код"
                text: dlg.intercomValue
                onTextChanged: dlg.intercomValue = text
            }
            TextField {
                width: parent.width
                placeholderText: "Этаж"
                text: dlg.floorValue
                inputMethodHints: Qt.ImhDigitsOnly
                onTextChanged: dlg.floorValue = text
            }
            TextField {
                width: parent.width
                placeholderText: "Номер квартиры"
                text: dlg.apartmentValue
                onTextChanged: dlg.apartmentValue = text
            }
            Label {
                width: parent.width
                text: "* Обязательные поля. Остальные можно заполнить позже."
                font.pixelSize: 12
                opacity: 0.65
                wrapMode: Text.Wrap
            }
        }
    }

    onAboutToShow: errorText.visible = false
    onAccepted: {
        var n = nameValue.trim()
        var a = addressValue.trim()
        if (!n || !a) {
            errorText.visible = true
            Qt.callLater(function() { dlg.open() })
            return
        }
        acceptedWith(n, a, intercomValue.trim(), floorValue.trim(), apartmentValue.trim())
    }
}
