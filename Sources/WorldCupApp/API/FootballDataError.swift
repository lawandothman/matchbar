import Foundation

enum FootballDataError: LocalizedError {
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .badResponse(401), .badResponse(403):
            return "Invalid API token"
        case .badResponse(429):
            return "Rate limited, retrying shortly"
        case .badResponse(let code):
            return "API error (\(code))"
        }
    }
}
