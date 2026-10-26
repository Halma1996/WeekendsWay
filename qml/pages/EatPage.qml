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
    background: Item {}

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

    header: PageHeader {
        title: root.title
        addVisible: true
        onBackRequested: {
            if (root.StackView.view) root.StackView.view.pop()
            else if (root.stack) root.stack.pop()
        }
        onAddRequested: {
            editDlg.titleText = "Добавить место"
            editDlg.nameValue = ""
            editDlg.addressValue = ""
            editDlg._editIndex = -1
            editDlg.open()
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
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        model: venuesModel
        clip: true
        spacing: 8

        // небольшой верхний отступ
        header: Item { width: 1; height: 16 }

        delegate: Rectangle {
            width: ListView.view.width
            height: Math.max(88, venueRow.implicitHeight + 24)
            radius: 20
            color: Theme.surface
            border.color: Theme.border

            RowLayout {
                id: venueRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 4
                    Label {
                        Layout.fillWidth: true
                        text: name
                        color: Theme.text
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: address === name ? "Найти на карте" : address
                        color: Theme.muted
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
                IconAction {
                    id: routeBtn
                    objectName: "venueMapButton"
                    Layout.preferredWidth: 44
                    Layout.minimumWidth: 44
                    Layout.maximumWidth: 44
                    filled: true
                    display: AbstractButton.IconOnly
                    icon.source: "qrc:/icons/route.svg"
                    icon.width: 26
                    icon.height: 26
                    padding: 9
                    Accessible.name: address === name ? "Найти " + name + " на карте" : "Построить маршрут к " + name
                    onClicked: {
                        var opened = address === name ? Navigator.openSearch(name)
                                                      : Navigator.openRoute(address, "walking")
                        if (!opened) toast.show("Не удалось открыть карты")
                    }
                }
                IconAction {
                    id: editBtn
                    Layout.preferredWidth: 44
                    Layout.minimumWidth: 44
                    Layout.maximumWidth: 44
                    text: "✎"
                    Accessible.name: "Изменить место " + name
                    onClicked: {
                        editDlg.titleText = "Редактировать место"
                        editDlg.nameValue = name
                        editDlg.addressValue = address
                        editDlg._editIndex = index
                        editDlg.open()
                    }
                }
                IconAction {
                    id: delBtn
                    objectName: "deleteVenueButton"
                    Layout.preferredWidth: 44
                    Layout.minimumWidth: 44
                    Layout.maximumWidth: 44
                    destructive: true
                    display: AbstractButton.IconOnly
                    icon.source: "qrc:/icons/trash.svg"
                    icon.width: 24
                    icon.height: 24
                    Accessible.name: "Удалить место " + name
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
                anchors.margins: 0
                spacing: 8

                Label {
                    width: parent.width
                    color: Theme.muted
                    text: venuesModel.count === 0 ? "Пока нет мест. Нажми + чтобы добавить." : ""
                    opacity: 0.7
                    wrapMode: Text.Wrap
                }

                ActionButton {
                    text: "Показать путь AppData"
                    onClicked: toast.show(Storage.appDataPath())
                }
            }
        }
    }

    Component.onCompleted: load()
}
