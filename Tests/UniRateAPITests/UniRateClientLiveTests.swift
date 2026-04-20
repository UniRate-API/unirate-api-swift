import XCTest
@testable import UniRateAPI

/// Live integration tests that hit `api.unirateapi.com`.
///
/// Automatically skipped unless `UNIRATE_API_KEY` is set. Set it with:
///
///   UNIRATE_API_KEY=your-key swift test
///
/// These tests exercise the endpoints accessible on a free-tier key.
/// Pro-gated endpoints (historical rates/timeseries/limits, commodities)
/// surface as `.apiError(statusCode: 403, ...)` and are covered by the mock tests.
final class UniRateClientLiveTests: XCTestCase {

    private var client: UniRateClient!

    override func setUpWithError() throws {
        guard let key = ProcessInfo.processInfo.environment["UNIRATE_API_KEY"], !key.isEmpty else {
            throw XCTSkip("Set UNIRATE_API_KEY to run live integration tests.")
        }
        client = UniRateClient(apiKey: key)
    }

    func testLiveRate() async throws {
        let rate = try await client.getRate(from: "USD", to: "EUR")
        XCTAssertGreaterThan(rate, 0)
        XCTAssertLessThan(rate, 10)
    }

    func testLiveAllRates() async throws {
        let rates = try await client.getAllRates(from: "USD")
        XCTAssertNotNil(rates["EUR"])
        XCTAssertGreaterThan(rates.count, 100)
    }

    func testLiveConvert() async throws {
        let result = try await client.convert(amount: 100, from: "USD", to: "EUR")
        XCTAssertGreaterThan(result, 0)
        XCTAssertLessThan(result, 1000)
    }

    func testLiveSupportedCurrencies() async throws {
        let currencies = try await client.getSupportedCurrencies()
        XCTAssertTrue(currencies.contains("USD"))
        XCTAssertTrue(currencies.contains("EUR"))
        XCTAssertGreaterThan(currencies.count, 100)
    }

    func testLiveVATCountry() async throws {
        let resp = try await client.getVATRate(country: "DE")
        XCTAssertEqual(resp.vatData.countryCode, "DE")
        XCTAssertEqual(resp.vatData.countryName, "Germany")
        XCTAssertEqual(resp.vatData.vatRate, 19.0)
    }

    func testLiveVATAllCountries() async throws {
        let resp = try await client.getVATRates()
        XCTAssertGreaterThan(resp.totalCountries, 20)
        XCTAssertEqual(resp.vatRates["DE"]?.countryName, "Germany")
    }
}
