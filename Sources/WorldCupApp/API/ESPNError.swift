import Foundation

enum ESPNError: LocalizedError {
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .badResponse(let code):
            return "ESPN API error (\(code))"
        }
    }
}
