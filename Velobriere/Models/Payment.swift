import Foundation

enum PaymentMethod: String, Codable, Hashable, CaseIterable {
    case applePay
    case card

    var label: String {
        switch self {
        case .applePay: "Apple Pay"
        case .card: "Carte bancaire"
        }
    }
}

enum PaymentStatus: String, Codable, Hashable {
    /// Demande créée, pas encore payée.
    case pending
    case paid
    /// Annulée après paiement, avec remboursement total ou partiel.
    case refunded
}

struct PaymentResult: Hashable {
    let method: PaymentMethod
    let amount: Double
    /// Référence de transaction renvoyée par le prestataire de paiement.
    let transactionReference: String
    let processedAt: Date
}

enum PaymentError: LocalizedError {
    case declined
    case cancelledByUser

    var errorDescription: String? {
        switch self {
        case .declined:
            "Le paiement a été refusé. Vérifiez vos informations ou essayez un autre moyen de paiement."
        case .cancelledByUser:
            "Paiement interrompu."
        }
    }
}
