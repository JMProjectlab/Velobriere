import Foundation

/// Catalogue des vélos proposés à la réservation.
///
/// Le premier modèle référencé est le Decathlon E-ACTV 100 LF C2. Les
/// caractéristiques techniques précises (autonomie, poids, tailles de cadre…)
/// ne sont volontairement pas listées ici : la fiche produit Decathlon
/// (lien ci-dessous) n'a pas pu être récupérée automatiquement (accès
/// restreint sur decathlonpro.fr), donc l'app renvoie vers la page officielle
/// plutôt que d'afficher des chiffres non vérifiés. Les tarifs, eux, sont
/// ceux communiqués par Ker Vélo Brière — casque et antivol inclus dans toutes
/// les locations, livraison en option (+10 €, rayon de 10 km).
enum BikeCatalog {
    static let eActv100 = Bike(
        id: "e-actv-100-lf-c2",
        brand: "Decathlon",
        name: "E-ACTV 100 LF C2",
        tagline: "Vélo à assistance électrique, cadre bas",
        highlights: [
            "Cadre bas, facile à enfourcher",
            "Assistance électrique pour rouler sans effort",
            "Confortable pour les balades autour de la Brière",
            "Idéal pour découvrir marais, villages et chemins",
            "Deux tailles : S/M et L/XL, deux exemplaires de chaque",
            "Casque et antivol inclus dans toutes les locations"
        ],
        variants: [
            BikeVariant(id: "sm",  size: "S / M",  colorName: "Vert sauge", imageName: "BikeSM",  units: 2),
            BikeVariant(id: "lxl", size: "L / XL", colorName: "Blanc",      imageName: "BikeLXL", units: 2)
        ],
        pricingOptions: [
            PricingOption(id: "half-day", label: "Demi-journée", price: 25),
            PricingOption(id: "day", label: "Journée", price: 39),
            PricingOption(id: "weekend", label: "Week-end", price: 69),
            PricingOption(id: "week", label: "Semaine", price: 169)
        ],
        deliveryFee: 10,
        deliveryRadiusKm: 10,
        productURL: URL(string: "https://www.decathlonpro.fr/e-actv-100-lf-c2-id-8983925.html")
    )

    static let all: [Bike] = [eActv100]
}
