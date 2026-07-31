import Foundation

struct PricingOption: Identifiable, Hashable {
    let id: String
    let label: String
    let price: Double

    var displayPrice: String {
        price.formatted(.currency(code: "EUR"))
    }
}
