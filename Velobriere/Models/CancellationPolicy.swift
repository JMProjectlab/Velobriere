import Foundation

/// Conditions d'annulation appliquées par Vélo Brière.
///
/// Annulation à plus de 2 jours du départ : remboursement intégral.
/// Annulation à 2 jours ou moins du départ : 50 % du montant est retenu.
enum CancellationPolicy {

    /// Part du montant retenue lorsque l'annulation intervient dans la fenêtre de frais.
    static let feeRatio = 0.5

    /// Nombre de jours avant le départ à partir duquel les frais s'appliquent.
    static let feeWindowDays = 2

    /// Jours pleins restants avant le début de la location (négatif si déjà commencée).
    static func daysUntilStart(_ startDate: Date, from now: Date = .now) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let start = calendar.startOfDay(for: startDate)
        return calendar.dateComponents([.day], from: today, to: start).day ?? 0
    }

    /// L'annulation entraîne-t-elle des frais ?
    static func incursFee(startDate: Date, from now: Date = .now) -> Bool {
        daysUntilStart(startDate, from: now) <= feeWindowDays
    }

    /// Montant retenu par Vélo Brière en cas d'annulation.
    static func fee(amount: Double, startDate: Date, from now: Date = .now) -> Double {
        guard incursFee(startDate: startDate, from: now) else { return 0 }
        return (amount * feeRatio).roundedToCents
    }

    /// Montant remboursé au client.
    static func refund(amount: Double, startDate: Date, from now: Date = .now) -> Double {
        (amount - fee(amount: amount, startDate: startDate, from: now)).roundedToCents
    }

    /// Phrase affichée avant de confirmer une annulation.
    static func warningMessage(amount: Double, startDate: Date, from now: Date = .now) -> String {
        let days = daysUntilStart(startDate, from: now)
        guard incursFee(startDate: startDate, from: now) else {
            return "Votre location débute dans \(days) jours. L'annulation est sans frais : vous serez remboursé de \(amount.eur)."
        }
        let feeAmount = fee(amount: amount, startDate: startDate, from: now)
        let refundAmount = refund(amount: amount, startDate: startDate, from: now)
        let delay = days <= 0 ? "Votre location débute aujourd'hui" : "Votre location débute dans \(days) jour\(days > 1 ? "s" : "")"
        return "\(delay). À moins de \(feeWindowDays) jours du départ, des frais d'annulation de 50 % s'appliquent : \(feeAmount.eur) seront retenus et \(refundAmount.eur) vous seront remboursés."
    }
}

extension Double {
    var roundedToCents: Double { (self * 100).rounded() / 100 }
    var eur: String { formatted(.currency(code: "EUR")) }
}
