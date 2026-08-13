import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth
#endif

/// Persistance des demandes de réservation.
///
/// Deux modes, comme côté web :
///
/// * **local** — un fichier JSON dans le conteneur de l'app. C'est le mode
///   actuel, et le seul tant que le paquet Firebase n'est pas ajouté au projet
///   (Xcode → *Add Package Dependencies* → `firebase-ios-sdk`, produits
///   *FirebaseAuth* et *FirebaseFirestore*), avec `GoogleService-Info.plist`
///   déposé dans la cible.
/// * **partagé** — Firestore fait autorité, et la réservation passe par une
///   transaction sur le compteur de la taille. C'est le seul mode où deux
///   appareils voient les mêmes réservations et où la double réservation est
///   réellement impossible.
///
/// Le code Firebase est encadré par `#if canImport(FirebaseFirestore)` : sans le
/// paquet, il n'existe pas et le projet compile exactement comme avant.
/// Voir `SETUP-FIREBASE.md`.
@MainActor
final class ReservationStore: ObservableObject {
    @Published private(set) var reservations: [Reservation] = []

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("reservations.json")
        load()
    }

    /// Vrai quand Firestore prend le relais du fichier local.
    var estPartage: Bool {
        #if canImport(FirebaseFirestore)
        return FirebaseSupport.isAvailable && Auth.auth().currentUser != nil
        #else
        return false
        #endif
    }

    /// Enregistre une réservation après avoir vérifié qu'elle est recevable.
    ///
    /// La vérification vit ici, et pas seulement dans l'écran de saisie : c'est
    /// le magasin qui détient l'invariant *« la somme des quantités réservées
    /// pour une taille, un jour donné, ne dépasse jamais le stock »*. Un écran
    /// peut oublier de vérifier ; le magasin, non. Le jour où les réservations
    /// passeront par un serveur, c'est exactement ce contrôle qui devra devenir
    /// une transaction — il est déjà écrit au bon endroit.
    ///
    /// - Important: contrôle **local**. Deux appareils différents ne voient pas
    ///   les réservations l'un de l'autre tant qu'il n'y a pas de backend
    ///   partagé : cette vérification est nécessaire, elle n'est pas suffisante.
    func add(_ reservation: Reservation) throws {
        try validate(reservation)
        reservations.append(reservation)
        reservations.sort { $0.startDate < $1.startDate }
        save()
    }

    /// Annule en passant d'abord par le serveur quand il fait autorité.
    ///
    /// L'ordre compte : si le serveur refuse, rien n'est modifié localement.
    /// L'inverse laisserait une réservation annulée sur l'appareil mais toujours
    /// active côté serveur, donc un vélo bloqué pour rien.
    func cancelSynchronised(_ reservationID: UUID,
                            fee: Double,
                            refund: Double,
                            creditNoteNumber: String?) async throws {
        #if canImport(FirebaseFirestore)
        if estPartage, let existing = reservation(withID: reservationID) {
            try await annulerDistant(existing)
        }
        #endif

        cancel(reservationID, fee: fee, refund: refund, creditNoteNumber: creditNoteNumber)

        #if canImport(FirebaseFirestore)
        // Le détail comptable suit. Un échec ici ne remet pas l'annulation en
        // cause : le vélo est déjà rendu au stock.
        if estPartage, let updated = reservation(withID: reservationID) {
            try? await mettreAJourDistant(updated)
        }
        #endif
    }

    /// Insère sans revalider, parce que le serveur a déjà tranché.
    ///
    /// En mode partagé, c'est la transaction Firestore qui détient l'invariant :
    /// revalider ici sur une copie locale incomplète pourrait refuser une
    /// réservation que le serveur a acceptée.
    func acceptFromServer(_ reservation: Reservation) {
        guard !reservations.contains(where: { $0.id == reservation.id }) else { return }
        reservations.append(reservation)
        reservations.sort { $0.startDate < $1.startDate }
        save()
    }

    /// Vérifie qu'une réservation peut être enregistrée. Lève `ReservationError`
    /// sinon.
    func validate(_ reservation: Reservation, now: Date = .now) throws {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: reservation.startDate)
        let end = calendar.startOfDay(for: reservation.endDate)

        guard start <= end else { throw ReservationError.invalidDateRange }
        guard start >= calendar.startOfDay(for: now) else { throw ReservationError.startsInThePast }
        guard reservation.quantity > 0 else { throw ReservationError.invalidQuantity }

        let bike = BikeCatalog.all.first { $0.id == reservation.bikeId } ?? BikeCatalog.eActv100
        let variant = bike.variants.first { $0.id == reservation.variantId }

        // La disponibilité se calcule sans la réservation examinée : sans cela,
        // revalider une réservation déjà enregistrée la compterait deux fois.
        let others = reservations.filter { $0.id != reservation.id }
        let available = Self.availableUnits(among: others,
                                            for: bike,
                                            variant: variant,
                                            from: start,
                                            to: end)
        guard reservation.quantity <= available else {
            throw ReservationError.notEnoughUnits(available: available, requested: reservation.quantity)
        }
    }

    /// Retire une réservation de la liste. Réservé aux réservations déjà
    /// annulées : une réservation payée doit passer par `cancel(_:)`, qui
    /// applique les frais et émet l'avoir.
    func remove(_ reservationID: UUID) {
        reservations.removeAll { $0.id == reservationID }
        save()
    }

    func reservation(withID id: UUID) -> Reservation? {
        reservations.first { $0.id == id }
    }

    /// Enregistre l'encaissement et le numéro de facture émis.
    func markPaid(_ reservationID: UUID, result: PaymentResult, invoiceNumber: String) {
        guard let index = reservations.firstIndex(where: { $0.id == reservationID }) else { return }
        reservations[index].paymentStatus = .paid
        reservations[index].paymentMethod = result.method
        reservations[index].paymentReference = result.transactionReference
        reservations[index].paidAt = result.processedAt
        reservations[index].invoiceNumber = invoiceNumber
        reservations[index].status = .confirmed
        save()
    }

    /// Annule une réservation en appliquant les frais éventuels, et conserve le
    /// détail du remboursement pour l'avoir.
    func cancel(_ reservationID: UUID, fee: Double, refund: Double, creditNoteNumber: String?) {
        guard let index = reservations.firstIndex(where: { $0.id == reservationID }) else { return }
        reservations[index].status = .cancelled
        reservations[index].cancelledAt = .now
        reservations[index].cancellationFee = fee
        reservations[index].refundedAmount = refund
        reservations[index].creditNoteNumber = creditNoteNumber
        if reservations[index].paymentStatus == .paid {
            reservations[index].paymentStatus = .refunded
        }
        save()
    }

    // MARK: - Disponibilité
    //
    // Le stock est suivi PAR TAILLE : réserver un S/M ne réduit pas celui des
    // L/XL. Passer `variant: nil` donne la vue d'ensemble, toutes tailles
    // confondues (utilisée sur l'accueil et la fiche catalogue).

    /// Nombre de vélos déjà réservés (hors annulations) pour un jour donné.
    /// `variantId` à `nil` compte toutes les tailles.
    func reservedQuantity(bikeId: String, variantId: String?, on day: Date) -> Int {
        Self.reservedQuantity(among: reservations, bikeId: bikeId, variantId: variantId, on: day)
    }

    /// Vélos encore disponibles pour un jour donné, dans la taille demandée.
    func availableUnits(for bike: Bike, variant: BikeVariant? = nil, on day: Date) -> Int {
        Self.availableUnits(among: reservations, for: bike, variant: variant, on: day)
    }

    /// Disponibilité minimale sur toute la période demandée (le jour le plus chargé fait foi).
    func availableUnits(for bike: Bike, variant: BikeVariant? = nil, from startDate: Date, to endDate: Date) -> Int {
        Self.availableUnits(among: reservations, for: bike, variant: variant, from: startDate, to: endDate)
    }

    // Les versions statiques prennent la liste en paramètre : `validate(_:)` a
    // besoin de calculer la disponibilité **en excluant** la réservation qu'il
    // examine, ce que les méthodes d'instance ne permettent pas. Une seule
    // implémentation, deux points d'entrée.

    static func reservedQuantity(among reservations: [Reservation],
                                 bikeId: String,
                                 variantId: String?,
                                 on day: Date) -> Int {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: day)
        return reservations
            .filter { $0.bikeId == bikeId && $0.status != .cancelled }
            .filter { variantId == nil || $0.variantId == variantId }
            .filter { calendar.startOfDay(for: $0.startDate) <= day && day <= calendar.startOfDay(for: $0.endDate) }
            .reduce(0) { $0 + $1.quantity }
    }

    static func availableUnits(among reservations: [Reservation],
                               for bike: Bike,
                               variant: BikeVariant? = nil,
                               on day: Date) -> Int {
        let capacity = variant?.units ?? bike.totalUnits
        let reserved = reservedQuantity(among: reservations,
                                        bikeId: bike.id,
                                        variantId: variant?.id,
                                        on: day)
        return max(0, capacity - reserved)
    }

    static func availableUnits(among reservations: [Reservation],
                               for bike: Bike,
                               variant: BikeVariant? = nil,
                               from startDate: Date,
                               to endDate: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else {
            return availableUnits(among: reservations, for: bike, variant: variant, on: start)
        }

        var minAvailable = Int.max
        var day = start
        while day <= end {
            minAvailable = min(minAvailable,
                               availableUnits(among: reservations, for: bike, variant: variant, on: day))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return minAvailable
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = (try? decoder.decode([Reservation].self, from: data)) ?? []
        reservations = decoded.map(migratingVariant)
    }

    /// Réservations enregistrées avant l'introduction des deux tailles : elles
    /// sont rattachées à la première taille du catalogue, sans quoi elles
    /// n'apparaîtraient dans le stock d'aucune taille.
    private func migratingVariant(_ reservation: Reservation) -> Reservation {
        guard reservation.variantId == nil else { return reservation }
        let bike = BikeCatalog.all.first { $0.id == reservation.bikeId } ?? BikeCatalog.eActv100
        guard let variant = bike.variants.first else { return reservation }
        var updated = reservation
        updated.variantId = variant.id
        updated.variantLabel = variant.size
        return updated
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(reservations) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Clés de jour « AAAA-MM-JJ » couvertes par la période, bornes incluses.
    /// En heure locale — surtout pas en UTC, qui décalerait d'un jour le soir.
    static func dayKeys(from start: Date, to end: Date) -> [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        var out: [String] = []
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while day <= last {
            out.append(formatter.string(from: day))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return out.isEmpty ? [formatter.string(from: calendar.startOfDay(for: start))] : out
    }
}

#if canImport(FirebaseFirestore)

/// Point d'entrée unique vers Firebase, sur le modèle de Scornade.
///
/// `FirebaseApp.configure()` échoue si `GoogleService-Info.plist` est absent du
/// bundle : on vérifie donc sa présence d'abord, ce qui laisse l'application
/// démarrer et fonctionner en local tant que le fichier n'a pas été déposé.
enum FirebaseSupport {
    private(set) static var isAvailable = false

    static func configureIfPossible() {
        guard !isAvailable else { return }
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            return
        }
        FirebaseApp.configure()
        isAvailable = true
    }
}

extension ReservationStore {

    private var db: Firestore { Firestore.firestore() }

    /// Enregistre la réservation côté serveur, en garantissant le stock.
    ///
    /// Tout se joue dans la transaction : on relit le compteur de la taille au
    /// moment de l'écriture, on vérifie chaque jour de la période, et on
    /// n'incrémente que si tous passent. Si quelqu'un a réservé entre-temps,
    /// Firestore rejoue la transaction avec les valeurs à jour — c'est cette
    /// relecture qui rend la double réservation impossible.
    ///
    /// Pendant exact de `VB.Remote.commitReservation()` côté web : les deux
    /// écrivent la même forme de document et doivent évoluer ensemble.
    func enregistrerDistant(_ reservation: Reservation) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw ReservationError.notSignedIn }
        guard let variantId = reservation.variantId else { throw ReservationError.unknownVariant }

        // Tout ce dont la transaction a besoin est calculé ici, dans l'acteur
        // principal, et passé au bloc sous forme de valeurs simples : le bloc
        // s'exécute sur un autre fil et ne doit rien capturer d'isolé.
        let jours = Self.dayKeys(from: reservation.startDate, to: reservation.endDate)
        let quantite = reservation.quantity
        let payload = try Self.encodePayload(reservation)
        let availabilityRef = db.collection("availability").document(variantId)
        let reservationRef = db.collection("reservations").document(reservation.id.uuidString)
        let statut = reservation.status.rawValue

        do {
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(availabilityRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                guard let data = snapshot.data(), let units = data["units"] as? Int else {
                    errorPointer?.pointee = Self.erreur("Cette taille de vélo n'est pas configurée. Contactez le loueur.")
                    return nil
                }

                var days = (data["days"] as? [String: Int]) ?? [:]
                for jour in jours {
                    let pris = days[jour] ?? 0
                    guard pris + quantite <= units else {
                        let reste = max(0, units - pris)
                        errorPointer?.pointee = Self.erreur(
                            reste <= 0
                            ? "Plus aucun vélo de cette taille n'est disponible sur la période choisie."
                            : "Il ne reste que \(reste) vélo\(reste > 1 ? "s" : "") de cette taille le \(jour)."
                        )
                        return nil
                    }
                    days[jour] = pris + quantite
                }

                transaction.updateData(["days": days], forDocument: availabilityRef)
                transaction.setData([
                    "uid": uid,
                    "variantId": variantId,
                    "startDay": jours.first ?? "",
                    "endDay": jours.last ?? "",
                    "quantity": quantite,
                    "status": statut,
                    "payload": payload
                ], forDocument: reservationRef)
                return nil
            }
        } catch let error as NSError {
            throw ReservationError.remote(error.localizedDescription)
        }
    }

    /// Annule côté serveur et rend les vélos au stock, dans la même transaction.
    func annulerDistant(_ reservation: Reservation) async throws {
        guard let variantId = reservation.variantId else { throw ReservationError.unknownVariant }

        let jours = Self.dayKeys(from: reservation.startDate, to: reservation.endDate)
        let quantite = reservation.quantity
        var annulee = reservation
        annulee.status = .cancelled
        let payload = try Self.encodePayload(annulee)
        let availabilityRef = db.collection("availability").document(variantId)
        let reservationRef = db.collection("reservations").document(reservation.id.uuidString)

        do {
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(availabilityRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                var days = (snapshot.data()?["days"] as? [String: Int]) ?? [:]
                for jour in jours {
                    // Jamais sous zéro, même si une annulation était rejouée.
                    days[jour] = max(0, (days[jour] ?? 0) - quantite)
                }
                transaction.updateData(["days": days], forDocument: availabilityRef)
                transaction.updateData(["status": Reservation.Status.cancelled.rawValue,
                                        "payload": payload],
                                       forDocument: reservationRef)
                return nil
            }
        } catch let error as NSError {
            throw ReservationError.remote(error.localizedDescription)
        }
    }

    /// Met à jour le détail comptable — facture, avoir — sans toucher au stock.
    func mettreAJourDistant(_ reservation: Reservation) async throws {
        let payload = try Self.encodePayload(reservation)
        let ref = db.collection("reservations").document(reservation.id.uuidString)
        try await ref.updateData(["status": reservation.status.rawValue, "payload": payload])
    }

    private static func encodePayload(_ reservation: Reservation) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(reservation)
        return String(decoding: data, as: UTF8.self)
    }

    private static func erreur(_ message: String) -> NSError {
        NSError(domain: "Velobriere.Reservation",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}

#endif
