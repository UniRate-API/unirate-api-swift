import XCTest
@testable import UniRateAPI

final class StubSession: HTTPFetching, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (Data, HTTPURLResponse)

    private let handler: Handler
    private(set) var lastRequest: URLRequest?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        let (data, response) = try handler(request)
        return (data, response)
    }
}

private func httpResponse(url: URL, status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
}

final class UniRateClientTests: XCTestCase {

    func makeClient(handler: @escaping StubSession.Handler) -> (UniRateClient, StubSession) {
        let stub = StubSession(handler: handler)
        let client = UniRateClient(
            apiKey: "test-key",
            baseURL: URL(string: "https://api.unirateapi.com")!,
            timeout: 5,
            session: stub
        )
        return (client, stub)
    }

    func testGetRate() async throws {
        let (client, stub) = makeClient { request in
            let url = request.url!
            XCTAssertTrue(url.path.hasSuffix("/api/rates"))
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(query.contains(URLQueryItem(name: "from", value: "USD")))
            XCTAssertTrue(query.contains(URLQueryItem(name: "to", value: "EUR")))
            XCTAssertTrue(query.contains(URLQueryItem(name: "api_key", value: "test-key")))
            let body = #"{"rate": 0.9321}"#.data(using: .utf8)!
            return (body, httpResponse(url: url, status: 200))
        }
        let rate = try await client.getRate(from: "usd", to: "eur")
        XCTAssertEqual(rate, 0.9321, accuracy: 0.0001)
        XCTAssertNotNil(stub.lastRequest)
    }

