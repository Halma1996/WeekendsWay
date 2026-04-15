#pragma once

#include <QObject>
#include <QString>

///
/// \brief The Navigator class - класс для работы с навигацией, открывает стороннее приложение (на андроид)
/// или гугл карты на пк , для построения маршрута
///
class Navigator : public QObject
{
    Q_OBJECT
public:
    explicit Navigator(QObject* parent = nullptr);

    ///
    /// \brief openRoute ф-ция открытия карт
    /// \param destination
    /// \param travelMode    travelMode: "walking" | "driving" | "transit" | "bicycling" (Google Maps web modes)
    /// \return
    ///
    Q_INVOKABLE bool openRoute(const QString& destination, const QString& travelMode = "transit");

    ///
    /// \brief openSearch ф-ция для открытия поискового запроса на карте, если нет точного адреса (пока не используется)
    /// \param query
    /// \return
    ///
    Q_INVOKABLE bool openSearch(const QString& query);
};
