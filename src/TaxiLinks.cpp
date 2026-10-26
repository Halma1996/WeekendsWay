#include "TaxiLinks.h"
#include <QRegularExpression>
#include <QUrlQuery>
#include <cmath>

bool TaxiLinks::validCoordinates(double latitude, double longitude)
{
    return std::isfinite(latitude) && std::isfinite(longitude)
        && latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
}

bool TaxiLinks::coordinates(const QString& text, double& latitude, double& longitude)
{
    static const QRegularExpression pattern(QStringLiteral(
        "^\\s*([+-]?[0-9]+(?:\\.[0-9]+)?)\\s*,\\s*([+-]?[0-9]+(?:\\.[0-9]+)?)\\s*$"));
    const auto match = pattern.match(text);
    if (!match.hasMatch()) return false;
    bool latOk = false, lonOk = false;
    const double lat = match.captured(1).toDouble(&latOk);
    const double lon = match.captured(2).toDouble(&lonOk);
    if (!latOk || !lonOk || !validCoordinates(lat, lon)) return false;
    latitude = lat;
    longitude = lon;
    return true;
}

QUrl TaxiLinks::destination(double latitude, double longitude)
{
    if (!validCoordinates(latitude, longitude)) return {};
    // Official Yandex Go destination link. Do not invent text-address params,
    // a pickup point, a tariff or a partner tracking ID. Go confirms the order.
    QUrl url(QStringLiteral("https://3.redirect.appmetrica.yandex.com/route"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("end-lat"), QString::number(latitude, 'g', 15));
    query.addQueryItem(QStringLiteral("end-lon"), QString::number(longitude, 'g', 15));
    query.addQueryItem(QStringLiteral("ref"), QStringLiteral("weekendsway"));
    query.addQueryItem(QStringLiteral("appmetrica_tracking_id"), QStringLiteral("1178268795219780156"));
    query.addQueryItem(QStringLiteral("lang"), QStringLiteral("ru"));
    url.setQuery(query);
    return url;
}
