import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import "../components"

Page {
    id: root
    title: "Домой"
    background: Item {}
    property var stack
    property string fileName: "home.json"

    Toast { id: toast }
    header: PageHeader {
        title: root.title
        onBackRequested: {
            if (root.StackView.view) root.StackView.view.pop()
            else if (root.stack) root.stack.pop()
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        padding: 20
        topPadding: 12
        contentWidth: availableWidth

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 16
            Label {
                Layout.fillWidth: true
                text: "Сохраните один домашний адрес (Lean-MVP)."
                color: Theme.muted
                wrapMode: Text.Wrap
            }
            InputField {
                id: addrField
                Layout.fillWidth: true
                placeholderText: "Адрес / место"
            }
            Item { implicitHeight: 4 }
            ActionButton {
                text: "Сохранить"
                tone: "primary"
                Layout.fillWidth: true
                onClicked: {
                    var data = { name: "Дом", address: addrField.text.trim() }
                    if (!data.address) {
                        toast.show("Укажи адрес")
                        return
                    }
                    if (Storage.saveJson(root.fileName, [data])) toast.show("Сохранено")
                    else toast.show("Не удалось сохранить")
                }
            }
            ActionButton {
                text: "Маршрут"
                Layout.fillWidth: true
                enabled: addrField.text.trim().length > 0
                onClicked: {
                    if (!Navigator.openRoute(addrField.text.trim(), "transit"))
                        toast.show("Не удалось открыть карты")
                }
            }
            Item { implicitHeight: 6 }
            ActionButton {
                Layout.fillWidth: true
                text: "Сбросить"
                onClicked: {
                    Storage.removeFile(root.fileName)
                    addrField.text = ""
                    toast.show("Сброшено")
                }
            }
        }
    }
    Component.onCompleted: {
        var arr = Storage.loadJson(root.fileName, [])
        if (arr && arr.length > 0) {
            var obj = arr[0]
            if (obj && obj.address) addrField.text = obj.address
        }
    }
}
