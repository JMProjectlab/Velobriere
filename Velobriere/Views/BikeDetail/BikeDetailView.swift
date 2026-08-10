import SwiftUI

struct BikeDetailView: View {
    let bike: Bike

    @EnvironmentObject private var reservationStore: ReservationStore
    @EnvironmentObject private var invoiceStore: InvoiceStore
    @State private var showsReservationSheet = false
    @State private var selectedVariantID: String

    init(bike: Bike) {
        self.bike = bike
        _selectedVariantID = State(initialValue: bike.variants.first?.id ?? "")
    }

    private var selectedVariant: BikeVariant { bike.variant(withID: selectedVariantID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                bikePhoto

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

                sizePicker

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
            NewReservationView(bike: bike, initialVariantID: selectedVariantID)
                .environmentObject(reservationStore)
                .environmentObject(invoiceStore)
        }
    }

    /// Disponibilité de la taille sélectionnée : chaque taille a son propre stock.
    private var availabilityBadge: some View {
        let variant = selectedVariant
        let availableToday = reservationStore.availableUnits(for: bike, variant: variant, on: .now)
        return HStack(spacing: 4) {
            Circle()
                .fill(availableToday > 0 ? Theme.Colors.sage : Theme.Colors.warning)
                .frame(width: 6, height: 6)
            Text("Taille \(variant.size) : \(availableToday)/\(variant.units) disponibles aujourd'hui")
                .font(Theme.Fonts.body(12, weight: .semibold))
                .foregroundStyle(Theme.Colors.inkSoft)
        }
    }

    private var bikePhoto: some View {
        Image(selectedVariant.imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .background(Theme.Colors.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .animation(.easeInOut(duration: 0.2), value: selectedVariantID)
            .accessibilityLabel("\(bike.name), taille \(selectedVariant.size), \(selectedVariant.colorName)")
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("TAILLE")
                .font(Theme.Fonts.body(12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.Colors.sage)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(bike.variants) { variant in
                    sizeOption(variant)
                }
            }

            Text("Deux exemplaires par taille. Le stock est suivi séparément : une taille complète n'empêche pas de réserver l'autre.")
                .font(Theme.Fonts.body(12))
                .foregroundStyle(Theme.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sizeOption(_ variant: BikeVariant) -> some View {
        let isSelected = variant.id == selectedVariantID
        let available = reservationStore.availableUnits(for: bike, variant: variant, on: .now)
        return Button {
            selectedVariantID = variant.id
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.size)
                    .font(Theme.Fonts.display(17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                Text(variant.colorName)
                    .font(Theme.Fonts.body(12))
                    .foregroundStyle(Theme.Colors.inkSoft)
                Text("\(available)/\(variant.units) dispo.")
                    .font(Theme.Fonts.body(11, weight: .semibold))
                    .foregroundStyle(available > 0 ? Theme.Colors.primaryStrong : Theme.Colors.warning)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.primary.opacity(0.12) : Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Theme.Colors.line, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
