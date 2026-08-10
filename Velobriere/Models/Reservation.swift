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
    /// Taille réservée. Optionnel pour rester compatible avec les réservations
    /// enregistrées avant l'introduction des deux tailles : `ReservationStore`
    /// les rattache à la première taille du catalogue au chargement.
    var variantId: String?
    /// Libellé de la taille tel qu'affiché au client, par exemple « S / M ».
    var variantLabel: String?
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

    /// « E-ACTV 100 LF C2 — taille S / M » (le modèle seul si la taille est inconnue).
    var bikeDescription: String {
        guard let variantLabel, !variantLabel.isEmpty else { return bikeName }
        return "\(bikeName) — taille \(variantLabel)"
    }
}
