import Foundation

struct FixtureTeam: Decodable, Equatable {
    let name: String?
    let shortName: String?
    let tla: String?
    let crest: String?

    var displayName: String { shortName ?? name ?? "TBD" }
    var code: String { tla ?? displayName }
    var flag: String? { CountryFlag.emoji(for: tla) }
}
