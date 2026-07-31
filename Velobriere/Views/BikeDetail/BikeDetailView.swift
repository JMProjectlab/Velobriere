import SwiftUI

struct BikeDetailView: View {
    let bike: Bike

    @EnvironmentObject private var reservationStore: ReservationStore
    @State private var showsReservationSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                imagePlaceholder

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(bike.brand.uppercased())
                        .font(Theme.Fonts.body(12, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.Colors.sage)
                    Text(bike.name)
                        .font(Theme.Fonts.display(24, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink)
                    Text(bike.tagline)
                        .font(Theme.Fonts.body(15))
                        .foregroundStyle(Theme.Colors.inkSoft)

                    availabilityBadge
                        .padding(.top, Theme.Spacing.xs)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("TARIFS")
                        .font(Theme.Fonts.body(12, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.Colors.sage)

                    ForEach(bike.pricingOptions) { option in
                        HStack {
                            Text(option.label)
                                .font(Theme.Fonts.body(14))
                                .foregroundStyle(Theme.Colors.ink)
                            Spacer()
                            Text(option.displayPrice)
                                .font(Theme.Fonts.body(14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.primaryStrong)
                        }
                        if option.id != bike.pricingOptions.last?.id {
                            Divider()
                        }
                    }

                    Text("Casque et antivol inclus dans toutes les locations.")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .padding(.top, Theme.Spacing.xs)
                    Text("Livraison en option : +\(bike.deliveryFee.formatted(.currency(code: "EUR"))) (rayon \(bike.deliveryRadiusKm) km).")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("POINTS FORTS")
                        .font(Theme.Fonts.body(12, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.Colors.sage)

                    ForEach(bike.highlights, id: \.self) { highlight in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(Theme.Colors.sage)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(highlight)
                                .font(Theme.Fonts.body(14))
                                .foregroundStyle(Theme.Colors.ink)
                        }
                    }
                }

                VStack(spacing: Theme.Spacing.sm) {
                    PrimaryButton(title: "Réserver ce vélo") {
                        showsReservationSheet = true
                    }
                    if let url = bike.productURL {
                        Link(destination: url) {
                            Text("Voir la fiche produit Decathlon")
                                .font(Theme.Fonts.body(14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.primaryStrong)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle(bike.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsReservationSheet) {
            NewReservationView(bike: bike)
        }
    }

    private var availabilityBadge: some View {
        let availableToday = reservationStore.availableUnits(for: bike, on: .now)
        return HStack(spacing: 4) {
            Circle()
                .fill(availableToday > 0 ? Theme.Colors.sage : Theme.Colors.warning)
                .frame(width: 6, height: 6)
            Text("\(availableToday)/\(bike.totalUnits) disponibles aujourd'hui")
                .font(Theme.Fonts.body(12, weight: .semibold))
                .foregroundStyle(Theme.Colors.inkSoft)
        }
    }

    private var imagePlaceholder: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.Colors.surfaceAlt)
                Image(systemName: bike.imageSystemName)
                    .font(.system(size: 90))
                    .foregroundStyle(Theme.Colors.primary)
            }
            .frame(height: 220)

            Text("Photo à venir — consultez la fiche produit ci-dessous pour les visuels officiels.")
                .font(Theme.Fonts.body(12))
                .foregroundStyle(Theme.Colors.inkSoft)
        }
    }
}
