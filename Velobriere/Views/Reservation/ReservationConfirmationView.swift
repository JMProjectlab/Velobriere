import SwiftUI

struct ReservationConfirmationView: View {
    let reservation: Reservation
    let onDone: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Colors.primary)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Réservation confirmée")
                    .font(Theme.Fonts.display(22, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink)
                Text("\(reservation.bikeDescription) · du \(Self.dateFormatter.string(from: reservation.startDate)) au \(Self.dateFormatter.string(from: reservation.endDate))")
                    .font(Theme.Fonts.body(14))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .multilineTextAlignment(.center)
                Text("\(reservation.pricingLabel) · Total \(reservation.totalPrice.formatted(.currency(code: "EUR")))")
                    .font(Theme.Fonts.body(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryStrong)

                if let invoiceNumber = reservation.invoiceNumber {
                    Text("Facture \(invoiceNumber) — disponible dans l'onglet Réservations.")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            PrimaryButton(title: "Terminé", action: onDone)
                .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.xl)
        .background(Theme.Colors.background)
        .navigationBarBackButtonHidden(true)
    }
}
