import Foundation

struct GoalEvent: Equatable {
    let scorer: String?
    let scorerShort: String?
    let minute: String?
    let isHome: Bool
    let isOwnGoal: Bool
    let isPenalty: Bool

    var label: String { compose(scorer ?? "Goal") }
    var compactLabel: String { compose(scorerShort ?? scorer ?? "Goal") }

    private func compose(_ name: String) -> String {
        var text = name
        if let minute {
            text += " \(minute)"
        }
        if isOwnGoal {
            text += " (og)"
        }
        if isPenalty {
            text += " (pen)"
        }
        return text
    }
}
