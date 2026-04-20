import Foundation
import UniRateAPI

// Usage: UNIRATE_API_KEY=your-key swift run QuickStart
// (or copy into a small SwiftPM executable target — this file is illustrative.)

@main
struct QuickStart {
    static func main() async throws {
        guard let key = ProcessInfo.processInfo.environment["UNIRATE_API_KEY"] else {
            print("Set UNIRATE_API_KEY before running.")
            return
        }

        let client = UniRateClient(apiKey: key)

        let rate = try await client.getRate(from: "USD", to: "EUR")
        print("USD → EUR: \(rate)")

        let euros = try await client.convert(amount: 100, from: "USD", to: "EUR")
        print("100 USD = \(euros) EUR")

        let currencies = try await client.getSupportedCurrencies()
        print("Supported currencies: \(currencies.count)")

        let historical = try await client.getHistoricalRate(
            date: "2024-01-01", from: "USD", to: "EUR"
        )
        print("USD → EUR on 2024-01-01: \(historical)")

        let germany = try await client.getVATRate(country: "DE")
        print("Germany VAT: \(germany.vatData.vatRate)%")
    }
}
