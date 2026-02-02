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

### Navigator
`Navigator.openRoute(destination, travelMode)` открывает маршрут во внешнем навигаторе.

`travelMode`:
- `"walking"`, `"driving"`, `"transit"`, `"bicycling"`

### Платформы
- **Android**: intent `google.navigation:q=...`
- **Desktop**: web fallback (открытие URL в браузере)

Если на Android нет приложения-обработчика intent, используется web fallback.


## Версия Qt

Текущая версия проекта настроена под **Qt 5.15.2** (CMake + QML/Qt Quick Controls 2).

Ранее проект запускался на Qt 5.12, но сейчас целевой набор — Qt 5.15.
