import Foundation

public struct HistoricalLimit: Decodable, Sendable, Equatable {
    public let earliestDate: String
    public let latestDate: String

    private enum CodingKeys: String, CodingKey {
        case earliestDate = "earliest_date"
        case latestDate = "latest_date"
    }
}

public struct HistoricalLimitsResponse: Decodable, Sendable, Equatable {
    public let totalCurrencies: Int
    public let currencies: [String: HistoricalLimit]

    private enum CodingKeys: String, CodingKey {
        case totalCurrencies = "total_currencies"
        case currencies
    }
}

public struct VATRate: Decodable, Sendable, Equatable {
    public let countryCode: String?
    public let country: String?
    public let vatRate: Double

    private enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"
        case country
        case vatRate = "vat_rate"
    }
}

public struct VATCountryResponse: Decodable, Sendable, Equatable {
    public let vatData: VATRate

    private enum CodingKeys: String, CodingKey {
        case vatData = "vat_data"
    }
}

public struct VATRatesResponse: Decodable, Sendable, Equatable {
    public let totalCountries: Int
    public let vatRates: [String: VATRate]

    private enum CodingKeys: String, CodingKey {
        case totalCountries = "total_countries"
        case vatRates = "vat_rates"
    }
}
