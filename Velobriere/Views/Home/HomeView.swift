import SwiftUI

/// Écran d'accueil : le logo de la marque, puis les entrées de l'application.
/// Chaque carte porte une information vivante (vélos libres, réservations en
/// cours) plutôt qu'un simple libellé.
struct HomeView: View {
    let bike: Bike
    /// Bascule vers l'onglet correspondant.
    let onSelect: (RootTabView.Tab) -> Void

    @EnvironmentObject private var reservationStore: ReservationStore

    private var availableToday: Int {
        reservationStore.availableUnits(for: bike, on: .now)
    }

    /// « S / M : 2 · L / XL : 1 » — le stock est propre à chaque taille.
    private var availabilityBySize: String {
        bike.variants
            .map { "\($0.size) : \(reservationStore.availableUnits(for: bike, variant: $0, on: .now))" }
            .joined(separator: " · ")
    }

    private var activeReservations: Int {
        reservationStore.reservations.filter { $0.status != .cancelled }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                hero
                cards
                contact
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - En-tête

    private var hero: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Le logo porte son fond crème : on l'encadre plutôt que de le
            // détourer, ce qui le garde lisible en thème sombre.
            Image("BrandSymbol")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.Colors.line, lineWidth: 1)
                )
                .accessibilityLabel("Ker Vélo Brière — vélo électrique au bord des marais de Brière")

            Text("KER VÉLO BRIÈRE")
                .font(Theme.Fonts.display(30, weight: .bold))
                .tracking(3)
                .foregroundStyle(Theme.Colors.primaryStrong)
                .padding(.top, Theme.Spacing.xs)

            Text("LOCATION DE VÉLOS ÉLECTRIQUES")
                .font(Theme.Fonts.body(11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.Colors.sage)

            Text("Balades électriques au cœur de la Brière, entre marais, villages et chemins. Casque et antivol inclus, livraison possible dans un rayon de \(bike.deliveryRadiusKm) km.")
                .font(Theme.Fonts.body(14))
                .foregroundStyle(Theme.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.xs)
                .padding(.horizontal, Theme.Spacing.sm)
        }
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Entrées

    private var cards: some View {
        VStack(spacing: Theme.Spacing.sm) {
            card(
                tab: .catalog,
                icon: "bicycle",
                title: "Vélos",
                description: "Deux tailles, \(bike.sizesLabel) : découvrir, comparer et réserver.",
                highlighted: true
            ) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(availableToday > 0 ? Theme.Colors.sage : Theme.Colors.warning)
                        .frame(width: 6, height: 6)
                    Text(availabilityBySize)
                        .font(Theme.Fonts.body(12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.inkSoft)
                }
            }

            card(
                tab: .reservations,
                icon: "calendar",
                title: "Mes réservations",
                description: "Vos locations, vos factures et vos avoirs."
            ) {
                if activeReservations > 0 {
                    Text("\(activeReservations) en cours")
                        .font(Theme.Fonts.body(11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryStrong)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Theme.Colors.primary.opacity(0.16))
                        .clipShape(Capsule())
                } else {
                    Text("Aucune en cours")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                }
            }

            card(
                tab: .legal,
                icon: "info.circle",
                title: "Informations",
                description: "Mentions légales, confidentialité et CGL."
            ) {
                Text("Nous contacter")
                    .font(Theme.Fonts.body(12))
                    .foregroundStyle(Theme.Colors.inkSoft)
            }
        }
    }

    private func card<Meta: View>(
        tab: RootTabView.Tab,
        icon: String,
        title: String,
        description: String,
        highlighted: Bool = false,
        @ViewBuilder meta: () -> Meta
    ) -> some View {
        Button {
            onSelect(tab)
        } label: {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(highlighted ? Theme.Colors.surface : Theme.Colors.primaryStrong)
                    .frame(width: 38, height: 38)
                    .background(highlighted ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.Fonts.display(17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                    Text(description)
                        .font(Theme.Fonts.body(13))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    meta()
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.sage)
                    .padding(.top, 12)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(highlighted ? Theme.Colors.primary.opacity(0.07) : Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(highlighted ? Theme.Colors.primary : Theme.Colors.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contact

    private var contact: some View {
        VStack(spacing: 2) {
            Text("135 Kermouraud, 44410 Saint-Lyphard")
                .font(Theme.Fonts.body(12))
                .foregroundStyle(Theme.Colors.inkSoft)
            Link(destination: URL(string: "tel:+33607343797")!) {
                Text("06 07 34 37 97")
                    .font(Theme.Fonts.body(13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top, Theme.Spacing.xs)
    }
}
