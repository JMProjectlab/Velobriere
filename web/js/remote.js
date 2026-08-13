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
