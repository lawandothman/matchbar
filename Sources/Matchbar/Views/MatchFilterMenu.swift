import SwiftUI

struct MatchFilterMenu: View {
    let teams: [FixtureTeam]
    let groups: [String]
    @Binding var selectedTeam: String?
    @Binding var selectedGroup: String?

    private var isActive: Bool { selectedTeam != nil || selectedGroup != nil }

    var body: some View {
        Menu {
            Picker("Team", selection: $selectedTeam) {
                Text("All teams").tag(String?.none)
                Divider()
                ForEach(teams, id: \.tla) { team in
                    Text([team.flag, team.displayName].compactMap { $0 }.joined(separator: " "))
                        .tag(team.tla)
                }
            }
            .pickerStyle(.menu)

            Picker("Group", selection: $selectedGroup) {
                Text("All groups").tag(String?.none)
                Divider()
                ForEach(groups, id: \.self) { group in
                    Text(group).tag(String?.some(group))
                }
            }
            .pickerStyle(.menu)

            if isActive {
                Divider()
                Button("Clear filters") {
                    selectedTeam = nil
                    selectedGroup = nil
                }
            }
        } label: {
            Image(systemName: isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 14))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .buttonStyle(.plain)
    }
}
