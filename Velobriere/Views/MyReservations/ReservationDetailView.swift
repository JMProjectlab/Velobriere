import SwiftUI

struct ReservationDetailView: View {
    let reservationID: UUID

    @EnvironmentObject private var reservationStore: ReservationStore
    @EnvironmentObject private var invoiceStore: InvoiceStore

    @State private var showsCancelConfirmation = false
    @State private var isCancelling = false
    @State private var cancellationResultMessage: String?

    private let paymentService: PaymentService = SimulatedPaymentService()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    private var reservation: Reservation? {
        reservationStore.reservation(withID: reservationID)
    }

    var body: some View {
        Group {
            if let reservation {
                content(for: reservation)
            } else {
                EmptyStateView(
                    title: "Réservation introuvable",
                    message: "Cette réservation a été supprimée.",
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        }
        .background(Theme.Colors.background)
        .navigationTitle("Réservation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for reservation: Reservation) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                summaryCard(reservation)

                if reservation.status == .cancelled {
                    cancelledCard(reservation)
                } else if CancellationPolicy.incursFee(startDate: reservation.startDate) {
                    feeWarningCard(reservation)
                }

                documentsCard(reservation)

                if reservation.status != .cancelled {
                    cancelButton(reservation)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .confirmationDialog(
            "Annuler cette réservation ?",
            isPresented: $showsCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Confirmer l'annulation", role: .destructive) {
                cancel(reservation)
            }
            Button("Conserver ma réservation", role: .cancel) {}
        } message: {
            Text(CancellationPolicy.warningMessage(amount: reservation.totalPrice, startDate: reservation.startDate))
        }
        .alert("Réservation annulée", isPresented: Binding(
            get: { cancellationResultMessage != nil },
            set: { if !$0 { cancellationResultMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cancellationResultMessage ?? "")
        }
    }

    // MARK: - Cartes

    private func summaryCard(_ reservation: Reservation) -> some View {
        card(title: "Votre location") {
            row("Vélo", reservation.bikeName)
            row("Du", Self.dateFormatter.string(from: reservation.startDate))
            row("Au", Self.dateFormatter.string(from: reservation.endDate))
            row("Formule", reservation.pricingLabel)
            row("Vélos", "\(reservation.quantity)")
            if reservation.includesDelivery {
                row("Livraison", "Incluse")
            }
            Divider()
            HStack {
                Text("Montant payé")
                    .font(Theme.Fonts.body(15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                Text(reservation.totalPrice.eur)
                    .font(Theme.Fonts.body(17, weight: .bold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
            }
            if let method = reservation.paymentMethod {
                Text("Réglé par \(method.label)")
                    .font(Theme.Fonts.body(12))
                    .foregroundStyle(Theme.Colors.inkSoft)
            }
        }
    }

    private func feeWarningCard(_ reservation: Reservation) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text(CancellationPolicy.noticeTitle(startDate: reservation.startDate))
                    .font(Theme.Fonts.body(13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                Text(CancellationPolicy.noticeBody(amount: reservation.totalPrice, startDate: reservation.startDate))
                    .font(Theme.Fonts.body(12))
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.warning, lineWidth: 1)
        )
    }

    private func cancelledCard(_ reservation: Reservation) -> some View {
        card(title: "Annulation") {
            if let cancelledAt = reservation.cancelledAt {
                row("Annulée le", Self.dateFormatter.string(from: cancelledAt))
            }
            if let fee = reservation.cancellationFee, fee > 0 {
                row("Frais retenus", fee.eur)
            }
            if let refunded = reservation.refundedAmount {
                HStack {
                    Text("Remboursé")
                        .font(Theme.Fonts.body(15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer()
                    Text(refunded.eur)
                        .font(Theme.Fonts.body(17, weight: .bold))
                        .foregroundStyle(Theme.Colors.primaryStrong)
                }
            }
        }
    }

    private func documentsCard(_ reservation: Reservation) -> some View {
        let documents = invoiceStore.invoices(for: reservation.id)
        return card(title: "Factures et avoirs") {
            if documents.isEmpty {
                Text("Aucun document pour cette réservation.")
                    .font(Theme.Fonts.body(13))
                    .foregroundStyle(Theme.Colors.inkSoft)
            } else {
                ForEach(documents) { invoice in
                    NavigationLink(value: invoice) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(invoice.kind.label) \(invoice.number)")
                                    .font(Theme.Fonts.body(13, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink)
                                Text(invoice.total.eur)
                                    .font(Theme.Fonts.body(12))
                                    .foregroundStyle(Theme.Colors.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.Colors.sage)
                        }
                    }
                    .buttonStyle(.plain)
                    if invoice.id != documents.last?.id { Divider() }
                }
            }
        }
    }

    private func cancelButton(_ reservation: Reservation) -> some View {
        Button {
            showsCancelConfirmation = true
        } label: {
            Text(isCancelling ? "Annulation en cours…" : "Annuler ma réservation")
                .font(Theme.Fonts.body(15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Theme.Colors.warning)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .stroke(Theme.Colors.warning, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isCancelling)
    }

    // MARK: - Actions

    private func cancel(_ reservation: Reservation) {
        isCancelling = true
        let fee = CancellationPolicy.fee(amount: reservation.totalPrice, startDate: reservation.startDate)
        let refund = CancellationPolicy.refund(amount: reservation.totalPrice, startDate: reservation.startDate)

        Task {
            var creditNoteNumber: String?
            // Rien à rembourser (location commencée) : pas d'avoir à émettre.
            if refund > 0 {
                if let reference = reservation.paymentReference {
                    _ = try? await paymentService.refund(amount: refund, originalReference: reference)
                }
                creditNoteNumber = invoiceStore.issueCreditNote(
                    for: reservation,
                    refundAmount: refund,
                    feeAmount: fee
                ).number
            }
            reservationStore.cancel(reservation.id, fee: fee, refund: refund, creditNoteNumber: creditNoteNumber)
            isCancelling = false
            cancellationResultMessage = CancellationPolicy.resultMessage(
                fee: fee,
                refund: refund,
                creditNoteNumber: creditNoteNumber
            )
        }
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Theme.Fonts.body(13))
                .foregroundStyle(Theme.Colors.inkSoft)
            Spacer(minLength: Theme.Spacing.sm)
            Text(value)
                .font(Theme.Fonts.body(13, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(Theme.Fonts.body(12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Colors.sage)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
    }
}
