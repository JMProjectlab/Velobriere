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

    /// Nombre de vélos déjà réservés (hors annulations) pour un jour donné.
    func reservedQuantity(bikeId: String, on day: Date) -> Int {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: day)
        return reservations
            .filter { $0.bikeId == bikeId && $0.status != .cancelled }
            .filter { calendar.startOfDay(for: $0.startDate) <= day && day <= calendar.startOfDay(for: $0.endDate) }
            .reduce(0) { $0 + $1.quantity }
    }

    /// Vélos encore disponibles pour un jour donné.
    func availableUnits(for bike: Bike, on day: Date) -> Int {
        max(0, bike.totalUnits - reservedQuantity(bikeId: bike.id, on: day))
    }

    /// Disponibilité minimale sur toute la période demandée (le jour le plus chargé fait foi).
    func availableUnits(for bike: Bike, from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return availableUnits(for: bike, on: start) }

        var minAvailable = Int.max
        var day = start
        while day <= end {
            minAvailable = min(minAvailable, availableUnits(for: bike, on: day))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return minAvailable
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
