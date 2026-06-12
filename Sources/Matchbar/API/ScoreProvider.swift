import Foundation

protocol ScoreProvider: Sendable {
    func fixtures(from: Date, to: Date) async throws -> [Fixture]
    func standings() async throws -> [GroupStanding]
    func matchStats(eventID: Int, homeTLA: String?) async throws -> MatchStats?
}
