import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

import "pages"

ApplicationWindow {
    id: win
    width: 420
    height: 760
    minimumWidth: 360
    minimumHeight: 640
    visible: true
    title: "WeekendsWay"

    Material.theme: Material.Light
    Material.primary: "#00fa9e"
    StackView {
        id: stack
        anchors.fill: parent
        initialItem: mainPageComponent
    }

    Component {
        id: mainPageComponent
        MainPage {
            onGoHome:    stack.push(homePageComponent,    { stack: stack })
            onGoFriends: stack.push(friendsPageComponent, { stack: stack })
            onGoEat:     stack.push(eatPageComponent,     { stack: stack })
        }
    }

    // A lightweight startup animation. The main UI remains ready behind it.
    Rectangle {
        id: splash
        anchors.fill: parent
        z: 100
        color: "#17171b"
        visible: opacity > 0
        opacity: 1

        Column {
            anchors.centerIn: parent
            spacing: 24

            Image {
                id: catsImage
                width: Math.min(win.width * 0.65, 260)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/cats-loading.jpg"
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: 512
                sourceSize.height: 512
                transform: Rotation {
                    origin.x: catsImage.width / 2
                    origin.y: catsImage.height / 2
                    NumberAnimation on angle {
                        from: 0
                        to: 360
                        duration: 1800
                        loops: Animation.Infinite
                        running: splash.visible
                    }
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "WeekendsWay"
                color: "white"
                font.pixelSize: 22
            }
        }

        Timer {
            interval: 1800
            running: true
            repeat: false
            onTriggered: splash.opacity = 0
        }
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }

    Component { id: homePageComponent;    HomePage {} }
    Component { id: friendsPageComponent; FriendsPage {} }
    Component { id: eatPageComponent;     EatPage {} }
}
