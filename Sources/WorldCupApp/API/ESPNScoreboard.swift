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
}

struct ESPNStatusType: Decodable {
    let state: String
    let name: String
}

struct ESPNCompetition: Decodable {
    let competitors: [ESPNCompetitor]
}

struct ESPNCompetitor: Decodable {
    let homeAway: String
    let score: String?
    let shootoutScore: Int?
    let team: ESPNTeamInfo
}

struct ESPNTeamInfo: Decodable {
    let displayName: String?
    let shortDisplayName: String?
    let abbreviation: String?
}
