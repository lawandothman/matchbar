import Foundation

struct ESPNSummaryResponse: Decodable {
    let boxscore: ESPNBoxscore?
}

struct ESPNBoxscore: Decodable {
    let teams: [ESPNBoxTeam]?
}

struct ESPNBoxTeam: Decodable {
    let team: ESPNTeamInfo
    let statistics: [ESPNBoxStat]?
}

struct ESPNBoxStat: Decodable {
    let name: String?
    let displayValue: String?
}
