import SwiftUI

struct LegalInfoView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Retrouvez ici les informations légales de Ker Vélo Brière et le détail du traitement de vos données.")
                        .font(Theme.Fonts.body(14))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .padding(.top, Theme.Spacing.xs)

                    ForEach(LegalContent.all) { document in
                        NavigationLink(value: document) {
                            documentRow(document)
                        }
                        .buttonStyle(.plain)
                    }

                    contactCard
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Informations")
            .navigationDestination(for: LegalDocument.self) { document in
                LegalDocumentView(document: document)
            }
        }
    }

    private func documentRow(_ document: LegalDocument) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(document.title)
                        .font(Theme.Fonts.display(16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                    if document.needsCompletion {
                        Circle()
                            .fill(Theme.Colors.warning)
                            .frame(width: 6, height: 6)
                    }
                }
                Text(document.summary)
                    .font(Theme.Fonts.body(13))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.sage)
                .padding(.top, 4)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
    }

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("NOUS CONTACTER")
                .font(Theme.Fonts.body(12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Colors.sage)
            Text("Ker Vélo Brière\n135 Kermouraud\n44410 Saint-Lyphard")
                .font(Theme.Fonts.body(14))
                .foregroundStyle(Theme.Colors.ink)
            Link(destination: URL(string: "tel:+33607343797")!) {
                Text("06 07 34 37 97")
                    .font(Theme.Fonts.body(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
            }
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
