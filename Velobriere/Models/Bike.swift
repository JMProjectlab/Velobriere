import Foundation

struct Bike: Identifiable, Hashable {
    let id: String
    let brand: String
    let name: String
    let tagline: String
    let highlights: [String]
    let variants: [BikeVariant]
    let pricingOptions: [PricingOption]
    let deliveryFee: Double
    let deliveryRadiusKm: Int
    /// Somme des exemplaires de toutes les tailles.
    var totalUnits: Int { variants.reduce(0) { $0 + $1.units } }
    let productURL: URL?

    /// Taille correspondant à l'identifiant, la première du catalogue à défaut
    /// (identifiant inconnu ou réservation antérieure aux deux tailles).
    func variant(withID id: String?) -> BikeVariant {
        variants.first { $0.id == id } ?? variants[0]
    }

    var sizesLabel: String {
        variants.map(\.size).joined(separator: " · ")
    }

    var startingPriceLabel: String {
        guard let lowest = pricingOptions.min(by: { $0.price < $1.price }) else { return "" }
        return "À partir de \(lowest.displayPrice)"
    }
}
