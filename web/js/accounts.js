/* Comptes clients : inscription, connexion, session.
 *
 * DEUX MODES, une seule API. Les écrans appellent `VB.Accounts` sans savoir
 * lequel est actif :
 *
 *   • Firebase Auth, dès que `web/js/firebase-config.js` est renseigné.
 *     L'identité est vérifiée côté serveur, la session suit d'un appareil à
 *     l'autre, le mot de passe n'est jamais stocké ici. C'est le mode réel.
 *
 *   • Simulation locale, sinon. Le site reste utilisable et démontrable sans
 *     aucune configuration — voir les limites ci-dessous, qui ne valent QUE
 *     pour ce mode.
 *
 * Les getters de session (`current`, `currentId`) restent synchrones : le
 * compte Firebase est tenu en cache et rafraîchi par `onAuthStateChanged`.
 *
 * ⚠️ LIMITES DE LA SIMULATION LOCALE — elles disparaissent en mode Firebase
 *
 * Sans serveur, tout se joue dans le navigateur. Par conséquent :
 *
 * 1. Ce n'est PAS une authentification. Rien ne vérifie l'identité côté serveur.
 *    Quiconque accède au navigateur peut lire ou modifier le localStorage, donc
 *    se connecter sans mot de passe. Cela protège contre une consultation
 *    distraite, pas contre quelqu'un de déterminé.
 *
 * 2. Les comptes ne suivent pas d'un appareil à l'autre. Un compte créé sur un
 *    ordinateur n'existe pas sur le téléphone du même client.
 *
 * 3. Le mot de passe est haché en SHA-256 avec un sel aléatoire par compte —
 *    nettement mieux qu'un stockage en clair, mais SHA-256 n'est PAS une
 *    fonction de dérivation de mot de passe : elle est rapide, donc peu coûteuse
 *    à attaquer par force brute. Un vrai système hache côté serveur avec
 *    bcrypt, scrypt ou Argon2.
 *
 * C'est exactement ce que le mode Firebase corrige.
 */

window.VB = window.VB || {};

VB.ACCOUNTS_KEY = 'velobriere-web-accounts-v1';
VB.SESSION_KEY = 'velobriere-web-session-v1';

VB.PASSWORD_MIN_LENGTH = 8;

