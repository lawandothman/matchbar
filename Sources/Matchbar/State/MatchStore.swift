import Foundation
import Observation

@MainActor
@Observable
final class MatchStore {
    private(set) var fixtures: [Fixture] = []
    private(set) var standings: [GroupStanding] = []
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?

    private var pollTask: Task<Void, Never>?
    private var announcedGoals: [Int: Int] = [:]
    private let provider: any ScoreProvider = ESPNClient()
    private let notifier = MatchNotifier()

    var liveFixtures: [Fixture] { fixtures.filter(\.isLive) }

    var sections: [FixtureDaySection] {
        let calendar = Calendar.current
        return Dictionary(grouping: fixtures) { calendar.startOfDay(for: $0.utcDate) }
            .map { day, fixtures in
                FixtureDaySection(day: day, fixtures: fixtures.sorted { $0.utcDate < $1.utcDate })
            }
            .sorted { $0.day < $1.day }
    }

    // where the popover should land when opened: today, the next match day,
    // or the last section once the tournament is over
    var todaySectionID: Date? {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return sections.first(where: { $0.day >= startOfToday })?.id ?? sections.last?.id
    }

    var allTeams: [FixtureTeam] {
        var seen = Set<String>()
        return standings
            .flatMap { $0.table.map(\.team) }
            .filter { team in
                guard let tla = team.tla, seen.insert(tla).inserted else { return false }
                return true
            }
            .sorted { $0.displayName < $1.displayName }
    }

    var groupLabels: [String] {
        standings.map(\.label).sorted()
    }

