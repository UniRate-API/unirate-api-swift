# UniRate Swift Client

Official Swift client for the [UniRate API](https://unirateapi.com) — free, real-time and historical currency exchange rates plus VAT rates.

- 🔄 Real-time exchange rates between 170+ currencies (fiat + crypto)
- 📈 Historical rates back to 1999
- ⏰ Time-series ranges up to 5 years
- 💰 Currency conversion (current and historical)
- 🏛️ VAT rates for countries worldwide
- 🆓 Free tier, no credit card required
- ⚡ Modern Swift: `async`/`await`, `Sendable`, `Codable`
- 📦 Zero external dependencies — pure Foundation + Swift Package Manager

## Requirements

- Swift 5.9+
- macOS 12+, iOS 15+, tvOS 15+, watchOS 8+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/UniRate-API/unirate-api-swift.git", from: "0.1.0")
]
```

Then add `"UniRateAPI"` to your target's dependencies.

Or in Xcode: **File → Add Package Dependencies…** and paste the repo URL.

## Quick start

```swift
import UniRateAPI

let client = UniRateClient(apiKey: "your-api-key")

// Current rate
let rate = try await client.getRate(from: "USD", to: "EUR")
print("USD → EUR: \(rate)")

// Convert
let euros = try await client.convert(amount: 100, from: "USD", to: "EUR")
print("100 USD = \(euros) EUR")

// All supported currencies
let currencies = try await client.getSupportedCurrencies()
print("\(currencies.count) currencies supported")
```

Get a free API key at [https://unirateapi.com](https://unirateapi.com).

## API

### Current rates

```swift
// Single pair
let rate: Double = try await client.getRate(from: "USD", to: "EUR")

// All rates for a base
let rates: [String: Double] = try await client.getAllRates(from: "USD")

// Convert an amount
let result: Double = try await client.convert(amount: 100, from: "USD", to: "EUR")

// Supported currency list
let codes: [String] = try await client.getSupportedCurrencies()
```

### Historical data

```swift
// Rate on a specific date
let rate = try await client.getHistoricalRate(date: "2024-01-01", from: "USD", to: "EUR")

// All rates on a date
let rates = try await client.getHistoricalRates(date: "2024-01-01", from: "USD")

// Convert using historical rate
let amount = try await client.convertHistorical(amount: 100, from: "USD", to: "EUR", date: "2024-01-01")

// Time series
let series = try await client.getTimeSeries(
    startDate: "2024-01-01",
    endDate: "2024-01-07",
    base: "USD",
    currencies: ["EUR", "GBP"]
)

// Available historical coverage per currency
let limits = try await client.getHistoricalLimits()
```

### VAT rates

```swift
// All countries
let vatRates = try await client.getVATRates()

// Single country (ISO-3166 alpha-2 code)
let germany = try await client.getVATRate(country: "DE")
print("Germany VAT: \(germany.vatData.vatRate)%")
```

## Error handling

All methods throw `UniRateError`:

```swift
do {
    let rate = try await client.getRate(from: "USD", to: "ZZZ")
} catch UniRateError.authentication {
    // invalid API key
} catch UniRateError.invalidCurrency {
    // unknown currency code
} catch UniRateError.rateLimit {
    // back off and retry
} catch UniRateError.invalidDate {
    // bad date format
} catch UniRateError.apiError(let code, let message) {
    // other HTTP error
}
```

## Advanced — custom `URLSession` / dependency injection

The client accepts anything conforming to `HTTPFetching` (matching `URLSession`'s `data(for:)` signature), which makes mocking trivial in tests:

```swift
final class StubSession: HTTPFetching {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let body = #"{"rate": 0.9}"#.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
        )!
        return (body, response)
    }
}

let client = UniRateClient(apiKey: "test", session: StubSession())
```

## Rate limits

- **Currency endpoints:** standard rate limits apply
- **Historical endpoints:** 50 requests/hour on the free tier
- **VAT endpoints:** 1800 requests/hour on the free tier

## Related clients

- [unirate-api-python](https://github.com/UniRate-API/unirate-api-python) (PyPI: `unirate-api`)
- [unirate-api-nodejs](https://github.com/UniRate-API/unirate-api-nodejs) (npm: `unirate-api`)

## License

MIT — see [LICENSE](LICENSE).
