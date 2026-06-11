import Foundation

struct FixtureTeam: Decodable, Equatable {
    let name: String?
    let tla: String?
    let crest: String?

    var displayName: String { name ?? "TBD" }
    var shortName: String { tla ?? name ?? "TBD" }
}
