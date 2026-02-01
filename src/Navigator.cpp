#include "Navigator.h"

#include <QDesktopServices>
#include <QUrl>
#include <QUrlQuery>

#if defined(Q_OS_ANDROID)
  #include <QAndroidJniObject>
  #include <QtAndroid>
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

bool Navigator::openRoute(const QString& destination, const QString& travelMode)
{
    if (destination.trimmed().isEmpty())
        return false;

#if defined(Q_OS_ANDROID)
    // Prefer native intent if possible.
    // "google.navigation:q=<query>" typically opens Google Maps. Other apps may also handle it.
    const QString uriStr = QString("google.navigation:q=%1").arg(QString::fromUtf8(QUrl::toPercentEncoding(destination)));

    QAndroidJniObject uri = QAndroidJniObject::callStaticObjectMethod(
        "android/net/Uri",
        "parse",
        "(Ljava/lang/String;)Landroid/net/Uri;",
        QAndroidJniObject::fromString(uriStr).object<jstring>()
    );

    QAndroidJniObject actionView = QAndroidJniObject::getStaticObjectField(
        "android/content/Intent",
        "ACTION_VIEW",
        "Ljava/lang/String;"
    );

    QAndroidJniObject intent("android/content/Intent",
                            "(Ljava/lang/String;Landroid/net/Uri;)V",
                            actionView.object<jstring>(),
                            uri.object<jobject>());

    if (intent.isValid()) {
        QtAndroid::startActivity(intent, 0);
        return true;
    }
    // If intent creation failed, fall back to web.
#endif

    return QDesktopServices::openUrl(googleMapsDirectionsUrl(destination, travelMode));
}

bool Navigator::openSearch(const QString& query)
{
    if (query.trimmed().isEmpty())
        return false;

#if defined(Q_OS_ANDROID)
    const QString uriStr = QString("geo:0,0?q=%1").arg(QString::fromUtf8(QUrl::toPercentEncoding(query)));

    QAndroidJniObject uri = QAndroidJniObject::callStaticObjectMethod(
        "android/net/Uri",
        "parse",
        "(Ljava/lang/String;)Landroid/net/Uri;",
        QAndroidJniObject::fromString(uriStr).object<jstring>()
    );

    QAndroidJniObject actionView = QAndroidJniObject::getStaticObjectField(
        "android/content/Intent",
        "ACTION_VIEW",
        "Ljava/lang/String;"
    );

    QAndroidJniObject intent("android/content/Intent",
                            "(Ljava/lang/String;Landroid/net/Uri;)V",
                            actionView.object<jstring>(),
                            uri.object<jobject>());

    if (intent.isValid()) {
        QtAndroid::startActivity(intent, 0);
        return true;
    }
#endif

    return QDesktopServices::openUrl(googleMapsSearchUrl(query));
}
