import SwiftUI

struct MyReservationsView: View {
    @EnvironmentObject private var reservationStore: ReservationStore
    @EnvironmentObject private var invoiceStore: InvoiceStore

    /// Réservation encore active dont on demande l'annulation.
    @State private var reservationToCancel: Reservation?
    /// Réservation déjà annulée que l'on retire de la liste.
    @State private var reservationToDelete: Reservation?
    @State private var resultMessage: String?

    private let paymentService: PaymentService = SimulatedPaymentService()

    var body: some View {
        NavigationStack {
            Group {
                if reservationStore.reservations.isEmpty {
                    EmptyStateView(
                        title: "Aucune réservation",
                        message: "Vos réservations apparaîtront ici une fois payées depuis la fiche d'un vélo.",
                        systemImage: "calendar.badge.clock"
                    )
                } else {
                    List {
                        ForEach(reservationStore.reservations) { reservation in
                            NavigationLink(value: reservation.id) {
                                ReservationRowView(reservation: reservation)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if reservation.status == .cancelled {
                                    Button(role: .destructive) {
                                        reservationToDelete = reservation
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                } else {
                                    // Une réservation payée ne peut pas être effacée d'un geste :
                                    // elle passe par l'annulation, avec ses frais et son avoir.
                                    Button {
                                        reservationToCancel = reservation
                                    } label: {
                                        Label("Annuler", systemImage: "xmark.circle")
                                    }
                                    .tint(Theme.Colors.warning)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Mes réservations")
            .navigationDestination(for: UUID.self) { id in
                ReservationDetailView(reservationID: id)
            }
            .navigationDestination(for: Invoice.self) { invoice in
                InvoiceDocumentView(invoice: invoice)
            }
            .confirmationDialog(
                "Annuler cette réservation ?",
                isPresented: Binding(
                    get: { reservationToCancel != nil },
                    set: { if !$0 { reservationToCancel = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Confirmer l'annulation", role: .destructive) {
                    if let reservation = reservationToCancel { cancel(reservation) }
                    reservationToCancel = nil
                }
                Button("Conserver ma réservation", role: .cancel) { reservationToCancel = nil }
            } message: {
                if let reservation = reservationToCancel {
                    Text(CancellationPolicy.warningMessage(
                        amount: reservation.totalPrice,
                        startDate: reservation.startDate
                    ))
                }
            }
            .confirmationDialog(
                "Retirer cette réservation de la liste ?",
                isPresented: Binding(
                    get: { reservationToDelete != nil },
                    set: { if !$0 { reservationToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Retirer", role: .destructive) {
                    if let reservation = reservationToDelete {
                        reservationStore.remove(reservation.id)
                    }
                    reservationToDelete = nil
                }
                Button("Conserver", role: .cancel) { reservationToDelete = nil }
            } message: {
                Text("La réservation disparaîtra de cette liste. Les factures et avoirs déjà émis sont conservés.")
            }
            .alert("Réservation annulée", isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage ?? "")
            }
        }
    }

    private func cancel(_ reservation: Reservation) {
        let fee = CancellationPolicy.fee(amount: reservation.totalPrice, startDate: reservation.startDate)
        let refund = CancellationPolicy.refund(amount: reservation.totalPrice, startDate: reservation.startDate)

        Task {
            var creditNoteNumber: String?
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
            resultMessage = CancellationPolicy.resultMessage(
                fee: fee,
                refund: refund,
                creditNoteNumber: creditNoteNumber
            )
        }
    }
}
