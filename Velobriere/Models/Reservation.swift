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

/// Les raisons pour lesquelles une réservation peut être refusée à
/// l'enregistrement par `ReservationStore.validate(_:)`.
///
/// Ces cas sont normalement écartés par l'écran de saisie, qui désactive le
/// bouton et affiche un message. Ils existent quand même parce qu'un écran peut
/// évoluer, se tromper, ou être contourné : la règle appartient au magasin,
/// l'écran ne fait que l'anticiper pour le confort de l'utilisateur.
enum ReservationError: LocalizedError, Equatable {
    /// La date de fin précède la date de début.
    case invalidDateRange
    /// La location commencerait avant aujourd'hui.
    case startsInThePast
    /// Quantité nulle ou négative.
    case invalidQuantity
    /// Le stock de la taille demandée est insuffisant sur au moins un jour de
    /// la période.
    case notEnoughUnits(available: Int, requested: Int)
    /// Mode partagé : personne n'est connecté, la réservation ne peut pas être
    /// rattachée à un compte.
    case notSignedIn
    /// Mode partagé : la taille demandée n'a pas de compteur côté serveur.
    case unknownVariant
    /// Mode partagé : le serveur a refusé l'écriture.
    case remote(String)

    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "La date de fin doit être postérieure à la date de début."
        case .startsInThePast:
            return "La période choisie commence dans le passé."
        case .invalidQuantity:
            return "Le nombre de vélos doit être d'au moins un."
        case .notEnoughUnits(let available, let requested):
            if available <= 0 {
                return "Plus aucun vélo de cette taille n'est disponible sur la période choisie."
            }
            return "Il ne reste que \(available) vélo\(available > 1 ? "s" : "") de cette taille "
                 + "sur la période choisie, pour \(requested) demandé\(requested > 1 ? "s" : "")."
        case .notSignedIn:
            return "Connectez-vous pour enregistrer votre réservation."
        case .unknownVariant:
            return "Cette taille de vélo n'est pas configurée. Contactez le loueur."
        case .remote(let message):
            return message
        }
    }
}
