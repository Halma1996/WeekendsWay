import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

import App 1.0

import "../components"
import "../utils/StorageHelpers.js" as SH

Page {
    id: root
    title: "Кушать"

    property string fileName: "venues.json"
    property string defaultsFileName: "venues-defaults.json"
    property var stack
    readonly property var standardPlaces: [
        "Вкусно и точка",
        "Rostic's",
        "Burger King",
        "Papa John's",
        "Pizza Hut",
        "Додо Пицца"
    ]
    ListModel { id: venuesModel }

    Toast { id: toast }

    header: ToolBar {
        Material.background: "#faa700"
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
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            ToolButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 5
                text: "+"
                font.pixelSize: 24
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
        var arr = SH.modelToArray(venuesModel)
        arr = SH.normalizeNameAddressArray(arr)
        if (!Storage.saveJson(fileName, arr))
            toast.show("Ошибка сохранения")
    }

    function load() {
        var arr = Storage.loadJson(fileName, [])
        arr = SH.normalizeNameAddressArray(arr)
        var defaultsState = Storage.loadJson(defaultsFileName, {})
        if (!defaultsState || defaultsState.version !== 1) {
            var existing = Object.create(null)
            function placeKey(name) {
                return String(name || "").toLocaleLowerCase().replace(/[\s'’\-—]/g, "")
            }
            for (var i = 0; i < arr.length; ++i)
                existing[placeKey(arr[i].name)] = true
            for (var j = 0; j < standardPlaces.length; ++j) {
                var name = standardPlaces[j]
                if (!existing[placeKey(name)]) {
                    // A chain name opens a map search; no particular branch is assumed.
                    arr.push({ name: name, address: name })
                    existing[placeKey(name)] = true
                }
            }
            if (Storage.saveJson(fileName, arr)) {
                if (!Storage.saveJson(defaultsFileName, { version: 1 }))
                    toast.show("Не удалось сохранить настройки стандартных мест")
            } else {
                toast.show("Не удалось сохранить стандартные места")
            }
        }
        SH.arrayToModel(arr, venuesModel)
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

                    Label { width: parent.width; text: name; font.bold: true; elide: Text.ElideRight }
                    Label {
                        width: parent.width
                        text: address === name ? "Найти на карте" : address
                        opacity: 0.7
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                ToolButton {
                    id: routeBtn
                    objectName: "venueMapButton"
                    text: "🧭"
                    Accessible.name: address === name ? "Найти " + name + " на карте" : "Построить маршрут к " + name
                    onClicked: {
                        var opened = address === name ? Navigator.openSearch(name)
                                                      : Navigator.openRoute(address, "walking")
                        if (!opened)
                            toast.show("Не удалось открыть карты")
                    }
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
                    objectName: "deleteVenueButton"
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
