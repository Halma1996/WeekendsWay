import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import "../components"

Page {
    id: root
    implicitWidth: 360
    background: Item {}
    signal goHome()
    signal goFriends()
    signal goEat()

    header: PageHeader { title: "WeekendsWay"; backVisible: false }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        padding: 20
        topPadding: 8
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 14

            BigActionButton {
                Layout.fillWidth: true
                text: "Домой"
                subtitle: "Один адрес • открыть маршрут"
                icon.source: "qrc:/icons/home.png"
                onClicked: root.goHome()
            }
            BigActionButton {
                Layout.fillWidth: true
                text: "К друзьям"
                subtitle: "Список • карточка • маршрут"
                icon.source: "qrc:/icons/friends.png"
                purple: true
                onClicked: root.goFriends()
            }
            BigActionButton {
                Layout.fillWidth: true
                text: "Кушать"
                subtitle: "Список мест • открыть маршрут"
                icon.source: "qrc:/icons/eat.png"
                onClicked: root.goEat()
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: hint.implicitHeight + 32
                radius: 22
                color: Theme.card
                Label {
                    id: hint
                    anchors.fill: parent
                    anchors.margins: 16
                    text: "Выбери место — и построй маршрут в пару касаний."
                    color: Theme.muted
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
            }
            ActionButton {
                objectName: "mapDefaultsButton"
                Layout.fillWidth: true
                visible: Navigator.mapChoiceSupported
                text: "Карты: " + Navigator.defaultMapName
                font.pixelSize: 13
                Accessible.name: "Выбрать приложение карт по умолчанию"
                onClicked: Navigator.chooseDefaultMap()
            }
        }
    }
}
