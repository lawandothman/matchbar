import Foundation

protocol ScoreProvider: Sendable {
    func fixtures(from: Date, to: Date) async throws -> [Fixture]
}