VB.Accounts = {

  /* ---------- Mode ---------- */

  /** Vrai dès que Firebase est configuré et initialisé. */
  distant() {
    return !!(VB.Remote && VB.Remote.active);
  },

  /** Compte Firebase courant, tenu à jour par `onAuthStateChanged`.
      Permet à `current()` de rester synchrone comme avant. */
  _cache: null,

  /** Appelé au démarrage et à chaque changement d'état d'authentification. */
  async _onAuthChanged(user) {
    if (!user) {
      VB.Accounts._cache = null;
      return;
    }
    let profile = null;
    try { profile = await VB.Remote.loadProfile(user.uid); } catch (e) { /* profil optionnel */ }
    VB.Accounts._cache = {
      id: user.uid,
      email: (user.email || '').toLowerCase(),
      firstName: profile?.firstName || '',
      lastName: profile?.lastName || '',
      countryCode: profile?.countryCode || '+33',
      phone: profile?.phone || '',
      createdAt: profile?.createdAt ? new Date(profile.createdAt) : new Date()
    };
  },

  /* ---------- Stockage (mode local uniquement) ---------- */

  all() {
    try {
      const raw = localStorage.getItem(VB.ACCOUNTS_KEY);
      if (!raw) return [];
      return (JSON.parse(raw) || []).map(a => ({ ...a, createdAt: new Date(a.createdAt) }));
    } catch (e) { return []; }
  },

  save(accounts) {
    try {
      localStorage.setItem(VB.ACCOUNTS_KEY, JSON.stringify(
        accounts.map(a => ({ ...a, createdAt: a.createdAt.toISOString() }))
      ));
    } catch (e) { /* stockage indisponible */ }
  },

  normalizeEmail: email => email.trim().toLowerCase(),

  findById(id) {
    return VB.Accounts.all().find(a => a.id === id) || null;
  },

  /* ---------- Mots de passe ---------- */

  randomSalt() {
    const bytes = new Uint8Array(16);
    crypto.getRandomValues(bytes);
    return [...bytes].map(b => b.toString(16).padStart(2, '0')).join('');
  },

  async hashPassword(password, salt) {
    const data = new TextEncoder().encode(`${salt}:${password}`);
    const buffer = await crypto.subtle.digest('SHA-256', data);
    return [...new Uint8Array(buffer)].map(b => b.toString(16).padStart(2, '0')).join('');
  },

  /** Comparaison à temps constant, pour ne pas fuiter d'information par la durée. */
  constantTimeEquals(a, b) {
    if (a.length !== b.length) return false;
    let diff = 0;
    for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
    return diff === 0;
  },

  /* ---------- Inscription / connexion ---------- */

  /** @returns {Promise<{ok: true, account} | {ok: false, error: string}>} */
  async signUp({ firstName, lastName, email, countryCode, phone, password }) {
    const normalized = VB.Accounts.normalizeEmail(email);

    if (VB.Accounts.distant()) {
      try {
        const uid = await VB.Remote.createAccount(normalized, password);
        const profile = {
          firstName: firstName.trim(),
          lastName: lastName.trim().toUpperCase(),
          countryCode,
          phone: phone.trim(),
          email: normalized,
          createdAt: new Date().toISOString()
        };
        await VB.Remote.saveProfile(uid, profile);
        await VB.Accounts._onAuthChanged({ uid, email: normalized });
        return { ok: true, account: VB.Accounts._cache };
      } catch (error) {
        return { ok: false, error: VB.Remote.errorMessage(error, 'inscription') };
      }
    }

    if (VB.Accounts.all().some(a => a.email === normalized)) {
      return { ok: false, error: 'Un compte existe déjà avec cette adresse e-mail. Connectez-vous plutôt.' };
    }

    const salt = VB.Accounts.randomSalt();
    const account = {
      id: 'a-' + (crypto.randomUUID ? crypto.randomUUID().slice(0, 12) : Math.random().toString(36).slice(2, 14)),
      email: normalized,
      firstName: firstName.trim(),
      lastName: lastName.trim().toUpperCase(),
      countryCode,
      phone: phone.trim(),
      salt,
      passwordHash: await VB.Accounts.hashPassword(password, salt),
      createdAt: new Date()
    };

    const accounts = VB.Accounts.all();
    accounts.push(account);
    VB.Accounts.save(accounts);
    return { ok: true, account };
  },

  async signIn(email, password) {
    if (VB.Accounts.distant()) {
      try {
        const uid = await VB.Remote.signIn(VB.Accounts.normalizeEmail(email), password);
        await VB.Accounts._onAuthChanged({ uid, email: VB.Accounts.normalizeEmail(email) });
        return { ok: true, account: VB.Accounts._cache };
      } catch (error) {
        return { ok: false, error: VB.Remote.errorMessage(error, 'connexion') };
      }
    }

    const account = VB.Accounts.all().find(a => a.email === VB.Accounts.normalizeEmail(email));
    // Message identique dans les deux cas : ne pas révéler si l'adresse existe.
    const genericError = { ok: false, error: 'Adresse e-mail ou mot de passe incorrect.' };
    if (!account) return genericError;

    const hash = await VB.Accounts.hashPassword(password, account.salt);
    if (!VB.Accounts.constantTimeEquals(hash, account.passwordHash)) return genericError;
    return { ok: true, account };
  },

  async changePassword(accountId, currentPassword, newPassword) {
    if (VB.Accounts.distant()) {
      try {
        await VB.Remote.changePassword(currentPassword, newPassword);
        return { ok: true };
      } catch (error) {
        return { ok: false, error: VB.Remote.errorMessage(error, 'motdepasse') };
      }
    }

    const accounts = VB.Accounts.all();
    const account = accounts.find(a => a.id === accountId);
    if (!account) return { ok: false, error: 'Compte introuvable.' };

    const currentHash = await VB.Accounts.hashPassword(currentPassword, account.salt);
    if (!VB.Accounts.constantTimeEquals(currentHash, account.passwordHash)) {
      return { ok: false, error: 'Mot de passe actuel incorrect.' };
    }

    account.salt = VB.Accounts.randomSalt();
    account.passwordHash = await VB.Accounts.hashPassword(newPassword, account.salt);
    VB.Accounts.save(accounts);
    return { ok: true };
  },

  /* ---------- Session ---------- */

  currentId() {
    if (VB.Accounts.distant()) return VB.Accounts._cache?.id ?? null;
    try { return localStorage.getItem(VB.SESSION_KEY); } catch (e) { return null; }
  },

  current() {
    if (VB.Accounts.distant()) return VB.Accounts._cache;
    const id = VB.Accounts.currentId();
    return id ? VB.Accounts.findById(id) : null;
  },

  /** En mode Firebase, la session est ouverte par `signIn`/`signUp` et
      persistée par le SDK : il n'y a rien à écrire ici. */
  setSession(accountId) {
    if (VB.Accounts.distant()) return;
    try { localStorage.setItem(VB.SESSION_KEY, accountId); } catch (e) { /* stockage indisponible */ }
  },

  clearSession() {
    if (VB.Accounts.distant()) {
      VB.Accounts._cache = null;
      VB.Remote.signOut().catch(e => console.warn('[VB] Déconnexion :', e));
      return;
    }
    try { localStorage.removeItem(VB.SESSION_KEY); } catch (e) { /* stockage indisponible */ }
  }
};

/* ---------- Validation du formulaire ---------- */

VB.passwordProblem = password => {
  if (password.length < VB.PASSWORD_MIN_LENGTH) {
    return `Le mot de passe doit contenir au moins ${VB.PASSWORD_MIN_LENGTH} caractères.`;
  }
  return null;
};

/* ---------- Rattachement des réservations ---------- */

/**
 * Rattache au compte les réservations passées faites sans être connecté,
 * lorsque l'adresse e-mail correspond. C'est ce qui permet de « retrouver »
 * ses anciennes réservations en créant un compte après coup.
 * @returns {number} nombre de réservations récupérées
 */
VB.claimGuestReservations = account => {
  let claimed = 0;
  VB.state.reservations.forEach(r => {
    if (!r.accountId && r.email && VB.Accounts.normalizeEmail(r.email) === account.email) {
      r.accountId = account.id;
      claimed++;
    }
  });
  if (claimed > 0) VB.saveReservations();
  return claimed;
};

/** Réservations visibles : celles du compte connecté, ou les réservations
    anonymes de ce navigateur si personne n'est connecté. */
VB.visibleReservations = () => {
  const id = VB.Accounts.currentId();
  return VB.state.reservations.filter(r => (id ? r.accountId === id : !r.accountId));
};
