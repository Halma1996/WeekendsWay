import QtQuick 2.12
import QtQuick.Controls 2.5

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
            text: "Домой"
            subtitle: "Один адрес • открыть маршрут"
            emoji: "🏠"
            onClicked: root.goHome()
        }

        BigActionButton {
            text: "К друзьям"
            subtitle: "Список • карточка • маршрут"
            emoji: "👥"
            onClicked: root.goFriends()
        }

        BigActionButton {
            text: "Кушать"
            subtitle: "Список мест • открыть маршрут"
            emoji: "🍴"
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
