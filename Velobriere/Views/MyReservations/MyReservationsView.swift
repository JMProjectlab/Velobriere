import SwiftUI

struct MyReservationsView: View {
    @EnvironmentObject private var reservationStore: ReservationStore

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
                        }
                        .onDelete(perform: reservationStore.delete)
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
        }
    }
}
