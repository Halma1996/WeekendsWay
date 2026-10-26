#include "Contacts.h"

#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QThread>
#include <memory>

#ifdef Q_OS_ANDROID
#include <QJniEnvironment>
#include <QJniObject>
#include <QPermissions>
#endif

namespace {
const QString permissionError = QStringLiteral(
    "Доступ к контактам не разрешён. Включите разрешение «Контакты» "
    "в настройках приложения и повторите попытку.");
}

Contacts::Contacts(QObject* parent) : QObject(parent) {}

Contacts::~Contacts()
{
    if (m_worker)
        m_worker->wait();
}

bool Contacts::supported() const
{
#ifdef Q_OS_ANDROID
    return true;
#else
    return false;
#endif
}

void Contacts::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void Contacts::finishWithError(const QString& message)
{
    m_error = message;
    emit errorChanged();
    setBusy(false);
}

void Contacts::readContacts()
{
    if (m_busy)
        return;
    m_error.clear();
    emit errorChanged();
    setBusy(true);

#ifdef Q_OS_ANDROID
    QContactsPermission permission;
    permission.setAccessMode(QContactsPermission::ReadOnly);
    if (qApp->checkPermission(permission) == Qt::PermissionStatus::Granted) {
        startReading();
        return;
    }
    qApp->requestPermission(permission, this, [this](const QPermission& result) {
        if (result.status() == Qt::PermissionStatus::Granted)
            startReading();
        else
            finishWithError(permissionError);
    });
#else
    finishWithError(QStringLiteral("Контакты телефона доступны в Android-приложении."));
#endif
}

void Contacts::startReading()
{
#ifdef Q_OS_ANDROID
    // The provider may contain thousands of records: never query it on the UI thread.
    struct Result {
        QVariantList contacts;
        QString error;
    };
    const auto result = std::make_shared<Result>();
    m_worker = QThread::create([result]() {
        const QJniObject context = QNativeInterface::QAndroidApplication::context();
        const QJniObject response = QJniObject::callStaticObjectMethod(
            "org/weekendsway/ContactsBridge", "readContacts",
            "(Landroid/content/Context;)Ljava/lang/String;", context.object<jobject>());
        QJniEnvironment env;
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
            result->error = QStringLiteral("Не удалось прочитать контакты. Повторите попытку.");
            return;
        }
        if (!response.isValid()) {
            result->error = QStringLiteral("Не удалось подключиться к контактам телефона.");
            return;
        }
        QJsonParseError parseError;
        const auto document = QJsonDocument::fromJson(response.toString().toUtf8(), &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
            result->error = QStringLiteral("Не удалось прочитать список контактов.");
            return;
        }
        const auto payload = document.object();
        if (payload.value(QStringLiteral("error")).toString() == QStringLiteral("permission")) {
            result->error = permissionError;
        } else if (!payload.value(QStringLiteral("contacts")).isArray()) {
            result->error = QStringLiteral("Не удалось прочитать контакты. Повторите попытку.");
        } else {
            result->contacts = payload.value(QStringLiteral("contacts")).toArray().toVariantList();
        }
    });
    m_worker->setParent(this);
    connect(m_worker, &QThread::finished, this, [this, result]() {
        m_worker->deleteLater();
        m_worker = nullptr;
        if (!result->error.isEmpty()) {
            finishWithError(result->error);
            return;
        }
        setBusy(false);
        emit loaded(result->contacts);
    });
    m_worker->start();
#endif
}
