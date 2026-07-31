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

    private var isFormValid: Bool {
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !customerPhone.trimmingCharacters(in: .whitespaces).isEmpty &&
        endDate >= startDate
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
        Form {
            Section("Dates") {
                DatePicker("Prise en charge", selection: $startDate, in: Date.now..., displayedComponents: .date)
                DatePicker("Restitution", selection: $endDate, in: startDate..., displayedComponents: .date)
                Stepper("Nombre de vélos : \(quantity)", value: $quantity, in: 1...5)
            }

            Section("Vos coordonnées") {
                TextField("Nom et prénom", text: $customerName)
                    .textContentType(.name)
                TextField("Téléphone", text: $customerPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                TextField("E-mail (optionnel)", text: $customerEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section("Remarques") {
                TextField("Taille, itinéraire souhaité, horaire de retrait…", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Text(bike.displayPrice)
                    .font(Theme.Fonts.body(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryStrong)
            } header: {
                Text("Résumé")
            } footer: {
                Text("Cette demande est enregistrée sur votre appareil. Vélo Brière vous recontactera pour la confirmer.")
            }
        }
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
