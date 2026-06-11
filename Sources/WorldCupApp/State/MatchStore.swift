import Foundation
import Observation

@MainActor
@Observable
final class MatchStore {
    private(set) var fixtures: [Fixture] = []
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?
    private(set) var hasToken = false

    private var pollTask: Task<Void, Never>?

    var liveFixtures: [Fixture] { fixtures.filter(\.isLive) }

    var todayFixtures: [Fixture] {
        let calendar = Calendar.current
        return fixtures
            .filter { calendar.isDateInToday($0.utcDate) }
            .sorted { $0.utcDate < $1.utcDate }
    }

    init() {
        hasToken = TokenStore.token != nil
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(60))
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
            fixtures = try await client.fixtures(
                from: now.addingTimeInterval(-86400),
                to: now.addingTimeInterval(86400)
            )
            lastUpdated = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
