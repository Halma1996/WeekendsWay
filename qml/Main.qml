import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

import "pages"
import "components"

ApplicationWindow {
    id: win
    width: 420
    height: 760
    minimumWidth: 360
    minimumHeight: 640
    visible: true
    title: "WeekendsWay"

    color: Theme.background
    font.pixelSize: 15
    Material.theme: Theme.dark ? Material.Dark : Material.Light
    Material.primary: Theme.background
    Material.accent: Theme.accent
    Material.foreground: Theme.text
    Material.background: Theme.surface
    background: Rectangle {
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.backgroundTop }
            GradientStop { position: 1; color: Theme.background }
        }
    }
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

    BeerSplash {
        anchors.fill: parent
        z: 100
    }

    MapChoiceDialog {}

    Component { id: homePageComponent;    HomePage {} }
    Component { id: friendsPageComponent; FriendsPage {} }
    Component { id: eatPageComponent;     EatPage {} }
}
