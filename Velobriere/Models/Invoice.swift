import Foundation

/// Facture ou avoir rattaché à une réservation.
///
/// La numérotation est séquentielle, chronologique et sans rupture, comme
/// l'exige la réglementation française sur la facturation.
struct Invoice: Identifiable, Codable, Hashable {

    enum Kind: String, Codable, Hashable {
        case invoice
        case creditNote

        var label: String {
            switch self {
            case .invoice: "Facture"
            case .creditNote: "Avoir"
            }
        }

        var prefix: String {
            switch self {
            case .invoice: "FA"
            case .creditNote: "AV"
            }
        }
    }

    struct Line: Identifiable, Codable, Hashable {
        let id: String
        let label: String
        let quantity: Int
        let unitPrice: Double

        var total: Double { (unitPrice * Double(quantity)).roundedToCents }
    }

    let id: UUID
    let number: String
    let kind: Kind
    let issuedAt: Date
    let reservationId: UUID
    let customerName: String
    let customerEmail: String
    let lines: [Line]
    /// Référence de la facture d'origine, pour un avoir.
    let relatedInvoiceNumber: String?
    let paymentMethodLabel: String?

    var total: Double { lines.reduce(0) { $0 + $1.total }.roundedToCents }

    /// Mention de TVA. Le régime de Ker Vélo Brière n'étant pas connu, il reste à
    /// renseigner : soit le taux applicable, soit la mention de franchise en base.
    static let vatNote = "[À COMPLÉTER : régime de TVA — taux applicable, ou mention « TVA non applicable, art. 293 B du CGI » en franchise en base]"

    static let sellerIdentityNote = "[À COMPLÉTER : forme juridique, SIRET, RCS et n° de TVA intracommunautaire]"
}
