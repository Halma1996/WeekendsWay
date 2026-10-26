#pragma once
#include <QString>
#include <QStringList>
#include <QUrl>

namespace MapLinks {
QStringList appIds();
QString appName(const QString& id);
QString packageName(const QString& id);
QUrl search(const QString& id, const QString& query);
QUrl route(const QString& id, const QString& destination, const QString& mode);
bool needsAddressConfirmation(const QString& id, const QString& destination);
}
