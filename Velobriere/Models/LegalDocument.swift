import Foundation

/// Un document légal (mentions légales, politique de confidentialité, CGL).
///
/// Les passages que Ker Vélo Brière doit renseigner sont balisés avec
/// `LegalDocument.placeholderMarker` : l'app les met en évidence pour éviter
/// qu'un document incomplet parte en production.
struct LegalDocument: Identifiable, Hashable {
    struct Section: Identifiable, Hashable {
        let id: String
        let heading: String
        let body: String

        var needsCompletion: Bool {
            body.contains(LegalDocument.placeholderMarker)
        }
    }

    static let placeholderMarker = "[À COMPLÉTER"

    let id: String
    let title: String
    let summary: String
    let lastUpdated: String
    let sections: [Section]

    var needsCompletion: Bool {
        sections.contains(where: \.needsCompletion)
    }
}
