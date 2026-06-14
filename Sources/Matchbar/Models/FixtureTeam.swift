import Foundation

struct FixtureTeam: Equatable, Codable {
    let name: String?
    let shortName: String?
    let tla: String?
    let crest: String?

    var displayName: String { TeamNameOverrides.shortened(shortName ?? name ?? "TBD") }
    var code: String { tla ?? displayName }
    var flag: String? { CountryFlag.emoji(for: tla) }
}
