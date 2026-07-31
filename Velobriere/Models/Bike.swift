import Foundation

struct Bike: Identifiable, Hashable {
    let id: String
    let brand: String
    let name: String
    let tagline: String
    let highlights: [String]
    let pricePerDay: Double?
    let productURL: URL?
    let imageSystemName: String

    var displayPrice: String {
        guard let pricePerDay else { return "Tarif sur devis" }
        return pricePerDay.formatted(.currency(code: "EUR")) + " / jour"
    }
}
