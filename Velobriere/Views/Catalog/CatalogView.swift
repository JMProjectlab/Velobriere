import SwiftUI

struct CatalogView: View {
    let bikes: [Bike]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.md)

                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(bikes) { bike in
                            NavigationLink(value: bike) {
                                BikeCardView(bike: bike)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Nos vélos")
            .navigationDestination(for: Bike.self) { bike in
                BikeDetailView(bike: bike)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image("BrandSymbol")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.Colors.line, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text("KER VÉLO BRIÈRE")
                        .font(Theme.Fonts.display(14, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Theme.Colors.primaryStrong)
                    Text("Location de vélos électriques")
                        .font(Theme.Fonts.body(11))
                        .foregroundStyle(Theme.Colors.inkSoft)
                }
            }

            Text("Réservez votre vélo")
                .font(Theme.Fonts.display(26, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
                .padding(.top, Theme.Spacing.sm)

            Text("Balades électriques au cœur de la Brière, entre marais, villages et chemins.")
                .font(Theme.Fonts.body(15))
                .foregroundStyle(Theme.Colors.inkSoft)
        }
    }
}
