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
    public let countryName: String?
    public let vatRate: Double

    private enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"
        case countryName = "country_name"
        case vatRate = "vat_rate"
    }
}

public struct VATCountryResponse: Decodable, Sendable, Equatable {
    public let country: String?
    public let vatData: VATRate

    private enum CodingKeys: String, CodingKey {
        case country
        case vatData = "vat_data"
    }
}

public struct VATRatesResponse: Decodable, Sendable, Equatable {
    public let date: String?
    public let totalCountries: Int
    public let vatRates: [String: VATRate]

    private enum CodingKeys: String, CodingKey {
        case date
        case totalCountries = "total_countries"
        case vatRates = "vat_rates"
    }
}
