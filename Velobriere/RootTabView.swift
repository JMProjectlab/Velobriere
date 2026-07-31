import SwiftUI

struct RootTabView: View {
    @StateObject private var reservationStore = ReservationStore()

    var body: some View {
        TabView {
            CatalogView(bikes: BikeCatalog.all)
                .tabItem {
                    Label("Vélos", systemImage: "bicycle")
                }

            MyReservationsView()
                .tabItem {
                    Label("Réservations", systemImage: "calendar")
                }
        }
        .tint(Theme.Colors.primary)
        .environmentObject(reservationStore)
    }
}
