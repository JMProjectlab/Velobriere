/* Synchronisation Firestore — chargée seulement si une configuration existe.
 *
 * Le SDK est importé dynamiquement : sans `firebase-config.js` renseigné, aucun
 * octet n'est téléchargé et le site fonctionne exactement comme avant, avec ses
 * réservations dans le navigateur.
 *
 * Ce que ce module apporte, et qui était impossible en local :
 *
 *   1. Les réservations sont partagées. Le client qui réserve depuis son
 *      téléphone et le loueur qui consulte depuis le sien voient enfin la même
 *      chose.
 *   2. La double réservation devient impossible. La vérification du stock et
 *      son incrément se font dans UNE transaction Firestore, sur UN document
 *      par taille (`availability/{variantId}`), donc deux réservations
 *      simultanées ne peuvent pas passer toutes les deux.
 *
 * Le point 2 est le seul qui compte vraiment : c'est ce que les vérifications
 * locales de `VB.validateDraft` ne pourront jamais garantir.
 *
 * Forme des documents — à garder identique côté iOS :
 *   reservations/{id}        { uid, variantId, startDay, endDay, quantity,
 *                              status, payload }
 *   availability/{variantId} { units, days: { "2026-08-14": 1, … } }
 *
 * `payload` porte la réservation complète en JSON (client, tarif, facture) ;
 * les champs sortis à côté sont ceux dont les règles de sécurité et le calcul
 * de disponibilité ont besoin.
 */

window.VB = window.VB || {};

const SDK = 'https://www.gstatic.com/firebasejs/10.12.2';

let mods = null;
let db = null;
let auth = null;
let unsubReservations = null;

/* ---------- Initialisation ---------- */

async function loadConfig() {
  try {
    const m = await import('./firebase-config.js');
    const cfg = m.firebaseConfig;
    return cfg && cfg.apiKey && !String(cfg.apiKey).startsWith('REMPLACER') ? cfg : null;
  } catch {
    return null;
  }
}

