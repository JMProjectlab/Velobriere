import SwiftUI

struct NewReservationView: View {
    let bike: Bike

    @EnvironmentObject private var reservationStore: ReservationStore
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
    @State private var endDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(2 * 86_400)
    @State private var quantity = 1
    @State private var customerName = ""
    @State private var customerPhone = ""
    @State private var customerEmail = ""
    @State private var notes = ""
    @State private var createdReservation: Reservation?

    private var availableForSelectedRange: Int {
        reservationStore.availableUnits(for: bike, from: startDate, to: endDate)
    }

    private var isFormValid: Bool {
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !customerPhone.trimmingCharacters(in: .whitespaces).isEmpty &&
        endDate >= startDate &&
        availableForSelectedRange > 0 &&
        quantity <= availableForSelectedRange
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
                    TextField("Nom et prénom", text: $customerName)
                        .textContentType(.name)
                    Divider()
                    TextField("Téléphone", text: $customerPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    Divider()
                    TextField("E-mail (optionnel)", text: $customerEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
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
                Button("Confirmer") { submit() }
                    .disabled(!isFormValid)
            }
        }
        .onChange(of: startDate) { _, _ in clampQuantity() }
        .onChange(of: endDate) { _, _ in clampQuantity() }
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

    private func submit() {
        let reservation = Reservation(
            id: UUID(),
            bikeId: bike.id,
            bikeName: bike.name,
            startDate: startDate,
            endDate: endDate,
            quantity: quantity,
            customerName: customerName,
            customerPhone: customerPhone,
            customerEmail: customerEmail,
            notes: notes,
            createdAt: .now,
            status: .pending
        )
        reservationStore.add(reservation)
        createdReservation = reservation
    }
}
