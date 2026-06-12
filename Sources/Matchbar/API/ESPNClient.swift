import Foundation

struct ESPNClient: ScoreProvider {
    var session: URLSession = .shared

    private static let scoreboardURL = "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard"
    private static let standingsURL = "https://site.api.espn.com/apis/v2/sports/soccer/fifa.world/standings"

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // ESPN dates omit seconds: "2026-06-11T19:00Z"
    private static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let fallbackDateFormatter = ISO8601DateFormatter()

    func fixtures(from: Date, to: Date) async throws -> [Fixture] {
        let range = "\(Self.dayFormatter.string(from: from))-\(Self.dayFormatter.string(from: to))"
        var components = URLComponents(string: Self.scoreboardURL)!
        components.queryItems = [
            URLQueryItem(name: "dates", value: range),
            URLQueryItem(name: "limit", value: "200"),
        ]
        let response: ESPNScoreboardResponse = try await get(components.url!)
        return response.events.compactMap(fixture)
    }

    func standings() async throws -> [GroupStanding] {
        let response: ESPNStandingsResponse = try await get(URL(string: Self.standingsURL)!)
        return response.children.map { child in
            let rows = child.standings.entries.enumerated().map { index, entry in
                standingRow(from: entry, fallbackPosition: index + 1)
            }
            // rank by the group-stage tiebreakers; ESPN's own ordering goes
            // stale during live rounds
            var ranked = rows.sorted { a, b in
                if a.points != b.points { return a.points > b.points }
                if a.goalDifference != b.goalDifference { return a.goalDifference > b.goalDifference }
                if a.goalsFor != b.goalsFor { return a.goalsFor > b.goalsFor }
                return a.position < b.position
            }
            for index in ranked.indices {
                ranked[index].position = index + 1
            }
            return GroupStanding(group: child.name, table: ranked)
        }
    }

    func matchStats(eventID: Int, homeTLA: String?) async throws -> MatchStats? {
        let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/summary?event=\(eventID)")!
        let response: ESPNSummaryResponse = try await get(url)
        guard let teams = response.boxscore?.teams, teams.count >= 2 else { return nil }

        let homeIndex = teams.firstIndex { $0.team.abbreviation == homeTLA } ?? 0
        let awayIndex = homeIndex == 0 ? 1 : 0
        return MatchStats(
            home: teamStats(teams[homeIndex]),
            away: teamStats(teams[awayIndex])
        )
    }

    private func teamStats(_ box: ESPNBoxTeam) -> TeamMatchStats {
        var values: [String: String] = [:]
        for stat in box.statistics ?? [] {
            if let name = stat.name, let value = stat.displayValue {
                values[name] = value
            }
        }
        func int(_ key: String) -> Int? { values[key].flatMap(Int.init) }
        func double(_ key: String) -> Double? { values[key].flatMap(Double.init) }

        let accurate = int("accuratePasses")
        let total = int("totalPasses")
        var accuracy: Double?
        if let accurate, let total, total > 0 {
            accuracy = Double(accurate) / Double(total)
        }

        return TeamMatchStats(
            shots: int("totalShots"),
            shotsOnTarget: int("shotsOnTarget"),
            possession: double("possessionPct"),
            passes: total,
            passAccuracy: accuracy,
            fouls: int("foulsCommitted"),
            yellowCards: int("yellowCards"),
            redCards: int("redCards"),
            offsides: int("offsides"),
            corners: int("wonCorners")
        )
    }

