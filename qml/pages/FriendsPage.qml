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
                    editDlg._editIndex = -1
                    editDlg.open()
                }
            }
        }
    }

    EditItemDialog {
        id: editDlg
        property int _editIndex: -1

        onAcceptedWith: function(n, a) {
            if (_editIndex < 0) {
                friendsModel.append({ name: n, address: a })
            } else {
                friendsModel.set(_editIndex, { name: n, address: a })
            }
            save()
            toast.show("Сохранено")
        }
    }

    function save() {
        var arr = SH.modelToArray(friendsModel)
        arr = SH.normalizeNameAddressArray(arr)
        Storage.saveJson(fileName, arr)
    }

    function load() {
        var arr = Storage.loadJson(fileName, [])
        arr = SH.normalizeNameAddressArray(arr)
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
            x: 16
            width: ListView.view.width - 32
            height: 72
            radius: 12
            color: "#F7F7F7"
            border.color: "#E0E0E0"

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Column {
                    width: parent.width - routeBtn.width - editBtn.width - delBtn.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Label { text: name; font.bold: true; elide: Text.ElideRight }
                    Label { text: address; opacity: 0.7; font.pixelSize: 12; elide: Text.ElideRight }
                }

                ToolButton {
                    id: routeBtn
                    text: "🧭"
                    onClicked: Navigator.openRoute(address, "transit")
                }

                ToolButton {
                    id: editBtn
                    text: "✏️"
                    onClicked: {
                        editDlg.titleText = "Редактировать друга"
                        editDlg.nameValue = name
                        editDlg.addressValue = address
                        editDlg._editIndex = index
                        editDlg.open()
                    }
                }

                ToolButton {
                    id: delBtn
                    text: "🗑️"
                    onClicked: {
                        friendsModel.remove(index)
                        save()
                        toast.show("Удалено")
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
