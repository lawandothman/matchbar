import Foundation
import Observation

@MainActor
@Observable
final class MatchStore {
    private(set) var fixtures: [Fixture] = []
    private(set) var standings: [GroupStanding] = []
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?
    private(set) var hasToken = false

    private var pollTask: Task<Void, Never>?
    private let notifier = MatchNotifier()

    var liveFixtures: [Fixture] { fixtures.filter(\.isLive) }

    var sections: [FixtureDaySection] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let visible = fixtures.filter { $0.utcDate >= startOfToday || $0.isLive }
        return Dictionary(grouping: visible) { calendar.startOfDay(for: $0.utcDate) }
            .map { day, fixtures in
                FixtureDaySection(day: day, fixtures: fixtures.sorted { $0.utcDate < $1.utcDate })
            }
            .sorted { $0.day < $1.day }
    }

    init() {
        hasToken = TokenStore.token != nil
        notifier.requestAuthorization()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                let interval: Double = self?.liveFixtures.isEmpty == false ? 30 : 60
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func saveToken(_ token: String) {
        TokenStore.save(token)
        hasToken = TokenStore.token != nil
        Task { await refresh() }
    }

    func refresh() async {
        guard let token = TokenStore.token else {
            hasToken = false
            return
        }
        hasToken = true

        let client = FootballDataClient(token: token)
        let now = Date()
        do {
            let previous = Dictionary(uniqueKeysWithValues: fixtures.map { ($0.id, $0) })
            fixtures = try await client.fixtures(
                from: now.addingTimeInterval(-86400),
                to: now.addingTimeInterval(7 * 86400)
            )
            if !previous.isEmpty {
                announce(changesFrom: previous)
            }
            standings = try await client.standings()
            lastUpdated = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func announce(changesFrom previous: [Int: Fixture]) {
        for fixture in fixtures {
            guard let prior = previous[fixture.id] else { continue }

            let oldHome = prior.score.fullTime.home ?? 0
            let newHome = fixture.score.fullTime.home ?? 0
            let oldAway = prior.score.fullTime.away ?? 0
            let newAway = fixture.score.fullTime.away ?? 0

            if newHome > oldHome {
                notifier.notify(title: "⚽️ Goal — \(fixture.homeTeam.displayName)", body: fixture.summaryLine)
            }
            if newAway > oldAway {
                notifier.notify(title: "⚽️ Goal — \(fixture.awayTeam.displayName)", body: fixture.summaryLine)
            }
            if newHome < oldHome || newAway < oldAway {
                notifier.notify(title: "Goal disallowed", body: fixture.summaryLine)
            }
            if !prior.status.isLive, fixture.isLive {
                notifier.notify(title: "Kickoff", body: fixture.summaryLine)
            }
            if prior.status.isLive, fixture.status == .finished {
                notifier.notify(title: "Full time", body: fixture.summaryLine)
            }
        }
    }
}
