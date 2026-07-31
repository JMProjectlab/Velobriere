import SwiftUI

struct ReservationRowView: View {
    let reservation: Reservation

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(reservation.bikeName)
                    .font(Theme.Fonts.display(16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                Text("\(Self.dateFormatter.string(from: reservation.startDate)) → \(Self.dateFormatter.string(from: reservation.endDate)) · \(reservation.quantity) vélo\(reservation.quantity > 1 ? "s" : "")")
                    .font(Theme.Fonts.body(13))
                    .foregroundStyle(Theme.Colors.inkSoft)
                Text(statusLabel)
                    .font(Theme.Fonts.body(12, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var statusColor: Color {
        switch reservation.status {
        case .pending: Theme.Colors.sage
        case .confirmed: Theme.Colors.primary
        case .cancelled: Theme.Colors.warning
        }
    }

    private var statusLabel: String {
        switch reservation.status {
        case .pending: "En attente de confirmation"
        case .confirmed: "Confirmée"
        case .cancelled: "Annulée"
        }
    }
}
