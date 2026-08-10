import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable {
        case home, catalog, reservations, legal
    }

    @StateObject private var reservationStore = ReservationStore()
    @StateObject private var invoiceStore = InvoiceStore()
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(bike: BikeCatalog.eActv100) { selectedTab = $0 }
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
                .tag(Tab.home)

            CatalogView(bikes: BikeCatalog.all)
                .tabItem {
                    Label("Vélos", systemImage: "bicycle")
                }
                .tag(Tab.catalog)

            MyReservationsView()
                .tabItem {
                    Label("Réservations", systemImage: "calendar")
                }
                .tag(Tab.reservations)

            LegalInfoView()
                .tabItem {
                    Label("Informations", systemImage: "info.circle")
                }
                .tag(Tab.legal)
        }
        .tint(Theme.Colors.primary)
        .environmentObject(reservationStore)
        .environmentObject(invoiceStore)
    }
}
