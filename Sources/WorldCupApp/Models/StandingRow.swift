import Foundation

struct StandingRow: Decodable, Identifiable, Equatable {
    let position: Int
    let team: FixtureTeam
    let playedGames: Int
    let won: Int
    let draw: Int
    let lost: Int
    let points: Int
    let goalDifference: Int

    var id: Int { position }
}
