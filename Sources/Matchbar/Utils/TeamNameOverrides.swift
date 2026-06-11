import Foundation

enum TeamNameOverrides {
    // football-data short names that are FIFA officialese, longer or less
    // readable than the common name
    private static let overrides: [String: String] = [
        "Korea Republic": "South Korea",
        "Korea DPR": "North Korea",
        "IR Iran": "Iran",
        "United Arab Emirates": "UAE",
        "Bosnia and Herzegovina": "Bosnia-H.",
        "Democratic Republic of the Congo": "DR Congo",
    ]

    static func shortened(_ name: String) -> String {
        overrides[name] ?? name
    }
}
