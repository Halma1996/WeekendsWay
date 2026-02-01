#pragma once

#include <QObject>
#include <QString>

/**
 * Navigator: minimal bridge to open an external navigation app.
 *
 * - Desktop: opens Google Maps in the browser via https://www.google.com/maps/...
 * - Android: tries to open a native navigation intent (google.navigation:).
 *   If that fails, falls back to opening a web URL.
 */
class Navigator : public QObject
{
    Q_OBJECT
public:
    explicit Navigator(QObject* parent = nullptr);

    // travelMode: "walking" | "driving" | "transit" | "bicycling" (Google Maps web modes)
    Q_INVOKABLE bool openRoute(const QString& destination, const QString& travelMode = "transit");

    // Opens a search query (useful for place names).
    Q_INVOKABLE bool openSearch(const QString& query);
};
