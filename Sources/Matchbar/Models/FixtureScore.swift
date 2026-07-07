import Foundation

struct FixtureScore: Equatable, Codable {
    let fullTime: ScoreValues
    let duration: ScoreDuration?
    let penalties: ScoreValues?

    /// Compact single-line form for tight spaces like the menu bar, e.g. "1–1 (2–4 p)".
    var display: String {
        guard let base = baseDisplay else { return "–" }
        guard let penalties, let home = penalties.home, let away = penalties.away else { return base }
        return "\(base) (\(home)–\(away) p)"
    }

    /// Full-time score on its own, e.g. "1–1".
    var baseDisplay: String? {
        guard let home = fullTime.home, let away = fullTime.away else { return nil }
        return "\(home)–\(away)"
    }

    /// Shootout result on its own, e.g. "2–4 pens", or nil when there was no shootout.
    var penaltyDisplay: String? {
        guard let penalties, let home = penalties.home, let away = penalties.away else { return nil }
        return "\(home)–\(away) pens"
    }
}
