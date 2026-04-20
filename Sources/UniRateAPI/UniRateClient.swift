import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPFetching: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPFetching {}

public struct UniRateClient: Sendable {
    public static let defaultBaseURL = URL(string: "https://api.unirateapi.com")!

    private let apiKey: String
    private let baseURL: URL
    private let session: HTTPFetching
    private let timeout: TimeInterval

    public init(
        apiKey: String,
        baseURL: URL = UniRateClient.defaultBaseURL,
        timeout: TimeInterval = 30,
        session: HTTPFetching = URLSession.shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.timeout = timeout
        self.session = session
    }

    // MARK: - Current rates & conversion

    /// Fetch the exchange rate between two currencies.
    public func getRate(from: String = "USD", to: String) async throws -> Double {
        let body: RateResponse = try await request(
            path: "/api/rates",
            query: ["from": from.uppercased(), "to": to.uppercased()]
        )
        return body.rate
    }

    /// Fetch all exchange rates for a base currency.
    public func getAllRates(from: String = "USD") async throws -> [String: Double] {
        let body: RatesResponse = try await request(
            path: "/api/rates",
            query: ["from": from.uppercased()]
        )
        return body.rates
    }

    /// Convert an amount from one currency to another using the current rate.
    public func convert(amount: Double, from: String = "USD", to: String) async throws -> Double {
        let body: ConvertResponse = try await request(
            path: "/api/convert",
            query: [
                "amount": String(amount),
                "from": from.uppercased(),
                "to": to.uppercased(),
            ]
        )
        return body.result
    }

    /// Get the list of supported currency codes.
    public func getSupportedCurrencies() async throws -> [String] {
        let body: CurrenciesResponse = try await request(
            path: "/api/currencies",
            query: [:]
        )
        return body.currencies
    }

    // MARK: - Historical data

    /// Fetch a historical exchange rate for a specific date.
    ///
    /// - Parameter date: ISO date string `YYYY-MM-DD`.
    public func getHistoricalRate(date: String, from: String = "USD", to: String) async throws -> Double {
        let body: HistoricalRateResponse = try await request(
            path: "/api/historical/rates",
            query: [
                "date": date,
                "amount": "1",
                "from": from.uppercased(),
                "to": to.uppercased(),
            ]
        )
        return body.rate
    }

    /// Fetch all historical exchange rates for a base currency on a given date.
    public func getHistoricalRates(date: String, from: String = "USD") async throws -> [String: Double] {
        let body: HistoricalRatesResponse = try await request(
            path: "/api/historical/rates",
            query: [
                "date": date,
                "amount": "1",
                "from": from.uppercased(),
            ]
        )
        return body.rates
    }

    /// Convert an amount using a historical exchange rate.
    public func convertHistorical(
        amount: Double,
        from: String,
        to: String,
        date: String
    ) async throws -> Double {
        let body: HistoricalConvertResponse = try await request(
            path: "/api/historical/rates",
            query: [
                "date": date,
                "amount": String(amount),
                "from": from.uppercased(),
                "to": to.uppercased(),
            ]
        )
        return body.result
    }

    /// Fetch a time series of exchange rates (up to 5 years).
    public func getTimeSeries(
        startDate: String,
        endDate: String,
        base: String = "USD",
        currencies: [String]? = nil,
        amount: Double = 1
    ) async throws -> [String: [String: Double]] {
        var query: [String: String] = [
            "start_date": startDate,
            "end_date": endDate,
            "amount": String(amount),
            "base": base.uppercased(),
        ]
        if let currencies, !currencies.isEmpty {
            query["currencies"] = currencies.map { $0.uppercased() }.joined(separator: ",")
        }
        let body: TimeSeriesResponse = try await request(
            path: "/api/historical/timeseries",
            query: query
        )
        return body.data
    }

    /// Fetch the available historical-data coverage per currency.
    public func getHistoricalLimits() async throws -> HistoricalLimitsResponse {
        try await request(path: "/api/historical/limits", query: [:])
    }

    // MARK: - VAT

    /// Fetch VAT rates for all countries.
    public func getVATRates() async throws -> VATRatesResponse {
        try await request(path: "/api/vat/rates", query: [:])
    }

    /// Fetch the VAT rate for a specific country (ISO-3166 alpha-2 code, e.g. `"DE"`).
    public func getVATRate(country: String) async throws -> VATCountryResponse {
        try await request(
            path: "/api/vat/rates",
            query: ["country": country.uppercased()]
        )
    }

    // MARK: - Internals

    private func request<T: Decodable>(path: String, query: [String: String]) async throws -> T {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw UniRateError.invalidResponse
        }
        var items = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        components.queryItems = items

        guard let url = components.url else {
            throw UniRateError.invalidResponse
        }

        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = "GET"
        req.setValue("unirate-swift/0.1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw UniRateError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw UniRateError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 400:
            throw UniRateError.invalidDate(String(data: data, encoding: .utf8) ?? "Invalid request parameters")
        case 401:
            throw UniRateError.authentication("Missing or invalid API key")
        case 404:
            throw UniRateError.invalidCurrency("Currency not found or no data available")
        case 429:
            throw UniRateError.rateLimit("Rate limit exceeded")
        case 503:
            throw UniRateError.apiError(statusCode: 503, message: "Service unavailable")
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw UniRateError.apiError(statusCode: http.statusCode, message: body)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw UniRateError.decodingFailure(error.localizedDescription)
        }
    }
}

// MARK: - Response DTOs

private struct RateResponse: Decodable { let rate: Double }
private struct RatesResponse: Decodable { let rates: [String: Double] }
private struct ConvertResponse: Decodable { let result: Double }
private struct CurrenciesResponse: Decodable { let currencies: [String] }
private struct HistoricalRateResponse: Decodable { let rate: Double }
private struct HistoricalRatesResponse: Decodable { let rates: [String: Double] }
private struct HistoricalConvertResponse: Decodable { let result: Double }
private struct TimeSeriesResponse: Decodable { let data: [String: [String: Double]] }
