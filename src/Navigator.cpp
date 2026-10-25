#include "Navigator.h"

#include <QDesktopServices>
#include <QUrl>
#include <QUrlQuery>

Navigator::Navigator(QObject* parent)
    : QObject(parent)
{
}

static QUrl googleMapsDirectionsUrl(const QString& destination, const QString& travelMode)
{
    QUrl url("https://www.google.com/maps/dir/");
    QUrlQuery q;
    q.addQueryItem("api", "1");
    q.addQueryItem("destination", destination);
    q.addQueryItem("travelmode", travelMode.isEmpty() ? "transit" : travelMode);
    url.setQuery(q);
    return url;
}

static QUrl googleMapsSearchUrl(const QString& query)
{
    QUrl url("https://www.google.com/maps/search/");
    QUrlQuery q;
    q.addQueryItem("api", "1");
    q.addQueryItem("query", query);
    url.setQuery(q);
    return url;
}

// Universal Maps URLs preserve the selected travel mode and work with
// Android's ACTION_VIEW resolver as well as desktop browsers.
bool Navigator::openRoute(const QString& destination, const QString& travelMode)
{
    if (destination.trimmed().isEmpty())
        return false;

    const QString mode = travelMode == "walking" || travelMode == "driving"
        || travelMode == "transit" || travelMode == "bicycling"
        ? travelMode : QStringLiteral("transit");
    return QDesktopServices::openUrl(googleMapsDirectionsUrl(destination.trimmed(), mode));
}

bool Navigator::openSearch(const QString& query)
{
    if (query.trimmed().isEmpty())
        return false;

    return QDesktopServices::openUrl(googleMapsSearchUrl(query.trimmed()));
}
