#include "Navigator.h"

#include <QDesktopServices>
#include <QUrl>
#include <QUrlQuery>

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniObject>
#include <jni.h>
#endif

Navigator::Navigator(QObject* parent) : QObject(parent) {}

static QUrl googleMapsDirectionsUrl(const QString& destination, const QString& travelMode)
{
    QUrl url("https://www.google.com/maps/dir/");
    QUrlQuery q;
    q.addQueryItem("api", "1");
    q.addQueryItem("destination", destination);
    q.addQueryItem("travelmode", travelMode.isEmpty() ? "transit" : travelMode);
    url.setQuery(q);
    return url;
}

static QUrl googleMapsSearchUrl(const QString& query)
{
    QUrl url("https://www.google.com/maps/search/");
    QUrlQuery q;
    q.addQueryItem("api", "1");
    q.addQueryItem("query", query);
    url.setQuery(q);
    return url;
}

#ifdef Q_OS_ANDROID
static bool startAndroidViewIntent(const QString& uriStr)
{
    const QJniObject uriString = QJniObject::fromString(uriStr);

    const QJniObject uri = QJniObject::callStaticObjectMethod(
        "android/net/Uri",
        "parse",
        "(Ljava/lang/String;)Landroid/net/Uri;",
        uriString.object<jstring>());

    const QJniObject actionView = QJniObject::getStaticObjectField(
        "android/content/Intent",
        "ACTION_VIEW",
        "Ljava/lang/String;");

    QJniObject intent("android/content/Intent",
                      "(Ljava/lang/String;Landroid/net/Uri;)V",
                      actionView.object<jstring>(),
                      uri.object<jobject>());

    const QJniObject context = QNativeInterface::QAndroidApplication::context();

    if (!intent.isValid() || !context.isValid()
        || !QNativeInterface::QAndroidApplication::isActivityContext()) {
        return false;
    }

    context.callMethod<void>(
        "startActivity",
        "(Landroid/content/Intent;)V",
        intent.object<jobject>());

    return true;
}
#endif

bool Navigator::openRoute(const QString& destination, const QString& travelMode)
{
    if (destination.trimmed().isEmpty())
        return false;

#ifdef Q_OS_ANDROID
    const QString uriStr =
        QString("google.navigation:q=%1")
            .arg(QString::fromUtf8(QUrl::toPercentEncoding(destination)));

    if (startAndroidViewIntent(uriStr))
        return true;
#endif

    return QDesktopServices::openUrl(googleMapsDirectionsUrl(destination, travelMode));
}

bool Navigator::openSearch(const QString& query)
{
    if (query.trimmed().isEmpty())
        return false;

#ifdef Q_OS_ANDROID
    const QString uriStr =
        QString("geo:0,0?q=%1")
            .arg(QString::fromUtf8(QUrl::toPercentEncoding(query)));

    if (startAndroidViewIntent(uriStr))
        return true;
#endif

    return QDesktopServices::openUrl(googleMapsSearchUrl(query));
}