    init() {
        notifier.requestAuthorization()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                let interval: Double = self?.liveFixtures.isEmpty == false ? 30 : 60
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func refresh() async {
        let now = Date()
        do {
            let previous = Dictionary(uniqueKeysWithValues: fixtures.map { ($0.id, $0) })
            let fetched = try await provider.fixtures(
                from: now.addingTimeInterval(-40 * 86400),
                to: now.addingTimeInterval(40 * 86400)
            )
            // ESPN's CDN occasionally serves a stale snapshot; never let a
            // fixture move backwards in time
            fixtures = fetched.map { fixture in
                guard let prior = previous[fixture.id], isStale(fixture, comparedTo: prior) else {
                    return fixture
                }
                return prior
            }
            if !previous.isEmpty {
                announce(changesFrom: previous)
            }
            standings = try await provider.standings()
            stampGroups()
            stampForm()
            stampQualification()
            lastUpdated = Date()
            lastError = nil
            welcomeIfNeeded()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // one-time hello after the first successful fetch, delayed past the
    // notification permission prompt
    private func welcomeIfNeeded() {
        guard MatchNotifier.isAvailable,
              !UserDefaults.standard.bool(forKey: "didWelcome"),
              !fixtures.isEmpty
        else { return }
        UserDefaults.standard.set(true, forKey: "didWelcome")

        if let live = liveFixtures.first {
            notifier.notify(title: "You're all set", body: "Live now: \(live.summaryLine)", after: 15)
        } else if let next = fixtures.filter({ $0.utcDate > Date() }).min(by: { $0.utcDate < $1.utcDate }) {
            let when = next.utcDate.formatted(.dateTime.weekday(.wide).hour().minute())
            notifier.notify(title: "You're all set", body: "\(next.summaryLine) · \(when)", after: 15)
        }
    }

    // ESPN's scoreboard carries no group info per fixture; derive it from the
    // standings. Both teams sharing a group marks a group-stage match.
    private func stampGroups() {
        var groupByTeam: [String: String] = [:]
        for group in standings {
            for row in group.table {
                if let tla = row.team.tla {
                    groupByTeam[tla] = group.label
                }
            }
        }
        fixtures = fixtures.map { fixture in
            guard let homeTLA = fixture.homeTeam.tla,
                  let awayTLA = fixture.awayTeam.tla,
                  let homeGroup = groupByTeam[homeTLA],
                  homeGroup == groupByTeam[awayTLA]
            else { return fixture }
            var stamped = fixture
            stamped.stage = .groupStage
            stamped.group = homeGroup
            return stamped
        }
    }

    // last-five form per team, derived from finished fixtures; shootout
    // wins count as wins
    private func stampForm() {
        var resultsByTeam: [String: [FormResult]] = [:]
        let finished = fixtures
            .filter { $0.status == .finished }
            .sorted { $0.utcDate < $1.utcDate }

        for fixture in finished {
            guard let home = fixture.score.fullTime.home,
                  let away = fixture.score.fullTime.away,
                  let homeTLA = fixture.homeTeam.tla,
                  let awayTLA = fixture.awayTeam.tla
            else { continue }

            var homeResult: FormResult = home > away ? .win : (home < away ? .loss : .draw)
            if home == away,
               let homePens = fixture.score.penalties?.home,
               let awayPens = fixture.score.penalties?.away {
                homeResult = homePens > awayPens ? .win : .loss
            }
            let awayResult: FormResult = switch homeResult {
            case .win: .loss
            case .loss: .win
            case .draw: .draw
            }
            resultsByTeam[homeTLA, default: []].append(homeResult)
            resultsByTeam[awayTLA, default: []].append(awayResult)
        }

        standings = standings.map { group in
            var stamped = group
            stamped.table = group.table.map { row in
                var stampedRow = row
                stampedRow.form = Array((resultsByTeam[row.team.tla ?? ""] ?? []).suffix(5))
                return stampedRow
            }
            return stamped
        }
    }

    // 8 of the 12 third-placed teams advance; mark thirds currently inside
    // that cross-group top eight
    private func stampQualification() {
        let thirds = standings.compactMap { $0.table.count >= 3 ? $0.table[2] : nil }
        let topEight = thirds
            .sorted { a, b in
                if a.points != b.points { return a.points > b.points }
                if a.goalDifference != b.goalDifference { return a.goalDifference > b.goalDifference }
                return a.goalsFor > b.goalsFor
            }
            .prefix(8)
            .compactMap { $0.team.tla }
        let qualifying = Set(topEight)

        standings = standings.map { group in
            var stamped = group
            stamped.table = group.table.map { row in
                var stampedRow = row
                stampedRow.isBestThirdSpot = row.position == 3 && qualifying.contains(row.team.tla ?? "")
                return stampedRow
            }
            return stamped
        }
    }

    func matchStats(for fixture: Fixture) async -> MatchStats? {
        try? await provider.matchStats(eventID: fixture.id, homeTLA: fixture.homeTeam.tla)
    }

    private func isStale(_ fixture: Fixture, comparedTo prior: Fixture) -> Bool {
        let notStarted = fixture.status == .timed || fixture.status == .scheduled
        if (prior.status.isLive || prior.status == .finished) && notStarted {
            return true
        }
        if prior.status.isLive, fixture.status.isLive,
           let old = prior.clockSeconds, let new = fixture.clockSeconds, new < old {
            return true
        }
        return false
    }

    private func announce(changesFrom previous: [Int: Fixture]) {
        for fixture in fixtures {
            guard let prior = previous[fixture.id] else { continue }

            let oldHome = prior.score.fullTime.home ?? 0
            let newHome = fixture.score.fullTime.home ?? 0
            let oldAway = prior.score.fullTime.away ?? 0
            let newAway = fixture.score.fullTime.away ?? 0
            let total = newHome + newAway
            // ESPN posts the score immediately but the scorer details minutes
            // later; gate on goals already announced so late details never
            // re-notify
            let announced = announcedGoals[fixture.id] ?? (oldHome + oldAway)

            if total > announced {
                let newEvents = fixture.goals.filter { !prior.goals.contains($0) }
                if newEvents.count >= total - announced {
                    for goal in newEvents.suffix(total - announced) {
                        notifier.notify(title: "⚽️ \(goal.label)", body: fixture.summaryLine)
                    }
                } else {
                    if newHome > oldHome {
                        notifier.notify(title: "⚽️ Goal — \(fixture.homeTeam.displayName)", body: fixture.summaryLine)
                    }
                    if newAway > oldAway {
                        notifier.notify(title: "⚽️ Goal — \(fixture.awayTeam.displayName)", body: fixture.summaryLine)
                    }
                }
                announcedGoals[fixture.id] = total
            } else if total < announced {
                notifier.notify(title: "Goal disallowed", body: fixture.summaryLine)
                announcedGoals[fixture.id] = total
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
