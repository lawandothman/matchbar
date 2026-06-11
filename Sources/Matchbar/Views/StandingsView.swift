import SwiftUI

struct StandingsView: View {
    let standings: [GroupStanding]

    var body: some View {
        if standings.isEmpty {
            Text("No standings yet")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(standings) { standing in
                        GroupTableView(standing: standing)
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 460)
        }
    }
}
