#include <QtTest>
#include <QTemporaryDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>
#include "Navigator.h"
#include "MapLinks.h"

class FakePlatform final : public MapPlatform {
public:
    QStringList installed {"yandex", "google", "2gis"};
    QStringList failing;
    QList<QPair<QString, QUrl>> opened;
    bool supportsChoice() const override { return true; }
    bool available(const QString& app, const QUrl&) override { return installed.contains(app); }
    bool open(const QString& app, const QUrl& url) override {
        if (!installed.contains(app) || failing.contains(app)) return false;
        opened.append({app, url}); return true;
    }
};
class NavigatorTests : public QObject {
    Q_OBJECT
private slots:
    void installedOnlyAndCancel() {
        QTemporaryDir dir;
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        fake->installed = {"google"};
        Navigator nav(std::move(platform), dir.filePath("maps.json"));
        QSignalSpy choices(&nav, &Navigator::mapChoiceRequested);
        QVERIFY(nav.openRoute("Москва, Ленина, 10"));
        QCOMPARE(choices.count(), 1); QCOMPARE(nav.mapApps().size(), 1);
        QCOMPARE(nav.mapApps().first().toMap().value("id").toString(), "google");
        QVERIFY(!nav.selectMapApp("yandex", true)); QVERIFY(fake->opened.isEmpty());
        nav.cancelMapChoice(); QVERIFY(!nav.mapChoicePending());
        QVERIFY(!QFile::exists(dir.filePath("maps.json")));
    }
    void oneTimeChoiceDoesNotBecomeDefault() {
        QTemporaryDir dir;
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        Navigator nav(std::move(platform), dir.filePath("maps.json"));
        QVERIFY(nav.openRoute(" Дом ", "walking")); QVERIFY(nav.selectMapApp("yandex", false));
        QCOMPARE(fake->opened.size(), 1); QVERIFY(nav.defaultMapApp().isEmpty());
        QVERIFY(nav.openSearch("Додо Пицца")); QVERIFY(nav.mapChoicePending());
        QVERIFY(nav.selectMapApp("2gis", false)); QCOMPARE(fake->opened.last().first, "2gis");
        QVERIFY(fake->opened.last().second.toEncoded().contains("/search/"));
    }
    void rememberedDefaultSurvivesRestartAndCanBeChanged() {
        QTemporaryDir dir;
        {
            auto platform = std::make_unique<FakePlatform>();
            Navigator nav(std::move(platform), dir.filePath("maps.json"));
            QVERIFY(nav.openRoute("Москва")); QVERIFY(nav.selectMapApp("yandex", true));
            QCOMPARE(nav.defaultMapApp(), "yandex");
        }
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        Navigator nav(std::move(platform), dir.filePath("maps.json"));
        QSignalSpy choices(&nav, &Navigator::mapChoiceRequested);
        QVERIFY(nav.openSearch("Вкусно и точка")); QCOMPARE(choices.count(), 0);
        QCOMPARE(fake->opened.last().first, "yandex"); QVERIFY(!nav.mapChoicePending());
        nav.chooseDefaultMap(); QVERIFY(nav.choosingDefaultMap());
        QVERIFY(nav.selectMapApp("google", false)); QCOMPARE(nav.defaultMapApp(), "google");
        const auto count = fake->opened.size(); // Settings must not launch a map.
        nav.chooseDefaultMap(); QVERIFY(nav.alwaysAskForMap());
        QVERIFY(nav.defaultMapApp().isEmpty()); QCOMPARE(fake->opened.size(), count);
        QVERIFY(nav.openRoute("Москва")); QCOMPARE(choices.count(), 3);
    }
    void uninstalledOrFailedDefaultReturnsToChooser() {
        QTemporaryDir dir;
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        Navigator nav(std::move(platform), dir.filePath("maps.json"));
        nav.chooseDefaultMap(); QVERIFY(nav.selectMapApp("google", false));
        fake->installed.removeAll("google");
        QVERIFY(nav.openRoute("Москва")); QVERIFY(nav.mapChoicePending());
        QVERIFY(nav.defaultMapApp().isEmpty()); QCOMPARE(nav.mapApps().size(), 2);
        QVERIFY(fake->opened.isEmpty()); nav.cancelMapChoice();
        nav.chooseDefaultMap(); QVERIFY(nav.selectMapApp("yandex", false));
        fake->failing = {"yandex"};
        QVERIFY(nav.openRoute("Москва")); QVERIFY(nav.mapChoicePending());
        QVERIFY(nav.defaultMapApp().isEmpty()); QVERIFY(!nav.mapChoiceError().isEmpty());
        QVERIFY(fake->opened.isEmpty());
    }
    void removedAfterPromptAndLaunchFailureAreRecoverable() {
        QTemporaryDir dir;
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        Navigator nav(std::move(platform), dir.filePath("maps.json"));
        QVERIFY(nav.openRoute("Москва")); fake->installed.removeAll("2gis");
        QVERIFY(!nav.selectMapApp("2gis", true)); QVERIFY(nav.mapChoicePending());
        fake->failing = {"google"};
        QVERIFY(!nav.selectMapApp("google", true)); QVERIFY(nav.defaultMapApp().isEmpty());
        QVERIFY(nav.mapChoicePending()); QVERIFY(nav.selectMapApp("yandex", false));
        QCOMPARE(fake->opened.size(), 1); QCOMPARE(fake->opened.first().first, "yandex");
    }
    void noAppsAndBlankInputNeverLaunchOrOfferOtherApps() {
        QTemporaryDir dir;
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        fake->installed.clear(); Navigator nav(std::move(platform), dir.filePath("maps.json"));
        QVERIFY(!nav.openRoute("  ")); QVERIFY(!nav.mapChoicePending());
        QVERIFY(nav.openRoute("Москва")); QVERIFY(nav.mapApps().isEmpty());
        QVERIFY(!nav.selectMapApp("browser", true)); QVERIFY(fake->opened.isEmpty());
        QVERIFY(!nav.openSearch("Повторный запрос")); QCOMPARE(nav.mapChoiceDestination(), "Москва");
    }
    void settingsFailureDoesNotLaunchOrPretendToRemember() {
        QTemporaryDir dir;
        QFile blocker(dir.filePath("not-a-directory")); QVERIFY(blocker.open(QIODevice::WriteOnly)); blocker.close();
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        Navigator nav(std::move(platform), dir.filePath("not-a-directory/maps.json"));
        QVERIFY(nav.openRoute("Москва")); QVERIFY(!nav.selectMapApp("google", true));
        QVERIFY(nav.mapChoicePending()); QVERIFY(nav.defaultMapApp().isEmpty());
        QVERIFY(!nav.mapChoiceError().isEmpty()); QVERIFY(fake->opened.isEmpty());
        QVERIFY(nav.selectMapApp("google", false)); QCOMPARE(fake->opened.size(), 1);
    }
    void encodedAddressesAndAllModes() {
        const QString address = QStringLiteral("Москва, А & Б + %?#/~=1");
        for (const QString& mode : {"walking", "driving", "transit", "bicycling"}) {
            const auto google = MapLinks::route("google", address, mode);
            const QUrlQuery g(google); QCOMPARE(g.queryItemValue("destination", QUrl::FullyDecoded), address);
            QCOMPARE(g.queryItemValue("travelmode"), mode); QCOMPARE(g.queryItems().size(), 3);
            const QString yandexAddress = QString(address).remove('~');
            const auto yandex = MapLinks::route("yandex", yandexAddress, mode);
            const QUrlQuery y(yandex); QCOMPARE(y.queryItemValue("rtext", QUrl::FullyDecoded), "~" + yandexAddress);
            QCOMPARE(y.queryItems().size(), 2);
            QVERIFY(MapLinks::search("2gis", address).toEncoded().contains("%2F"));
        }
        const QUrlQuery tildeQuery(MapLinks::route("yandex", "А~Б", "walking"));
        QVERIFY(!tildeQuery.hasQueryItem("rtext"));
        QCOMPARE(tildeQuery.queryItemValue("text", QUrl::FullyDecoded), QStringLiteral("А~Б"));
        QCOMPARE(QUrlQuery(MapLinks::route("google", address, "bad")).queryItemValue("travelmode"), "transit");
        QVERIFY(MapLinks::route("other", address, "walking").isEmpty());
    }
    void twoGisCoordinatesUseLongitudeFirstAndCurrentRouteFormat() {
        const auto link = MapLinks::route("2gis", "55.759725, 37.665247", "transit");
        QCOMPARE(link.toEncoded(), QByteArray("dgis://2gis.ru/directions/tab/bus/points/%7C37.665247,55.759725"));
        QVERIFY(!MapLinks::needsAddressConfirmation("2gis", "-90,180"));
        QVERIFY(MapLinks::needsAddressConfirmation("2gis", "91,37"));
        QVERIFY(MapLinks::needsAddressConfirmation("2gis", "Москва, Ленина, 1"));
        QVERIFY(MapLinks::route("2gis", "Москва, Ленина, 1", "walking").path().startsWith("/search/"));
    }
};
QTEST_GUILESS_MAIN(NavigatorTests)
#include "test-navigator.moc"
