import QtQuick 2.15
import QtQuick.Controls 2.15

IconAction {
    id: control

    text: "\u2190"
    font.pixelSize: 30
    Accessible.name: "Назад"

    signal backRequested
    onClicked: backRequested()
}
