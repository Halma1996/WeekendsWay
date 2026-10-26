#include <QtTest>
#include <QUrlQuery>
#include <limits>
#include "Taxi.h"
#include "TaxiLinks.h"

class FakeTaxiPlatform final : public TaxiPlatform {
public:
    QList<QPair<QString, quint64>> lookups;
    QList<QUrl> opened;
    bool failOpen = false;
    void resolve(const QString& address, quint64 id) override { lookups.append({address, id}); }
    bool open(const QUrl& url) override {
        if (failOpen) return false;
        opened.append(url);
        return true;
    }
    void answer(quint64 id, const QVariantList& points, const QString& error = {}) {
        emit resolved(id, points, error);
    }
};

static QVariantMap point(const QString& label, double lat = 55.75, double lon = 37.61)
{
    return {{"label", label}, {"latitude", lat}, {"longitude", lon}};
}

class TaxiTests : public QObject {
    Q_OBJECT
private slots:
    void coordinateLinks_data() {
        QTest::addColumn<QString>("text"); QTest::addColumn<double>("latitude"); QTest::addColumn<double>("longitude");
        QTest::newRow("moscow") << " 55.73400123907955, 37.588533418821726 " << 55.73400123907955 << 37.588533418821726;
        QTest::newRow("negative") << "-33.8688, +151.2093" << -33.8688 << 151.2093;
        QTest::newRow("origin") << "0,0" << 0.0 << 0.0;
        QTest::newRow("limits") << "-90,180" << -90.0 << 180.0;
    }
    void coordinateLinks() {
        QFETCH(QString, text); QFETCH(double, latitude); QFETCH(double, longitude);
        double lat = 0, lon = 0;
        QVERIFY(TaxiLinks::coordinates(text, lat, lon));
        QCOMPARE(lat, latitude); QCOMPARE(lon, longitude);
        const auto url = TaxiLinks::destination(lat, lon);
        QCOMPARE(url.scheme(), "https"); QCOMPARE(url.host(), "3.redirect.appmetrica.yandex.com");
        QCOMPARE(url.path(), "/route");
        const QUrlQuery query(url);
        QVERIFY(qAbs(query.queryItemValue("end-lat").toDouble() - latitude) < 1e-11);
        QVERIFY(qAbs(query.queryItemValue("end-lon").toDouble() - longitude) < 1e-11);
        QCOMPARE(query.queryItemValue("appmetrica_tracking_id"), "1178268795219780156");
        QCOMPARE(query.queryItemValue("ref"), "weekendsway");
        QCOMPARE(query.queryItemValue("lang"), "ru");
        QCOMPARE(query.queryItems().size(), 5); // No fabricated address, pickup or fare.
    }
    void invalidCoordinates_data() {
        QTest::addColumn<QString>("text");
        for (const auto& value : {"91,37", "55,-181", "NaN,37", "55,Infinity", "55,37,1", "55.7 37.6", "1e2,37", "55,7;37,6", "", "Москва, д. 12/3"})
            QTest::newRow(value) << QString::fromUtf8(value);
    }
    void invalidCoordinates() {
        QFETCH(QString, text); double lat = 0, lon = 0;
        QVERIFY(!TaxiLinks::coordinates(text, lat, lon));
        QVERIFY(TaxiLinks::destination(91, 37).isEmpty());
        QVERIFY(TaxiLinks::destination(55, -181).isEmpty());
        QVERIFY(TaxiLinks::destination(std::numeric_limits<double>::quiet_NaN(), 37).isEmpty());
    }
    void coordinatesLaunchWithoutGeocodingAndNoBlankLaunch() {
        auto platform = std::make_unique<FakeTaxiPlatform>(); auto* fake = platform.get();
        Taxi taxi(std::move(platform));
        QVERIFY(!taxi.request(" \n ")); QVERIFY(!taxi.pending());
        QVERIFY(taxi.request("55.75,37.61"));
        QCOMPARE(fake->opened.size(), 1); QVERIFY(fake->lookups.isEmpty());
        QVERIFY(!taxi.pending()); QVERIFY(!taxi.busy());
    }
    void textAddressIsPreservedAndNeedsExplicitSelection_data() {
        QTest::addColumn<QString>("address");
        QTest::newRow("cyrillic") << QStringLiteral("Москва, ул. Льва Толстого, 12/3, корпус 2Б");
        QTest::newRow("special") << QStringLiteral("Санкт-Петербург, 2-я ул., д. 5 А & Б + №7 #2 ? 100% %2F");
        QTest::newRow("chain") << QStringLiteral("Papa John's");
    }
    void textAddressIsPreservedAndNeedsExplicitSelection() {
        QFETCH(QString, address);
        auto platform = std::make_unique<FakeTaxiPlatform>(); auto* fake = platform.get();
        Taxi taxi(std::move(platform));
        QVERIFY(taxi.request("  " + address + "  "));
        QVERIFY(taxi.pending()); QVERIFY(taxi.busy()); QCOMPARE(fake->lookups.last().first, address);
        QCOMPARE(taxi.destination(), address); QVERIFY(fake->opened.isEmpty());
        const auto label = QStringLiteral("Россия, ") + address;
        fake->answer(fake->lookups.last().second, {point(label)});
        QVERIFY(!taxi.busy()); QCOMPARE(taxi.candidates().size(), 1);
        QCOMPARE(taxi.candidates().first().toMap().value("label").toString(), label);
        QVERIFY(fake->opened.isEmpty()); // Even one geocoder result is confirmed.
        QVERIFY(!taxi.selectDestination(-1)); QVERIFY(!taxi.selectDestination(1));
        QVERIFY(taxi.selectDestination(0)); QCOMPARE(fake->opened.size(), 1);
        QCOMPARE(QUrlQuery(fake->opened.last()).queryItemValue("end-lat"), "55.75");
        QVERIFY(!taxi.pending());
    }
    void picksTheSelectedBranchAndRejectsBadProviderData() {
        auto platform = std::make_unique<FakeTaxiPlatform>(); auto* fake = platform.get();
        Taxi taxi(std::move(platform)); QVERIFY(taxi.request("Додо Пицца"));
        fake->answer(fake->lookups.last().second, {
            point("Первый филиал"), point("Дубликат"), point("Второй филиал", 59.94, 30.31),
            point("Недопустимая широта", 91, 30), QVariantMap{{"label", "Нет координат"}}, point("")});
        QCOMPARE(taxi.candidates().size(), 2);
        QVERIFY(taxi.selectDestination(1));
        const QUrlQuery selected(fake->opened.last());
        QCOMPARE(selected.queryItemValue("end-lat"), "59.94");
        QCOMPARE(selected.queryItemValue("end-lon"), "30.31");
    }
    void cancelAndNewSearchIgnoreOldResponses() {
        auto platform = std::make_unique<FakeTaxiPlatform>(); auto* fake = platform.get();
        Taxi taxi(std::move(platform)); QVERIFY(taxi.request("Старый адрес"));
        const auto old = fake->lookups.last().second;
        taxi.cancel(); fake->answer(old, {point("Старый адрес")});
        QVERIFY(!taxi.pending()); QVERIFY(taxi.candidates().isEmpty()); QVERIFY(fake->opened.isEmpty());
        QVERIFY(taxi.request("Новый адрес"));
        const auto current = fake->lookups.last().second;
        fake->answer(old, {point("Старый адрес")}); QVERIFY(taxi.busy());
        QVERIFY(taxi.search("Уточнённый адрес"));
        fake->answer(current, {point("Новый адрес")}); QVERIFY(taxi.busy());
        fake->answer(fake->lookups.last().second, {point("Уточнённый адрес")});
        QCOMPARE(taxi.candidates().first().toMap().value("label").toString(), "Уточнённый адрес");
    }
    void timeoutAndProviderFailuresAreRecoverable() {
        auto platform = std::make_unique<FakeTaxiPlatform>(); auto* fake = platform.get();
        Taxi taxi(std::move(platform), 10); QVERIFY(taxi.request("Адрес"));
        const auto timedOut = fake->lookups.last().second;
        QTRY_VERIFY(!taxi.busy()); QVERIFY(taxi.pending()); QVERIFY(!taxi.error().isEmpty());
        fake->answer(timedOut, {point("Поздний ответ")}); QVERIFY(taxi.candidates().isEmpty());
        QVERIFY(taxi.search("Адрес ещё раз"));
        fake->answer(fake->lookups.last().second, {}, "Нет соединения");
        QCOMPARE(taxi.error(), "Нет соединения"); QVERIFY(!taxi.busy());
        QVERIFY(taxi.search("Полный адрес"));
        fake->answer(fake->lookups.last().second, {}); QVERIFY(!taxi.error().isEmpty());
        QVERIFY(taxi.search("Полный адрес"));
        fake->answer(fake->lookups.last().second, {point("Полный адрес")});
        QVERIFY(taxi.error().isEmpty()); QVERIFY(taxi.selectDestination(0));
    }
    void launchFailureKeepsConfirmedPointsForRetry() {
        auto platform = std::make_unique<FakeTaxiPlatform>(); auto* fake = platform.get();
        Taxi taxi(std::move(platform)); QVERIFY(taxi.request("Дом"));
        fake->answer(fake->lookups.last().second, {point("Дом")});
        fake->failOpen = true; QVERIFY(!taxi.selectDestination(0));
        QVERIFY(taxi.pending()); QVERIFY(!taxi.busy()); QCOMPARE(taxi.candidates().size(), 1);
        QVERIFY(!taxi.error().isEmpty());
        fake->failOpen = false; QVERIFY(taxi.selectDestination(0)); QVERIFY(!taxi.pending());
    }
};

QTEST_GUILESS_MAIN(TaxiTests)
#include "test-taxi.moc"
