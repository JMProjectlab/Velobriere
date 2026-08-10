import SwiftUI

struct BikeCardView: View {
    let bike: Bike

    @EnvironmentObject private var reservationStore: ReservationStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(bike.variants) { variant in
                    Image(variant.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Theme.Colors.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                        .accessibilityLabel("\(bike.name), taille \(variant.size), \(variant.colorName)")
                }
            }

            Text(bike.brand.uppercased())
                .font(Theme.Fonts.body(11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Colors.sage)

            Text(bike.name)
                .font(Theme.Fonts.display(19, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)

            Text(bike.tagline)
                .font(Theme.Fonts.body(14))
                .foregroundStyle(Theme.Colors.inkSoft)

            VStack(alignment: .leading, spacing: 6) {
                Text("Disponibles aujourd'hui")
                    .font(Theme.Fonts.body(11))
                    .foregroundStyle(Theme.Colors.inkSoft)

                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(bike.variants) { variant in
                        let available = reservationStore.availableUnits(for: bike, variant: variant, on: .now)
                        Text("\(variant.size) · \(available)/\(variant.units)")
                            .font(Theme.Fonts.body(11, weight: .semibold))
                            .foregroundStyle(available > 0 ? Theme.Colors.primaryStrong : Theme.Colors.warning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.surfaceAlt)
                            .clipShape(Capsule())
                    }
                }
            }

            Text(bike.startingPriceLabel)
                .font(Theme.Fonts.body(14, weight: .semibold))
                .foregroundStyle(Theme.Colors.primaryStrong)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
    }
}
