import Foundation

struct FootballDataClient: ScoreProvider {
    let token: String
    var session: URLSession = .shared

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func fixtures(from: Date, to: Date) async throws -> [Fixture] {
        var components = URLComponents(string: "https://api.football-data.org/v4/competitions/WC/matches")!
        components.queryItems = [
            URLQueryItem(name: "dateFrom", value: Self.dayFormatter.string(from: from)),
            URLQueryItem(name: "dateTo", value: Self.dayFormatter.string(from: to)),
        ]

        var request = URLRequest(url: components.url!)
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
        return try decoder.decode(MatchesResponse.self, from: data).matches
    }
}
