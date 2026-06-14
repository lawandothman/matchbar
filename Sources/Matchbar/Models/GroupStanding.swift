import Foundation

struct GroupStanding: Identifiable, Equatable, Codable {
    let group: String?
    var table: [StandingRow]

    var id: String { group ?? "" }

    var label: String {
        group?.replacingOccurrences(of: "GROUP_", with: "Group ") ?? ""
    }
}
