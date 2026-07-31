import SwiftUI

struct MyReservationsView: View {
    @EnvironmentObject private var reservationStore: ReservationStore

    var body: some View {
        NavigationStack {
            Group {
                if reservationStore.reservations.isEmpty {
                    EmptyStateView(
                        title: "Aucune réservation",
                        message: "Vos demandes de réservation apparaîtront ici une fois créées depuis la fiche d'un vélo.",
                        systemImage: "calendar.badge.clock"
                    )
                } else {
                    List {
                        ForEach(reservationStore.reservations) { reservation in
                            ReservationRowView(reservation: reservation)
                        }
                        .onDelete(perform: reservationStore.delete)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Mes réservations")
        }
    }
}
