import Foundation
import Observation

@MainActor
@Observable
final class MatchStore {
    private(set) var fixtures: [Fixture] = []
    private(set) var standings: [GroupStanding] = []
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?
    private(set) var restoredSavedAt: Date?

    private var pollTask: Task<Void, Never>?
    private var sleepTask: Task<Void, Never>?
    private var announcedGoals: [Int: Int] = [:]
    private let provider: any ScoreProvider = ESPNClient()
    private let notifier = MatchNotifier()
    private let snapshotStore = SnapshotStore()

    private var windowAnchorDay: Date?
    private var lastWideFetch: Date = .distantPast
    private var restoredFromDisk = false

    private struct CachedStats {
        let value: MatchStats
        let fetchedAt: Date
        let isFinal: Bool
    }
    private var statsCache: [Int: CachedStats] = [:]
    private var statsInFlight: [Int: Task<MatchStats?, Never>] = [:]

    private let liveInterval: TimeInterval = 30
    private let idleFloor: TimeInterval = 60
    private let idleCeiling: TimeInterval = 15 * 60
    private let preRoll: TimeInterval = 120
    private let wideFallback: TimeInterval = 600
    private let liveStatsTTL: TimeInterval = 20
    private let liveSanity: TimeInterval = 3 * 3600

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

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
        restoreFromDisk()
        pollTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                guard let self else { return }
                await self.interruptibleSleep(self.nextPollDelay())
                if Task.isCancelled { break }
                await self.tick()
            }
        }
    }

    func refreshNow() {
        sleepTask?.cancel()
    }

    private func interruptibleSleep(_ delay: TimeInterval) async {
        let task = Task { _ = try? await Task.sleep(for: .seconds(delay)) }
        sleepTask = task
        await task.value
        sleepTask = nil
    }

    private func restoreFromDisk() {
        guard let snapshot = snapshotStore.load() else { return }
        let cutoff = Date().addingTimeInterval(-liveSanity)
        fixtures = snapshot.fixtures.map { fixture in
            guard fixture.isLive, fixture.utcDate < cutoff else { return fixture }
            var stale = fixture
            stale.status = .unknown
            return stale
        }
        standings = snapshot.standings
        restoredFromDisk = true
        restoredSavedAt = snapshot.savedAt
    }

    func refresh() async {
        let now = Date()
        do {
            let previous = Dictionary(uniqueKeysWithValues: fixtures.map { ($0.id, $0) })
            let fetched = try await provider.fixtures(
                from: now.addingTimeInterval(-40 * 86400),
                to: now.addingTimeInterval(40 * 86400)
            )
            commit(fetched, previous: previous)
            standings = try await provider.standings()
            stampGroups()
            stampForm()
            stampQualification()
            windowAnchorDay = Self.utcCalendar.startOfDay(for: now)
            lastWideFetch = now
            lastUpdated = Date()
            lastError = nil
            snapshotStore.save(fixtures: fixtures, standings: standings)
            welcomeIfNeeded()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func tick() async {
        let now = Date()
        let today = Self.utcCalendar.startOfDay(for: now)
        if restoredFromDisk
            || windowAnchorDay != today
            || now.timeIntervalSince(lastWideFetch) > wideFallback {
            await refresh()
            return
        }
        do {
            let previous = Dictionary(uniqueKeysWithValues: fixtures.map { ($0.id, $0) })
            let fresh = try await provider.fixtures(
                from: today.addingTimeInterval(-86400),
                to: today.addingTimeInterval(86400)
            )
            var merged = previous
            var didFinish = false
            for fixture in fresh {
                if let prior = merged[fixture.id], isStale(fixture, comparedTo: prior) { continue }
                if merged[fixture.id]?.status.isLive == true, fixture.status == .finished {
                    didFinish = true
                }
                merged[fixture.id] = fixture
            }
            fixtures = merged.values.sorted {
                $0.utcDate != $1.utcDate ? $0.utcDate < $1.utcDate : $0.id < $1.id
            }
            announce(changesFrom: previous)
            stampGroups()
            if didFinish {
                standings = try await provider.standings()
                stampForm()
                stampQualification()
                snapshotStore.save(fixtures: fixtures, standings: standings)
            }
            lastUpdated = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func commit(_ fetched: [Fixture], previous: [Int: Fixture]) {
        if restoredFromDisk {
            fixtures = fetched
            announcedGoals = Dictionary(uniqueKeysWithValues: fetched.map {
                ($0.id, ($0.score.fullTime.home ?? 0) + ($0.score.fullTime.away ?? 0))
            })
            restoredFromDisk = false
            restoredSavedAt = nil
            return
        }
        fixtures = fetched.map { fixture in
            guard let prior = previous[fixture.id], isStale(fixture, comparedTo: prior) else {
                return fixture
            }
            return prior
        }
        if !previous.isEmpty {
            announce(changesFrom: previous)
        }
    }

    private func nextPollDelay() -> TimeInterval {
        if !liveFixtures.isEmpty { return liveInterval }
        if fixtures.isEmpty || lastError != nil { return idleFloor }
        let now = Date()
        let nextKickoff = fixtures
            .filter { $0.status == .timed && $0.utcDate > now }
            .map(\.utcDate)
            .min()
        guard let nextKickoff else { return idleCeiling }
        let untilKickoff = nextKickoff.timeIntervalSince(now)
        if untilKickoff <= preRoll { return idleFloor }
        return min(untilKickoff - preRoll, idleCeiling)
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

    /// Cache-aware match stats. Finished matches are served from memory forever;
    /// live matches refresh on a short TTL (the detail view forces a refresh on
    /// its live loop). `forceRefresh` bypasses the TTL.
    func matchStats(for fixture: Fixture, forceRefresh: Bool = false) async -> MatchStats? {
        let id = fixture.id
        // immutable hit: full-time stats never change
        if let cached = statsCache[id], cached.isFinal {
            return cached.value
        }
        // live hit within the freshness window, unless the caller forced a refresh
        // or the fixture has since gone terminal (then we want true full-time stats)
        if !forceRefresh, !isTerminal(fixture.status),
           let cached = statsCache[id],
           Date().timeIntervalSince(cached.fetchedAt) < liveStatsTTL {
            return cached.value
        }
        // coalesce duplicate in-flight fetches (e.g. a quick back/forward re-open)
        if let inFlight = statsInFlight[id] {
            return await inFlight.value
        }

        let isFinal = isTerminal(fixture.status)
        let homeTLA = fixture.homeTeam.tla
        let task = Task<MatchStats?, Never> { [provider] in
            try? await provider.matchStats(eventID: id, homeTLA: homeTLA)
        }
        statsInFlight[id] = task
        let result = await task.value
        statsInFlight[id] = nil

        // only cache successes; leave a transient failure uncached so it retries
        if let result {
            statsCache[id] = CachedStats(value: result, fetchedAt: Date(), isFinal: isFinal)
        }
        return result
    }

    /// Synchronous peek so a re-opened finished match paints instantly (no spinner).
    func cachedStats(for id: Int) -> MatchStats? {
        statsCache[id]?.value
    }

    // terminal == stats are frozen; mirrors the post-state mapping in ESPNClient
    private func isTerminal(_ status: FixtureStatus) -> Bool {
        switch status {
        case .finished, .cancelled, .postponed, .suspended: return true
        default: return false
        }
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
