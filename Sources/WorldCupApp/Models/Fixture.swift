import Foundation

struct Fixture: Decodable, Identifiable, Equatable {
    let id: Int
    let utcDate: Date
    let status: FixtureStatus
    let stage: FixtureStage
    let group: String?
    let homeTeam: FixtureTeam
    let awayTeam: FixtureTeam
    let score: FixtureScore

    var isLive: Bool { status.isLive }

    var roundLabel: String? {
        if let group {
            return group.replacingOccurrences(of: "GROUP_", with: "Group ")
        }
        return stage.shortLabel
    }
}
