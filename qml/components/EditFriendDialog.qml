import QtQuick 2.15
import QtQuick.Controls 2.15

StyledDialog {
    id: dlg
    modal: true
    title: titleText
    standardButtons: Dialog.Ok | Dialog.Cancel
    closePolicy: Popup.CloseOnEscape

    property string titleText: "Добавить друга"
    property string nameValue: ""
    property string phoneValue: ""
    property string addressValue: ""
    property string intercomValue: ""
    property string floorValue: ""
    property string apartmentValue: ""

    signal acceptedWith(string name, string address, string intercom, string floor, string apartment, string phone)

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
                color: Theme.danger
                text: "Укажи имя"
            }
            InputField {
                width: parent.width
                placeholderText: "Имя *"
                text: dlg.nameValue
                onTextChanged: { dlg.nameValue = text; errorText.visible = false }
            }
            InputField {
                width: parent.width
                placeholderText: "Адрес для маршрута"
                text: dlg.addressValue
                onTextChanged: { dlg.addressValue = text; errorText.visible = false }
            }
            InputField {
                width: parent.width
                placeholderText: "Телефон"
                text: dlg.phoneValue
                inputMethodHints: Qt.ImhDialableCharactersOnly
                onTextChanged: dlg.phoneValue = text
            }
            InputField {
                width: parent.width
                placeholderText: "Ключ от домофона / код"
                text: dlg.intercomValue
                onTextChanged: dlg.intercomValue = text
            }
            InputField {
                width: parent.width
                placeholderText: "Этаж"
                text: dlg.floorValue
                inputMethodHints: Qt.ImhDigitsOnly
                onTextChanged: dlg.floorValue = text
            }
            InputField {
                width: parent.width
                placeholderText: "Номер квартиры"
                text: dlg.apartmentValue
                onTextChanged: dlg.apartmentValue = text
            }
            Label {
                width: parent.width
                text: "* Имя обязательно. Адрес нужен для маршрута, его можно добавить позже."
                font.pixelSize: 12
                color: Theme.muted
                wrapMode: Text.Wrap
            }
        }
    }

    onAboutToShow: errorText.visible = false
    onAccepted: {
        var n = nameValue.trim()
        var a = addressValue.trim()
        if (!n) {
            errorText.visible = true
            Qt.callLater(function() { dlg.open() })
            return
        }
        acceptedWith(n, a, intercomValue.trim(), floorValue.trim(), apartmentValue.trim(), phoneValue.trim())
    }
}
