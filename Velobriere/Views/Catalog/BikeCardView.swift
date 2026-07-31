import SwiftUI

struct BikeCardView: View {
    let bike: Bike

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.Colors.surfaceAlt)
                Image(systemName: bike.imageSystemName)
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Colors.primary)
            }
            .frame(height: 160)

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

            Text(bike.displayPrice)
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
