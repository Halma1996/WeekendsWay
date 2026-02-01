#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "Navigator.h"
#include "Storage.h"

static QObject* navigator_provider(QQmlEngine*, QJSEngine*)
{
    return new Navigator();
}

static QObject* storage_provider(QQmlEngine*, QJSEngine*)
{
    return new Storage();
}

int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);

    // force Material style for consistent look across platforms.
    QQuickStyle::setStyle("Material");

    // Register C++ singletons in QML as:

    qmlRegisterSingletonType<Navigator>("App", 1, 0, "Navigator", navigator_provider);
    qmlRegisterSingletonType<Storage>("App", 1, 0, "Storage", storage_provider);

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/Main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );

    engine.load(url);
    return app.exec();
}
