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

    property string fileName: "friends.json"
    property var stack
    ListModel { id: friendsModel }

    Toast { id: toast }

    header: ToolBar {
        Material.background: "#00fa19"

        Item {
            anchors.fill: parent
            anchors.margins: 8

            ReturnButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 5

                onBackRequested: {
                        if (root.StackView.view) root.StackView.view.pop()
                        else if (root.stack) root.stack.pop()
                    }
            }

            Label {
                anchors.centerIn: parent
                text: root.title
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }

            ToolButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 5
                text: "+"
                font.pixelSize: 24
                onClicked: {
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
        model: friendsModel
        clip: true
        spacing: 8

        header: Column {
            width: listView.width
            topPadding: 8
            bottomPadding: 12
            spacing: 4

            Button {
                id: contactsSyncButton
                objectName: "openContactsSyncButton"
                x: 16
                width: parent.width - 32
                height: 56
                text: "Синхронизировать контакты"
                font.pixelSize: 15
                highlighted: true
                enabled: !Contacts.busy
                background: Rectangle {
                    radius: 12
                    color: contactsSyncButton.down ? "#10513C" : "#176B50"
                }
                onClicked: syncDialog.open()
            }
            Label {
                x: 16
                width: parent.width - 32
                text: "Все контакты или только выбранные"
                font.pixelSize: 12
                opacity: 0.65
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

        delegate: Rectangle {
            id: friendCard
            x: 16
            width: ListView.view.width - 32
            height: cardContent.implicitHeight + 24
            radius: 12
            color: "#F7F7F7"
            border.color: "#E0E0E0"

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
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: address || "Добавьте адрес для маршрута"
                            opacity: 0.7
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: phone.length > 0
                            text: phone
                            font.pixelSize: 12
                            opacity: 0.7
                            elide: Text.ElideRight
                        }
                    }

                    ToolButton {
                        id: routeFriendButton
                        Layout.preferredWidth: 56
                        Layout.minimumWidth: 56
                        Layout.maximumWidth: 56
                        Layout.preferredHeight: 56
                        Layout.minimumHeight: 56
                        display: AbstractButton.IconOnly
                        icon.source: "qrc:/icons/route.svg"
                        icon.width: 34
                        icon.height: 34
                        icon.color: "#176B50"
                        padding: 11
                        topInset: 0
                        bottomInset: 0
                        background: Rectangle {
                            radius: 14
                            color: routeFriendButton.down ? "#C5E7D7" : "#E0F2E8"
                        }
                        Accessible.name: "Построить маршрут к " + name
                        ToolTip.visible: hovered
                        ToolTip.text: "Построить маршрут"
                        enabled: address.trim().length > 0
                        opacity: enabled ? 1 : 0.35
                        onClicked: {
                            if (!Navigator.openRoute(address, "transit"))
                                toast.show("Не удалось открыть карты")
                        }
                    }
                    ToolButton {
                        text: friendCard.expanded ? "⌃" : "⌄"
                        font.pixelSize: 22
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
                        ToolButton {
                            text: "⧉"
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
                        opacity: 0.65
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            Layout.minimumHeight: 56
                            text: "Изменить"
                            font.pixelSize: 15
                            leftPadding: 12
                            rightPadding: 12
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
                        Button {
                            id: deleteFriendButton
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            Layout.minimumHeight: 56
                            text: "Удалить"
                            display: AbstractButton.TextBesideIcon
                            icon.source: "qrc:/icons/trash.svg"
                            icon.width: 32
                            icon.height: 32
                            icon.color: "#B3261E"
                            font.pixelSize: 16
                            Material.foreground: "#B3261E"
                            padding: 10
                            leftPadding: 12
                            rightPadding: 12
                            topInset: 0
                            bottomInset: 0
                            background: Rectangle {
                                radius: 14
                                color: deleteFriendButton.down ? "#F4C5C0" : "#FCE9E7"
                            }
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
                anchors.margins: 16
                spacing: 8

                Label {
                    text: friendsModel.count === 0 ? "Пока нет друзей. Нажми + чтобы добавить." : ""
                    opacity: 0.7
                    wrapMode: Text.Wrap
                }

                Button {
                    text: "Показать путь AppData"
                    onClicked: toast.show(Storage.appDataPath())
                }
            }
        }
    }

    Component.onCompleted: load()
}
