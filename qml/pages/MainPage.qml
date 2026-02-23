import QtQuick 2.15
import QtQuick.Controls 2.15

import "../components"

Page {
    id: root
    signal goHome()
    signal goFriends()
    signal goEat()

    header: ToolBar {
        Label {
            anchors.centerIn: parent
            text: "WeekendsWay"
            font.pixelSize: 18
            font.bold: true
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        BigActionButton {
            width: parent.width
            text: "Домой"
            subtitle: "Один адрес • открыть маршрут"
            icon.source: "qrc:/icons/home.svg"
            icon.width: 48
            icon.height: 48
            //emoji: "🏠"
            onClicked: root.goHome()

        }

        BigActionButton {
            width: parent.width
            text: "К друзьям"
            subtitle: "Список • карточка • маршрут"
            icon.source: "qrc:/icons/friends.svg"
            icon.width: 48
            icon.height: 48
            onClicked: root.goFriends()
        }

        BigActionButton {
            width: parent.width
            text: "Кушать"
            subtitle: "Список мест • открыть маршрут"
            icon.source: "qrc:/icons/eat.svg"
            icon.width: 48
            icon.height: 48
            onClicked: root.goEat()
        }

        Rectangle { height: 1; width: parent.width; color: "#DDDDDD"; radius: 1; opacity: 0.8 }

        Label {
            text: "Halma_app: я стараюсь, все будет работать, но это не точно"
            //text: "Lean-MVP: все маршруты открываются во внешнем навигаторе. Карты внутри приложения — позже."
            wrapMode: Text.Wrap
            opacity: 0.75
        }
    }
}
