import SwiftUI

struct FixtureRow: View {
    let fixture: Fixture

    var body: some View {
        HStack(spacing: 8) {
            statusColumn
                .frame(width: 44, alignment: .leading)

            Text(fixture.homeTeam.displayName)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)

            Text(scoreColumn)
                .monospacedDigit()
                .fontWeight(fixture.isLive ? .bold : .regular)
                .frame(width: 44)

            Text(fixture.awayTeam.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .font(.system(size: 12))
    }

    private var scoreColumn: String {
        switch fixture.status {
        case .scheduled, .timed:
            return "v"
        default:
            return fixture.score.display
        }
    }

    @ViewBuilder
    private var statusColumn: some View {
        switch fixture.status {
        case .inPlay:
            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        case .paused:
            Text("HT")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        case .extraTime:
            Text("ET")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        case .penaltyShootout:
            Text("PENS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        case .finished:
            Text("FT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        case .scheduled, .timed:
            Text(fixture.utcDate, format: .dateTime.hour().minute())
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        default:
            Text(fixture.status.rawValue.prefix(4))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
