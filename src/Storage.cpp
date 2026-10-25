#include "Storage.h"

#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QJsonDocument>
#include <QDebug>
#include <QMetaType>
#include <QJSValue>
#include <QGuiApplication>
#include <QClipboard>

Storage::Storage(QObject* parent) : QObject(parent) {}

QString Storage::appDataPath() const
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(base);
    return base;
}

static QString resolvePath(const QString& baseDir, const QString& fileName)
{
    return QDir(baseDir).filePath(fileName);
}

QVariant Storage::loadJson(const QString& fileName, const QVariant& fallback) const
{
    const QString base = appDataPath();
    const QString path = resolvePath(base, fileName);

    QFile f(path);
    if (!f.exists())
        return fallback;

    if (!f.open(QIODevice::ReadOnly))
        return fallback;

    const QByteArray bytes = f.readAll();
    f.close();

    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(bytes, &err);
    if (err.error != QJsonParseError::NoError || doc.isNull())
        return fallback;

    return doc.toVariant();
}

bool Storage::saveJson(const QString& fileName, const QVariant& data) const
{
    const QString base = appDataPath();
    const QString path = resolvePath(base, fileName);

    QVariant normalized = normalizeForJson(data);
    QJsonDocument doc = QJsonDocument::fromVariant(normalized);
    if (doc.isNull()) {
        qWarning() << "saveJson failed: cannot convert to JSON. type=" << normalized.typeName();
        return false;

    }

    QSaveFile f(path);
    if (!f.open(QIODevice::WriteOnly))
        return false;

    const QByteArray bytes = doc.toJson(QJsonDocument::Indented);
    if (f.write(bytes) != bytes.size()) {
        f.cancelWriting();
        return false;
    }
    return f.commit();
}

bool Storage::copyToClipboard(const QString& text) const
{
    if (text.isEmpty() || !QGuiApplication::clipboard())
        return false;

    QGuiApplication::clipboard()->setText(text);
    return true;
}

bool Storage::removeFile(const QString& fileName) const
{
    const QString base = appDataPath();
    const QString path = resolvePath(base, fileName);
    return QFile::remove(path);
}

QVariant Storage::normalizeForJson(const QVariant &jsonValue)
{
    // Если прилетел QJSValue , конвертируем в обычный QVariant
    if (jsonValue.userType() == qMetaTypeId<QJSValue>()) {
        return normalizeForJson(jsonValue.value<QJSValue>().toVariant());
    }

    // Рекурсивно нормализуем списки
    if (jsonValue.typeId() == QMetaType::QVariantList) {
        QVariantList lst = jsonValue.toList();
        for (int i = 0; i < lst.size(); ++i)
            lst[i] = normalizeForJson(lst[i]);
        return lst;
    }

    // Рекурсивно нормализуем map-ы
    if (jsonValue.typeId() == QMetaType::QVariantMap) {
        QVariantMap mp = jsonValue.toMap();
        for (auto it = mp.begin(); it != mp.end(); ++it)
            it.value() = normalizeForJson(it.value());
        return mp;
    }

    return jsonValue;
}
