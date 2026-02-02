import QtQuick 2.15
import QtQuick.Controls 2.15

Popup {
    id: root
    modal: false
    focus: false
    closePolicy: Popup.NoAutoClose

    // Текст уведомления
    property string message: ""
    // Длительность показа (мс)
    property int duration: 1800

    // Позиция (низ по центру)
    x: (parent ? (parent.width - width) / 2 : 0)
    y: (parent ? parent.height - height - 24 : 0)

    padding: 10

    background: Rectangle {
        radius: 10
        color: "#323232"
        opacity: 0.92
    }

    contentItem: Text {
        text: root.message
        color: "white"
        wrapMode: Text.Wrap
    }

    Timer {
        id: t
        interval: root.duration
        repeat: false
        onTriggered: root.close()
    }

    function show(msg, ms) {
        root.message = msg
        if (ms !== undefined) root.duration = ms
        root.open()
        t.restart()
    }
}
