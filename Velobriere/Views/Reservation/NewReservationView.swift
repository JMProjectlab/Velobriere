import SwiftUI

struct NewReservationView: View {
    let bike: Bike

    @EnvironmentObject private var reservationStore: ReservationStore
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
    @State private var endDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(2 * 86_400)
    @State private var quantity = 1
    @State private var customerFirstName = ""
    @State private var customerLastName = ""
    @State private var countryCode = CountryCodes.default.dial
    @State private var customerPhone = ""
    @State private var customerEmail = ""
    @State private var notes = ""
    @State private var createdReservation: Reservation?
    @State private var validationMessage: String?

    private var availableForSelectedRange: Int {
        reservationStore.availableUnits(for: bike, from: startDate, to: endDate)
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
                }

                card(title: "Remarques") {
                    TextField("Taille, itinéraire souhaité, horaire de retrait…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                card(title: "Résumé") {
                    Text(bike.displayPrice)
                        .font(Theme.Fonts.body(14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryStrong)
                    Text("Cette demande est enregistrée sur votre appareil. Vélo Brière vous recontactera pour la confirmer.")
                        .font(Theme.Fonts.body(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
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

        guard missingFields.isEmpty, !hasAvailabilityIssue else {
            var message = ""
            if !missingFields.isEmpty {
                message += "Merci de renseigner \(listFormatted(missingFields))."
            }
            if hasAvailabilityIssue {
                if !message.isEmpty { message += " " }
                message += "Il ne reste pas assez de vélos disponibles sur la période choisie : ajustez les dates ou la quantité."
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
            customerFirstName: customerFirstName.trimmingCharacters(in: .whitespaces),
            customerLastName: customerLastName.trimmingCharacters(in: .whitespaces).uppercased(),
            customerCountryCode: countryCode,
            customerPhone: customerPhone.trimmingCharacters(in: .whitespaces),
            customerEmail: customerEmail.trimmingCharacters(in: .whitespaces),
            notes: notes,
            createdAt: .now,
            status: .pending
        )
        reservationStore.add(reservation)
        createdReservation = reservation
    }
}
