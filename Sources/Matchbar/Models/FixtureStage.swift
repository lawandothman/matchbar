import Foundation

enum FixtureStage: String, Equatable, Codable {
    case groupStage
    case last32
    case last16
    case quarterFinals
    case semiFinals
    case thirdPlace
    case finalStage
    case unknown

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
