import SwiftUI

struct InvoiceDocumentView: View {
    let invoice: Invoice

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                header
                partiesCard
                linesCard
                footerCard
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle(invoice.kind.label)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(invoice.kind.label.uppercased())
                .font(Theme.Fonts.body(12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.Colors.sage)
            Text(invoice.number)
                .font(Theme.Fonts.display(24, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
            Text("Émis le \(Self.dateFormatter.string(from: invoice.issuedAt))")
                .font(Theme.Fonts.body(13))
                .foregroundStyle(Theme.Colors.inkSoft)
            if let related = invoice.relatedInvoiceNumber {
                Text("Se rapporte à la facture \(related)")
                    .font(Theme.Fonts.body(13))
                    .foregroundStyle(Theme.Colors.inkSoft)
            }
        }
    }

    private var partiesCard: some View {
        card(title: "Émetteur et client") {
            Text("Ker Vélo Brière\n135 Kermouraud\n44410 Saint-Lyphard\n06 07 34 37 97")
                .font(Theme.Fonts.body(13))
                .foregroundStyle(Theme.Colors.ink)
            Text(Invoice.sellerIdentityNote)
                .font(Theme.Fonts.body(11))
                .foregroundStyle(Theme.Colors.warning)
                .fixedSize(horizontal: false, vertical: true)

            Divider().padding(.vertical, 2)

            Text("Client")
                .font(Theme.Fonts.body(11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.Colors.sage)
            Text(invoice.customerName)
                .font(Theme.Fonts.body(13))
                .foregroundStyle(Theme.Colors.ink)
            if !invoice.customerEmail.isEmpty {
                Text(invoice.customerEmail)
                    .font(Theme.Fonts.body(13))
                    .foregroundStyle(Theme.Colors.inkSoft)
            }
        }
    }

    private var linesCard: some View {
        card(title: "Détail") {
            ForEach(invoice.lines) { line in
                if line.quantity == 0 {
                    // Ligne d'information (frais retenus), sans incidence sur le total.
                    Text(line.label)
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(line.label)
                                .font(Theme.Fonts.body(13))
                                .foregroundStyle(Theme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if line.quantity > 1 {
                                Text("\(line.quantity) × \(line.unitPrice.eur)")
                                    .font(Theme.Fonts.body(11))
                                    .foregroundStyle(Theme.Colors.inkSoft)
                            }
                        }
                        Spacer(minLength: Theme.Spacing.sm)
                        Text(line.total.eur)
                            .font(Theme.Fonts.body(13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    Divider()
                }
            }

            HStack {
                Text(invoice.kind == .creditNote ? "Total remboursé" : "Total")
                    .font(Theme.Fonts.body(15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                Text(invoice.total.eur)
                    .font(Theme.Fonts.body(18, weight: .bold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
            }
        }
    }

    private var footerCard: some View {
        card(title: "Mentions") {
            Text(Invoice.vatNote)
                .font(Theme.Fonts.body(11))
                .foregroundStyle(Theme.Colors.warning)
                .fixedSize(horizontal: false, vertical: true)
            if let method = invoice.paymentMethodLabel {
                Text("Réglé par \(method).")
                    .font(Theme.Fonts.body(12))
                    .foregroundStyle(Theme.Colors.inkSoft)
            }
            if invoice.kind == .creditNote {
                Text("Le remboursement est effectué sur le moyen de paiement d'origine.")
                    .font(Theme.Fonts.body(12))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(Theme.Fonts.body(12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Colors.sage)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
    }
}