    func testGetAllRates() async throws {
        let (client, _) = makeClient { request in
            let body = #"{"rates": {"EUR": 0.9, "GBP": 0.8}}"#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let rates = try await client.getAllRates(from: "USD")
        XCTAssertEqual(rates["EUR"], 0.9)
        XCTAssertEqual(rates["GBP"], 0.8)
    }

    func testConvert() async throws {
        let (client, _) = makeClient { request in
            let body = #"{"result": 93.21}"#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let amount = try await client.convert(amount: 100, from: "USD", to: "EUR")
        XCTAssertEqual(amount, 93.21, accuracy: 0.01)
    }

    func testGetSupportedCurrencies() async throws {
        let (client, _) = makeClient { request in
            let body = #"{"currencies": ["USD", "EUR", "GBP", "BTC"]}"#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let currencies = try await client.getSupportedCurrencies()
        XCTAssertEqual(currencies, ["USD", "EUR", "GBP", "BTC"])
    }

    func testHistoricalRate() async throws {
        let (client, stub) = makeClient { request in
            let body = #"{"rate": 0.8412}"#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let rate = try await client.getHistoricalRate(date: "2024-01-01", from: "USD", to: "EUR")
        XCTAssertEqual(rate, 0.8412, accuracy: 0.0001)
        let query = URLComponents(url: stub.lastRequest!.url!, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertTrue(query.contains(URLQueryItem(name: "date", value: "2024-01-01")))
    }

    func testTimeSeries() async throws {
        let (client, stub) = makeClient { request in
            let body = #"""
            {"data": {"2024-01-01": {"EUR": 0.90}, "2024-01-02": {"EUR": 0.91}}}
            """#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let series = try await client.getTimeSeries(
            startDate: "2024-01-01",
            endDate: "2024-01-02",
            base: "USD",
            currencies: ["EUR"]
        )
        XCTAssertEqual(series["2024-01-01"]?["EUR"], 0.90)
        XCTAssertEqual(series["2024-01-02"]?["EUR"], 0.91)
        let query = URLComponents(url: stub.lastRequest!.url!, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertTrue(query.contains(URLQueryItem(name: "currencies", value: "EUR")))
    }

    func testHistoricalLimits() async throws {
        let (client, _) = makeClient { request in
            let body = #"""
            {"total_currencies": 2, "currencies": {"USD": {"earliest_date": "1999-01-01", "latest_date": "2026-04-20"}, "EUR": {"earliest_date": "1999-01-01", "latest_date": "2026-04-20"}}}
            """#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let limits = try await client.getHistoricalLimits()
        XCTAssertEqual(limits.totalCurrencies, 2)
        XCTAssertEqual(limits.currencies["USD"]?.earliestDate, "1999-01-01")
    }

    func testVATForCountry() async throws {
        let (client, _) = makeClient { request in
            let body = #"""
            {"country": "DE", "vat_data": {"country_code": "DE", "country_name": "Germany", "vat_rate": 19.0}}
            """#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let resp = try await client.getVATRate(country: "DE")
        XCTAssertEqual(resp.country, "DE")
        XCTAssertEqual(resp.vatData.vatRate, 19.0)
        XCTAssertEqual(resp.vatData.countryCode, "DE")
        XCTAssertEqual(resp.vatData.countryName, "Germany")
    }

    func testVATAllCountries() async throws {
        let (client, _) = makeClient { request in
            let body = #"""
            {"date": "2026-01-22", "total_countries": 2, "vat_rates": {"DE": {"country_code": "DE", "country_name": "Germany", "vat_rate": 19.0}, "FR": {"country_code": "FR", "country_name": "France", "vat_rate": 20.0}}}
            """#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        let resp = try await client.getVATRates()
        XCTAssertEqual(resp.totalCountries, 2)
        XCTAssertEqual(resp.date, "2026-01-22")
        XCTAssertEqual(resp.vatRates["DE"]?.vatRate, 19.0)
        XCTAssertEqual(resp.vatRates["FR"]?.countryName, "France")
    }

    func testHistoricalPaywall() async throws {
        // Free-tier key receives 403 for historical endpoints; ensure we surface it.
        let (client, _) = makeClient { request in
            let body = #"{"error": "Historical data access requires a Pro subscription"}"#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 403))
        }
        do {
            _ = try await client.getHistoricalRate(date: "2024-01-01", from: "USD", to: "EUR")
            XCTFail("Expected apiError for 403")
        } catch UniRateError.apiError(let code, _) {
            XCTAssertEqual(code, 403)
        } catch {
            XCTFail("Expected .apiError, got \(error)")
        }
    }

    // MARK: - Error paths

    func testAuthenticationError() async throws {
        let (client, _) = makeClient { request in
            return (Data(), httpResponse(url: request.url!, status: 401))
        }
        do {
            _ = try await client.getRate(to: "EUR")
            XCTFail("Expected authentication error")
        } catch UniRateError.authentication {
            // ok
        } catch {
            XCTFail("Expected .authentication, got \(error)")
        }
    }

    func testRateLimitError() async throws {
        let (client, _) = makeClient { request in
            return (Data(), httpResponse(url: request.url!, status: 429))
        }
        do {
            _ = try await client.getRate(to: "EUR")
            XCTFail("Expected rate limit error")
        } catch UniRateError.rateLimit {
            // ok
        } catch {
            XCTFail("Expected .rateLimit, got \(error)")
        }
    }

    func testInvalidCurrencyError() async throws {
        let (client, _) = makeClient { request in
            return (Data(), httpResponse(url: request.url!, status: 404))
        }
        do {
            _ = try await client.getRate(to: "ZZZ")
            XCTFail("Expected invalid currency error")
        } catch UniRateError.invalidCurrency {
            // ok
        } catch {
            XCTFail("Expected .invalidCurrency, got \(error)")
        }
    }

    func testApiKeyIsSent() async throws {
        let (client, stub) = makeClient { request in
            let body = #"{"currencies": []}"#.data(using: .utf8)!
            return (body, httpResponse(url: request.url!, status: 200))
        }
        _ = try await client.getSupportedCurrencies()
        let query = URLComponents(url: stub.lastRequest!.url!, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertTrue(query.contains(URLQueryItem(name: "api_key", value: "test-key")))
    }
}
