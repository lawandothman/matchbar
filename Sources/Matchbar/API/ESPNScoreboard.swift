import Foundation

struct ESPNScoreboardResponse: Decodable {
    let events: [ESPNEvent]
}

struct ESPNEvent: Decodable {
    let id: String
    let date: String
    let status: ESPNStatus
    let competitions: [ESPNCompetition]
}

struct ESPNStatus: Decodable {
    let type: ESPNStatusType
    let displayClock: String?
    let clock: Double?
}

struct ESPNStatusType: Decodable {
    let state: String
    let name: String
}

struct ESPNCompetition: Decodable {
    let competitors: [ESPNCompetitor]
    let details: [ESPNPlayDetail]?
}

struct ESPNCompetitor: Decodable {
    let homeAway: String
    let score: String?
    let shootoutScore: Int?
    let team: ESPNTeamInfo
}

struct ESPNTeamInfo: Decodable {
    let id: String?
    let displayName: String?
    let shortDisplayName: String?
    let abbreviation: String?
}

struct ESPNPlayDetail: Decodable {
    let clock: ESPNPlayClock?
    let team: ESPNTeamRef?
    let scoringPlay: Bool?
    let ownGoal: Bool?
    let penaltyKick: Bool?
    let athletesInvolved: [ESPNAthlete]?
}

struct ESPNPlayClock: Decodable {
    let displayValue: String?
}

struct ESPNTeamRef: Decodable {
    let id: String?
}

struct ESPNAthlete: Decodable {
    let displayName: String?
    let shortName: String?
}