/** Branche Firestore si c'est possible. Renvoie `false` en mode local. */
VB.Remote = {
  active: false,

  async init() {
    const config = await loadConfig();
    if (!config) return false;

    const [appMod, authMod, dbMod] = await Promise.all([
      import(`${SDK}/firebase-app.js`),
      import(`${SDK}/firebase-auth.js`),
      import(`${SDK}/firebase-firestore.js`)
    ]);
    mods = { ...authMod, ...dbMod };

    const app = appMod.initializeApp(config);
    auth = authMod.getAuth(app);
    db = dbMod.getFirestore(app);
    this.active = true;
    return true;
  },

  uid() {
    return auth?.currentUser?.uid ?? null;
  },

  /* ---------- Comptes ----------
     Firebase Auth remplace la simulation de `VB.Accounts` : l'identité est
     vérifiée côté serveur, la session suit d'un appareil à l'autre, et le mot
     de passe n'est jamais stocké ici. Le profil (nom, téléphone) vit à côté,
     dans `users/{uid}` : Auth ne conserve que l'e-mail. */

  /** Prévient à chaque connexion ou déconnexion, y compris au démarrage. */
  onAuthChanged(callback) {
    if (!this.active) return;
    mods.onAuthStateChanged(auth, callback);
  },

  async createAccount(email, password) {
    const cred = await mods.createUserWithEmailAndPassword(auth, email, password);
    return cred.user.uid;
  },

  async signIn(email, password) {
    const cred = await mods.signInWithEmailAndPassword(auth, email, password);
    return cred.user.uid;
  },

  async signOut() {
    this.stopWatching();
    await mods.signOut(auth);
  },

  /** Firebase exige une authentification récente pour changer un mot de passe. */
  async changePassword(currentPassword, newPassword) {
    const user = auth.currentUser;
    if (!user) throw new Error('Vous devez être connecté.');
    const credential = mods.EmailAuthProvider.credential(user.email, currentPassword);
    await mods.reauthenticateWithCredential(user, credential);
    await mods.updatePassword(user, newPassword);
  },

  async saveProfile(uid, profile) {
    await mods.setDoc(mods.doc(db, 'users', uid), profile, { merge: true });
  },

  async loadProfile(uid) {
    const snap = await mods.getDoc(mods.doc(db, 'users', uid));
    return snap.exists() ? snap.data() : null;
  },

  /** Traduit les codes d'erreur Firebase en messages lisibles.
      Connexion : message identique dans tous les cas, pour ne pas révéler
      si l'adresse existe. */
  errorMessage(error, contexte) {
    const code = error?.code || '';
    if (contexte === 'connexion') {
      if (code.startsWith('auth/too-many-requests')) {
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      }
      if (code.startsWith('auth/')) return 'Adresse e-mail ou mot de passe incorrect.';
    }
    switch (code) {
      case 'auth/email-already-in-use':
        return 'Un compte existe déjà avec cette adresse e-mail. Connectez-vous plutôt.';
      case 'auth/invalid-email':
        return "L'adresse e-mail n'est pas valide.";
      case 'auth/weak-password':
        return 'Le mot de passe est trop court.';
      case 'auth/wrong-password':
      case 'auth/invalid-credential':
        return 'Mot de passe actuel incorrect.';
      case 'auth/requires-recent-login':
        return 'Par sécurité, reconnectez-vous avant de changer votre mot de passe.';
      case 'auth/network-request-failed':
        return 'Connexion au serveur impossible. Vérifiez votre accès à Internet.';
      default:
        return error?.message || 'Une erreur est survenue.';
    }
  },

  /* ---------- Lecture ---------- */

  /** Écoute les réservations du compte connecté et rafraîchit l'affichage. */
  watchReservations(onChange) {
    if (!this.active || !this.uid()) return;
    this.stopWatching();
    const q = mods.query(
      mods.collection(db, 'reservations'),
      mods.where('uid', '==', this.uid())
    );
    unsubReservations = mods.onSnapshot(q, snap => {
      const list = snap.docs
        .map(d => {
          try { return JSON.parse(d.data().payload); } catch { return null; }
        })
        .filter(Boolean)
        .map(r => ({ ...r, start: new Date(r.start), end: new Date(r.end) }));
      onChange(list);
    });
  },

  stopWatching() {
    if (unsubReservations) { unsubReservations(); unsubReservations = null; }
  },

  /** Disponibilités publiques d'une taille, pour le calendrier. */
  async availability(variantId) {
    if (!this.active) return null;
    const snap = await mods.getDoc(mods.doc(db, 'availability', variantId));
    return snap.exists() ? snap.data() : null;
  },

  /* ---------- Écriture ---------- */

  /**
   * Enregistre une réservation en garantissant qu'elle ne dépasse pas le stock.
   *
   * Tout se joue dans la transaction : on relit le compteur de la taille au
   * moment de l'écriture, on vérifie chaque jour de la période, et on
   * n'incrémente que si tous passent. Si un autre client a réservé entre-temps,
   * Firestore rejoue la transaction avec les valeurs à jour — c'est cette
   * relecture qui rend la double réservation impossible.
   *
   * @throws {Error} avec un message lisible si le stock manque.
   */
  async commitReservation(reservation) {
    if (!this.active) throw new Error('Synchronisation indisponible.');
    const uid = this.uid();
    if (!uid) throw new Error('Vous devez être connecté pour réserver.');

    const jours = VB.Remote.daysBetween(reservation.start, reservation.end);
    const availabilityRef = mods.doc(db, 'availability', reservation.variantId);
    const reservationRef = mods.doc(db, 'reservations', reservation.id);

    await mods.runTransaction(db, async tx => {
      const snap = await tx.get(availabilityRef);
      if (!snap.exists()) {
        throw new Error("Cette taille de vélo n'est pas configurée. Contactez le loueur.");
      }
      const data = snap.data();
      const units = Number(data.units) || 0;
      const days = { ...(data.days || {}) };

      for (const jour of jours) {
        const pris = Number(days[jour]) || 0;
        if (pris + reservation.quantity > units) {
          const reste = Math.max(0, units - pris);
          throw new Error(
            reste <= 0
              ? "Plus aucun vélo de cette taille n'est disponible sur la période choisie."
              : `Il ne reste que ${reste} vélo${reste > 1 ? 's' : ''} de cette taille `
                + `le ${VB.Remote.formatDay(jour)}.`
          );
        }
        days[jour] = pris + reservation.quantity;
      }

      tx.update(availabilityRef, { days });
      tx.set(reservationRef, {
        uid,
        variantId: reservation.variantId,
        startDay: jours[0],
        endDay: jours[jours.length - 1],
        quantity: reservation.quantity,
        status: reservation.status,
        payload: JSON.stringify(reservation)
      });
    });
  },

  /**
   * Met à jour le détail d'une réservation existante — numéro de facture,
   * avoir, frais d'annulation — sans toucher aux compteurs.
   *
   * Les champs qui déterminent la disponibilité (taille, dates, quantité) sont
   * figés à la création et les règles de sécurité refusent de les voir changer :
   * seul le contenu comptable évolue.
   */
  async updateReservation(reservation) {
    if (!this.active) return;
    await mods.updateDoc(mods.doc(db, 'reservations', reservation.id), {
      status: reservation.status,
      payload: JSON.stringify(reservation)
    });
  },

  /** Annule une réservation et rend les vélos au stock, dans la même transaction. */
  async cancelReservation(reservation) {
    if (!this.active) throw new Error('Synchronisation indisponible.');

    const jours = VB.Remote.daysBetween(reservation.start, reservation.end);
    const availabilityRef = mods.doc(db, 'availability', reservation.variantId);
    const reservationRef = mods.doc(db, 'reservations', reservation.id);

    await mods.runTransaction(db, async tx => {
      const snap = await tx.get(availabilityRef);
      const days = { ...((snap.exists() && snap.data().days) || {}) };
      for (const jour of jours) {
        // `max(0, …)` : un compteur ne descend jamais sous zéro, même si une
        // annulation était rejouée deux fois.
        days[jour] = Math.max(0, (Number(days[jour]) || 0) - reservation.quantity);
      }
      if (snap.exists()) tx.update(availabilityRef, { days });
      tx.update(reservationRef, {
        status: 'cancelled',
        payload: JSON.stringify({ ...reservation, status: 'cancelled' })
      });
    });
  },

  /* ---------- Utilitaires de dates ---------- */

  /** Liste des jours « AAAA-MM-JJ » couverts par la période, bornes incluses. */
  daysBetween(start, end) {
    const out = [];
    let d = VB.startOfDay(start);
    const last = VB.startOfDay(end);
    while (d <= last) {
      out.push(VB.Remote.dayKey(d));
      d = VB.addDays(d, 1);
    }
    return out.length ? out : [VB.Remote.dayKey(VB.startOfDay(start))];
  },

  /** Clé de jour en heure locale — surtout pas `toISOString()`, qui décale en UTC. */
  dayKey(date) {
    const d = VB.startOfDay(date);
    const mois = String(d.getMonth() + 1).padStart(2, '0');
    const jour = String(d.getDate()).padStart(2, '0');
    return `${d.getFullYear()}-${mois}-${jour}`;
  },

  formatDay(key) {
    const [a, m, j] = key.split('-');
    return `${j}/${m}/${a}`;
  }
};
