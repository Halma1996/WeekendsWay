# WeekendsWay(Qt 5.15 + CMake + QML)

Lean-MVP версия pet-проекта для демонстрации QML-навыков:
- 3 раздела: Домой / К друзьям / Кушать
- Списки друзей и мест сохраняются в JSON
- Маршрут открывается во внешнем навигаторе (Android intent / Desktop browser)

## Структура
- `qml/` — QML UI (в ресурсах qrc)
- `src/` — C++ мосты: Navigator (open maps) и Storage (json)

## Где лежат данные
Storage пишет в `QStandardPaths::AppDataLocation`.
В приложении на страницах списков есть кнопка "Открыть данные (AppData)" — покажет путь.

## Заметки
- `Navigator.openRoute(destination, travelMode)`:
  - travelMode: "walking" | "driving" | "transit" | "bicycling" (для web Google Maps)
- Android intent использует `google.navigation:q=...` (обычно открывает Google Maps).
  Если на устройстве нет обработчика, используется web fallback.


## Qt 5.12 compatibility
This branch/template variant is adjusted to build with Qt 5.12.x (CMake min 3.10, find_package Qt 5.12).
