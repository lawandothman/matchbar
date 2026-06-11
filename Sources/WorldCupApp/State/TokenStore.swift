import Foundation

enum TokenStore {
    private static let defaultsKey = "footballDataToken"

    static var token: String? {
        if let env = ProcessInfo.processInfo.environment["FOOTBALL_DATA_TOKEN"], !env.isEmpty {
            return env
        }
        guard let stored = UserDefaults.standard.string(forKey: defaultsKey), !stored.isEmpty else {
            return nil
        }
        return stored
    }

    static func save(_ token: String) {
        UserDefaults.standard.set(token.trimmingCharacters(in: .whitespacesAndNewlines), forKey: defaultsKey)
    }
}
