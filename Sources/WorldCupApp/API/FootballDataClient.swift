import Foundation

struct FootballDataClient: ScoreProvider {
    let token: String
    var session: URLSession = .shared

    private static let base = "https://api.football-data.org/v4/competitions/WC"

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func fixtures(from: Date, to: Date) async throws -> [Fixture] {
        var components = URLComponents(string: "\(Self.base)/matches")!
        components.queryItems = [
            URLQueryItem(name: "dateFrom", value: Self.dayFormatter.string(from: from)),
            URLQueryItem(name: "dateTo", value: Self.dayFormatter.string(from: to)),
        ]
        let response: MatchesResponse = try await get(components.url!)
        return response.matches
    }

    func standings() async throws -> [GroupStanding] {
        let response: StandingsResponse = try await get(URL(string: "\(Self.base)/standings")!)
        return response.standings.filter { $0.type == nil || $0.type == "TOTAL" }
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Auth-Token")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FootballDataError.badResponse(0)
        }
        guard http.statusCode == 200 else {
            throw FootballDataError.badResponse(http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}
