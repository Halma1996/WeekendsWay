import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import App 1.0
import "../components"

Page {
    id: root
    title: "Кушать"

    property string fileName: "venues.json"
    property var stack
    ListModel { id: venuesModel }

    Toast { id: toast }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            ToolButton {
                text: "\u25C0"
                onClicked: if (root.stack) root.stack.pop()
            }

            Label {
                text: root.title
                font.pixelSize: 18
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            ToolButton {
                text: "+"
                onClicked: {
                    editDlg.titleText = "Добавить место"
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
                venuesModel.append({ name: n, address: a })
            } else {
                venuesModel.set(_editIndex, { name: n, address: a })
            }
            save()
            toast.show("Сохранено")
        }
    }

    function save() {
        var arr = []
        for (var i = 0; i < venuesModel.count; ++i) {
            var it = venuesModel.get(i)
            var n = it && it.name !== undefined ? ("" + it.name).trim() : ""
            var a = it && it.address !== undefined ? ("" + it.address).trim() : ""

            if (n.length > 0 || a.length > 0) {
                arr.push({ name: n, address: a })
            }
        }
        Storage.saveJson(fileName, arr)
    }

    function load() {
        venuesModel.clear()
        var arr = Storage.loadJson(fileName, [])
        if (!arr || arr.length === undefined) return

        for (var i = 0; i < arr.length; ++i) {
            var it = arr[i]
            if (!it) continue
            if (it && it.name && it.address) {
                venuesModel.append({ name: it.name, address: it.address })
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: venuesModel
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
                    onClicked: Navigator.openRoute(address, "walking")
                }

                ToolButton {
                    id: editBtn
                    text: "✏️"
                    onClicked: {
                        editDlg.titleText = "Редактировать место"
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
                        venuesModel.remove(index)
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
                    text: venuesModel.count === 0 ? "Пока нет мест. Нажми + чтобы добавить." : ""
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
