import SwiftUI

struct NewReservationView: View {
    let bike: Bike

    @EnvironmentObject private var reservationStore: ReservationStore
    @EnvironmentObject private var invoiceStore: InvoiceStore
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
    @State private var endDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(2 * 86_400)
    @State private var quantity = 1
    @State private var selectedVariantID: String
    @State private var selectedPricingOptionID: String
    @State private var includesDelivery = false
    @State private var customerFirstName = ""
    @State private var customerLastName = ""
    @State private var countryCode = CountryCodes.default.dial
    @State private var customerPhone = ""
    @State private var customerEmail = ""
    @State private var notes = ""
    @State private var acceptedTerms = false
    @State private var pendingReservation: Reservation?
    @State private var createdReservation: Reservation?
    @State private var validationMessage: String?
    @State private var presentedDocument: LegalDocument?

    init(bike: Bike, initialVariantID: String? = nil) {
        self.bike = bike
        _selectedVariantID = State(initialValue: bike.variant(withID: initialVariantID).id)
        _selectedPricingOptionID = State(initialValue: bike.pricingOptions.first?.id ?? "")
    }

    private var selectedVariant: BikeVariant { bike.variant(withID: selectedVariantID) }

    /// Disponibilité de la taille choisie uniquement : chaque taille a son stock.
    private var availableForSelectedRange: Int {
        reservationStore.availableUnits(for: bike, variant: selectedVariant, from: startDate, to: endDate)
    }

    private var selectedPricingOption: PricingOption? {
        bike.pricingOptions.first(where: { $0.id == selectedPricingOptionID })
    }

    private var totalPrice: Double {
        let base = (selectedPricingOption?.price ?? 0) * Double(quantity)
        return base + (includesDelivery ? bike.deliveryFee : 0)
    }

