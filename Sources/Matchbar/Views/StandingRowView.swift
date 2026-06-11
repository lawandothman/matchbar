import SwiftUI

struct StandingRowView: View {
    let row: StandingRow

    var body: some View {
        HStack(spacing: 4) {
            Text("\(row.position)")
                .foregroundStyle(.secondary)
                .frame(width: 14, alignment: .trailing)

            Text(teamLabel)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(row.playedGames)").frame(width: 20, alignment: .trailing)
            Text("\(row.won)").frame(width: 20, alignment: .trailing)
            Text("\(row.draw)").frame(width: 20, alignment: .trailing)
            Text("\(row.lost)").frame(width: 20, alignment: .trailing)
            Text(goalDifference).frame(width: 30, alignment: .trailing)
            Text("\(row.points)")
                .fontWeight(.semibold)
                .frame(width: 28, alignment: .trailing)
        }
        .font(.system(size: 12))
        .monospacedDigit()
    }

    private var teamLabel: String {
        [row.team.flag, row.team.displayName].compactMap { $0 }.joined(separator: " ")
    }

    private var goalDifference: String {
        row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)"
    }
}
