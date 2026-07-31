import Foundation

struct Bike: Identifiable, Hashable {
    let id: String
    let brand: String
    let name: String
    let tagline: String
    let highlights: [String]
    let pricingOptions: [PricingOption]
    let deliveryFee: Double
    let deliveryRadiusKm: Int
    let totalUnits: Int
    let productURL: URL?
    let imageSystemName: String

    var startingPriceLabel: String {
        guard let lowest = pricingOptions.min(by: { $0.price < $1.price }) else { return "" }
        return "À partir de \(lowest.displayPrice)"
    }
}
