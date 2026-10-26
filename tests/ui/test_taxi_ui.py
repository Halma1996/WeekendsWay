"""Exercise real pages and the taxi dialog with a fake platform boundary.

Run separately from other PySide tests (one QML singleton registry per process).
The C++ Qt tests cover link construction, lookup results and cancellation.
"""
import copy
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QObject, Signal, Slot, Property, QResource, QLibraryInfo, QUrl, QMetaObject, Q_ARG, Qt
from PySide6.QtGui import QGuiApplication, QInputMethodEvent
from PySide6.QtQml import QQmlApplicationEngine, QQmlProperty, qmlRegisterSingletonInstance
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtTest import QTest

ROOT = Path(__file__).resolve().parents[2]
ADDRESS = "Москва, 2-я ул. Льва Толстого, д. 12/3, корпус 2Б & №7 + 100% #2"


def visual_items(item):
    yield item
    for child in item.childItems():
        yield from visual_items(child)


class StorageMock(QObject):
    def __init__(self):
        super().__init__()
        self.data = {}

    @Slot(str, "QVariant", result="QVariant")
    def loadJson(self, name, fallback):
        if name in self.data:
            return copy.deepcopy(self.data[name])
        return fallback.toVariant() if hasattr(fallback, "toVariant") else fallback

    @Slot(str, "QVariant", result=bool)
    def saveJson(self, name, value):
        self.data[name] = value.toVariant() if hasattr(value, "toVariant") else value
        return True

    @Slot(str, result=bool)
    def removeFile(self, name):
        self.data.pop(name, None)
        return True

    @Slot(str, result=bool)
    def copyToClipboard(self, text):
        return True


class ContactsMock(QObject):
    loaded = Signal("QVariantList")
    supported = Property(bool, lambda self: True, constant=True)
    busy = Property(bool, lambda self: False, constant=True)
    error = Property(str, lambda self: "", constant=True)

    @Slot()
    def readContacts(self):
        self.loaded.emit([])


class NavigatorMock(QObject):
    mapAppsChanged = Signal()
    defaultMapChanged = Signal()
    mapChoiceChanged = Signal()
    mapChoiceRequested = Signal()
    mapChoiceFinished = Signal()
    mapChoiceSupported = Property(bool, lambda self: False, constant=True)
    mapApps = Property("QVariantList", lambda self: [], notify=mapAppsChanged)
    defaultMapApp = Property(str, lambda self: "", notify=defaultMapChanged)
    defaultMapName = Property(str, lambda self: "Всегда спрашивать", notify=defaultMapChanged)
    mapChoiceError = Property(str, lambda self: "", notify=mapChoiceChanged)
    mapChoiceDestination = Property(str, lambda self: "", notify=mapChoiceChanged)
    choosingDefaultMap = Property(bool, lambda self: False, notify=mapChoiceChanged)
    mapChoicePending = Property(bool, lambda self: False, notify=mapChoiceChanged)

    def __init__(self):
        super().__init__()
        self.calls = []

    @Slot(str, str, result=bool)
    def openRoute(self, address, mode):
        self.calls.append(("route", address, mode))
        return True

    @Slot(str, result=bool)
    def openSearch(self, query):
        self.calls.append(("search", query))
        return True

    @Slot()
    def cancelMapChoice(self):
        pass


class TaxiMock(QObject):
    changed = Signal()
    requested = Signal()
    finished = Signal()
    pending = Property(bool, lambda self: self._pending, notify=changed)
    busy = Property(bool, lambda self: self._busy, notify=changed)
    destination = Property(str, lambda self: self._destination, notify=changed)
    error = Property(str, lambda self: self._error, notify=changed)
    candidates = Property("QVariantList", lambda self: self._candidates, notify=changed)

    def __init__(self):
        super().__init__()
        self._pending = self._busy = False
        self._destination = self._error = ""
        self._candidates = []
        self.calls = []

    @Slot(str, result=bool)
    def request(self, address):
        self._pending = True
        self._destination = address
        self._error = ""
        self._candidates = []
        self.changed.emit()
        self.requested.emit()
        return self.search(address)

    @Slot(str, result=bool)
    def search(self, address):
        self.calls.append(("search", address))
        self._busy = True
        self._destination = address
        self._error = ""
        self._candidates = []
        self.changed.emit()
        return True

    def answer(self, candidates, error=""):
        self._busy = False
        self._candidates = copy.deepcopy(candidates)
        self._error = error
        self.changed.emit()

    @Slot(int, result=bool)
    def selectDestination(self, index):
        self.calls.append(("select", index))
        self.cancel()
        return True

    @Slot()
    def cancel(self):
        was_pending = self._pending
        self._pending = self._busy = False
        self._error = ""
        self._candidates = []
        self.changed.emit()
        if was_pending:
            self.finished.emit()


class TaxiUiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication(sys.argv)
        QQuickStyle.setStyle("Material")
        cls.storage, cls.contacts, cls.navigator, cls.taxi = StorageMock(), ContactsMock(), NavigatorMock(), TaxiMock()
        for name, obj in (("Storage", cls.storage), ("Contacts", cls.contacts), ("Navigator", cls.navigator), ("Taxi", cls.taxi)):
            qmlRegisterSingletonInstance(type(obj), "App", 1, 0, name, obj)
        cls.temp = tempfile.TemporaryDirectory(prefix="weekendsway-taxi-ui-")
        rcc = Path(QLibraryInfo.path(QLibraryInfo.LibraryExecutablesPath)) / "rcc"
        cls.resource = str(Path(cls.temp.name) / "app.rcc")
        subprocess.run([str(rcc), "--binary", str(ROOT / "qml/qml.qrc"), "-o", cls.resource], check=True)
        assert QResource.registerResource(cls.resource)
        cls.engine = QQmlApplicationEngine()
        cls.warnings = []
        cls.engine.warnings.connect(lambda entries: cls.warnings.extend(entry.toString() for entry in entries))
        cls.engine.loadData(b'''
import QtQuick
import QtQuick.Controls.Material
import "qrc:/components"
QtObject {
    function setDark(dark) { Theme.systemTheme = dark ? Material.Dark : Material.Light }
}
''', QUrl("qrc:/taxi-theme-harness.qml"))
        cls.harness = cls.engine.rootObjects()[0]
        cls.engine.load(QUrl("qrc:/Main.qml"))
        assert len(cls.engine.rootObjects()) == 2, cls.warnings
        cls.window = cls.engine.rootObjects()[1]
        QTest.qWait(3000)

    @classmethod
    def tearDownClass(cls):
        cls.window.close()
        cls.engine.deleteLater()
        QTest.qWait(100)
        QResource.unregisterResource(cls.resource)
        cls.temp.cleanup()

    def items(self):
        return list(visual_items(self.window.contentItem()))

    def by_name(self, name):
        result = [item for item in self.items() if item.isVisible() and item.objectName() == name]
        self.assertTrue(result, name)
        return result[0]

    def by_text(self, text):
        result = [item for item in self.items() if item.isVisible() and item.property("text") == text
                  and item.metaObject().indexOfSignal("clicked()") >= 0]
        self.assertTrue(result, text)
        return result[0]

    def click(self, item):
        if isinstance(item, str):
            item = self.by_text(item)
        self.assertTrue(item.property("enabled"))
        QTest.mouseClick(self.window, Qt.LeftButton, Qt.NoModifier,
                         item.mapToScene(item.boundingRect().center()).toPoint())
        QTest.qWait(300)

    def setUp(self):
        self.storage.data = {
            "home.json": [{"name": "Дом", "address": ADDRESS}],
            "friends.json": [{"name": "Настя", "address": ADDRESS, "phone": "+7 999 123-45-67"},
                             {"name": "Без адреса", "address": "", "phone": "12345"}],
            "venues.json": [{"name": "Кафе", "address": ADDRESS}, {"name": "Додо Пицца", "address": "Додо Пицца"}],
            "venues-defaults.json": {"version": 1},
        }
        self.taxi.calls.clear()
        self.navigator.calls.clear()
        self.window.setWidth(420)
        self.window.setHeight(760)

    def tearDown(self):
        self.taxi.cancel()
        QTest.qWait(300)
        if any(item.isVisible() and item.property("text") == "←" for item in self.items()):
            self.click("←")
        self.assertFalse(self.warnings, "\n".join(self.warnings))

    def test_home_button_order_and_lossless_address(self):
        self.click("Домой")
        save, taxi, route = self.by_text("Сохранить"), self.by_name("homeTaxiButton"), self.by_text("Маршрут")
        self.assertLess(save.y(), taxi.y())
        self.assertLess(taxi.y(), route.y())
        self.click(taxi)
        self.assertEqual(self.taxi.calls[-1], ("search", ADDRESS))
        self.assertEqual(self.by_name("taxiAddressField").property("text"), ADDRESS)
        self.assertTrue(self.by_name("taxiSearchingLabel").isVisible())
        self.assertFalse(self.by_name("searchTaxiAddressButton").property("enabled"))
        self.click(self.by_name("cancelTaxiButton"))
        self.click("Маршрут")
        self.assertEqual(self.navigator.calls[-1], ("route", ADDRESS, "transit"))

    def test_friend_taxi_and_gear_keep_existing_editor(self):
        self.click("К друзьям")
        taxi_buttons = [item for item in self.items() if item.isVisible() and item.objectName() == "friendTaxiButton"]
        self.assertEqual(len(taxi_buttons), 2)
        self.assertFalse(taxi_buttons[1].property("enabled"))
        self.click(self.by_name("friendTaxiButton"))
        self.assertEqual(self.taxi.calls[-1], ("search", ADDRESS))
        self.click(self.by_name("cancelTaxiButton"))
        self.click(self.by_name("friendMapButton"))
        self.assertEqual(self.navigator.calls[-1], ("route", ADDRESS, "transit"))
        self.click("⌄")
        edit = self.by_name("editFriendButton")
        self.assertEqual(QQmlProperty(edit, "icon.source").read(), QUrl("qrc:/icons/edit.png"))
        # The resource exists and the actual edit action opens the existing form.
        self.assertTrue(QResource(":/icons/edit.png").isValid())
        self.click(edit)
        self.assertTrue(self.by_text("OK"))
        self.click("Cancel")

    def test_venue_uses_card_address_and_chain_remains_a_search(self):
        self.click("Кушать")
        buttons = [item for item in self.items() if item.isVisible() and item.objectName() == "venueTaxiButton"]
        self.assertEqual(len(buttons), 2)
        self.click(buttons[0])
        self.assertEqual(self.taxi.calls[-1], ("search", ADDRESS))
        self.click(self.by_name("cancelTaxiButton"))
        self.click(buttons[1])
        self.assertEqual(self.taxi.calls[-1], ("search", "Додо Пицца"))
        self.click(self.by_name("cancelTaxiButton"))
        maps = [item for item in self.items() if item.isVisible() and item.objectName() == "venueMapButton"]
        self.click(maps[1])
        self.assertEqual(self.navigator.calls[-1], ("search", "Додо Пицца"))

    def test_dialog_retry_composition_and_explicit_destination(self):
        self.taxi.request("Додо Пицца")
        QTest.qWait(300)
        self.taxi.answer([], "Адрес не найден. Уточните город, улицу и дом.")
        QTest.qWait(100)
        self.assertTrue(self.by_name("taxiErrorLabel").isVisible())
        field = self.by_name("taxiAddressField")
        field.setProperty("text", "Москва, ")
        field.setProperty("cursorPosition", len("Москва, "))
        field.forceActiveFocus()
        QGuiApplication.sendEvent(field, QInputMethodEvent("Садовая, 12/3", []))
        self.assertEqual(field.property("displayText"), "Москва, Садовая, 12/3")
        # Invoke the real handler without forcing an IME commit as mouse focus changes.
        QMetaObject.invokeMethod(self.by_name("searchTaxiAddressButton"), "clicked")
        self.assertEqual(self.taxi.calls[-1], ("search", "Москва, Садовая, 12/3"))
        self.taxi.answer([{"label": "Москва, Садовая, 12/3", "latitude": 55.75, "longitude": 37.61},
                          {"label": "Санкт-Петербург, Садовая, 12/3", "latitude": 59.94, "longitude": 30.31}])
        QTest.qWait(150)
        self.assertFalse(any(call[0] == "select" for call in self.taxi.calls))
        self.click(self.by_name("taxiDestination_1"))
        self.assertEqual(self.taxi.calls[-1], ("select", 1))
        self.assertFalse(self.taxi.pending)

    def test_compact_light_and_dark_layout(self):
        for width in (320, 420):
            for dark in (False, True):
                self.window.setMinimumWidth(0)
                self.window.setMinimumHeight(0)
                self.window.setWidth(width)
                self.window.setHeight(760)
                QMetaObject.invokeMethod(self.harness, "setDark", Q_ARG("QVariant", dark))
                for page in ("К друзьям", "Кушать"):
                    self.click(page)
                    for item in self.items():
                        if not item.isVisible() or item.metaObject().indexOfSignal("clicked()") < 0:
                            continue
                        left = item.mapToScene(item.boundingRect().topLeft())
                        right = item.mapToScene(item.boundingRect().bottomRight())
                        if 0 <= left.y() and right.y() <= self.window.height():
                            self.assertGreaterEqual(left.x(), -1)
                            self.assertLessEqual(right.x(), width + 1)
                    self.click("←")
                self.window.setHeight(400)
                self.taxi.request(ADDRESS)
                self.taxi.answer([{"label": ADDRESS, "latitude": 55.75, "longitude": 37.61}])
                QTest.qWait(300)
                cancel = self.by_name("cancelTaxiButton")
                top = cancel.mapToScene(cancel.boundingRect().topLeft())
                bottom = cancel.mapToScene(cancel.boundingRect().bottomRight())
                self.assertGreaterEqual(top.y(), 0)
                self.assertLessEqual(bottom.y(), 400)
                self.click(cancel)


if __name__ == "__main__":
    unittest.main(verbosity=2)
