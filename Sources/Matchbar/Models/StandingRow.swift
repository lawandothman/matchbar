import Foundation

struct StandingRow: Identifiable, Equatable, Codable {
    var position: Int
    let team: FixtureTeam
    let playedGames: Int
    let won: Int
    let draw: Int
    let lost: Int
    let points: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int
    var form: [FormResult] = []
    var isBestThirdSpot = false

    var id: Int { position }
}
