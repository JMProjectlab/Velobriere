import SwiftUI

/// Étape de paiement du tunnel : Apple Pay en un geste, ou carte bancaire.
struct CheckoutView: View {
    let reservation: Reservation
    let onPaid: (PaymentResult) -> Void
    let onCancel: () -> Void

    private let paymentService: PaymentService = SimulatedPaymentService()

    @State private var isProcessing = false
    @State private var processingMethod: PaymentMethod?
    @State private var errorMessage: String?
    @State private var cardNumber = ""
    @State private var cardExpiry = ""
    @State private var cardCVC = ""
    @State private var showsCardForm = false

    private var isCardFormValid: Bool {
        cardNumber.filter(\.isNumber).count >= 13 &&
        cardExpiry.filter(\.isNumber).count == 4 &&
        (3...4).contains(cardCVC.filter(\.isNumber).count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                simulationNotice
                summaryCard

                if paymentService.isApplePayAvailable {
                    applePayButton
                }

                if showsCardForm {
                    cardForm
                } else {
                    Button {
                        withAnimation { showsCardForm = true }
                    } label: {
                        Text("Payer par carte bancaire")
                            .font(Theme.Fonts.body(15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Theme.Colors.primaryStrong)
                            .background(Theme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                                    .stroke(Theme.Colors.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }

                Text("Le paiement vaut acceptation des conditions générales de location. En cas d'annulation à moins de \(CancellationPolicy.feeWindowDays) jours du départ, 50 % du montant est retenu.")
                    .font(Theme.Fonts.body(11))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Paiement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Retour", action: onCancel).disabled(isProcessing)
            }
        }
        .alert("Paiement impossible", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sous-vues

    private var simulationNotice: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.warning)
            Text("Paiement simulé — aucun montant n'est réellement débité. Le branchement d'un prestataire (Stripe, SumUp…) reste à faire.")
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

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("VOTRE COMMANDE")
                .font(Theme.Fonts.body(12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Colors.sage)

            HStack {
                Text("\(reservation.pricingLabel) × \(reservation.quantity)")
                    .font(Theme.Fonts.body(14))
                Spacer()
                Text((reservation.pricePerUnit * Double(reservation.quantity)).eur)
                    .font(Theme.Fonts.body(14))
            }
            .foregroundStyle(Theme.Colors.ink)

            if reservation.includesDelivery {
                HStack {
                    Text("Livraison").font(Theme.Fonts.body(14))
                    Spacer()
                    Text(reservation.deliveryFee.eur).font(Theme.Fonts.body(14))
                }
                .foregroundStyle(Theme.Colors.ink)
            }

            Divider()

            HStack {
                Text("Total à payer")
                    .font(Theme.Fonts.body(15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                Text(reservation.totalPrice.eur)
                    .font(Theme.Fonts.body(18, weight: .bold))
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

    private var applePayButton: some View {
        Button {
            pay(with: .applePay)
        } label: {
            HStack(spacing: 6) {
                if isProcessing && processingMethod == .applePay {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "applelogo")
                    Text("Pay").font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    private var cardForm: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("CARTE BANCAIRE")
                .font(Theme.Fonts.body(12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Colors.sage)

            TextField("Numéro de carte", text: $cardNumber)
                .keyboardType(.numberPad)
                .textContentType(.creditCardNumber)
            Divider()
            HStack(spacing: Theme.Spacing.md) {
                TextField("MM/AA", text: $cardExpiry).keyboardType(.numberPad)
                Divider().frame(height: 20)
                TextField("CVC", text: $cardCVC).keyboardType(.numberPad)
            }

            PrimaryButton(
                title: isProcessing && processingMethod == .card ? "Paiement en cours…" : "Payer \(reservation.totalPrice.eur)",
                isDisabled: !isCardFormValid || isProcessing
            ) {
                pay(with: .card)
            }
            .padding(.top, Theme.Spacing.xs)

            Text("Aucune donnée de carte n'est transmise ni conservée : ce formulaire est une maquette. En production, la saisie doit être confiée au SDK du prestataire de paiement.")
                .font(Theme.Fonts.body(11))
                .foregroundStyle(Theme.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
    }

    // MARK: - Paiement

    private func pay(with method: PaymentMethod) {
        isProcessing = true
        processingMethod = method
        Task {
            do {
                let result = try await paymentService.charge(amount: reservation.totalPrice, method: method)
                isProcessing = false
                processingMethod = nil
                onPaid(result)
            } catch {
                isProcessing = false
                processingMethod = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}
