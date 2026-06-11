import Foundation

enum TeamNameOverrides {
    // ESPN short names that are FIFA officialese, longer or less readable
    // than the common name
    private static let overrides: [String: String] = [
        "Korea Republic": "South Korea",
        "Korea DPR": "North Korea",
        "IR Iran": "Iran",
        "United Arab Emirates": "UAE",
        "Bosnia and Herzegovina": "Bosnia-H.",
        "Democratic Republic of the Congo": "DR Congo",
    ]

    static func shortened(_ name: String) -> String {
        overrides[name] ?? placeholder(name) ?? name
    }

    // knockout seeding codes ESPN uses before teams are decided:
    // "1A" winner of Group A, "2B" runner-up, "3RD A/B/C/D/F" a best third
    private static func placeholder(_ name: String) -> String? {
        let upper = name.uppercased()
        if upper.count == 2,
           let kind = upper.first, let group = upper.last,
           ("A"..."L").contains(String(group)) {
            if kind == "1" { return "Winner \(group)" }
            if kind == "2" { return "Runner-up \(group)" }
        }
        if upper.hasPrefix("3RD ") {
            return "Best 3rd"
        }
        // "RD32 W9", "RD16 W1", "QF W3", "SF L2" - winner/loser of an
        // earlier knockout match
        let parts = upper.split(separator: " ")
        if parts.count == 2,
           parts[0].hasPrefix("RD") || parts[0] == "QF" || parts[0] == "SF",
           let kind = parts[1].first, kind == "W" || kind == "L",
           let number = Int(parts[1].dropFirst()) {
            return kind == "W" ? "Winner \(number)" : "Loser \(number)"
        }
        return nil
    }
}
