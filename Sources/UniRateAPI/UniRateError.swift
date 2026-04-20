import Foundation

public enum UniRateError: Error, LocalizedError, Sendable {
    case authentication(String)
    case rateLimit(String)
    case invalidCurrency(String)
    case invalidDate(String)
    case apiError(statusCode: Int, message: String)
    case decodingFailure(String)
    case network(String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .authentication(let message): return "Authentication failed: \(message)"
        case .rateLimit(let message): return "Rate limit exceeded: \(message)"
        case .invalidCurrency(let message): return "Invalid currency: \(message)"
        case .invalidDate(let message): return "Invalid date: \(message)"
        case .apiError(let code, let message): return "API error (status \(code)): \(message)"
        case .decodingFailure(let message): return "Failed to decode response: \(message)"
        case .network(let message): return "Network error: \(message)"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}
