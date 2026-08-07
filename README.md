# Vélo Brière — réservation de vélos électriques

Deux applications, mêmes fonctionnalités et mêmes règles métier :

| Dossier | Quoi | Comment l'ouvrir |
|---|---|---|
| `Velobriere/` | App iOS (SwiftUI) | `Velobriere.xcodeproj` dans Xcode 15+ |
| `web/` | Application web responsive | `web/index.html` dans un navigateur — voir [`web/README.md`](web/README.md) |

Les règles d'annulation, de tarification et de facturation sont dupliquées dans
les deux bases : toute évolution doit être répercutée des deux côtés.

---

## App iOS de réservation

App iOS (SwiftUI) pour réserver un vélo auprès de **Vélo Brière**, location de vélos
électriques à Saint-Lyphard, au cœur du Parc naturel régional de Brière.

## Ouvrir le projet

1. Ouvrez `Velobriere.xcodeproj` avec Xcode 15 ou supérieur (iOS 17+).
2. Sélectionnez votre équipe de développement dans l'onglet *Signing & Capabilities*
   de la target `Velobriere` (le bundle id par défaut `com.velobriere.app` est à
   adapter si besoin).
3. Lancez sur un simulateur ou un appareil (⌘R).

Ce dépôt a été préparé dans un environnement Linux sans Xcode : le projet n'a donc
pas pu être compilé ni exécuté ici. Merci de vérifier la compilation sur un Mac
avant mise en production.

## Ce qui est implémenté (v1)

- **Catalogue** : un premier vélo, le Decathlon **E-ACTV 100 LF C2**, avec lien vers
  sa fiche produit officielle.
- **Fiche vélo** : présentation, points forts, prix (« sur devis » tant qu'un tarif
  n'est pas renseigné dans `BikeCatalog.swift`).
- **Réservation** : formulaire (dates, nombre de vélos, coordonnées, remarques),
  écran de confirmation.
- **Mes réservations** : liste des demandes enregistrées, suppression par glissement.
- Persistance locale uniquement (fichier JSON dans le dossier Documents de l'app) —
  pas encore de backend ni de synchronisation entre appareils.

## Charte graphique

Les couleurs et rayons de la charte fournie (`chartegraphiquevelobriere.html`) sont
repris dans `Assets.xcassets` (jeux de couleurs adaptatifs clair/sombre) et
`DesignSystem/Theme.swift`. Le symbole du logo (roseaux, héron, vélo) a été extrait
de la charte et sert d'icône d'app et de vignette de marque dans l'écran d'accueil.

Les polices Poppins / Work Sans / Caveat de la charte ne sont pas incluses (fichiers
non fournis) : `Theme.swift` référence déjà leurs noms, avec repli automatique sur la
police système tant qu'elles ne sont pas ajoutées. Pour les activer pleinement :
1. Ajoutez les fichiers `.ttf`/`.otf` à la target.
2. Déclarez-les dans Info.plist sous la clé `Fonts provided by application`
   (nécessite de passer de `GENERATE_INFOPLIST_FILE` à un fichier Info.plist
   classique, ou d'utiliser `INFOPLIST_KEY_UIAppFonts` avec un tableau).

## Limites connues / à faire

- La fiche produit Decathlon (`decathlonpro.fr`) a renvoyé une erreur 403 lors de la
  préparation de ce projet (accès pro/restreint) : les caractéristiques précises
  (autonomie, poids, tailles de cadre…) ne sont donc pas affichées pour éviter
  d'inventer des chiffres. L'app renvoie vers la fiche officielle pour ces détails.
- Aucune photo réelle du vélo n'a pu être récupérée : un espace réservé (icône) est
  utilisé dans le catalogue et la fiche produit.
- La réservation est une simple demande stockée sur l'appareil : il n'y a pas encore
  de confirmation par SMS/e-mail ni de vérification de disponibilité réelle. À
  brancher sur un backend (ou un simple envoi d'e-mail/webhook) selon le besoin.
- Pas de tests automatisés pour l'instant.
