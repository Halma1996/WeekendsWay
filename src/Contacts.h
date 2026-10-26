#pragma once

#include <QObject>
#include <QVariantList>

class QThread;

// Reads the Android address book only after an explicit request from the UI.
class Contacts : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool supported READ supported CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit Contacts(QObject* parent = nullptr);
    ~Contacts() override;

    bool supported() const;
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
    Q_INVOKABLE void readContacts();

signals:
    void busyChanged();
    void errorChanged();
    void loaded(const QVariantList& contacts);

private:
    void startReading();
    void finishWithError(const QString& message);
    void setBusy(bool busy);

    bool m_busy = false;
    QString m_error;
    QThread* m_worker = nullptr;
};
