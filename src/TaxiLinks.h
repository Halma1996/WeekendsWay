#pragma once
#include <QString>
#include <QUrl>

namespace TaxiLinks {
bool coordinates(const QString& text, double& latitude, double& longitude);
bool validCoordinates(double latitude, double longitude);
QUrl destination(double latitude, double longitude);
}
