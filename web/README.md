# Vélo Brière — application web

Version web de l'application de réservation, accessible depuis un ordinateur,
une tablette ou un téléphone. Mêmes fonctionnalités que l'app iOS, mise en page
adaptée à chaque écran.

## Lancer l'application

C'est un site statique : aucun serveur, aucune dépendance, aucune étape de
construction.

- **En local** : ouvrez `web/index.html` dans votre navigateur (double-clic suffit).
- **En ligne** : déposez le contenu du dossier `web/` sur n'importe quel
  hébergeur statique (GitHub Pages, Netlify, Vercel, un simple dossier
  Apache/nginx…). Aucune configuration particulière n'est requise.

## Fonctionnalités

- Catalogue et fiche vélo, avec la grille tarifaire réelle
- Calendrier de disponibilité : chaque jour indique les vélos restants
  (vert disponible / sable places limitées / rouge complet)
- Réservation : dates, formule, livraison en option, quantité plafonnée à la
  disponibilité réelle
- Contrôles de saisie : prénom, nom (mis en majuscules), indicatif pays +
  numéro de téléphone, e-mail avec vérification du domaine, acceptation des CGL
  obligatoire
- Paiement : Apple Pay ou carte bancaire — **simulé**, voir ci-dessous
- Factures et avoirs numérotés séquentiellement, consultables par réservation
- Annulation avec politique de frais et confirmation explicite
- Mentions légales, politique de confidentialité et CGL
- Thème clair / sombre, suivant le système ou basculé manuellement

## Politique d'annulation

| Moment de l'annulation | Retenu | Remboursé |
|---|---|---|
| Plus de 2 jours avant le départ | 0 % | 100 % |
| 2 jours ou moins, jour du départ inclus | 50 % | 50 % |
| Location déjà commencée | 100 % | 0 % |

Un avoir est émis dès qu'il y a un remboursement. Aucune réservation payée ne
peut être supprimée d'un clic : elle passe par l'annulation, avec sa
confirmation et son avoir.

## ⚠️ Le paiement est simulé

`VB.chargePayment` (dans `js/domain.js`) attend puis renvoie une référence
factice. **Aucun montant n'est débité, aucune donnée de carte n'est transmise
ni conservée.** Le formulaire de carte est une maquette.

Pour encaisser réellement, il faut :

1. un compte marchand chez un prestataire (Stripe, SumUp, Adyen…) ;
2. un **serveur** qui crée l'intention de paiement et renvoie son secret client —
   la clé secrète ne doit jamais se trouver dans le code de la page ;
3. le SDK du prestataire pour la saisie de la carte : il porte la conformité
   PCI-DSS et l'authentification forte (DSP2). Ne manipulez jamais vous-même un
   numéro de carte ;
4. pour Apple Pay sur le web : un domaine vérifié auprès d'Apple et le certificat
   marchand rattaché au prestataire ;
5. la confirmation du paiement **côté serveur** (webhook) avant de considérer la
   réservation comme payée.

Le remplacement se limite à `VB.chargePayment` : tout le reste du tunnel est déjà
en place.

## ⚠️ Les textes juridiques sont des squelettes

Les mentions légales, la politique de confidentialité et les CGL contiennent des
`[À COMPLÉTER : …]` — SIRET, forme juridique, régime de TVA, assureur, dépôt de
garantie, médiateur, durées de conservation. L'interface les signale (pastille,
badge, bandeau) pour qu'un document incomplet ne parte pas en ligne par
inadvertance.

Ces textes doivent être complétés **puis relus par un professionnel du droit**.
Ce ne sont pas des conseils juridiques.

## Données

Tout est stocké dans le `localStorage` du navigateur : rien n'est envoyé à un
serveur, et les données ne sont pas partagées entre appareils. Le bandeau
« Réinitialiser » remet la démonstration à son état initial.

Clés utilisées : `velobriere-web-reservations-v1`, `velobriere-web-invoices-v1`,
`velobriere-web-invoice-counters-v1`, `velobriere-web-theme`.

## Organisation du code

| Fichier | Rôle |
|---|---|
| `index.html` | Structure de la page, en-tête, pied de page, boîte de dialogue |
| `css/styles.css` | Charte graphique, mise en page responsive, thèmes clair/sombre |
| `js/data.js` | Catalogue, indicatifs, textes légaux |
| `js/store.js` | État et persistance locale |
| `js/domain.js` | Dates, disponibilité, tarifs, annulation, facturation, paiement |
| `js/views.js` | Rendu des écrans |
| `js/app.js` | Routage, brouillon de réservation, évènements |

La logique métier de `js/domain.js` reprend celle de l'app iOS
(`Velobriere/Models/CancellationPolicy.swift`, `Data/ReservationStore.swift`,
`Data/InvoiceStore.swift`) : toute évolution des règles doit être répercutée
des deux côtés.