    var body: some View {
        NavigationStack {
            if let reservation = createdReservation {
                ReservationConfirmationView(reservation: reservation, onDone: { dismiss() })
            } else if let pending = pendingReservation {
                CheckoutView(
                    reservation: pending,
                    onPaid: { result in finalise(pending, with: result) },
                    onCancel: { pendingReservation = nil }
                )
            } else {
                form
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                card(title: "Taille") {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(bike.variants) { variant in
                            sizeOption(variant)
                        }
                    }
                    Text("Chaque taille dispose de \(bike.variants.first?.units ?? 0) exemplaires, comptés séparément.")
                        .font(Theme.Fonts.body(11))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AvailabilityCalendarView(
                    bike: bike,
                    variant: selectedVariant,
                    startDate: $startDate,
                    endDate: $endDate
                )

                card(title: "Formule") {
                    Picker("Durée", selection: $selectedPricingOptionID) {
                        ForEach(bike.pricingOptions) { option in
                            Text(option.label).tag(option.id)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle(isOn: $includesDelivery) {
                        Text("Livraison à domicile (+\(bike.deliveryFee.formatted(.currency(code: "EUR"))), rayon \(bike.deliveryRadiusKm) km)")
                            .font(Theme.Fonts.body(13))
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    .tint(Theme.Colors.primary)
                    .padding(.top, Theme.Spacing.xs)
                }

                card(title: "Nombre de vélos") {
                    Stepper(
                        "Nombre de vélos : \(quantity)",
                        value: $quantity,
                        in: 1...max(1, availableForSelectedRange)
                    )
                    .disabled(availableForSelectedRange <= 0)

                    if availableForSelectedRange <= 0 {
                        Text("Taille \(selectedVariant.size) complète sur cette période. Essayez l'autre taille ou d'autres dates.")
                            .font(Theme.Fonts.body(12))
                            .foregroundStyle(Theme.Colors.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                card(title: "Vos coordonnées") {
                    TextField("Prénom", text: $customerFirstName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                    Divider()
                    TextField("NOM", text: Binding(
                        get: { customerLastName },
                        set: { customerLastName = $0.uppercased() }
                    ))
                    .textContentType(.familyName)
                    .textInputAutocapitalization(.characters)
                    Divider()
                    HStack(spacing: Theme.Spacing.sm) {
                        Picker("Indicatif", selection: $countryCode) {
                            ForEach(CountryCodes.all) { country in
                                Text("\(country.flag) \(country.dial)").tag(country.dial)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .fixedSize()

                        TextField("Téléphone", text: $customerPhone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                    }
                    Divider()
                    TextField("E-mail", text: $customerEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    Text("Ces informations servent uniquement à traiter votre demande de réservation et à vous recontacter. Elles restent enregistrées sur votre appareil.")
                        .font(Theme.Fonts.body(11))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.xs)

                    Button("En savoir plus sur vos données") {
                        presentedDocument = LegalContent.confidentialite
                    }
                    .font(Theme.Fonts.body(11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
                }

                card(title: "Remarques") {
                    TextField("Itinéraire souhaité, horaire de retrait…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                card(title: "Conditions") {
                    Toggle(isOn: $acceptedTerms) {
                        Text("J'ai lu et j'accepte les conditions générales de location.")
                            .font(Theme.Fonts.body(13))
                            .foregroundStyle(Theme.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .tint(Theme.Colors.primary)

                    Button("Lire les conditions générales de location") {
                        presentedDocument = LegalContent.conditionsLocation
                    }
                    .font(Theme.Fonts.body(12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
                }

                card(title: "Résumé") {
                    HStack {
                        Text("\(bike.name) — taille \(selectedVariant.size)")
                            .font(Theme.Fonts.body(14))
                            .foregroundStyle(Theme.Colors.inkSoft)
                        Spacer()
                    }
                    if let option = selectedPricingOption {
                        HStack {
                            Text("\(option.label) × \(quantity)")
                                .font(Theme.Fonts.body(14))
                                .foregroundStyle(Theme.Colors.ink)
                            Spacer()
                            Text((option.price * Double(quantity)).formatted(.currency(code: "EUR")))
                                .font(Theme.Fonts.body(14))
                                .foregroundStyle(Theme.Colors.ink)
                        }
                    }
                    if includesDelivery {
                        HStack {
                            Text("Livraison")
                                .font(Theme.Fonts.body(14))
                                .foregroundStyle(Theme.Colors.ink)
                            Spacer()
                            Text(bike.deliveryFee.formatted(.currency(code: "EUR")))
                                .font(Theme.Fonts.body(14))
                                .foregroundStyle(Theme.Colors.ink)
                        }
                    }
                    Divider()
                    HStack {
                        Text("Total")
                            .font(Theme.Fonts.body(15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink)
                        Spacer()
                        Text(totalPrice.formatted(.currency(code: "EUR")))
                            .font(Theme.Fonts.body(16, weight: .bold))
                            .foregroundStyle(Theme.Colors.primaryStrong)
                    }
                    Text("Cette demande est enregistrée sur votre appareil. Ker Vélo Brière vous recontactera pour la confirmer.")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Réserver")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Payer") { attemptSubmit() }
            }
        }
        .onChange(of: startDate) { _, _ in clampQuantity() }
        .onChange(of: endDate) { _, _ in clampQuantity() }
        .onChange(of: selectedVariantID) { _, _ in clampQuantity() }
        .alert(
            "Impossible de confirmer",
            isPresented: Binding(
                get: { validationMessage != nil },
                set: { if !$0 { validationMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "")
        }
        .sheet(item: $presentedDocument) { document in
            NavigationStack {
                LegalDocumentView(document: document)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fermer") { presentedDocument = nil }
                        }
                    }
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
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
    }

    private func sizeOption(_ variant: BikeVariant) -> some View {
        let isSelected = variant.id == selectedVariantID
        let available = reservationStore.availableUnits(for: bike, variant: variant, from: startDate, to: endDate)
        return Button {
            selectedVariantID = variant.id
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(variant.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(variant.size)
                        .font(Theme.Fonts.body(14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                    Text(variant.colorName)
                        .font(Theme.Fonts.body(11))
                        .foregroundStyle(Theme.Colors.inkSoft)
                    Text(available > 0 ? "\(available) dispo." : "Complet")
                        .font(Theme.Fonts.body(11, weight: .semibold))
                        .foregroundStyle(available > 0 ? Theme.Colors.primaryStrong : Theme.Colors.warning)
                }
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Theme.Colors.primary.opacity(0.12) : Theme.Colors.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Theme.Colors.line, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func clampQuantity() {
        let available = availableForSelectedRange
        quantity = available > 0 ? min(quantity, available) : 1
    }

    private func attemptSubmit() {
        var missingFields: [String] = []
        if customerFirstName.trimmingCharacters(in: .whitespaces).isEmpty { missingFields.append("votre prénom") }
        if customerLastName.trimmingCharacters(in: .whitespaces).isEmpty { missingFields.append("votre nom") }
        if !isValidPhone(countryCode: countryCode, number: customerPhone) { missingFields.append("un numéro de téléphone valide") }
        if !isValidEmail(customerEmail) { missingFields.append("une adresse e-mail valide") }

        let available = availableForSelectedRange
        let hasAvailabilityIssue = endDate < startDate || available <= 0 || quantity > available

        guard missingFields.isEmpty, !hasAvailabilityIssue, acceptedTerms else {
            var message = ""
            if !missingFields.isEmpty {
                message += "Merci de renseigner \(listFormatted(missingFields))."
            }
            if hasAvailabilityIssue {
                if !message.isEmpty { message += " " }
                message += "Il ne reste pas assez de vélos en taille \(selectedVariant.size) sur la période choisie : changez de taille, de dates ou de quantité."
            }
            if !acceptedTerms {
                if !message.isEmpty { message += " " }
                message += "Merci d'accepter les conditions générales de location."
            }
            validationMessage = message
            return
        }

        // Dernier contrôle avant d'ouvrir le paiement : c'est le magasin qui
        // détient la règle, et lui seul voit l'état réel des réservations au
        // moment du clic. Mieux vaut refuser ici qu'après avoir encaissé.
        do {
            try reservationStore.validate(buildReservation())
        } catch {
            validationMessage = error.localizedDescription
            return
        }

        submit()
    }

    private func listFormatted(_ items: [String]) -> String {
        guard let last = items.last else { return "" }
        guard items.count > 1 else { return last }
        return items.dropLast().joined(separator: ", ") + " et " + last
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*\.[A-Za-z]{2,}$"#
        return email.trimmingCharacters(in: .whitespaces).range(of: pattern, options: .regularExpression) != nil
    }

    private func isValidPhone(countryCode: String, number: String) -> Bool {
        let digits = number.filter(\.isNumber)
        guard !digits.isEmpty else { return false }
        if countryCode == CountryCodes.default.dial {
            return (digits.count == 10 && digits.hasPrefix("0")) || digits.count == 9
        }
        return (6...14).contains(digits.count)
    }

    private func submit() {
        pendingReservation = buildReservation()
    }

    /// Enregistre la réservation payée, émet la facture et affiche la confirmation.
    ///
    /// En mode partagé, c'est la transaction Firestore qui fait autorité : elle
    /// relit le stock au moment de l'écriture. Le contrôle local ne sert plus
    /// qu'à donner un message immédiat quand le serveur n'est pas branché.
    private func finalise(_ reservation: Reservation, with result: PaymentResult) {
        #if canImport(FirebaseFirestore)
        if reservationStore.estPartage {
            Task {
                do {
                    try await reservationStore.enregistrerDistant(reservation)
                } catch {
                    pendingReservation = nil
                    validationMessage = error.localizedDescription
                        + " Le paiement n'a pas été validé : aucune réservation n'a été enregistrée."
                    return
                }
                // Le serveur a accepté : la réservation entre dans la liste
                // locale sans repasser par la validation, qui ne voit qu'une
                // copie partielle des réservations.
                reservationStore.acceptFromServer(reservation)
                completeAfterStorage(reservation, with: result)
            }
            return
        }
        #endif

        do {
            try reservationStore.add(reservation)
        } catch {
            // Le stock a changé entre l'ouverture du paiement et son
            // aboutissement. Aucune facture n'est émise et rien n'est
            // enregistré : le paiement devra être remboursé côté loueur.
            pendingReservation = nil
            validationMessage = (error.localizedDescription)
                + " Le paiement n'a pas été validé : aucune réservation n'a été enregistrée."
            return
        }
        completeAfterStorage(reservation, with: result)
    }

    /// Émission de la facture et affichage de la confirmation, une fois la
    /// réservation acquise — localement ou côté serveur.
    private func completeAfterStorage(_ reservation: Reservation, with result: PaymentResult) {
        let invoice = invoiceStore.issueInvoice(for: reservation, method: result.method)
        reservationStore.markPaid(reservation.id, result: result, invoiceNumber: invoice.number)
        pendingReservation = nil
        let stored = reservationStore.reservation(withID: reservation.id) ?? reservation
        createdReservation = stored

        #if canImport(FirebaseFirestore)
        // Le numéro de facture et l'encaissement rejoignent le serveur. Un
        // échec ici ne remet pas la réservation en cause : elle est déjà
        // enregistrée et le stock déjà pris.
        if reservationStore.estPartage {
            Task { try? await reservationStore.mettreAJourDistant(stored) }
        }
        #endif
    }

    private func buildReservation() -> Reservation {
        Reservation(
            id: UUID(),
            bikeId: bike.id,
            bikeName: bike.name,
            variantId: selectedVariant.id,
            variantLabel: selectedVariant.size,
            startDate: startDate,
            endDate: endDate,
            quantity: quantity,
            pricingLabel: selectedPricingOption?.label ?? "",
            pricePerUnit: selectedPricingOption?.price ?? 0,
            includesDelivery: includesDelivery,
            deliveryFee: bike.deliveryFee,
            totalPrice: totalPrice,
            customerFirstName: customerFirstName.trimmingCharacters(in: .whitespaces),
            customerLastName: customerLastName.trimmingCharacters(in: .whitespaces).uppercased(),
            customerCountryCode: countryCode,
            customerPhone: customerPhone.trimmingCharacters(in: .whitespaces),
            customerEmail: customerEmail.trimmingCharacters(in: .whitespaces),
            notes: notes,
            createdAt: .now,
            acceptedTermsAt: .now,
            status: .pending,
            paymentStatus: .pending,
            paymentMethod: nil,
            paymentReference: nil,
            paidAt: nil,
            invoiceNumber: nil,
            cancelledAt: nil,
            cancellationFee: nil,
            refundedAmount: nil,
            creditNoteNumber: nil
        )
    }
}
