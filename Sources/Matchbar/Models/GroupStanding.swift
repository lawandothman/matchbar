import Foundation

struct GroupStanding: Identifiable, Equatable {
    let group: String?
    let table: [StandingRow]

    var id: String { group ?? "" }

    var label: String {
        group?.replacingOccurrences(of: "GROUP_", with: "Group ") ?? ""
    }
}
