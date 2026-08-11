# Vélo Brière — réservation de vélos électriques

Deux applications, mêmes fonctionnalités et mêmes règles métier :

| Dossier | Quoi | Comment l'ouvrir |
|---|---|---|
| `Velobriere/` | App iOS (SwiftUI) | `Velobriere.xcodeproj` dans Xcode 15+ |
| `web/` | Application web responsive | En ligne sur [GitHub Pages](https://jmprojectlab.github.io/Velobriere/), ou `web/index.html` en local — voir [`web/README.md`](web/README.md) |
| `brand/` | Charte graphique | [`brand/charte-graphique.html`](brand/charte-graphique.html) dans un navigateur |

Les règles d'annulation, de tarification et de facturation sont dupliquées dans
les deux bases : toute évolution doit être répercutée des deux côtés.

La charte est un document de référence : logo, couleurs, typographie, ton de
voix. Les polices y sont embarquées, elle s'ouvre donc hors ligne. Rien dans
les deux applications ne la lit — c'est à nous de nous y tenir.

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
- **Deux tailles** : S/M (vert sauge) et L/XL (blanc), **deux exemplaires chacune**.
  Le stock est suivi séparément par taille : réserver un S/M ne réduit pas la
  disponibilité des L/XL. La taille se choisit sur la fiche vélo et dans le
  formulaire, et se retrouve sur la réservation, la confirmation et la facture.
- **Fiche vélo** : photos des deux tailles, présentation, points forts et la grille
  tarifaire réelle (demi-journée 25 €, journée 39 €, week-end 69 €, semaine 169 €,
  livraison +10 € dans un rayon de 10 km).
- **Réservation** : formulaire (taille, dates, nombre de vélos, coordonnées,
  remarques), paiement, écran de confirmation.
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
- Les photos utilisées dans le catalogue et la fiche sont celles fournies par Vélo
  Brière (une par taille), normalisées sur le fond crème de la charte.
- La réservation est une simple demande stockée sur l'appareil : il n'y a pas encore
  de confirmation par SMS/e-mail ni de vérification de disponibilité réelle. À
  brancher sur un backend (ou un simple envoi d'e-mail/webhook) selon le besoin.
- Pas de tests automatisés pour l'instant.
