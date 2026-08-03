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
    var deliveryFee: Double
    var totalPrice: Double
    var customerFirstName: String
    var customerLastName: String
    var customerCountryCode: String
    var customerPhone: String
    var customerEmail: String
    var notes: String
    var createdAt: Date
    /// Horodatage de l'acceptation des conditions générales de location,
    /// conservé comme preuve du consentement au contrat.
    var acceptedTermsAt: Date?
    var status: Status

    // MARK: - Paiement

    var paymentStatus: PaymentStatus
    var paymentMethod: PaymentMethod?
    var paymentReference: String?
    var paidAt: Date?
    var invoiceNumber: String?

    // MARK: - Annulation

    var cancelledAt: Date?
    /// Montant retenu au titre des frais d'annulation.
    var cancellationFee: Double?
    /// Montant effectivement remboursé au client.
    var refundedAmount: Double?
    var creditNoteNumber: String?

    var customerFullName: String {
        "\(customerFirstName) \(customerLastName)"
    }
}
