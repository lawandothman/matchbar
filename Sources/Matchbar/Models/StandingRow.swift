import Foundation

struct StandingRow: Identifiable, Equatable {
    var position: Int
    let team: FixtureTeam
    let playedGames: Int
    let won: Int
    let draw: Int
    let lost: Int
    let points: Int
    let goalsFor: Int
    let goalDifference: Int

    var id: Int { position }
}
