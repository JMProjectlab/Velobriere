import Foundation

/// Persistance locale des demandes de réservation (aucun backend pour l'instant).
@MainActor
final class ReservationStore: ObservableObject {
    @Published private(set) var reservations: [Reservation] = []

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("reservations.json")
        load()
    }

    func add(_ reservation: Reservation) {
        reservations.append(reservation)
        reservations.sort { $0.startDate < $1.startDate }
        save()
    }

    func delete(at offsets: IndexSet) {
        reservations.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        reservations = (try? decoder.decode([Reservation].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(reservations) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
