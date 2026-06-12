import SwiftUI

struct MatchStatRow: View {
    let label: String
    let home: String
    let away: String
    let homeLeads: Bool
    let awayLeads: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(home)
                .fontWeight(homeLeads ? .bold : .regular)
                .foregroundStyle(homeLeads ? .primary : .secondary)
                .frame(width: 60, alignment: .leading)

            Text(label)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            Text(away)
                .fontWeight(awayLeads ? .bold : .regular)
                .foregroundStyle(awayLeads ? .primary : .secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .font(.system(size: 12))
        .monospacedDigit()
    }
}
