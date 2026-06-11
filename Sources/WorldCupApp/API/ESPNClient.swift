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
        components.queryItems = [URLQueryItem(name: "dates", value: range)]
        let response: ESPNScoreboardResponse = try await get(components.url!)
        return response.events.compactMap(fixture)
    }

    func standings() async throws -> [GroupStanding] {
        let response: ESPNStandingsResponse = try await get(URL(string: Self.standingsURL)!)
        return response.children.map { child in
            GroupStanding(
                group: child.name,
                table: child.standings.entries.enumerated().map { index, entry in
                    standingRow(from: entry, fallbackPosition: index + 1)
                }
            )
        }
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

        return Fixture(
            id: id,
            utcDate: date,
            status: status,
            stage: .unknown,
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
            )
        )
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
