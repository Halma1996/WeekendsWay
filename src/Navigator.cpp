#include "Navigator.h"
#include "MapLinks.h"
#include <QCoreApplication>
#include <QGuiApplication>
#include <QDesktopServices>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#endif

namespace {
class NativeMapPlatform final : public MapPlatform {
public:
    bool supportsChoice() const override {
#ifdef Q_OS_ANDROID
        return true;
#else
        return false;
#endif
    }
    bool available(const QString& app, const QUrl& url) override { return call("isAvailable", app, url); }
    bool open(const QString& app, const QUrl& url) override {
#ifdef Q_OS_ANDROID
        return call("open", app, url);
#else
        Q_UNUSED(app);
        return QDesktopServices::openUrl(url);
#endif
    }
private:
    bool call(const char* method, const QString& app, const QUrl& url) {
#ifdef Q_OS_ANDROID
        const auto package = MapLinks::packageName(app);
        if (package.isEmpty() || !url.isValid()) return false;
        const auto context = QNativeInterface::QAndroidApplication::context();
        const auto packageObject = QJniObject::fromString(package);
        const auto urlObject = QJniObject::fromString(url.toString(QUrl::FullyEncoded));
        const auto result = QJniObject::callStaticMethod<jboolean>("org/weekendsway/MapsBridge", method,
            "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)Z",
            context.object<jobject>(), packageObject.object<jstring>(), urlObject.object<jstring>());
        QJniEnvironment env;
        if (env->ExceptionCheck()) { env->ExceptionClear(); return false; }
        return result == JNI_TRUE;
#else
        Q_UNUSED(method); Q_UNUSED(app); Q_UNUSED(url);
        return false;
#endif
    }
};
}

Navigator::Navigator(QObject* parent)
    : Navigator(std::make_unique<NativeMapPlatform>(),
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/maps.json", parent) {}
Navigator::Navigator(std::unique_ptr<MapPlatform> platform, const QString& settingsPath, QObject* parent)
    : QObject(parent), m_platform(std::move(platform)), m_settingsPath(settingsPath)
{
    QFile file(m_settingsPath);
    if (file.open(QIODevice::ReadOnly)) {
        const auto saved = QJsonDocument::fromJson(file.readAll()).object().value("defaultApp").toString();
        if (MapLinks::appIds().contains(saved)) m_default = saved;
    }
    refreshMapApps();
    if (auto* app = qobject_cast<QGuiApplication*>(QCoreApplication::instance())) {
        connect(app, &QGuiApplication::applicationStateChanged, this, [this](Qt::ApplicationState state) {
            if (state == Qt::ApplicationActive) refreshMapApps();
        });
    }
}
Navigator::~Navigator() = default;
bool Navigator::mapChoiceSupported() const { return m_platform->supportsChoice(); }
QString Navigator::defaultMapName() const
{
    return m_default.isEmpty() ? QStringLiteral("Всегда спрашивать") : MapLinks::appName(m_default);
}
QUrl Navigator::requestUrl(const QString& app) const
{
    if (m_defaults || !m_pending) return MapLinks::search(app, QStringLiteral("кафе"));
    return m_search ? MapLinks::search(app, m_destination) : MapLinks::route(app, m_destination, m_mode);
}
bool Navigator::containsApp(const QString& app) const
{
    for (const auto& entry : m_apps) if (entry.toMap().value("id").toString() == app) return true;
    return false;
}
void Navigator::setError(const QString& error) { m_error = error; emit mapChoiceChanged(); }
void Navigator::refreshMapApps()
{
    QVariantList apps;
    if (mapChoiceSupported()) {
        for (const auto& id : MapLinks::appIds()) {
            if (!m_platform->available(id, requestUrl(id))) continue;
            const bool confirm = m_pending && !m_defaults && !m_search && MapLinks::needsAddressConfirmation(id, m_destination);
            apps.append(QVariantMap{{"id", id}, {"name", MapLinks::appName(id)},
                {"note", confirm ? QStringLiteral("Выберите адрес в 2ГИС и нажмите «Сюда»") : QString()}});
        }
    }
    if (m_apps != apps) { m_apps = apps; emit mapAppsChanged(); }
    // A missing/disabled default must not silently redirect to a different app.
    if (mapChoiceSupported() && !m_default.isEmpty() && !containsApp(m_default)) {
        if (!saveDefault(QString())) {
            m_default.clear();
            emit defaultMapChanged();
        }
    }
}
bool Navigator::saveDefault(const QString& app)
{
    if (!QDir().mkpath(QFileInfo(m_settingsPath).absolutePath())) {
        setError(QStringLiteral("Не удалось сохранить выбор карт. Повторите попытку.")); return false;
    }
    QSaveFile file(m_settingsPath);
    const auto bytes = QJsonDocument(QJsonObject{{"defaultApp", app}}).toJson(QJsonDocument::Compact);
    if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size() || !file.commit()) {
        setError(QStringLiteral("Не удалось сохранить выбор карт. Повторите попытку.")); return false;
    }
    if (m_default != app) { m_default = app; emit defaultMapChanged(); }
    return true;
}
bool Navigator::request(const QString& destination, const QString& mode, bool search)
{
    if (destination.trimmed().isEmpty() || m_pending) return false;
    if (!mapChoiceSupported())
        return m_platform->open("google", search ? MapLinks::search("google", destination) : MapLinks::route("google", destination, mode));
    m_destination = destination.trimmed(); m_mode = mode; m_search = search; m_defaults = false; m_pending = true;
    setError({});
    refreshMapApps();
    if (!m_default.isEmpty() && containsApp(m_default)) {
        const auto app = m_default;
        if (m_platform->open(app, requestUrl(app))) { finishChoice(); return true; }
        saveDefault({});
        refreshMapApps();
        setError(QStringLiteral("Не удалось открыть выбранные карты. Выберите приложение ещё раз."));
    }
    emit mapChoiceChanged();
    emit mapChoiceRequested();
    return true;
}
bool Navigator::openRoute(const QString& destination, const QString& mode) { return request(destination, mode, false); }
bool Navigator::openSearch(const QString& query) { return request(query, {}, true); }
void Navigator::chooseDefaultMap()
{
    if (!mapChoiceSupported() || m_pending) return;
    m_defaults = true; m_pending = true; m_destination.clear(); m_mode.clear(); m_search = false;
    setError({}); refreshMapApps(); emit mapChoiceChanged(); emit mapChoiceRequested();
}
bool Navigator::selectMapApp(const QString& app, bool remember)
{
    if (!m_pending) return false;
    refreshMapApps();
    if (!containsApp(app)) { setError(QStringLiteral("Это приложение недоступно. Выберите другое.")); return false; }
    if (m_defaults) {
        if (!saveDefault(app)) return false;
        finishChoice(); return true;
    }
    const auto previous = m_default;
    if (remember && !saveDefault(app)) return false;
    if (!m_platform->open(app, requestUrl(app))) {
        if (remember) saveDefault(previous);
        refreshMapApps();
        setError(QStringLiteral("Не удалось открыть приложение. Выберите другое или повторите попытку."));
        return false;
    }
    finishChoice(); return true;
}
bool Navigator::alwaysAskForMap()
{
    if (!m_pending || !m_defaults || !saveDefault({})) return false;
    finishChoice(); return true;
}
void Navigator::finishChoice()
{
    m_pending = false; m_defaults = false; m_destination.clear(); m_mode.clear(); m_error.clear();
    emit mapChoiceChanged(); emit mapChoiceFinished();
}
void Navigator::cancelMapChoice() { if (m_pending) finishChoice(); }
