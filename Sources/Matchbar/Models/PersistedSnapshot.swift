import Foundation

struct PersistedSnapshot: Codable {
    let schema: Int
    let savedAt: Date
    let fixtures: [Fixture]
    let standings: [GroupStanding]
}
