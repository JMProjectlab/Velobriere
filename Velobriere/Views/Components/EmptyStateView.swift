import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String = "bicycle"

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.sage)
            Text(title)
                .font(Theme.Fonts.display(18, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)
            Text(message)
                .font(Theme.Fonts.body(14))
                .foregroundStyle(Theme.Colors.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
    }
}
