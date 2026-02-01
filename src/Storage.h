#pragma once

#include <QObject>
#include <QVariant>

/**
 * Storage: super simple JSON read/write for QML.
 *
 * - saveJson(fileName, data): data can be QVariantMap / QVariantList / nested structures.
 * - loadJson(fileName): returns the saved structure, or {} / [] if missing/invalid.
 *
 * Files are stored in QStandardPaths::AppDataLocation.
 */
class Storage : public QObject
{
    Q_OBJECT
public:
    explicit Storage(QObject* parent = nullptr);

    Q_INVOKABLE QString appDataPath() const;

    Q_INVOKABLE QVariant loadJson(const QString& fileName, const QVariant& fallback = QVariant()) const;
    Q_INVOKABLE bool saveJson(const QString& fileName, const QVariant& data) const;

    Q_INVOKABLE bool removeFile(const QString& fileName) const;

private:

    static QVariant normalizeForJson(const QVariant& v);
};
