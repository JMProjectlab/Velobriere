# Brancher Ker Vélo Brière sur Firebase

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
| 2. Comptes : `VB.Accounts` bascule sur Firebase Auth | **Faite** |
| 3. Bascule des écritures de réservation, web et iOS | **Faite** (Swift non compilé) |

Tant que `web/js/firebase-config.js` n'est pas renseigné, le site fonctionne
exactement comme avant : `VB.Remote.init()` ne télécharge rien, `VB.Accounts`
reste en simulation locale. **Rien n'est cassé, rien n'est encore actif.**

Dès que la configuration est en place, les comptes deviennent réels sans qu'une
ligne d'écran change.

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

## Étape 2 — les comptes (faite)

`VB.Accounts` a désormais deux modes derrière la même API : Firebase Auth si la
configuration est présente, simulation locale sinon. Aucun écran n'a changé.

Ce que la bascule corrige, une fois la configuration en place :

- l'identité est **vérifiée côté serveur** — le `localStorage` ne suffit plus à
  se faire passer pour quelqu'un ;
- la session **suit d'un appareil à l'autre** ;
- le mot de passe n'est plus stocké ni haché ici : Firebase s'en charge, avec
  une vraie fonction de dérivation ;
- changer de mot de passe exige une authentification récente.

Le profil (nom, téléphone) vit dans `users/{uid}`, Auth ne conservant que
l'e-mail. Les getters `current()` et `currentId()` restent synchrones : le
compte est tenu en cache et rafraîchi par `onAuthStateChanged`, qui déclenche
un réaffichage — la session Firebase se restaure de façon asynchrone, donc
personne n'est encore connecté au premier rendu.

Une chose à ne pas oublier côté console : activer **Authentication → Sign-in
method → Adresse e-mail / Mot de passe**, sinon toute inscription échouera.

---

## Étape 3 — les écritures et iOS (faite)

**Web.** Création et annulation passent par les transactions de `VB.Remote` dès
qu'un compte est connecté. Les réservations affichées viennent de Firestore, en
écoute temps réel : le client et le loueur voient enfin la même chose, depuis
n'importe quel appareil. Sans compte connecté, tout retombe sur le mode local.

**iOS.** `ReservationStore` gagne les mêmes transactions, encadrées par
`#if canImport(FirebaseFirestore)`. **Sans le paquet Firebase, ce code n'existe
pas et le projet compile exactement comme avant** — rien n'est cassé tant que
tu n'as pas fait la manipulation ci-dessous.

Pour activer le mode partagé sur iOS :

1. Xcode → *File → Add Package Dependencies* →
   `https://github.com/firebase/firebase-ios-sdk`, produits **FirebaseAuth** et
   **FirebaseFirestore**.
2. Déposer `GoogleService-Info.plist` dans la cible. Il est couvert par le
   `.gitignore` du dépôt : il ne part pas sur GitHub. **Vérifie quand même
   `git status` avant de committer** — sur Scornade, l'intégration Git de
   Xcode l'avait mis en zone d'attente malgré l'exclusion.
3. L'écran de connexion existe (`AccountView`, accessible depuis l'onglet
   Réservations). Le compte y est **facultatif** : réserver, consulter et
   annuler fonctionnent sans, en local. Se connecter ne fait qu'une chose, mais
   elle est décisive — les réservations deviennent partagées avec le loueur.

### Ce qui manque encore côté iOS

L'app **écrit** dans Firestore une fois connectée, mais elle n'en **lit** pas
encore : il n'y a pas d'écoute temps réel comme côté web
(`VB.Remote.watchReservations`). Conséquence : un client qui se connecte depuis
un nouvel iPhone ne retrouve pas ses réservations passées, et le loueur ne voit
pas depuis l'app iOS celles créées ailleurs.

C'est le dernier maillon. À faire après avoir vérifié le modèle de données en
conditions réelles sur le web — inutile de porter une deuxième fois une forme
de document qui bougerait encore.

`ReservationStore.validate(_:)` et `VB.validateDraft()` restent utiles après la
bascule : ils donnent un message immédiat sans aller-retour réseau. Ils cessent
simplement d'être la seule protection.

### L'ordre des opérations, et pourquoi il compte

À l'annulation, le serveur est appelé **avant** la mise à jour locale. L'inverse
laisserait une réservation annulée sur l'appareil mais toujours active côté
serveur : un vélo bloqué pour rien, invisible depuis l'app.

À la réservation, c'est le contraire : le serveur écrit d'abord, et la
réservation n'entre dans la liste locale qu'ensuite, sans repasser par la
validation — la décision du serveur fait autorité, et la copie locale est
partielle.

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
