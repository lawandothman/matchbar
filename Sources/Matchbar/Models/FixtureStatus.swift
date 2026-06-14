import Foundation

enum FixtureStatus: String, Equatable, Codable {
    case scheduled
    case timed
    case inPlay
    case paused
    case extraTime
    case penaltyShootout
    case finished
    case suspended
    case postponed
    case cancelled
    case awarded
    case unknown

    var isLive: Bool {
        switch self {
        case .inPlay, .paused, .extraTime, .penaltyShootout: return true
        default: return false
        }
    }
}
