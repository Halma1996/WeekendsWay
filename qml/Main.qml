import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.5

import "pages"

ApplicationWindow {
    id: win
    width: 420
    height: 760
    visible: true
    title: "WeekendsWay"

    Material.theme: Material.Light

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

    Component { id: homePageComponent;    HomePage {} }
    Component { id: friendsPageComponent; FriendsPage {} }
    Component { id: eatPageComponent;     EatPage {} }
}
