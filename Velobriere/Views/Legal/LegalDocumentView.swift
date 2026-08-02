import SwiftUI

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(document.title)
                        .font(Theme.Fonts.display(24, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink)
                    Text("Dernière mise à jour : \(document.lastUpdated)")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                }

                if document.needsCompletion {
                    completionBanner
                }

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                            Text(section.heading.uppercased())
                                .font(Theme.Fonts.body(12, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(Theme.Colors.sage)
                            Spacer()
                            if section.needsCompletion {
                                Text("À COMPLÉTER")
                                    .font(Theme.Fonts.body(10, weight: .semibold))
                                    .tracking(0.8)
                                    .foregroundStyle(Theme.Colors.warning)
                            }
                        }

                        Text(section.body)
                            .font(Theme.Fonts.body(14))
                            .foregroundStyle(Theme.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .stroke(section.needsCompletion ? Theme.Colors.warning.opacity(0.5) : Theme.Colors.line, lineWidth: 1)
                    )
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var completionBanner: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.warning)
            Text("Document incomplet : les passages signalés « À COMPLÉTER » doivent être renseignés, puis l'ensemble relu par un professionnel du droit avant publication.")
                .font(Theme.Fonts.body(12))
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.warning, lineWidth: 1)
        )
    }
}
