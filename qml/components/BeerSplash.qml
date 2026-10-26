import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    color: "#FFF8EC"
    visible: opacity > 0
    opacity: 1

    property real toastProgress: 0
    readonly property bool assetsReady: leftMug.status === Image.Ready
                                       && rightMug.status === Image.Ready

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 336)
        spacing: 14

        Item {
            id: scene
            width: parent.width
            height: width * 0.78

            Image {
                id: leftMug
                width: scene.width * 0.38
                height: width * 1.236
                x: scene.width * 0.063 * root.toastProgress
                y: scene.height * 0.25 - 7 * root.toastProgress
                source: "qrc:/beer-mug.png"
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(512, 640)
                asynchronous: true
                mirror: true
                transformOrigin: Item.Bottom
                rotation: 14 * root.toastProgress
            }

            Image {
                id: rightMug
                width: leftMug.width
                height: leftMug.height
                x: scene.width - width - scene.width * 0.063 * root.toastProgress
                y: leftMug.y
                source: leftMug.source
                fillMode: Image.PreserveAspectFit
                sourceSize: leftMug.sourceSize
                asynchronous: true
                transformOrigin: Item.Bottom
                rotation: -14 * root.toastProgress
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: scene.height * 0.31
                width: 1
                height: 1
                opacity: Math.max(0, Math.min(1, (root.toastProgress - 0.88) / 0.12))
                scale: 0.7 + 0.3 * root.toastProgress

                Repeater {
                    model: 3
                    Rectangle {
                        width: 3
                        height: index === 1 ? 15 : 12
                        x: (index - 1) * 14 - width / 2
                        y: index === 1 ? -19 : -12
                        radius: 1.5
                        rotation: (index - 1) * 42
                        color: "#E7A027"
                    }
                }
            }
        }

        Label {
            width: parent.width
            text: "WeekendsWay"
            color: "#392C20"
            font.pixelSize: 26
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            width: parent.width
            text: "Хороших выходных!"
            color: "#876F45"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }
    }

    SequentialAnimation {
        running: root.visible && root.assetsReady
        PauseAnimation { duration: 120 }
        NumberAnimation {
            target: root; property: "toastProgress"; to: 1
            duration: 420; easing.type: Easing.InOutCubic
        }
        PauseAnimation { duration: 90 }
        NumberAnimation {
            target: root; property: "toastProgress"; to: 0.55
            duration: 230; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "toastProgress"; to: 1
            duration: 260; easing.type: Easing.InOutCubic
        }
        PauseAnimation { duration: 100 }
        NumberAnimation {
            target: root; property: "toastProgress"; to: 0.5
            duration: 260; easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: 220 }
        PropertyAction { target: root; property: "opacity"; value: 0 }
    }

    Behavior on opacity { NumberAnimation { duration: 180 } }

    // Keep startup bounded even if the image cannot be decoded.
    Timer {
        interval: 2800
        running: root.visible
        onTriggered: root.opacity = 0
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
    }
}
