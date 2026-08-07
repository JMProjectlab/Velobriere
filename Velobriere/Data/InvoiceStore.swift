import Foundation

/// Émission et conservation des factures et avoirs.
///
/// La numérotation repose sur un compteur persistant par type et par année :
/// elle reste continue même si une facture est consultée ou supprimée côté
/// affichage, ce qu'impose la réglementation.
@MainActor
final class InvoiceStore: ObservableObject {
    @Published private(set) var invoices: [Invoice] = []

    private let fileURL: URL
    private let counterKey = "velobriere.invoice.counters"

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("invoices.json")
        load()
    }

    func invoices(for reservationID: UUID) -> [Invoice] {
        invoices
            .filter { $0.reservationId == reservationID }
            .sorted { $0.issuedAt < $1.issuedAt }
    }

    /// Émet la facture correspondant à une réservation payée.
    @discardableResult
    func issueInvoice(for reservation: Reservation, method: PaymentMethod) -> Invoice {
        var lines: [Invoice.Line] = [
            .init(
                id: "location",
                label: "Location \(reservation.bikeName) — \(reservation.pricingLabel)",
                quantity: reservation.quantity,
                unitPrice: reservation.pricePerUnit
            )
        ]
        if reservation.includesDelivery {
            lines.append(.init(id: "livraison", label: "Livraison à domicile", quantity: 1, unitPrice: reservation.deliveryFee))
        }

        let invoice = Invoice(
            id: UUID(),
            number: nextNumber(for: .invoice),
            kind: .invoice,
            issuedAt: .now,
            reservationId: reservation.id,
            customerName: "\(reservation.customerFirstName) \(reservation.customerLastName)",
            customerEmail: reservation.customerEmail,
            lines: lines,
            relatedInvoiceNumber: nil,
            paymentMethodLabel: method.label
        )
        append(invoice)
        return invoice
    }

    /// Émet l'avoir correspondant au montant remboursé lors d'une annulation.
    @discardableResult
    func issueCreditNote(for reservation: Reservation, refundAmount: Double, feeAmount: Double) -> Invoice {
        var lines: [Invoice.Line] = [
            .init(
                id: "remboursement",
                label: "Remboursement — annulation de la réservation",
                quantity: 1,
                unitPrice: refundAmount
            )
        ]
        if feeAmount > 0 {
            lines.append(.init(
                id: "frais",
                label: "Frais d'annulation retenus (50 %, annulation à moins de \(CancellationPolicy.feeWindowDays) jours) : \(feeAmount.eur) — non remboursés",
                quantity: 0,
                unitPrice: 0
            ))
        }

        let creditNote = Invoice(
            id: UUID(),
            number: nextNumber(for: .creditNote),
            kind: .creditNote,
            issuedAt: .now,
            reservationId: reservation.id,
            customerName: "\(reservation.customerFirstName) \(reservation.customerLastName)",
            customerEmail: reservation.customerEmail,
            lines: lines,
            relatedInvoiceNumber: reservation.invoiceNumber,
            paymentMethodLabel: nil
        )
        append(creditNote)
        return creditNote
    }

    // MARK: - Numérotation

    private func nextNumber(for kind: Invoice.Kind) -> String {
        let year = Calendar.current.component(.year, from: .now)
        let key = "\(kind.prefix)-\(year)"
        var counters = UserDefaults.standard.dictionary(forKey: counterKey) as? [String: Int] ?? [:]
        let next = (counters[key] ?? 0) + 1
        counters[key] = next
        UserDefaults.standard.set(counters, forKey: counterKey)
        return String(format: "%@-%d-%04d", kind.prefix, year, next)
    }

    // MARK: - Persistance

    private func append(_ invoice: Invoice) {
        invoices.append(invoice)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        invoices = (try? decoder.decode([Invoice].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(invoices) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
