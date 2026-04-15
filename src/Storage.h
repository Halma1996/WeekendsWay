#pragma once

#include <QObject>
#include <QVariant>

///
/// \brief the Storage class - класс для записи/чтения данных в json файл (вызывается в qml)
///
class Storage : public QObject
{
    Q_OBJECT
public:
    explicit Storage(QObject* parent = nullptr);
    ///
    /// \brief appDataPath возвращает локальную AppDataLocation ( в зависимости от ОС AppDataLocation может отличаться)
    /// \return
    ///
    Q_INVOKABLE QString appDataPath() const;
    ///
    /// \brief loadJson загружает данные из json
    /// \param fileName
    /// \param fallback
    /// \return
    ///
    Q_INVOKABLE QVariant loadJson(const QString& fileName, const QVariant& fallback = QVariant()) const;
    ///
    /// \brief saveJson сохраняет данные в json
    /// \param fileName
    /// \param data
    /// \return
    ///
    Q_INVOKABLE bool saveJson(const QString& fileName, const QVariant& data) const;
    ///
    /// \brief removeFile удаляет файл
    /// \param fileName
    /// \return
    ///
    Q_INVOKABLE bool removeFile(const QString& fileName) const;

private:
    ///
    /// \brief normalizeForJson ф-ция нормализации данных
    /// \param jsonValue
    /// \return
    ///
    static QVariant normalizeForJson(const QVariant& jsonValue);
};
