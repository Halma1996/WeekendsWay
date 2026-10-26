import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

import App 1.0

import "../components"
import "../utils/StorageHelpers.js" as SH
import "../utils/ContactSync.js" as CS

Page {
    id: root
    title: "К друзьям"
    background: Item {}

    property string fileName: "friends.json"
    property var stack
    ListModel { id: friendsModel }

    Toast { id: toast }

    header: PageHeader {
        title: root.title
        addVisible: true
        onBackRequested: {
            if (root.StackView.view) root.StackView.view.pop()
            else if (root.stack) root.stack.pop()
        }
        onAddRequested: {
            editDlg.titleText = "Добавить друга"
            editDlg.nameValue = ""
            editDlg.phoneValue = ""
            editDlg.addressValue = ""
            editDlg.intercomValue = ""
            editDlg.floorValue = ""
            editDlg.apartmentValue = ""
            editDlg._editIndex = -1
            editDlg.open()
        }
    }

    EditFriendDialog {
        id: editDlg
        property int _editIndex: -1

        onAcceptedWith: function(n, a, intercom, floor, apartment, phone) {
            var item = _editIndex < 0 ? CS.normalizeFriends([{name: n}])[0]
                                      : CS.normalizeFriends([friendsModel.get(_editIndex)])[0]
            item.name = n
            item.address = a
            item.phone = phone
            item.intercom = intercom
            item.floor = floor
            item.apartment = apartment
            if (_editIndex < 0)
                friendsModel.append(item)
            else
                friendsModel.set(_editIndex, item)
            save()
        }
    }

    ContactsSyncDialog {
        id: syncDialog
        onSyncRequested: function(contacts, allContacts) {
            var result = CS.merge(SH.modelToArray(friendsModel), contacts, allContacts)
            if (!Storage.saveJson(root.fileName, result.friends)) {
                resultError = "Не удалось сохранить друзей. Повторите попытку."
                return
            }
            SH.arrayToModel(result.friends, friendsModel)
            close()
            toast.show("Добавлено: " + result.added + ". Обновлено: " + result.updated
                       + ". Без изменений: " + result.unchanged + ".")
        }
    }

    function normalizeFriends(arr) {
        return CS.normalizeFriends(arr)
    }

    function save() {
        var arr = SH.modelToArray(friendsModel)
        arr = normalizeFriends(arr)
        if (!Storage.saveJson(fileName, arr))
            toast.show("Ошибка сохранения")
    }

    function load() {
        var arr = Storage.loadJson(fileName, [])
        arr = normalizeFriends(arr)
        SH.arrayToModel(arr, friendsModel)
    }


    ListView {
        id: listView
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        model: friendsModel
        clip: true
        spacing: 10

        header: Column {
            width: listView.width
            topPadding: 8
            bottomPadding: 12
            spacing: 4

            ActionButton {
                id: contactsSyncButton
                objectName: "openContactsSyncButton"
                width: parent.width
                height: 56
                text: "Синхронизировать контакты"
                font.pixelSize: 15
                tone: "purple"
                enabled: !Contacts.busy
                onClicked: syncDialog.open()
            }
            Label {
                width: parent.width
                text: "Все контакты или только выбранные"
                font.pixelSize: 12
                color: Theme.muted
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

        delegate: Rectangle {
            id: friendCard
            width: ListView.view.width
            height: cardContent.implicitHeight + 24
            radius: 20
            color: Theme.surface
            border.color: Theme.border

            // Keep the expanded state local to each visible card.
            property bool expanded: false
            readonly property bool hasDetails: intercom.length > 0 || floor.length > 0 || apartment.length > 0

            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: cardContent
                x: 12
                y: 12
                width: parent.width - 24
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            text: name
                            font.bold: true
                            font.pixelSize: 17
                            color: Theme.text
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: address || "Добавьте адрес для маршрута"
                            color: Theme.muted
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: phone.length > 0
                            text: phone
                            font.pixelSize: 12
                            color: Theme.muted
                            elide: Text.ElideRight
                        }
                    }

                    IconAction {
                        objectName: "friendTaxiButton"
                        Layout.preferredWidth: 56
                        Layout.minimumWidth: 56
                        Layout.maximumWidth: 56
                        Layout.preferredHeight: 56
                        Layout.minimumHeight: 56
                        display: AbstractButton.IconOnly
                        icon.source: "qrc:/icons/taxi.png"
                        icon.color: "transparent"
                        icon.width: 48
                        icon.height: 48
                        padding: 4
                        Accessible.name: "Вызвать такси к " + name
                        ToolTip.visible: hovered
                        ToolTip.text: "Вызвать такси"
                        enabled: address.trim().length > 0
                        onClicked: {
                            if (!Taxi.request(address))
                                toast.show("Проверьте адрес для такси")
                        }
                    }
                    IconAction {
                        id: routeFriendButton
                        objectName: "friendMapButton"
                        filled: true
                        Layout.preferredWidth: 56
                        Layout.minimumWidth: 56
                        Layout.maximumWidth: 56
                        Layout.preferredHeight: 56
                        Layout.minimumHeight: 56
                        display: AbstractButton.IconOnly
                        icon.source: "qrc:/icons/route.svg"
                        icon.width: 34
                        icon.height: 34
                        padding: 11
                        topInset: 0
                        bottomInset: 0
                        Accessible.name: "Построить маршрут к " + name
                        ToolTip.visible: hovered
                        ToolTip.text: "Построить маршрут"
                        enabled: address.trim().length > 0
                        onClicked: {
                            if (!Navigator.openRoute(address, "transit"))
                                toast.show("Не удалось открыть карты")
                        }
                    }
                    IconAction {
                        objectName: "friendDetailsButton"
                        display: AbstractButton.IconOnly
                        icon.source: "qrc:/icons/edit.png"
                        icon.color: "transparent"
                        icon.width: 36
                        icon.height: 36
                        padding: 6
                        Accessible.name: friendCard.expanded ? "Свернуть карточку" : "Раскрыть карточку"
                        onClicked: friendCard.expanded = !friendCard.expanded
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: friendCard.expanded
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        visible: intercom.length > 0
                        Label {
                            Layout.fillWidth: true
                            text: "Домофон: " + intercom
                            font.pixelSize: 13
                            wrapMode: Text.WrapAnywhere
                        }
                        IconAction {
                            text: "⧉"
                            contentItem: Item {
                                Rectangle {
                                    width: 14; height: 17
                                    x: (parent.width - width) / 2 - 3
                                    y: (parent.height - height) / 2 - 3
                                    radius: 3
                                    color: "transparent"
                                    border.width: 1.5
                                    border.color: Theme.accent
                                }
                                Rectangle {
                                    width: 14; height: 17
                                    x: (parent.width - width) / 2 + 2
                                    y: (parent.height - height) / 2 + 2
                                    radius: 3
                                    color: Theme.surface
                                    border.width: 1.5
                                    border.color: Theme.accent
                                }
                            }
                            Accessible.name: "Скопировать ключ домофона"
                            onClicked: {
                                if (Storage.copyToClipboard(intercom))
                                    toast.show("Ключ домофона скопирован")
                                else
                                    toast.show("Не удалось скопировать ключ")
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: floor.length > 0
                        text: "Этаж: " + floor
                        font.pixelSize: 13
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: apartment.length > 0
                        text: "Квартира: " + apartment
                        font.pixelSize: 13
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: !friendCard.hasDetails
                        text: "Дополнительная информация не указана"
                        color: Theme.muted
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        ActionButton {
                            objectName: "editFriendButton"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            Layout.minimumHeight: 56
                            text: "Изменить"
                            display: AbstractButton.TextBesideIcon
                            icon.source: "qrc:/icons/edit.png"
                            icon.color: "transparent"
                            icon.width: 32
                            icon.height: 32
                            Accessible.name: "Изменить друга " + name
                            font.pixelSize: 13
                            leftPadding: 8
                            rightPadding: 8
                            onClicked: {
                                editDlg.titleText = "Редактировать друга"
                                editDlg.nameValue = name
                                editDlg.phoneValue = phone
                                editDlg.addressValue = address
                                editDlg.intercomValue = intercom
                                editDlg.floorValue = floor
                                editDlg.apartmentValue = apartment
                                editDlg._editIndex = index
                                editDlg.open()
                            }
                        }
                        ActionButton {
                            id: deleteFriendButton
                            tone: "danger"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            Layout.minimumHeight: 56
                            text: "Удалить"
                            display: AbstractButton.TextBesideIcon
                            icon.source: "qrc:/icons/trash.svg"
                            icon.width: 32
                            icon.height: 32
                            font.pixelSize: 13
                            padding: 10
                            leftPadding: 8
                            rightPadding: 8
                            topInset: 0
                            bottomInset: 0
                            Accessible.name: "Удалить друга " + name
                            onClicked: {
                                friendsModel.remove(index)
                                save()
                                toast.show("Удалено")
                            }
                        }
                    }
                }
            }
        }

        footer: Item {
            width: ListView.view ? ListView.view.width : root.width
            height: 140

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 0
                spacing: 8

                Label {
                    width: parent.width
                    color: Theme.muted
                    text: friendsModel.count === 0 ? "Пока нет друзей. Нажми + чтобы добавить." : ""
                    opacity: 0.7
                    wrapMode: Text.Wrap
                }

            }
        }
    }

    Component.onCompleted: load()
}
