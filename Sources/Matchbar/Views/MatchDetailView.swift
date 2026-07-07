import SwiftUI

struct MatchDetailView: View {
    let store: MatchStore
    let fixtureID: Int
    let onBack: () -> Void
    @State private var stats: MatchStats?

    private var fixture: Fixture? {
        store.fixtures.first { $0.id == fixtureID }
    }

    private var displayStats: MatchStats? {
        stats ?? store.cachedStats(for: fixtureID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backRow

            if let fixture {
                VStack(spacing: 0) {
                    header(fixture)

                    if let stats = displayStats {
                        statTable(fixture: fixture, stats: stats)
                            .padding(.top, 14)
                    } else if fixture.status == .timed || fixture.status == .scheduled {
                        Text("Stats appear once the match kicks off")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 24)
                    } else {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.vertical, 24)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .task(id: fixtureID) {
            while !Task.isCancelled {
                guard let fixture, fixture.status != .timed, fixture.status != .scheduled else {
                    try? await Task.sleep(for: .seconds(30))
                    continue
                }
                if let fetched = await store.matchStats(for: fixture, forceRefresh: fixture.isLive) {
                    stats = fetched
                }
                if !fixture.isLive { break }
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private var backRow: some View {
        Button(action: onBack) {
            HStack(spacing: 3) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                Text("Matches")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func header(_ fixture: Fixture) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 2) {
                    Text(fixture.homeTeam.flag ?? "")
                        .font(.system(size: 28))
                    Text(fixture.homeTeam.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text(fixture.score.baseDisplay ?? "–")
                        .font(.system(size: 24, weight: .bold))
                        .monospacedDigit()
                    if let penaltyDisplay = fixture.score.penaltyDisplay {
                        Text(penaltyDisplay)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    statusBadge(fixture)
                }
                .frame(width: 120)

                VStack(spacing: 2) {
                    Text(fixture.awayTeam.flag ?? "")
                        .font(.system(size: 28))
                    Text(fixture.awayTeam.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            if !fixture.goals.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    scorerColumn(fixture, home: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Color.clear.frame(width: 120, height: 0)
                    scorerColumn(fixture, home: false)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if let round = fixture.roundLabel {
                Text(round)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func statusBadge(_ fixture: Fixture) -> some View {
        switch fixture.status {
        case .finished:
            Text("Full-time")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        case .timed, .scheduled:
            Text(fixture.utcDate, format: .dateTime.weekday(.abbreviated).hour().minute())
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        default:
            Text(fixture.liveLabel ?? "Live")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        }
    }

    private func scorerColumn(_ fixture: Fixture, home: Bool) -> some View {
        Text(fixture.goals.filter { $0.isHome == home }.map(\.compactLabel).joined(separator: "\n"))
            .font(.system(size: 9.5))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func statTable(fixture: Fixture, stats: MatchStats) -> some View {
        VStack(spacing: 9) {
            HStack {
                Text(fixture.homeTeam.flag ?? "")
                Text("Team stats")
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Text(fixture.awayTeam.flag ?? "")
            }
            .padding(.bottom, 2)

            ForEach(statLines(stats), id: \.label) { line in
                MatchStatRow(
                    label: line.label,
                    home: line.home,
                    away: line.away,
                    homeLeads: line.leader > 0,
                    awayLeads: line.leader < 0
                )
            }
        }
    }

    private func statLines(_ stats: MatchStats) -> [(label: String, home: String, away: String, leader: Int)] {
        func int(_ label: String, _ keyPath: KeyPath<TeamMatchStats, Int?>) -> (String, String, String, Int) {
            let home = stats.home[keyPath: keyPath]
            let away = stats.away[keyPath: keyPath]
            return (label, home.map(String.init) ?? "–", away.map(String.init) ?? "–", compare(home, away))
        }
        func pct(_ label: String, _ keyPath: KeyPath<TeamMatchStats, Double?>, scale: Double) -> (String, String, String, Int) {
            let home = stats.home[keyPath: keyPath]
            let away = stats.away[keyPath: keyPath]
            func text(_ value: Double?) -> String {
                value.map { "\(Int(($0 * scale).rounded()))%" } ?? "–"
            }
            return (label, text(home), text(away), compare(home, away))
        }
        return [
            int("Shots", \.shots),
            int("Shots on target", \.shotsOnTarget),
            pct("Possession", \.possession, scale: 1),
            int("Passes", \.passes),
            pct("Pass accuracy", \.passAccuracy, scale: 100),
            int("Fouls", \.fouls),
            int("Yellow cards", \.yellowCards),
            int("Red cards", \.redCards),
            int("Offsides", \.offsides),
            int("Corners", \.corners),
        ]
    }

    private func compare<T: Comparable>(_ home: T?, _ away: T?) -> Int {
        guard let home, let away, home != away else { return 0 }
        return home > away ? 1 : -1
    }
}
