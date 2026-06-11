import Foundation

enum ScoreDuration: String, Decodable, Equatable {
    case regular = "REGULAR"
    case extraTime = "EXTRA_TIME"
    case penaltyShootout = "PENALTY_SHOOTOUT"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ScoreDuration(rawValue: raw) ?? .unknown
    }
}