    private func fixture(_ event: ESPNEvent) -> Fixture? {
        guard let id = Int(event.id),
              let date = Self.eventDateFormatter.date(from: event.date)
                  ?? Self.fallbackDateFormatter.date(from: event.date),
              let competition = event.competitions.first,
              let home = competition.competitors.first(where: { $0.homeAway == "home" }),
              let away = competition.competitors.first(where: { $0.homeAway == "away" })
        else { return nil }

        let status = status(from: event.status.type)
        let started = event.status.type.state != "pre"

        var penalties: ScoreValues?
        if let homePens = home.shootoutScore, let awayPens = away.shootoutScore {
            penalties = ScoreValues(home: homePens, away: awayPens)
        }

        let goals: [GoalEvent] = (competition.details ?? [])
            .filter { $0.scoringPlay == true }
            .map { detail in
                GoalEvent(
                    scorer: detail.athletesInvolved?.first?.displayName,
                    scorerShort: detail.athletesInvolved?.first?.shortName,
                    minute: detail.clock?.displayValue,
                    isHome: detail.team?.id != nil && detail.team?.id == home.team.id,
                    isOwnGoal: detail.ownGoal == true,
                    isPenalty: detail.penaltyKick == true
                )
            }

        return Fixture(
            id: id,
            utcDate: date,
            status: status,
            stage: stage(for: date),
            group: nil,
            homeTeam: team(from: home.team),
            awayTeam: team(from: away.team),
            score: FixtureScore(
                fullTime: ScoreValues(
                    home: started ? home.score.flatMap(Int.init) : nil,
                    away: started ? away.score.flatMap(Int.init) : nil
                ),
                duration: penalties == nil ? .regular : .penaltyShootout,
                penalties: penalties
            ),
            minute: event.status.type.state == "in" ? event.status.displayClock : nil,
            clockSeconds: event.status.type.state == "in" ? event.status.clock : nil,
            goals: goals
        )
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    // the 2026 knockout calendar is fixed; ESPN's scoreboard carries no round
    // info, so infer it from the date (half-day padding absorbs UTC spillover
    // from late kickoffs in western venues)
    private func stage(for date: Date) -> FixtureStage {
        func boundary(_ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
            Self.utcCalendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
        }
        switch date {
        case ..<boundary(6, 28): return .groupStage
        case ..<boundary(7, 4, 12): return .last32
        case ..<boundary(7, 8, 12): return .last16
        case ..<boundary(7, 12, 12): return .quarterFinals
        case ..<boundary(7, 17): return .semiFinals
        case ..<boundary(7, 19, 6): return .thirdPlace
        default: return .finalStage
        }
    }

    private func team(from info: ESPNTeamInfo) -> FixtureTeam {
        FixtureTeam(
            name: info.displayName,
            shortName: info.shortDisplayName,
            tla: info.abbreviation,
            crest: nil
        )
    }

    private func status(from type: ESPNStatusType) -> FixtureStatus {
        let name = type.name.uppercased()
        switch type.state {
        case "pre":
            if name.contains("POSTPONED") { return .postponed }
            if name.contains("CANCEL") { return .cancelled }
            return .timed
        case "in":
            if name.contains("HALFTIME") { return .paused }
            if name.contains("SHOOTOUT") { return .penaltyShootout }
            if name.contains("OVERTIME") || name.contains("EXTRA") { return .extraTime }
            return .inPlay
        case "post":
            if name.contains("ABANDONED") || name.contains("SUSPEND") { return .suspended }
            if name.contains("POSTPONED") { return .postponed }
            if name.contains("CANCEL") { return .cancelled }
            return .finished
        default:
            return .unknown
        }
    }

    private func standingRow(from entry: ESPNStandingsEntry, fallbackPosition: Int) -> StandingRow {
        let stats = Dictionary(
            entry.stats.compactMap { stat in stat.value.map { (stat.name, Int($0)) } },
            uniquingKeysWith: { first, _ in first }
        )
        return StandingRow(
            position: stats["rank"] ?? fallbackPosition,
            team: team(from: entry.team),
            playedGames: stats["gamesPlayed"] ?? 0,
            won: stats["wins"] ?? 0,
            draw: stats["ties"] ?? 0,
            lost: stats["losses"] ?? 0,
            points: stats["points"] ?? 0,
            goalsFor: stats["pointsFor"] ?? 0,
            goalsAgainst: stats["pointsAgainst"] ?? 0,
            goalDifference: stats["pointDifferential"] ?? 0
        )
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw ESPNError.badResponse(0)
        }
        guard http.statusCode == 200 else {
            throw ESPNError.badResponse(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
