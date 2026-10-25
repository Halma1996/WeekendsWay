import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import App 1.0

import "../components"
import "../utils/StorageHelpers.js" as SH

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

        onAcceptedWith: function(n, a, intercom, floor, apartment) {
            var item = { name: n, address: a, intercom: intercom,
                         floor: floor, apartment: apartment }
            if (_editIndex < 0)
                friendsModel.append(item)
            else
                friendsModel.set(_editIndex, item)
            save()
        }
    }

    function normalizeFriends(arr) {
        var result = []
        if (!arr || arr.length === undefined) return result
        for (var i = 0; i < arr.length; ++i) {
            var item = arr[i]
            if (!item) continue
            var n = String(item.name === undefined ? "" : item.name).trim()
            var a = String(item.address === undefined ? "" : item.address).trim()
            if (!n && !a) continue
            result.push({
                name: n, address: a,
                intercom: String(item.intercom == null ? "" : item.intercom),
                floor: String(item.floor == null ? "" : item.floor),
                apartment: String(item.apartment == null ? "" : item.apartment)
            })
        }
        return result
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

        // небольшой верхний отступ
        header: Item { width: 1; height: 16 }

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
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            text: name
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: address
                            opacity: 0.7
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    ToolButton {
                        text: "🧭"
                        Accessible.name: "Построить маршрут к " + name
                        onClicked: {
                            if (!Navigator.openRoute(address, "transit"))
                                toast.show("Не удалось открыть карты")
                        }
                    }
                    ToolButton {
                        text: friendCard.expanded ? "⌃" : "⌄"
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
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "Изменить"
                            onClicked: {
                                editDlg.titleText = "Редактировать друга"
                                editDlg.nameValue = name
                                editDlg.addressValue = address
                                editDlg.intercomValue = intercom
                                editDlg.floorValue = floor
                                editDlg.apartmentValue = apartment
                                editDlg._editIndex = index
                                editDlg.open()
                            }
                        }
                        Button {
                            text: "Удалить"
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
