import Foundation

/// Catalogue des vélos proposés à la réservation.
///
/// Le premier modèle référencé est le Decathlon E-ACTV 100 LF C2. Les
/// caractéristiques techniques précises (autonomie, poids, tailles de cadre…)
/// ne sont volontairement pas listées ici : la fiche produit Decathlon
/// (lien ci-dessous) n'a pas pu être récupérée automatiquement (accès
/// restreint sur decathlonpro.fr), donc l'app renvoie vers la page officielle
/// plutôt que d'afficher des chiffres non vérifiés.
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
            "Idéal pour découvrir marais, villages et chemins"
        ],
        pricePerDay: nil,
        productURL: URL(string: "https://www.decathlonpro.fr/e-actv-100-lf-c2-id-8983925.html"),
        imageSystemName: "bicycle"
    )

    static let all: [Bike] = [eActv100]
}
