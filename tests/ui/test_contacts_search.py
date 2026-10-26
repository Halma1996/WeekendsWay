"""Regression checks against the real QML dialog, including IME preedit events.

Run with PySide6-Essentials 6.8.3; Android keyboard composition is reproduced
with QInputMethodEvent rather than only assigning committed TextInput.text.
"""

import copy
import os
from pathlib import Path
import sys
import unittest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl, QMetaObject, Q_ARG, QAbstractItemModel
from PySide6.QtGui import QGuiApplication, QInputMethodEvent
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonInstance
from PySide6.QtQuick import QQuickItem
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtTest import QSignalSpy, QTest
import shiboken6

ROOT = Path(__file__).resolve().parents[2]
CONTACTS = [
    {"contactId": "1", "contactKey": "key1", "name": "Настя", "phone": "+7 (999) 001-22-33", "address": "Москва"},
    {"contactId": "2", "contactKey": "key2", "name": "Настя Петрова", "phone": "12345", "address": "Тверь"},
    {"contactId": "3", "contactKey": "key3", "name": "Антон", "phone": "67890", "address": "Омск"},
    {"contactId": "4", "contactKey": "key4", "name": "Сергей", "phone": "", "address": ""},
]


def visual_items(item):
    yield item
    for child in item.childItems():
        yield from visual_items(child)


class ContactsMock(QObject):
    loaded = Signal("QVariantList")

    def __init__(self):
        super().__init__()
        self.entries = copy.deepcopy(CONTACTS)
        self.requests = 0

    @Property(bool, constant=True)
    def supported(self):
        return True

    @Property(bool, constant=True)
    def busy(self):
        return False

    @Property(str, constant=True)
    def error(self):
        return ""

    @Slot()
    def readContacts(self):
        self.requests += 1
        self.loaded.emit(copy.deepcopy(self.entries))


class ContactSearchTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication(sys.argv)
        QQuickStyle.setStyle("Material")
        cls.contacts = ContactsMock()
        qmlRegisterSingletonInstance(ContactsMock, "App", 1, 0, "Contacts", cls.contacts)
        cls.engine = QQmlApplicationEngine()
        cls.warnings = []
        cls.engine.warnings.connect(lambda warnings: cls.warnings.extend(w.toString() for w in warnings))
        cls.engine.loadData(b'''
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import "../../qml/components"
ApplicationWindow {
    width: 420; height: 720; visible: true
    ContactsSyncDialog { id: dialog }
    function openContacts() { dialog.open(); dialog.begin(false) }
    function closeContacts() { dialog.close() }
    function setDark(dark) { Theme.systemTheme = dark ? Material.Dark : Material.Light }
}
''', QUrl.fromLocalFile(str(ROOT / "tests/ui/contact-search-harness.qml")))
        assert cls.engine.rootObjects(), cls.warnings
        cls.window = cls.engine.rootObjects()[0]
        cls.dialog = cls.window.findChild(QObject, "contactsSyncDialog")
        cls.field = cls.window.findChild(QQuickItem, "contactsSearchField")
        cls.model = cls.window.findChild(QAbstractItemModel, "filteredContactsModel")
        assert cls.dialog is not None and cls.field is not None and cls.model is not None
        QTest.qWait(200)

    def invoke(self, target, method, *args):
        self.assertTrue(QMetaObject.invokeMethod(target, method, *[Q_ARG("QVariant", value) for value in args]))

    def setUp(self):
        self.contacts.entries = copy.deepcopy(CONTACTS)
        self.contacts.requests = 0
        self.invoke(self.window, "openContacts")
        QTest.qWait(300)
        self.field.forceActiveFocus()
        self.assertEqual(self.model.rowCount(), 4)

    def tearDown(self):
        self.invoke(self.window, "closeContacts")
        QTest.qWait(300)
        self.assertFalse(self.warnings, "\n".join(self.warnings))

    def names(self):
        role = next(key for key, value in self.model.roleNames().items() if bytes(value) == b"name")
        return [self.model.data(self.model.index(row, 0), role) for row in range(self.model.rowCount())]

    def preedit(self, text):
        QGuiApplication.sendEvent(self.field, QInputMethodEvent(text, []))
        QTest.qWait(180)

    def test_preedit_filters_before_space_and_commit_does_not_rebuild_rows(self):
        first = next(row for row in visual_items(self.window.contentItem())
                     if row.objectName() == "contactSelectionRow" and row.property("text") == "Настя")
        reset = QSignalSpy(self.model.modelReset)
        removed = QSignalSpy(self.model.rowsRemoved)
        inserted = QSignalSpy(self.model.rowsInserted)
        self.preedit("На")
        self.assertEqual(self.field.property("text"), "")
        self.assertEqual(self.field.property("displayText"), "На")
        self.assertEqual(self.names(), ["Настя", "Настя Петрова"])
        self.assertTrue(shiboken6.isValid(first), "Matching delegate was destroyed")
        counts = removed.count(), inserted.count()
        self.preedit("Настя")
        self.assertEqual(self.names(), ["Настя", "Настя Петрова"])
        self.assertEqual((removed.count(), inserted.count()), counts)
        commit = QInputMethodEvent()
        commit.setCommitString("Настя ")
        QGuiApplication.sendEvent(self.field, commit)
        QTest.qWait(180)
        self.assertEqual(self.names(), ["Настя", "Настя Петрова"])
        self.assertEqual((removed.count(), inserted.count()), counts)
        self.assertTrue(shiboken6.isValid(first))
        self.assertEqual(reset.count(), 0)
        self.assertEqual(self.contacts.requests, 1)

    def test_selection_survives_filtering_and_clearing(self):
        self.invoke(self.dialog, "setSelected", CONTACTS[0], True)
        self.field.setProperty("text", "Серг")
        QTest.qWait(180)
        self.assertEqual(self.names(), ["Сергей"])
        self.assertEqual(self.dialog.property("selectedCount"), 1)
        self.field.setProperty("text", "")
        QTest.qWait(180)
        self.assertEqual(self.names(), [contact["name"] for contact in CONTACTS])
        selected = self.dialog.property("selectedIds")
        selected = selected.toVariant() if hasattr(selected, "toVariant") else selected
        self.assertTrue(selected["key:key1"])
        self.assertEqual(self.dialog.property("selectedCount"), 1)

    def test_composition_in_middle_and_phone_search(self):
        self.field.setProperty("text", "На Петрова")
        self.field.setProperty("cursorPosition", 2)
        self.preedit("стя")
        self.assertEqual(self.field.property("displayText"), "Настя Петрова")
        self.assertEqual(self.names(), ["Настя Петрова"])
        self.preedit("")
        self.field.setProperty("text", "999001")
        QTest.qWait(180)
        self.assertEqual(self.names(), ["Настя"])

    def test_large_phonebook_and_partial_word_without_commit(self):
        self.contacts.entries += [
            {"contactId": str(100 + i), "contactKey": f"large{i}", "name": f"Контакт {i:04}", "phone": "", "address": ""}
            for i in range(5000)
        ]
        self.contacts.loaded.emit(self.contacts.entries)
        QTest.qWait(200)
        self.assertEqual(self.model.rowCount(), 5004)
        self.preedit("Контакт 0427")
        self.assertEqual(self.names(), ["Контакт 0427"])
        self.preedit("")
        self.assertEqual(self.model.rowCount(), 5004)
        self.assertEqual(self.contacts.requests, 1)

    def test_both_palettes_and_compact_keyboard_layout(self):
        for dark in (False, True):
            self.invoke(self.window, "setDark", dark)
            self.window.setWidth(320)
            self.window.setHeight(400)
            QTest.qWait(200)
            self.preedit("Наст")
            self.assertEqual(self.names(), ["Настя", "Настя Петрова"])
            confirm = self.window.findChild(QQuickItem, "confirmContactsSyncButton")
            self.assertLessEqual(confirm.mapToScene(confirm.boundingRect().bottomRight()).y(), 400)
            self.preedit("")
        self.window.setWidth(420)
        self.window.setHeight(720)


if __name__ == "__main__":
    unittest.main(verbosity=2)
