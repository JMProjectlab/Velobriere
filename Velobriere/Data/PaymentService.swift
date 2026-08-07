import Foundation

protocol PaymentService {
    /// Encaisse `amount` euros et renvoie la transaction, ou lève une `PaymentError`.
    func charge(amount: Double, method: PaymentMethod) async throws -> PaymentResult
    /// Rembourse `amount` euros sur la transaction d'origine.
    func refund(amount: Double, originalReference: String) async throws -> String
    /// Indique si Apple Pay est utilisable sur cet appareil.
    var isApplePayAvailable: Bool { get }
}

/// ⚠️ IMPLÉMENTATION SIMULÉE — N'ENCAISSE AUCUN ARGENT RÉEL.
///
/// Aucun paiement n'est transmis à quelque banque ou prestataire que ce soit :
/// cette classe se contente d'attendre puis de renvoyer une référence factice,
/// afin que le tunnel de vente soit testable de bout en bout.
///
/// Pour passer en production, écrire un `LivePaymentService: PaymentService`
/// adossé à un prestataire (Stripe, Adyen, SumUp…). Il faudra notamment :
///
/// 1. un compte marchand chez le prestataire, et ses clés d'API — la clé
///    secrète ne doit JAMAIS être embarquée dans l'app, uniquement côté serveur ;
/// 2. un endpoint serveur qui crée l'intention de paiement et renvoie son
///    secret client à l'app ;
/// 3. pour Apple Pay : un Merchant ID sur le portail développeur Apple,
///    la capability « Apple Pay » activée sur la target, et le rattachement
///    du certificat marchand au prestataire ;
/// 4. le SDK du prestataire, qui porte la conformité PCI-DSS et
///    l'authentification forte (DSP2) — ne jamais manipuler soi-même
///    un numéro de carte ;
/// 5. la confirmation du paiement côté serveur via webhook avant de
///    considérer la réservation comme payée.
final class SimulatedPaymentService: PaymentService {

    /// Vrai Apple Pay : remplacer par `PKPaymentAuthorizationController.canMakePayments()`.
    var isApplePayAvailable: Bool { true }

    func charge(amount: Double, method: PaymentMethod) async throws -> PaymentResult {
        try await Task.sleep(nanoseconds: 900_000_000)
        return PaymentResult(
            method: method,
            amount: amount,
            transactionReference: "SIMU-" + UUID().uuidString.prefix(8),
            processedAt: .now
        )
    }

    func refund(amount: Double, originalReference: String) async throws -> String {
        try await Task.sleep(nanoseconds: 600_000_000)
        return "SIMU-RB-" + UUID().uuidString.prefix(8)
    }
}
