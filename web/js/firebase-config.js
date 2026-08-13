// Configuration de l'application web Firebase de Vélo Brière.
// Source : console Firebase → Paramètres du projet → Vos applications → Web.
//
// Tant que `apiKey` vaut « REMPLACER », le site fonctionne exactement comme
// avant : les réservations restent dans le navigateur, sans compte ni
// synchronisation. C'est le repli voulu, pas une panne — on peut déployer le
// site avant d'avoir monté le projet Firebase.
//
// Ces clés ne sont pas des secrets : elles partent dans le navigateur de chaque
// visiteur. Ce qui protège les données, ce sont les règles Firestore
// (`firestore.rules` à la racine du dépôt).
//
// Voir SETUP-FIREBASE.md pour la marche à suivre côté console.

export const firebaseConfig = {
  apiKey: "REMPLACER",
  authDomain: "REMPLACER.firebaseapp.com",
  projectId: "REMPLACER",
  storageBucket: "REMPLACER.firebasestorage.app",
  messagingSenderId: "REMPLACER",
  appId: "REMPLACER"
};

export const estConfigure = () => firebaseConfig.apiKey !== "REMPLACER";
