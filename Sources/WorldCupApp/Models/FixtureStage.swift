import Foundation

enum FixtureStage: String, Decodable, Equatable {
    case groupStage = "GROUP_STAGE"
    case last32 = "LAST_32"
    case last16 = "LAST_16"
    case quarterFinals = "QUARTER_FINALS"
    case semiFinals = "SEMI_FINALS"
    case thirdPlace = "THIRD_PLACE"
    case finalStage = "FINAL"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FixtureStage(rawValue: raw) ?? .unknown
    }

    var shortLabel: String? {
        switch self {
        case .groupStage, .unknown: return nil
        case .last32: return "R32"
        case .last16: return "R16"
        case .quarterFinals: return "QF"
        case .semiFinals: return "SF"
        case .thirdPlace: return "3rd place"
        case .finalStage: return "Final"
        }
    }
}
