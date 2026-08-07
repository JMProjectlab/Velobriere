import SwiftUI

struct RootTabView: View {
    @StateObject private var reservationStore = ReservationStore()
    @StateObject private var invoiceStore = InvoiceStore()

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

            LegalInfoView()
                .tabItem {
                    Label("Informations", systemImage: "info.circle")
                }
        }
        .tint(Theme.Colors.primary)
        .environmentObject(reservationStore)
        .environmentObject(invoiceStore)
    }
}
