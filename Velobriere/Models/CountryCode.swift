import Foundation

struct CountryCode: Identifiable, Hashable {
    var id: String { dial }
    let dial: String
    let flag: String
    let label: String
}

enum CountryCodes {
    static let all: [CountryCode] = [
        CountryCode(dial: "+33", flag: "🇫🇷", label: "France"),
        CountryCode(dial: "+32", flag: "🇧🇪", label: "Belgique"),
        CountryCode(dial: "+41", flag: "🇨🇭", label: "Suisse"),
        CountryCode(dial: "+352", flag: "🇱🇺", label: "Luxembourg"),
        CountryCode(dial: "+49", flag: "🇩🇪", label: "Allemagne"),
        CountryCode(dial: "+44", flag: "🇬🇧", label: "Royaume-Uni"),
        CountryCode(dial: "+31", flag: "🇳🇱", label: "Pays-Bas"),
        CountryCode(dial: "+34", flag: "🇪🇸", label: "Espagne"),
        CountryCode(dial: "+39", flag: "🇮🇹", label: "Italie"),
        CountryCode(dial: "+351", flag: "🇵🇹", label: "Portugal"),
        CountryCode(dial: "+353", flag: "🇮🇪", label: "Irlande"),
        CountryCode(dial: "+1", flag: "🇺🇸", label: "États-Unis / Canada")
    ]

    static let `default` = all[0]
}
