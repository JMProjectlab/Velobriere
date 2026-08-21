import Foundation

/// Conditions d'annulation appliquées par Ker Vélo Brière.
///
/// - Plus de 2 jours avant le départ : remboursement intégral.
/// - De 2 jours à la veille incluse, et le jour du départ : 50 % retenus.
/// - Location déjà commencée : aucun remboursement.
enum CancellationPolicy {

    enum Tier {
        /// Annulation sans frais.
        case free
        /// 50 % du montant sont retenus.
        case partial
        /// Location commencée : rien n'est remboursé.
        case started

        var feeRatio: Double {
            switch self {
            case .free: 0
            case .partial: 0.5
            case .started: 1
            }
        }
    }

    /// Nombre de jours avant le départ à partir duquel les frais s'appliquent.
    static let feeWindowDays = 2

    /// Jours pleins restants avant le début de la location (négatif si déjà commencée).
    static func daysUntilStart(_ startDate: Date, from now: Date = .now) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let start = calendar.startOfDay(for: startDate)
        return calendar.dateComponents([.day], from: today, to: start).day ?? 0
    }

    /// La location a-t-elle déjà commencé ?
    static func hasStarted(_ startDate: Date, from now: Date = .now) -> Bool {
        daysUntilStart(startDate, from: now) < 0
    }

    static func tier(startDate: Date, from now: Date = .now) -> Tier {
        let days = daysUntilStart(startDate, from: now)
        if days < 0 { return .started }
        if days <= feeWindowDays { return .partial }
        return .free
    }

    /// L'annulation entraîne-t-elle une retenue ?
    static func incursFee(startDate: Date, from now: Date = .now) -> Bool {
        tier(startDate: startDate, from: now) != .free
    }

    /// Montant retenu par Ker Vélo Brière en cas d'annulation.
    static func fee(amount: Double, startDate: Date, from now: Date = .now) -> Double {
        (amount * tier(startDate: startDate, from: now).feeRatio).roundedToCents
    }

    /// Montant remboursé au client.
    static func refund(amount: Double, startDate: Date, from now: Date = .now) -> Double {
        (amount - fee(amount: amount, startDate: startDate, from: now)).roundedToCents
    }

    /// Bandeau affiché dans le détail d'une réservation encore active.
    static func noticeTitle(startDate: Date, from now: Date = .now) -> String {
        let days = daysUntilStart(startDate, from: now)
        switch tier(startDate: startDate, from: now) {
        case .started: return "Location en cours"
        case .partial: return days <= 0 ? "Votre location débute aujourd'hui" : "Départ dans \(days) jour\(days > 1 ? "s" : "")"
        case .free: return "Départ dans \(days) jours"
        }
    }

    static func noticeBody(amount: Double, startDate: Date, from now: Date = .now) -> String {
        switch tier(startDate: startDate, from: now) {
        case .started:
            return "La location a commencé : elle ne peut plus être remboursée. Une annulation ne donnera lieu à aucun remboursement."
        case .partial:
            return "Vous êtes dans la période de frais d'annulation : toute annulation entraîne une retenue de 50 %, soit \(fee(amount: amount, startDate: startDate, from: now).eur)."
        case .free:
            return "L'annulation est encore sans frais."
        }
    }

    /// Phrase affichée dans la boîte de dialogue de confirmation.
    static func warningMessage(amount: Double, startDate: Date, from now: Date = .now) -> String {
        let days = daysUntilStart(startDate, from: now)
        let feeAmount = fee(amount: amount, startDate: startDate, from: now)
        let refundAmount = refund(amount: amount, startDate: startDate, from: now)

        switch tier(startDate: startDate, from: now) {
        case .started:
            return "Votre location a déjà commencé : elle ne peut pas être remboursée. En confirmant, la réservation sera annulée et aucun remboursement ne sera effectué (\(amount.eur) restent dus)."
        case .partial:
            let delay = days <= 0 ? "Votre location débute aujourd'hui" : "Votre location débute dans \(days) jour\(days > 1 ? "s" : "")"
            return "\(delay). À moins de \(feeWindowDays) jours du départ, des frais d'annulation de 50 % s'appliquent : \(feeAmount.eur) seront retenus et \(refundAmount.eur) vous seront remboursés."
        case .free:
            return "Votre location débute dans \(days) jours. L'annulation est sans frais : vous serez remboursé de \(amount.eur)."
        }
    }

    /// Message affiché une fois l'annulation effectuée.
    static func resultMessage(fee: Double, refund: Double, creditNoteNumber: String?) -> String {
        if refund <= 0 {
            return "Votre réservation est annulée. La location ayant déjà commencé, aucun remboursement n'est effectué."
        }
        let creditNoteSentence = creditNoteNumber.map { " L'avoir \($0) est disponible dans le détail de la réservation." } ?? ""
        if fee > 0 {
            return "Votre réservation est annulée. \(fee.eur) ont été retenus au titre des frais d'annulation ; \(refund.eur) vous sont remboursés.\(creditNoteSentence)"
        }
        return "Votre réservation est annulée et intégralement remboursée (\(refund.eur)).\(creditNoteSentence)"
    }
}

extension Double {
    var roundedToCents: Double { (self * 100).rounded() / 100 }
    var eur: String { formatted(.currency(code: "EUR")) }
}
