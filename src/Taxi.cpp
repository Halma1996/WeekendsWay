#include "Taxi.h"
#include "TaxiLinks.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QThread>

#ifdef Q_OS_ANDROID
#include <QJniEnvironment>
#include <QJniObject>
#endif

namespace {
class DeviceTaxiPlatform final : public TaxiPlatform {
public:
    void resolve(const QString& address, quint64 requestId) override
    {
#ifdef Q_OS_ANDROID
        struct Result { QVariantList points; QString error; };
        const auto result = std::make_shared<Result>();
        // JNI returns within a bounded wait. No provider call or thread wait
        // runs on the GUI thread, including during cancellation/destruction.
        auto* worker = QThread::create([address, result]() {
            const auto context = QNativeInterface::QAndroidApplication::context();
            const auto query = QJniObject::fromString(address);
            const auto response = QJniObject::callStaticObjectMethod(
                "org/weekendsway/TaxiBridge", "resolve",
                "(Landroid/content/Context;Ljava/lang/String;)Ljava/lang/String;",
                context.object<jobject>(), query.object<jstring>());
            QJniEnvironment env;
            if (env->ExceptionCheck()) env->ExceptionClear();
            if (!response.isValid()) {
                result->error = QStringLiteral("Не удалось определить адрес на этом устройстве.");
                return;
            }
            QJsonParseError parseError;
            const auto document = QJsonDocument::fromJson(response.toString().toUtf8(), &parseError);
            if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
                result->error = QStringLiteral("Не удалось прочитать найденные адреса.");
                return;
            }
            const auto payload = document.object();
            const auto failure = payload.value(QStringLiteral("error")).toString();
            if (failure == "unavailable")
                result->error = QStringLiteral("На устройстве недоступен поиск адресов. Укажите координаты широта, долгота.");
            else if (failure == "timeout")
                result->error = QStringLiteral("Поиск адреса занял слишком много времени. Проверьте интернет и повторите попытку.");
            else if (!failure.isEmpty())
                result->error = QStringLiteral("Не удалось найти адрес. Проверьте интернет или уточните город, улицу и дом.");
            else if (!payload.value(QStringLiteral("points")).isArray())
                result->error = QStringLiteral("Не удалось прочитать найденные адреса.");
            else
                result->points = payload.value(QStringLiteral("points")).toArray().toVariantList();
        });
        connect(worker, &QThread::finished, this, [this, result, requestId]() {
            emit resolved(requestId, result->points, result->error);
        });
        connect(worker, &QThread::finished, worker, &QObject::deleteLater);
        worker->start();
#else
        Q_UNUSED(address)
        emit resolved(requestId, {}, QStringLiteral("Поиск адреса для такси доступен в Android-приложении."));
#endif
    }

    bool open(const QUrl& url) override
    {
#ifdef Q_OS_ANDROID
        const auto context = QNativeInterface::QAndroidApplication::context();
        const auto link = QJniObject::fromString(url.toString(QUrl::FullyEncoded));
        const auto opened = QJniObject::callStaticMethod<jboolean>(
            "org/weekendsway/TaxiBridge", "open", "(Landroid/content/Context;Ljava/lang/String;)Z",
            context.object<jobject>(), link.object<jstring>());
        QJniEnvironment env;
        if (env->ExceptionCheck()) { env->ExceptionClear(); return false; }
        return opened;
#else
        Q_UNUSED(url)
        return false;
#endif
    }
};
}

Taxi::Taxi(QObject* parent) : Taxi(std::make_unique<DeviceTaxiPlatform>(), 20000, parent) {}

Taxi::Taxi(std::unique_ptr<TaxiPlatform> platform, int timeoutMs, QObject* parent)
    : QObject(parent), m_platform(std::move(platform))
{
    m_timeout.setSingleShot(true);
    m_timeout.setInterval(timeoutMs);
    connect(m_platform.get(), &TaxiPlatform::resolved, this, &Taxi::acceptResults);
    connect(&m_timeout, &QTimer::timeout, this, [this]() {
        if (!m_pending || !m_busy) return;
        ++m_requestId; // Ignore a provider result arriving after the deadline.
        m_busy = false;
        m_error = QStringLiteral("Поиск адреса занял слишком много времени. Повторите попытку или укажите координаты.");
        emit changed();
    });
}

bool Taxi::request(const QString& address)
{
    if (address.trimmed().isEmpty()) return false;
    cancel();
    m_pending = true;
    m_destination = address.trimmed();
    emit changed();
    // Open the dialog first so a failed coordinate launch remains recoverable.
    emit requested();
    search(m_destination);
    return true; // Accepted; lookup/launch errors are shown in the dialog.
}

bool Taxi::search(const QString& address)
{
    if (!m_pending) return false;
    ++m_requestId;
    m_timeout.stop();
    m_busy = false;
    m_candidates.clear();
    m_error.clear();
    m_destination = address.trimmed();
    if (m_destination.isEmpty()) {
        m_error = QStringLiteral("Укажите адрес назначения.");
        emit changed();
        return false;
    }
    double latitude = 0, longitude = 0;
    if (TaxiLinks::coordinates(m_destination, latitude, longitude)) {
        emit changed();
        return launch(latitude, longitude);
    }
    m_busy = true;
    emit changed();
    m_timeout.start();
    m_platform->resolve(m_destination, m_requestId);
    return true;
}

void Taxi::acceptResults(quint64 requestId, const QVariantList& points, const QString& error)
{
    if (!m_pending || !m_busy || requestId != m_requestId) return;
    m_timeout.stop();
    m_busy = false;
    m_error = error;
    m_candidates.clear();
    QSet<QString> seen;
    if (error.isEmpty()) {
        for (const auto& value : points) {
            const auto point = value.toMap();
            bool latOk = false, lonOk = false;
            const double latitude = point.value("latitude").toDouble(&latOk);
            const double longitude = point.value("longitude").toDouble(&lonOk);
            const auto label = point.value("label").toString().trimmed();
            if (!latOk || !lonOk || label.isEmpty() || !TaxiLinks::validCoordinates(latitude, longitude)) continue;
            const auto identity = TaxiLinks::destination(latitude, longitude).toString();
            if (seen.contains(identity)) continue;
            seen.insert(identity);
            m_candidates.append(QVariantMap{{"latitude", latitude}, {"longitude", longitude}, {"label", label}});
            if (m_candidates.size() == 5) break;
        }
        if (m_candidates.isEmpty())
            m_error = QStringLiteral("Адрес не найден. Уточните город, улицу и дом. Для сети заведений укажите адрес нужного филиала.");
    }
    emit changed();
}

bool Taxi::selectDestination(int index)
{
    if (!m_pending || m_busy || index < 0 || index >= m_candidates.size()) return false;
    const auto point = m_candidates.at(index).toMap();
    return launch(point.value("latitude").toDouble(), point.value("longitude").toDouble());
}

bool Taxi::launch(double latitude, double longitude)
{
    const auto url = TaxiLinks::destination(latitude, longitude);
    if (url.isEmpty() || !m_platform->open(url)) {
        m_error = QStringLiteral("Не удалось открыть Яндекс Go. Установите или включите приложение и повторите попытку.");
        emit changed();
        return false;
    }
    cancel();
    return true;
}

void Taxi::cancel()
{
    ++m_requestId;
    m_timeout.stop();
    const bool wasPending = m_pending;
    m_pending = m_busy = false;
    m_candidates.clear();
    m_error.clear();
    emit changed();
    if (wasPending) emit finished();
}
