import Foundation

struct TeamMatchStats: Equatable {
    let shots: Int?
    let shotsOnTarget: Int?
    let possession: Double?
    let passes: Int?
    let passAccuracy: Double?
    let fouls: Int?
    let yellowCards: Int?
    let redCards: Int?
    let offsides: Int?
    let corners: Int?
}
