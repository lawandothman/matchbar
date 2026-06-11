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

    var summaryLine: String {
        let home = [homeTeam.flag, homeTeam.displayName].compactMap { $0 }.joined(separator: " ")
        let away = [awayTeam.flag, awayTeam.displayName].compactMap { $0 }.joined(separator: " ")
        return "\(home) \(score.display) \(away)"
    }

    var roundLabel: String? {
        if let group {
            return group.replacingOccurrences(of: "GROUP_", with: "Group ")
        }
        return stage.shortLabel
    }
}
