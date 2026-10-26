import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import App 1.0

StyledDialog {
    id: dlg
    objectName: "contactsSyncDialog"
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(480, parent ? parent.width - 24 : 480)
    height: Math.min(660, parent ? parent.height - 32 : 660)
    modal: true
    title: "Синхронизация контактов"
    closePolicy: Popup.CloseOnEscape
    readonly property bool compact: height < 520
    padding: compact ? 12 : 16
    Material.accent: Theme.purple

    background: Rectangle { color: Theme.surface; radius: 24; border.color: Theme.border }
    header: Label {
        text: dlg.title
        color: Theme.text
        font.pixelSize: dlg.compact ? 18 : 22
        font.bold: true
        wrapMode: Text.Wrap
        leftPadding: 16
        rightPadding: 16
        topPadding: dlg.compact ? 12 : 20
        bottomPadding: dlg.compact ? 4 : 10
    }

    property var allContacts: []
    property var selectedIds: ({})
    property int selectedCount: 0
    property bool listReady: false
    property bool selectEverything: false
    property string resultError: ""
    property string appliedQuery: ""
    signal syncRequested(var contacts, var allContacts)

    ListModel { id: visibleContacts; objectName: "filteredContactsModel" }

    Timer {
        id: filterDelay
        interval: 120
        onTriggered: dlg.filterContacts()
    }

    function identity(contact) {
        return contact.contactKey ? "key:" + contact.contactKey : "id:" + contact.contactId
    }

    function setSelected(contact, selected) {
        var copy = Object.assign({}, selectedIds)
        var key = identity(contact)
        if (selected) copy[key] = true
        else delete copy[key]
        selectedIds = copy
        selectedCount = Object.keys(copy).length
        resultError = ""
    }

    function selectAll(selected) {
        var ids = {}
        if (selected) {
            for (var i = 0; i < allContacts.length; ++i) ids[identity(allContacts[i])] = true
        }
        selectedIds = ids
        selectedCount = Object.keys(ids).length
        resultError = ""
    }

    function filterContacts(force) {
        // displayText includes the keyboard's uncommitted (underlined) word.
        // Waiting for text alone delays Android search until Space/Enter.
        var query = searchField.displayText.trim().toLocaleLowerCase()
        if (!force && query === appliedQuery) return
        var digits = query.replace(/\D/g, "")
        var matches = []
        var keep = {}
        for (var i = 0; i < allContacts.length; ++i) {
            var contact = allContacts[i]
            var searchable = (contact.name + " " + contact.phone + " " + contact.address).toLocaleLowerCase()
            if (!query || searchable.indexOf(query) >= 0
                    || (digits && contact.phone.replace(/\D/g, "").indexOf(digits) >= 0)) {
                matches.push(contact)
                keep[identity(contact)] = true
            }
        }
        // Both lists retain phonebook order. Keep matching rows and their
        // delegates instead of clearing the model (which flashes an empty list).
        var end = visibleContacts.count - 1
        while (end >= 0) {
            if (keep[identity(visibleContacts.get(end))]) { --end; continue }
            var start = end
            while (start > 0 && !keep[identity(visibleContacts.get(start - 1))]) --start
            visibleContacts.remove(start, end - start + 1)
            end = start - 1
        }
        for (var row = 0; row < matches.length; ++row) {
            if (row >= visibleContacts.count)
                visibleContacts.append(matches[row])
            else if (identity(visibleContacts.get(row)) !== identity(matches[row]))
                visibleContacts.insert(row, matches[row])
        }
        appliedQuery = query
    }

    function begin(all) {
        selectEverything = all
        resultError = ""
        Contacts.readContacts()
    }

    function submitSelection() {
        var selected = []
        for (var i = 0; i < allContacts.length; ++i) {
            if (selectedIds[identity(allContacts[i])]) selected.push(allContacts[i])
        }
        if (selected.length) syncRequested(selected, allContacts)
    }

    onAboutToShow: {
        filterDelay.stop()
        allContacts = []
        selectedIds = ({})
        selectedCount = 0
        listReady = false
        resultError = ""
        appliedQuery = ""
        searchField.clear()
        visibleContacts.clear()
    }
    onClosed: filterDelay.stop()

    Connections {
        target: Contacts
        function onLoaded(contacts) {
            if (!dlg.visible) return
            dlg.allContacts = contacts
            dlg.listReady = true
            dlg.selectAll(dlg.selectEverything)
            dlg.filterContacts(true)
        }
    }

    contentItem: ColumnLayout {
        spacing: dlg.compact ? 4 : 10
        Label {
            visible: !dlg.compact
            Layout.fillWidth: true
            text: "Добавим имена, телефоны и адреса, если они есть. Данные на телефоне не изменятся."
            wrapMode: Text.Wrap
            font.pixelSize: 14
            color: Theme.muted
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: !dlg.listReady && !Contacts.busy
            spacing: 6
            ActionButton {
                id: allButton
                objectName: "syncAllContactsButton"
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                text: "Все контакты"
                tone: "purple"
                enabled: Contacts.supported
                onClicked: dlg.begin(true)
            }
            ActionButton {
                id: chooseButton
                objectName: "chooseContactsButton"
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                text: "Выбрать контакты"
                enabled: Contacts.supported
                onClicked: dlg.begin(false)
            }
            Label {
                Layout.fillWidth: true
                text: "Android запросит доступ к контактам. Затем можно проверить список и подтвердить синхронизацию."
                wrapMode: Text.Wrap
                font.pixelSize: 12
                color: Theme.muted
            }
        }
        Label {
            Layout.fillWidth: true
            visible: !Contacts.supported
            text: "Синхронизация доступна в Android-приложении."
            wrapMode: Text.Wrap
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: Contacts.busy
            BusyIndicator { Layout.alignment: Qt.AlignHCenter; running: Contacts.busy }
            Label { text: "Загружаем контакты…" }
        }
        Label {
            Layout.fillWidth: true
            visible: text.length > 0
            text: dlg.resultError || Contacts.error
            color: Theme.danger
            wrapMode: Text.Wrap
            font.pixelSize: 13
        }
        InputField {
            id: searchField
            objectName: "contactsSearchField"
            Layout.fillWidth: true
            visible: dlg.listReady && dlg.allContacts.length > 0
            implicitHeight: dlg.compact ? 44 : 54
            topPadding: dlg.compact ? 8 : 14
            bottomPadding: dlg.compact ? 8 : 14
            placeholderText: "Имя или телефон"
            onDisplayTextChanged: if (dlg.visible && dlg.listReady) filterDelay.restart()
        }
        RowLayout {
            Layout.fillWidth: true
            visible: dlg.listReady && dlg.allContacts.length > 0
            spacing: 4
            CheckBox {
                objectName: "selectAllContactsCheckBox"
                Layout.fillWidth: true
                text: "Выбрать все"
                checked: dlg.selectedCount === dlg.allContacts.length && dlg.allContacts.length > 0
                onClicked: dlg.selectAll(checked)
            }
            Label { text: dlg.selectedCount + " / " + dlg.allContacts.length; font.pixelSize: 13 }
        }
        ListView {
            id: contactList
            objectName: "contactSelectionList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: dlg.listReady && dlg.allContacts.length > 0
            clip: true
            model: visibleContacts
            spacing: 4
            ScrollBar.vertical: ScrollBar {}
            delegate: CheckDelegate {
                objectName: "contactSelectionRow"
                width: ListView.view.width
                implicitHeight: Math.max(68, contactLabels.implicitHeight + 20)
                property var contact: ({ contactId: model.contactId, contactKey: model.contactKey,
                                         name: model.name, phone: model.phone, address: model.address })
                text: model.name
                checked: !!dlg.selectedIds[dlg.identity(contact)]
                Accessible.name: model.name + (model.phone ? ", " + model.phone : "")
                contentItem: Column {
                    id: contactLabels
                    spacing: 3
                    Label {
                        width: parent.width - 42
                        text: model.name
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Label {
                        width: parent.width - 42
                        visible: model.phone.length > 0
                        text: model.phone
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Label {
                        width: parent.width - 42
                        text: model.address || "Адрес можно добавить позже"
                        font.pixelSize: 12
                        color: Theme.muted
                        elide: Text.ElideRight
                    }
                }
                onClicked: dlg.setSelected(contact, checked)
            }
            Label {
                anchors.centerIn: parent
                visible: visibleContacts.count === 0
                text: "Контакты не найдены"
            }
        }
        Label {
            Layout.fillWidth: true
            visible: dlg.listReady && dlg.allContacts.length === 0
            text: "В телефонной книге нет контактов."
            wrapMode: Text.Wrap
        }
        Item { Layout.fillHeight: true; visible: !dlg.listReady || dlg.allContacts.length === 0 }
        Label {
            Layout.fillWidth: true
            visible: !dlg.compact && dlg.listReady && dlg.allContacts.length > 0
            text: "Повторная синхронизация обновит связанные записи. Ваши правки и дополнительные данные сохранятся."
            wrapMode: Text.Wrap
            font.pixelSize: 12
            color: Theme.muted
        }
    }

    footer: Item {
        implicitHeight: dlg.compact ? 58 : 74
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 10
            spacing: 8
            ActionButton {
                text: "Отмена"
                flat: true
                Layout.preferredHeight: 50
                onClicked: dlg.close()
            }
            ActionButton {
                id: confirmButton
                objectName: "confirmContactsSyncButton"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                visible: dlg.listReady
                text: "Применить (" + dlg.selectedCount + ")"
                font.pixelSize: 14
                leftPadding: 10
                rightPadding: 10
                tone: "purple"
                enabled: dlg.selectedCount > 0 && !Contacts.busy
                onClicked: dlg.submitSelection()
            }
        }
    }
}
