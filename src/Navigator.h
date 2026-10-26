#pragma once
#include <QObject>
#include <QString>
#include <QUrl>
#include <QVariantList>
#include <memory>

// The platform boundary keeps Android discovery/launching separate from choice
// and persistence, which can be tested without installed third-party apps.
class MapPlatform {
public:
    virtual ~MapPlatform() = default;
    virtual bool supportsChoice() const = 0;
    virtual bool available(const QString& app, const QUrl& url) = 0;
    virtual bool open(const QString& app, const QUrl& url) = 0;
};

class Navigator : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool mapChoiceSupported READ mapChoiceSupported CONSTANT)
    Q_PROPERTY(QVariantList mapApps READ mapApps NOTIFY mapAppsChanged)
    Q_PROPERTY(QString defaultMapApp READ defaultMapApp NOTIFY defaultMapChanged)
    Q_PROPERTY(QString defaultMapName READ defaultMapName NOTIFY defaultMapChanged)
    Q_PROPERTY(QString mapChoiceError READ mapChoiceError NOTIFY mapChoiceChanged)
    Q_PROPERTY(QString mapChoiceDestination READ mapChoiceDestination NOTIFY mapChoiceChanged)
    Q_PROPERTY(bool choosingDefaultMap READ choosingDefaultMap NOTIFY mapChoiceChanged)
    Q_PROPERTY(bool mapChoicePending READ mapChoicePending NOTIFY mapChoiceChanged)
public:
    explicit Navigator(QObject* parent = nullptr);
    Navigator(std::unique_ptr<MapPlatform> platform, const QString& settingsPath, QObject* parent = nullptr);
    ~Navigator() override;
    bool mapChoiceSupported() const;
    QVariantList mapApps() const { return m_apps; }
    QString defaultMapApp() const { return m_default; }
    QString defaultMapName() const;
    QString mapChoiceError() const { return m_error; }
    QString mapChoiceDestination() const { return m_destination; }
    bool choosingDefaultMap() const { return m_defaults; }
    bool mapChoicePending() const { return m_pending; }

    Q_INVOKABLE bool openRoute(const QString& destination, const QString& travelMode = "transit");
    Q_INVOKABLE bool openSearch(const QString& query);
    Q_INVOKABLE void chooseDefaultMap();
    Q_INVOKABLE bool selectMapApp(const QString& app, bool remember);
    Q_INVOKABLE bool alwaysAskForMap();
    Q_INVOKABLE void cancelMapChoice();
    Q_INVOKABLE void refreshMapApps();
signals:
    void mapAppsChanged();
    void defaultMapChanged();
    void mapChoiceChanged();
    void mapChoiceRequested();
    void mapChoiceFinished();
private:
    bool request(const QString& destination, const QString& mode, bool search);
    QUrl requestUrl(const QString& app) const;
    bool containsApp(const QString& app) const;
    bool saveDefault(const QString& app);
    void setError(const QString& error);
    void finishChoice();
    std::unique_ptr<MapPlatform> m_platform;
    QString m_settingsPath, m_default, m_error, m_destination, m_mode;
    QVariantList m_apps;
    bool m_search = false, m_defaults = false, m_pending = false;
};
