import Foundation

/// Une taille de vélo, avec son propre stock.
///
/// Le parc compte deux tailles de deux exemplaires chacune : réserver un S/M
/// ne réduit pas la disponibilité des L/XL. La disponibilité se calcule donc
/// toujours pour une taille donnée.
struct BikeVariant: Identifiable, Hashable {
    let id: String
    /// Taille affichée au client, par exemple « S / M ».
    let size: String
    let colorName: String
    /// Nom de l'image dans le catalogue d'assets.
    let imageName: String
    let units: Int
}
