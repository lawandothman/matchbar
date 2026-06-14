import Foundation

struct SnapshotStore {
    private static let schema = 1
    private static let staleness: TimeInterval = 6 * 3600

    private let url: URL = {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Matchbar", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("snapshot.json")
    }()

    func load() -> PersistedSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? decoder.decode(PersistedSnapshot.self, from: data),
              snapshot.schema == Self.schema,
              Date().timeIntervalSince(snapshot.savedAt) < Self.staleness
        else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        return snapshot
    }

    func save(fixtures: [Fixture], standings: [GroupStanding]) {
        let snapshot = PersistedSnapshot(
            schema: Self.schema,
            savedAt: Date(),
            fixtures: fixtures,
            standings: standings
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
