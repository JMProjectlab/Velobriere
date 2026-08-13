# Brancher Vélo Brière sur Firebase

Aujourd'hui, l'application **n'a aucun serveur** : les réservations vivent dans
un fichier local sur iOS et dans le `localStorage` du navigateur sur le web.
Conséquence : deux appareils ne voient pas les réservations l'un de l'autre, et
**aucune vérification côté client ne peut empêcher une double réservation**.

Ce document décrit la bascule. Elle se fait en trois temps, et seul le premier
est terminé.

---

## Où on en est

| Étape | État |
|---|---|
| 1. Fondation : modèle de données, règles de sécurité, couche Firestore web | **Faite** |
| 2. Comptes : remplacer `VB.Accounts` par Firebase Auth | à faire |
| 3. Bascule des écritures et portage iOS | à faire |

Tant que l'étape 2 n'est pas faite, le site continue de fonctionner en local :
`firebase-config.js` n'est pas renseigné, donc `VB.Remote.init()` ne télécharge
rien et ne change rien. **Rien n'est cassé, rien n'est encore branché.**

---

## Le modèle de données

```
reservations/{id}         { uid, variantId, startDay, endDay, quantity,
                            status, payload }
availability/{variantId}  { units: 2, days: { "2026-08-14": 1, … } }
config/public             paramètres lisibles par tous
config/admins             { uids: ["…"] } — les comptes du loueur
```

`payload` porte la réservation complète en JSON (client, tarif, facture). Les
champs sortis à côté sont exactement ceux dont les règles de sécurité et le
calcul de disponibilité ont besoin.

### Pourquoi un compteur par jour

C'est le cœur du dispositif. Le SDK client de Firestore **ne sait pas exécuter
de requête dans une transaction** — seulement lire des documents précis. On ne
peut donc pas, de façon sûre, « chercher les réservations qui chevauchent »
avant d'écrire.

D'où un seul document par taille, contenant le nombre de vélos pris chaque
jour. Réserver, c'est : lire ce document, vérifier chaque jour de la période,
incrémenter, écrire — le tout dans une transaction. Si quelqu'un réserve
entre-temps, Firestore rejoue la transaction avec les valeurs à jour. Deux
réservations simultanées ne peuvent pas passer toutes les deux.

C'est l'équivalent de la contrainte d'exclusion qu'on aurait eue gratuitement
en SQL. C'est aussi la seule raison sérieuse de brancher un serveur.

---

## Étape 1 — la console (30 min)

1. **Créer le projet** sur console.firebase.google.com. Un projet distinct de
   Scornade : les données d'une activité commerciale ne se mélangent pas avec
   celles d'une app perso.
2. **Authentication → Sign-in method** : activer *Adresse e-mail / Mot de passe*,
   et *Apple* si l'app iOS doit proposer « Se connecter avec Apple ».
3. **Authentication → Settings → Domaines autorisés** : ajouter
   `jmprojectlab.github.io`, sinon la connexion sera refusée depuis le site.
4. **Firestore Database** : créer la base en mode production, région
   `europe-west` (les données sont françaises, autant qu'elles restent en
   Europe — c'est aussi ce que demande le RGPD par défaut).
5. **Déployer les règles** : copier `firestore.rules` dans l'onglet Règles, ou
   `firebase deploy --only firestore:rules`. **À faire avant la première
   écriture**, pas après.
6. **Créer les documents de départ**, à la main dans la console :
   - `availability/sm` → `{ units: 2, days: {} }`
   - `availability/lxl` → `{ units: 2, days: {} }`
   - `config/admins` → `{ uids: ["<uid du compte du loueur>"] }`
7. **Application web** : Paramètres du projet → Vos applications → Web,
   enregistrer l'app, copier la configuration dans `web/js/firebase-config.js`
   à la place des `REMPLACER`.

Ces clés ne sont pas des secrets : elles partent dans le navigateur de chaque
visiteur. Ce qui protège les données, ce sont les règles.

---

## Étape 2 — les comptes

`web/js/accounts.js` est une simulation, et le fichier le dit lui-même :
l'authentification n'est pas vérifiée, les comptes ne suivent pas d'un appareil
à l'autre, et le hachage SHA-256 n'est pas une fonction de dérivation de mot de
passe.

Les règles Firestore exigent `request.auth` : **tant que `VB.Accounts` n'est pas
remplacé par Firebase Auth, aucune écriture ne passera.** C'est le vrai
prochain chantier. Les écrans n'ont pas à changer — seule l'implémentation de
`VB.Accounts` (inscription, connexion, session) devient un appel au SDK.

---

## Étape 3 — les écritures et iOS

Une fois les comptes en place :

- côté web, faire passer la création de réservation par
  `VB.Remote.commitReservation()` au lieu de `VB.state.reservations.push()`, et
  l'annulation par `VB.Remote.cancelReservation()` ;
- côté iOS, ajouter le paquet Firebase (Xcode → *Add Package Dependencies* →
  `https://github.com/firebase/firebase-ios-sdk`, produits *FirebaseAuth* et
  *FirebaseFirestore*), déposer `GoogleService-Info.plist` dans la cible, et
  porter la même transaction dans `ReservationStore`.

`ReservationStore.validate(_:)` et `VB.validateDraft()` restent utiles après la
bascule : ils donnent un message immédiat sans aller-retour réseau. Ils cessent
simplement d'être la seule protection.

---

## La limite assumée

Les règles autorisent un client authentifié à écrire sa réservation et à mettre
à jour les compteurs. Quelqu'un qui parlerait directement à l'API pourrait donc
fausser un compteur : les règles vérifient la forme des données, pas toute la
cohérence métier.

Fermer complètement cela demande des Cloud Functions, donc le plan **Blaze**
(facturation à l'usage). Ce n'est pas justifié pour un loueur familial avec
quatre vélos ; ça le deviendra le jour d'un client payant. La décision est
consignée dans le second cerveau, avec sa condition de réouverture.
