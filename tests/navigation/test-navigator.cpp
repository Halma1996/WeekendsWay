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
            QVERIFY(MapLinks::search("2gis", address).toEncoded().contains("%2F"));
        }
        const QUrlQuery tildeQuery(MapLinks::route("yandex", "А~Б", "walking"));
        QVERIFY(!tildeQuery.hasQueryItem("rtext"));
        QCOMPARE(tildeQuery.queryItemValue("text", QUrl::FullyDecoded), QStringLiteral("А~Б"));
        QCOMPARE(QUrlQuery(MapLinks::route("google", address, "bad")).queryItemValue("travelmode"), "transit");
        QVERIFY(MapLinks::route("other", address, "walking").isEmpty());
    }
    void yandexTextAddressUsesSearchAndPreservesEncoding_data() {
        QTest::addColumn<QString>("address");
        QTest::newRow("home") << QStringLiteral("Москва, ул. Ленина, дом 10, корпус 2");
        QTest::newRow("fractional-house") << QStringLiteral("Санкт-Петербург, ул. Зодчего Росси, д. 12/3, лит. Б");
        QTest::newRow("special-characters") << QStringLiteral("Орёл, ул. А & Б + %?#/~=1, д. 7/2, корп. №3");
        QTest::newRow("encoded-looking-text") << QStringLiteral("Москва, %D0%90, дом 1 &rtt=auto#точка");
        QTest::newRow("internal-whitespace") << QStringLiteral("  Тверь,  ул. Мира,\nд. 1/2\tкорп. 3  ");
    }
    void yandexTextAddressUsesSearchAndPreservesEncoding() {
        QFETCH(QString, address);
        for (const QString& mode : {"walking", "driving", "transit", "bicycling", "unknown"}) {
            const auto url = MapLinks::route("yandex", address, mode);
            QVERIFY(url.isValid()); QCOMPARE(url.scheme(), "yandexmaps");
            QCOMPARE(url.host(), "maps.yandex.ru"); QCOMPARE(url.path(), "/");
            QVERIFY(!url.hasFragment());
            const QUrlQuery query(url);
            QCOMPARE(query.queryItems().size(), 1);
            QCOMPARE(query.queryItemValue("text", QUrl::FullyDecoded), address.trimmed());
            QVERIFY(!query.hasQueryItem("rtext")); QVERIFY(!query.hasQueryItem("rtt"));
            QCOMPARE(url, MapLinks::search("yandex", address));
            QVERIFY(MapLinks::needsAddressConfirmation("yandex", address));
        }
        const auto encoded = MapLinks::route("yandex", address, "walking").toEncoded();
        QVERIFY(!encoded.contains(' '));
        QVERIFY(encoded.contains("%D0") || encoded.contains("%D1"));
        if (address.contains('&')) QVERIFY(encoded.contains("%26"));
        if (address.contains('+')) QVERIFY(encoded.contains("%2B"));
        if (address.contains('%')) QVERIFY(encoded.contains("%25"));
        if (address.contains('?')) QVERIFY(encoded.contains("%3F"));
        if (address.contains('#')) QVERIFY(encoded.contains("%23"));
        if (address.contains('/')) QVERIFY(encoded.contains("%2F"));
    }
    void yandexCoordinateRoutesPreserveAllTransportModes() {
        const QList<QPair<QString, QString>> modes {
            {"walking", "pd"}, {"driving", "auto"}, {"transit", "mt"},
            {"bicycling", "bc"}, {"unknown", "mt"}
        };
        for (const auto& mode : modes) {
            const auto url = MapLinks::route("yandex", "  +55.759725 , +37.665247  ", mode.first);
            QCOMPARE(url.toEncoded(), QByteArray("yandexmaps://maps.yandex.ru/?rtext=~55.759725,37.665247&rtt=") + mode.second.toLatin1());
            const QUrlQuery query(url);
            QCOMPARE(query.queryItemValue("rtext"), "~55.759725,37.665247");
            QCOMPARE(query.queryItemValue("rtt"), mode.second);
            QCOMPARE(query.queryItems().size(), 2); QVERIFY(!query.hasQueryItem("text"));
        }
        for (const QString& destination : {"-90,180", "90,-180", "0,0", "-33.8688,151.2093"}) {
            QVERIFY(!MapLinks::needsAddressConfirmation("yandex", destination));
            const QUrlQuery query(MapLinks::route("yandex", destination, "walking"));
            QCOMPARE(query.queryItemValue("rtext"), "~" + destination);
            QVERIFY(!query.hasQueryItem("text"));
        }
    }
    void invalidYandexCoordinatesAreNeverRoutePoints_data() {
        QTest::addColumn<QString>("destination");
        for (const char* value : {"91,37", "-90.0001,0", "55,181", "0,-180.0001",
                "NaN,37", "55,Inf", "1e309,37", "55.7", "55.7,37.6,1",
                "55,7;37,6", "55.7;37.6", "55.7,37.6 garbage", "55.7,37.6~1,2",
                "55.7,37.6&rtt=auto", "55..7,37.6"}) {
            QTest::newRow(value) << QString::fromLatin1(value);
        }
    }
    void invalidYandexCoordinatesAreNeverRoutePoints() {
        QFETCH(QString, destination);
        for (const QString& mode : {"walking", "driving", "transit", "bicycling"}) {
            const QUrlQuery query(MapLinks::route("yandex", destination, mode));
            QCOMPARE(query.queryItems().size(), 1);
            QCOMPARE(query.queryItemValue("text", QUrl::FullyDecoded), destination);
            QVERIFY(!query.hasQueryItem("rtext")); QVERIFY(!query.hasQueryItem("rtt"));
            QVERIFY(MapLinks::needsAddressConfirmation("yandex", destination));
        }
    }
    void yandexAddressThroughChooserAndRememberedDefault() {
        const QString address = QStringLiteral("  Москва, ул. А & Б, д. 12/3, корп. №2 + %?#~  ");
        QTemporaryDir dir;
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        Navigator nav(std::move(platform), dir.filePath("maps.json"));
        QSignalSpy choices(&nav, &Navigator::mapChoiceRequested);
        QVERIFY(nav.openRoute(address, "transit"));
        QCOMPARE(nav.mapChoiceDestination(), address.trimmed());
        QCOMPARE(nav.mapApps().size(), 3);
        const auto yandex = nav.mapApps().first().toMap();
        QCOMPARE(yandex.value("id").toString(), "yandex");
        QVERIFY(yandex.value("note").toString().contains(QStringLiteral("поиск адреса")));
        QVERIFY(yandex.value("note").toString().contains(QStringLiteral("способ передвижения")));
        QVERIFY(nav.mapApps().at(1).toMap().value("note").toString().isEmpty());
        QCOMPARE(nav.mapApps().at(2).toMap().value("note").toString(), QStringLiteral("Выберите адрес в 2ГИС и нажмите «Сюда»"));
        QVERIFY(nav.selectMapApp("yandex", true));
        QCOMPARE(fake->opened.last().second, MapLinks::search("yandex", address));
        QCOMPARE(nav.defaultMapApp(), "yandex");
        QVERIFY(nav.openRoute(address, "walking")); QCOMPARE(choices.count(), 1);
        QCOMPARE(fake->opened.size(), 2);
        QCOMPARE(fake->opened.last().second, MapLinks::search("yandex", address));
        QVERIFY(nav.openRoute("55.759725,37.665247", "transit")); QCOMPARE(choices.count(), 1);
        QCOMPARE(QUrlQuery(fake->opened.last().second).queryItemValue("rtext"), "~55.759725,37.665247");
        for (const auto& entry : nav.mapApps()) QVERIFY(entry.toMap().value("note").toString().isEmpty());
    }
    void yandexVenueSearchRemainsSearch() {
        QTemporaryDir dir;
        auto platform = std::make_unique<FakePlatform>(); auto* fake = platform.get();
        Navigator nav(std::move(platform), dir.filePath("maps.json"));
        for (const QString& name : {QStringLiteral("Вкусно и точка"), QStringLiteral("Rostic's"),
                QStringLiteral("Burger King"), QStringLiteral("Papa John's"),
                QStringLiteral("Pizza Hut"), QStringLiteral("Додо Пицца")}) {
            QVERIFY(nav.openSearch(name));
            for (const auto& entry : nav.mapApps()) QVERIFY(entry.toMap().value("note").toString().isEmpty());
            QVERIFY(nav.selectMapApp("yandex", false));
            const QUrlQuery query(fake->opened.last().second);
            QCOMPARE(query.queryItems().size(), 1);
            QCOMPARE(query.queryItemValue("text", QUrl::FullyDecoded), name);
            QVERIFY(!query.hasQueryItem("rtext")); QVERIFY(!query.hasQueryItem("rtt"));
        }
        QCOMPARE(fake->opened.size(), 6);
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
