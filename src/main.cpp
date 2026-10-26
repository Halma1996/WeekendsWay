#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "Navigator.h"
#include "Storage.h"
#include "Contacts.h"
#include "Taxi.h"

/// сигнатура ф-ций для использования в qmlRegisterSingletonType
static QObject* navigator_provider(QQmlEngine*, QJSEngine*)
{
    return new Navigator();
}

static QObject* storage_provider(QQmlEngine*, QJSEngine*)
{
    return new Storage();
}

static QObject* contacts_provider(QQmlEngine*, QJSEngine*)
{
    return new Contacts();
}

static QObject* taxi_provider(QQmlEngine*, QJSEngine*)
{
    return new Taxi();
}

int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);

    QQuickStyle::setStyle("Material");

    // Регистрируем с++ синглтоны в qml
    qmlRegisterSingletonType<Navigator>("App", 1, 0, "Navigator", navigator_provider);
    qmlRegisterSingletonType<Storage>("App", 1, 0, "Storage", storage_provider);
    qmlRegisterSingletonType<Contacts>("App", 1, 0, "Contacts", contacts_provider);
    qmlRegisterSingletonType<Taxi>("App", 1, 0, "Taxi", taxi_provider);

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
