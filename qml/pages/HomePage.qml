import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import App 1.0

import "../components"

Page {
    id: root
    title: "Домой"

    property var stack
    property string fileName: "home.json"

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
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: "Сохраните один домашний адрес (Lean-MVP)."
            wrapMode: Text.Wrap
            opacity: 0.8
        }

        TextField {
            id: nameField
            placeholderText: "Название (например, Дом)"
        }

        TextField {
            id: addrField
            width: Math.max(implicitWidth, contentWidth + leftPadding + rightPadding)
            placeholderText: "Адрес / место"

        }

        RowLayout {
            spacing: 12
            width: parent.width

            Button {
                text: "Сохранить"
                Layout.fillWidth: true
                onClicked: {
                    var data = { name: nameField.text.trim(), address: addrField.text.trim() }

                    if (!data.name || !data.address) {
                        toast.show("Заполни название и адрес")
                        return
                    }

                    if (Storage.saveJson(root.fileName, [data])) {
                        toast.show("Сохранено")
                    } else {
                        toast.show("Не удалось сохранить")
                    }
                }
            }

            Button {
                text: "Маршрут"
                Layout.fillWidth: true
                enabled: addrField.text.trim().length > 0
                onClicked: Navigator.openRoute(addrField.text.trim(), "transit")
            }
        }

        Rectangle { height: 1; width: parent.width; color: "#DDDDDD"; opacity: 0.8 }

        Button {
            width: parent.width
            text: "Сбросить"
            onClicked: {
                Storage.removeFile(root.fileName)
                nameField.text = ""
                addrField.text = ""
                toast.show("Сброшено")
            }
        }
    }

    Component.onCompleted: {
        var arr = Storage.loadJson(root.fileName, [])
        if (arr && arr.length > 0) {
            var obj = arr[0]
            if (obj && obj.name) nameField.text = obj.name
            if (obj && obj.address) addrField.text = obj.address
        }
    }
}
