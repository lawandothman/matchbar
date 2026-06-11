import Foundation

struct GoalEvent: Equatable {
    let scorer: String?
    let minute: String?
    let isHome: Bool
    let isOwnGoal: Bool
    let isPenalty: Bool

    var label: String {
        var text = scorer ?? "Goal"
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
