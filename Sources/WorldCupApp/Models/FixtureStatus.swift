import Foundation

enum FixtureStatus: String, Decodable, Equatable {
    case scheduled = "SCHEDULED"
    case timed = "TIMED"
    case inPlay = "IN_PLAY"
    case paused = "PAUSED"
    case finished = "FINISHED"
    case suspended = "SUSPENDED"
    case postponed = "POSTPONED"
    case cancelled = "CANCELLED"
    case awarded = "AWARDED"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FixtureStatus(rawValue: raw) ?? .unknown
    }

    var isLive: Bool { self == .inPlay || self == .paused }
}
