import Foundation

struct ESPNStandingsResponse: Decodable {
    let children: [ESPNStandingsGroup]
}

struct ESPNStandingsGroup: Decodable {
    let name: String?
    let standings: ESPNStandingsTable
}

struct ESPNStandingsTable: Decodable {
    let entries: [ESPNStandingsEntry]
}

struct ESPNStandingsEntry: Decodable {
    let team: ESPNTeamInfo
    let stats: [ESPNStat]
}

struct ESPNStat: Decodable {
    let name: String
    let value: Double?
}
