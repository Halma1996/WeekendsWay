#pragma once
#include <QObject>
#include <QTimer>
#include <QUrl>
#include <QVariantList>
#include <memory>

// Address lookup is asynchronous and replaceable in host tests. It neither
// reads the phonebook nor persists resolved points in the user's records.
class TaxiPlatform : public QObject {
    Q_OBJECT
public:
    using QObject::QObject;
    virtual void resolve(const QString& address, quint64 requestId) = 0;
    virtual bool open(const QUrl& url) = 0;
signals:
    void resolved(quint64 requestId, const QVariantList& points, const QString& error);
};

class Taxi : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool pending READ pending NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString destination READ destination NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(QVariantList candidates READ candidates NOTIFY changed)
public:
    explicit Taxi(QObject* parent = nullptr);
    Taxi(std::unique_ptr<TaxiPlatform> platform, int timeoutMs = 20000, QObject* parent = nullptr);
    bool pending() const { return m_pending; }
    bool busy() const { return m_busy; }
    QString destination() const { return m_destination; }
    QString error() const { return m_error; }
    QVariantList candidates() const { return m_candidates; }
    Q_INVOKABLE bool request(const QString& address);
    Q_INVOKABLE bool search(const QString& address);
    Q_INVOKABLE bool selectDestination(int index);
    Q_INVOKABLE void cancel();
signals:
    void changed();
    void requested();
    void finished();
private:
    void acceptResults(quint64 requestId, const QVariantList& points, const QString& error);
    bool launch(double latitude, double longitude);
    std::unique_ptr<TaxiPlatform> m_platform;
    QTimer m_timeout;
    quint64 m_requestId = 0;
    bool m_pending = false, m_busy = false;
    QString m_destination, m_error;
    QVariantList m_candidates;
};
