#include "MapLinks.h"
#include <QRegularExpression>
#include <QStringList>

namespace {
QByteArray encode(const QString& value)
{
    return QUrl::toPercentEncoding(value);
}
bool coordinates(const QString& text, QString& latitude, QString& longitude)
{
    static const QRegularExpression pattern(
        QStringLiteral("^\\s*([+-]?[0-9]+(?:\\.[0-9]+)?)\\s*,\\s*([+-]?[0-9]+(?:\\.[0-9]+)?)\\s*$"));
    const auto match = pattern.match(text);
    if (!match.hasMatch()) return false;
    bool latOk = false, lonOk = false;
    const double lat = match.captured(1).toDouble(&latOk);
    const double lon = match.captured(2).toDouble(&lonOk);
    if (!latOk || !lonOk || lat < -90 || lat > 90 || lon < -180 || lon > 180) return false;
    latitude = QString::number(lat, 'g', 12);
    longitude = QString::number(lon, 'g', 12);
    return true;
}
QString normalizedMode(const QString& mode)
{
    return mode == "walking" || mode == "driving" || mode == "bicycling" ? mode : QStringLiteral("transit");
}
}

QStringList MapLinks::appIds() { return {"yandex", "google", "2gis"}; }
QString MapLinks::appName(const QString& id)
{
    if (id == "yandex") return QStringLiteral("Яндекс Карты");
    if (id == "google") return QStringLiteral("Google Maps");
    if (id == "2gis") return QStringLiteral("2ГИС");
    return {};
}
QString MapLinks::packageName(const QString& id)
{
    if (id == "yandex") return QStringLiteral("ru.yandex.yandexmaps");
    if (id == "google") return QStringLiteral("com.google.android.apps.maps");
    if (id == "2gis") return QStringLiteral("ru.dublgis.dgismobile");
    return {};
}
QUrl MapLinks::search(const QString& id, const QString& query)
{
    const auto text = encode(query.trimmed());
    if (id == "yandex") return QUrl::fromEncoded("yandexmaps://maps.yandex.ru/?text=" + text);
    if (id == "google") return QUrl::fromEncoded("https://www.google.com/maps/search/?api=1&query=" + text);
    if (id == "2gis") return QUrl::fromEncoded("dgis://2gis.ru/search/" + text);
    return {};
}
QUrl MapLinks::route(const QString& id, const QString& destination, const QString& travelMode)
{
    const auto mode = normalizedMode(travelMode);
    const auto text = encode(destination.trimmed());
    if (id == "google")
        return QUrl::fromEncoded("https://www.google.com/maps/dir/?api=1&destination=" + text + "&travelmode=" + mode.toLatin1());
    if (id == "yandex") {
        // A literal tilde is a route-point separator even after URL decoding.
        // Search for such text instead of accidentally adding a waypoint.
        if (destination.contains('~')) return search(id, destination);
        const QByteArray type = mode == "walking" ? "pd" : mode == "driving" ? "auto" : mode == "bicycling" ? "bc" : "mt";
        return QUrl::fromEncoded("yandexmaps://maps.yandex.ru/?rtext=~" + text + "&rtt=" + type);
    }
    if (id == "2gis") {
        QString lat, lon;
        if (!coordinates(destination, lat, lon)) return search(id, destination);
        const QByteArray type = mode == "walking" ? "pedestrian" : mode == "driving" ? "car" : mode == "bicycling" ? "bicycle" : "bus";
        return QUrl::fromEncoded("dgis://2gis.ru/directions/tab/" + type + "/points/%7C" + lon.toLatin1() + "," + lat.toLatin1());
    }
    return {};
}
bool MapLinks::needsAddressConfirmation(const QString& id, const QString& destination)
{
    QString latitude, longitude;
    return id == "2gis" && !coordinates(destination, latitude, longitude);
}
