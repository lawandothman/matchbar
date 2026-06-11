import Foundation

enum CountryFlag {
    // FIFA trigram -> ISO 3166-1 alpha-2, for codes that exist as flag emoji
    private static let fifaToISO: [String: String] = [
        // CONCACAF
        "MEX": "MX", "USA": "US", "CAN": "CA", "CRC": "CR", "PAN": "PA",
        "HON": "HN", "GUA": "GT", "SLV": "SV", "JAM": "JM", "TRI": "TT",
        "CUB": "CU", "HAI": "HT", "CUW": "CW", "SUR": "SR", "NCA": "NI",
        // CONMEBOL
        "ARG": "AR", "BRA": "BR", "URU": "UY", "COL": "CO", "ECU": "EC",
        "PAR": "PY", "CHI": "CL", "PER": "PE", "VEN": "VE", "BOL": "BO",
        // UEFA
        "GER": "DE", "FRA": "FR", "ESP": "ES", "POR": "PT", "NED": "NL",
        "BEL": "BE", "ITA": "IT", "CRO": "HR", "SRB": "RS", "SUI": "CH",
        "AUT": "AT", "POL": "PL", "UKR": "UA", "CZE": "CZ", "SVK": "SK",
        "SVN": "SI", "HUN": "HU", "ROU": "RO", "GRE": "GR", "TUR": "TR",
        "DEN": "DK", "SWE": "SE", "NOR": "NO", "FIN": "FI", "ISL": "IS",
        "IRL": "IE", "ALB": "AL", "BIH": "BA", "MKD": "MK", "MNE": "ME",
        "GEO": "GE", "BUL": "BG", "RUS": "RU", "ISR": "IL", "KOS": "XK",
        // AFC
        "JPN": "JP", "KOR": "KR", "PRK": "KP", "AUS": "AU", "IRN": "IR",
        "KSA": "SA", "QAT": "QA", "UAE": "AE", "IRQ": "IQ", "JOR": "JO",
        "UZB": "UZ", "OMA": "OM", "BHR": "BH", "KUW": "KW", "LBN": "LB",
        "SYR": "SY", "PLE": "PS", "THA": "TH", "VIE": "VN", "IDN": "ID",
        "MAS": "MY", "SGP": "SG", "PHI": "PH", "IND": "IN", "CHN": "CN",
        "TJK": "TJ", "KGZ": "KG", "TKM": "TM", "KAZ": "KZ",
        // CAF
        "RSA": "ZA", "MAR": "MA", "EGY": "EG", "TUN": "TN", "ALG": "DZ",
        "SEN": "SN", "CIV": "CI", "GHA": "GH", "NGA": "NG", "CMR": "CM",
        "COD": "CD", "MLI": "ML", "BFA": "BF", "GUI": "GN", "GAB": "GA",
        "CPV": "CV", "ANG": "AO", "ZAM": "ZM", "ZIM": "ZW", "KEN": "KE",
        "UGA": "UG", "TAN": "TZ", "MOZ": "MZ", "BEN": "BJ", "TOG": "TG",
        "GAM": "GM", "GNB": "GW", "SLE": "SL", "LBY": "LY", "SDN": "SD",
        "ETH": "ET", "NAM": "NA", "BOT": "BW", "RWA": "RW", "MAD": "MG",
        "MTN": "MR", "NIG": "NE", "GEQ": "GQ", "CGO": "CG",
        // OFC
        "NZL": "NZ", "FIJ": "FJ", "PNG": "PG", "SOL": "SB",
    ]

    // UK home nations use subdivision tag sequences, not regional indicators
    private static let special: [String: String] = [
        "ENG": "\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}",
        "SCO": "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}",
        "WAL": "\u{1F3F4}\u{E0067}\u{E0062}\u{E0077}\u{E006C}\u{E0073}\u{E007F}",
    ]

    static func emoji(for tla: String?) -> String? {
        guard let tla = tla?.uppercased() else { return nil }
        if let flag = special[tla] { return flag }
        guard let iso = fifaToISO[tla] else { return nil }
        var flag = ""
        for scalar in iso.unicodeScalars {
            guard let indicator = Unicode.Scalar(0x1F1E6 + scalar.value - 65) else { return nil }
            flag.unicodeScalars.append(indicator)
        }
        return flag
    }
}
