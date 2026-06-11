import Foundation

struct FixtureScore: Decodable, Equatable {
    let fullTime: ScoreValues

    var display: String {
        guard let home = fullTime.home, let away = fullTime.away else { return "–" }
        return "\(home)–\(away)"
    }
}
