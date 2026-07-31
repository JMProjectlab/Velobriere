import Foundation

struct Reservation: Identifiable, Codable {
    enum Status: String, Codable, Hashable {
        case pending
        case confirmed
        case cancelled
    }

    let id: UUID
    let bikeId: String
    let bikeName: String
    var startDate: Date
    var endDate: Date
    var quantity: Int
    var pricingLabel: String
    var pricePerUnit: Double
    var includesDelivery: Bool
    var totalPrice: Double
    var customerFirstName: String
    var customerLastName: String
    var customerCountryCode: String
    var customerPhone: String
    var customerEmail: String
    var notes: String
    var createdAt: Date
    var status: Status
}
