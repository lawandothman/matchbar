import SwiftUI

struct FixtureRow: View {
    let fixture: Fixture

    var body: some View {
        HStack(spacing: 8) {
            statusColumn
                .frame(width: 44, alignment: .leading)

            Text(homeLabel)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)

            Text(scoreColumn)
                .monospacedDigit()
                .fontWeight(fixture.isLive ? .bold : .regular)
                .frame(width: 44)

            Text(awayLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            Text(fixture.roundLabel ?? "")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .trailing)
        }
        .font(.system(size: 12))
    }

    private var homeLabel: String {
        [fixture.homeTeam.displayName, fixture.homeTeam.flag].compactMap { $0 }.joined(separator: " ")
    }

    private var awayLabel: String {
        [fixture.awayTeam.flag, fixture.awayTeam.displayName].compactMap { $0 }.joined(separator: " ")
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
