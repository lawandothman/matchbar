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

    // ESPN's seeding codes for undecided knockout slots: "1A", "2B",
    // "3RD A/B/C/D/F", "RD32 W9", "QF W3", "SF L2". Show them all as TBD;
    // the fixture's round label carries the context.
    private static func placeholder(_ name: String) -> String? {
        let upper = name.uppercased()
        if upper.count == 2,
           let kind = upper.first, kind == "1" || kind == "2",
           let group = upper.last, ("A"..."L").contains(String(group)) {
            return "TBD"
        }
        if upper.hasPrefix("3RD ") {
            return "TBD"
        }
        let parts = upper.split(separator: " ")
        if parts.count == 2,
           parts[0].hasPrefix("RD") || parts[0] == "QF" || parts[0] == "SF",
           let kind = parts[1].first, kind == "W" || kind == "L",
           Int(parts[1].dropFirst()) != nil {
            return "TBD"
        }
        return nil
    }
}
