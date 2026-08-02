import SwiftUI

struct NewReservationView: View {
    let bike: Bike

    @EnvironmentObject private var reservationStore: ReservationStore
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
    @State private var endDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(2 * 86_400)
    @State private var quantity = 1
    @State private var selectedPricingOptionID: String
    @State private var includesDelivery = false
    @State private var customerFirstName = ""
    @State private var customerLastName = ""
    @State private var countryCode = CountryCodes.default.dial
    @State private var customerPhone = ""
    @State private var customerEmail = ""
    @State private var notes = ""
    @State private var acceptedTerms = false
    @State private var createdReservation: Reservation?
    @State private var validationMessage: String?
    @State private var presentedDocument: LegalDocument?

    init(bike: Bike) {
        self.bike = bike
        _selectedPricingOptionID = State(initialValue: bike.pricingOptions.first?.id ?? "")
    }

    private var availableForSelectedRange: Int {
        reservationStore.availableUnits(for: bike, from: startDate, to: endDate)
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
            } else {
                form
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                AvailabilityCalendarView(bike: bike, startDate: $startDate, endDate: $endDate)

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
                        Text("Complet sur cette période. Merci de choisir d'autres dates.")
                            .font(Theme.Fonts.body(12))
                            .foregroundStyle(Theme.Colors.warning)
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
                    TextField("Taille, itinéraire souhaité, horaire de retrait…", text: $notes, axis: .vertical)
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
                    Text("Cette demande est enregistrée sur votre appareil. Vélo Brière vous recontactera pour la confirmer.")
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
                Button("Confirmer") { attemptSubmit() }
            }
        }
        .onChange(of: startDate) { _, _ in clampQuantity() }
        .onChange(of: endDate) { _, _ in clampQuantity() }
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
                message += "Il ne reste pas assez de vélos disponibles sur la période choisie : ajustez les dates ou la quantité."
            }
            if !acceptedTerms {
                if !message.isEmpty { message += " " }
                message += "Merci d'accepter les conditions générales de location."
            }
            validationMessage = message
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
        let reservation = Reservation(
            id: UUID(),
            bikeId: bike.id,
            bikeName: bike.name,
            startDate: startDate,
            endDate: endDate,
            quantity: quantity,
            pricingLabel: selectedPricingOption?.label ?? "",
            pricePerUnit: selectedPricingOption?.price ?? 0,
            includesDelivery: includesDelivery,
            totalPrice: totalPrice,
            customerFirstName: customerFirstName.trimmingCharacters(in: .whitespaces),
            customerLastName: customerLastName.trimmingCharacters(in: .whitespaces).uppercased(),
            customerCountryCode: countryCode,
            customerPhone: customerPhone.trimmingCharacters(in: .whitespaces),
            customerEmail: customerEmail.trimmingCharacters(in: .whitespaces),
            notes: notes,
            createdAt: .now,
            acceptedTermsAt: .now,
            status: .pending
        )
        reservationStore.add(reservation)
        createdReservation = reservation
    }
}
