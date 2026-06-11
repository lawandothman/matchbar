import Foundation

struct FixtureScore: Decodable, Equatable {
    let fullTime: ScoreValues
    let duration: ScoreDuration?
    let penalties: ScoreValues?

    var display: String {
        guard let home = fullTime.home, let away = fullTime.away else { return "–" }
        var text = "\(home)–\(away)"
        if let penalties, let home = penalties.home, let away = penalties.away {
            text += " (\(home)–\(away) p)"
        }
        return text
    }
}
