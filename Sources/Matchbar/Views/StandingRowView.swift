import SwiftUI

struct StandingRowView: View {
    let row: StandingRow

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1)
                .fill(barColor)
                .frame(width: 2, height: 12)

            Text("\(row.position)")
                .foregroundStyle(.secondary)
                .frame(width: 12, alignment: .trailing)

            Text(teamLabel)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(row.goalsFor)").frame(width: 18, alignment: .trailing)
            Text("\(row.goalsAgainst)").frame(width: 18, alignment: .trailing)
            Text(goalDifference).frame(width: 24, alignment: .trailing)
            Text("\(row.points)")
                .fontWeight(.semibold)
                .frame(width: 22, alignment: .trailing)

            FormDots(form: row.form)
                .padding(.leading, 6)
        }
        .font(.system(size: 11))
        .monospacedDigit()
    }

    private var barColor: Color {
        if row.position <= 2 { return .green.opacity(0.8) }
        if row.isBestThirdSpot { return .green.opacity(0.3) }
        return .clear
    }

    private var teamLabel: String {
        [row.team.flag, row.team.displayName].compactMap { $0 }.joined(separator: " ")
    }

    private var goalDifference: String {
        row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)"
    }
}
