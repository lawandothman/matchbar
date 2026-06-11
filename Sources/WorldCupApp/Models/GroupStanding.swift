import Foundation

struct GroupStanding: Decodable, Identifiable, Equatable {
    let group: String?
    let type: String?
    let table: [StandingRow]

    var id: String { group ?? "" }

    var label: String {
        group?.replacingOccurrences(of: "GROUP_", with: "Group ") ?? ""
    }
}
