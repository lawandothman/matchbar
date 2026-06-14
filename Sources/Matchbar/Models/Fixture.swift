import Foundation

struct Fixture: Identifiable, Equatable, Codable {
    let id: Int
    let utcDate: Date
    var status: FixtureStatus
    var stage: FixtureStage
    var group: String?
    let homeTeam: FixtureTeam
    let awayTeam: FixtureTeam
    let score: FixtureScore
    let minute: String?
    let clockSeconds: Double?
    let goals: [GoalEvent]

    var isLive: Bool { status.isLive }

    var liveLabel: String? {
        switch status {
        case .inPlay, .extraTime: return minute
        case .paused: return "HT"
        case .penaltyShootout: return "PENS"
        default: return nil
        }
    }

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
