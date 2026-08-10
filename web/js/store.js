/* État applicatif et persistance locale (localStorage).
   Aucun backend : les données restent dans le navigateur. */

window.VB = window.VB || {};

VB.STORAGE_KEY = 'velobriere-web-reservations-v1';
VB.INVOICE_STORAGE_KEY = 'velobriere-web-invoices-v1';
VB.INVOICE_COUNTER_KEY = 'velobriere-web-invoice-counters-v1';

VB.state = {
  route: { name: 'home' },
  reservations: [],
  invoices: []
};

/* ---------- Réservations ---------- */

VB.seedReservations = () => {
  const today = VB.startOfDay(new Date());
  return [
    {
      id: 'seed-1', accountId: null,
      start: VB.addDays(today, 4), end: VB.addDays(today, 6), quantity: 2,
      pricingLabel: 'Journée', pricePerUnit: 39, includesDelivery: false,
      deliveryFee: VB.BIKE.deliveryFee, totalPrice: 78,
      firstName: 'Marie', lastName: 'DUPONT', countryCode: '+33', phone: '06 12 34 56 78',
      email: 'marie.dupont@example.com', notes: '',
      createdAt: VB.addDays(today, -2), acceptedTermsAt: VB.addDays(today, -2),
      status: 'confirmed', paymentStatus: 'paid', paymentMethod: 'card',
      paymentReference: 'SIMU-SEED0001', paidAt: VB.addDays(today, -2), invoiceNumber: null,
      cancelledAt: null, cancellationFee: null, refundedAmount: null, creditNoteNumber: null
    },
    {
      id: 'seed-2', accountId: null,
      start: VB.addDays(today, 9), end: VB.addDays(today, 10), quantity: 4,
      pricingLabel: 'Semaine', pricePerUnit: 169, includesDelivery: true,
      deliveryFee: VB.BIKE.deliveryFee, totalPrice: 4 * 169 + 10,
      firstName: 'Groupe', lastName: 'RANDO', countryCode: '+33', phone: '06 98 76 54 32',
      email: 'groupe.rando@example.com', notes: 'Casques enfants x2 si possible',
      createdAt: VB.addDays(today, -1), acceptedTermsAt: VB.addDays(today, -1),
      status: 'confirmed', paymentStatus: 'paid', paymentMethod: 'applePay',
      paymentReference: 'SIMU-SEED0002', paidAt: VB.addDays(today, -1), invoiceNumber: null,
      cancelledAt: null, cancellationFee: null, refundedAmount: null, creditNoteNumber: null
    }
  ];
};

VB.saveReservations = () => {
  try {
    localStorage.setItem(VB.STORAGE_KEY, JSON.stringify(VB.state.reservations.map(r => ({
      ...r,
      start: VB.toISO(r.start),
      end: VB.toISO(r.end),
      createdAt: r.createdAt.toISOString(),
      acceptedTermsAt: r.acceptedTermsAt ? r.acceptedTermsAt.toISOString() : null,
      paidAt: r.paidAt ? r.paidAt.toISOString() : null,
      cancelledAt: r.cancelledAt ? r.cancelledAt.toISOString() : null
    }))));
  } catch (e) { /* stockage indisponible : la démo continue sans persistance */ }
};

VB.loadReservations = () => {
  try {
    const raw = localStorage.getItem(VB.STORAGE_KEY);
    if (!raw) return VB.seedReservations();
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed) || parsed.length === 0) return VB.seedReservations();
    return parsed.map(r => ({
      ...r,
      start: VB.fromISO(r.start),
      end: VB.fromISO(r.end),
      createdAt: new Date(r.createdAt),
      acceptedTermsAt: r.acceptedTermsAt ? new Date(r.acceptedTermsAt) : null,
      paidAt: r.paidAt ? new Date(r.paidAt) : null,
      cancelledAt: r.cancelledAt ? new Date(r.cancelledAt) : null
    }));
  } catch (e) {
    return VB.seedReservations();
  }
};

VB.reservationById = id => VB.state.reservations.find(r => r.id === id);

/** Retire une réservation. Réservé aux réservations déjà annulées : une
    réservation payée passe par l'annulation, qui applique frais et avoir. */
VB.removeReservation = id => {
  VB.state.reservations = VB.state.reservations.filter(r => r.id !== id);
  VB.saveReservations();
};

/* ---------- Factures ---------- */

VB.saveInvoices = () => {
  try {
    localStorage.setItem(VB.INVOICE_STORAGE_KEY, JSON.stringify(
      VB.state.invoices.map(i => ({ ...i, issuedAt: i.issuedAt.toISOString() }))
    ));
  } catch (e) { /* stockage indisponible */ }
};

VB.loadInvoices = () => {
  try {
    const raw = localStorage.getItem(VB.INVOICE_STORAGE_KEY);
    if (!raw) return [];
    return (JSON.parse(raw) || []).map(i => ({ ...i, issuedAt: new Date(i.issuedAt) }));
  } catch (e) { return []; }
};

/* ---------- Démo ---------- */

VB.resetDemo = () => {
  try {
    localStorage.removeItem(VB.ACCOUNTS_KEY);
    localStorage.removeItem(VB.SESSION_KEY);
  } catch (e) { /* stockage indisponible */ }
  VB.state.reservations = VB.seedReservations();
  VB.state.invoices = [];
  try { localStorage.removeItem(VB.INVOICE_COUNTER_KEY); } catch (e) { /* stockage indisponible */ }
  VB.saveInvoices();
  // Facture rétroactivement les réservations de démonstration déjà payées.
  VB.state.reservations.forEach(r => { r.invoiceNumber = VB.issueInvoice(r, r.paymentMethod).number; });
  VB.saveReservations();
  VB.navigate({ name: 'home' });
};

VB.bootstrapData = () => {
  VB.state.reservations = VB.loadReservations();
  // Réservations d'avant l'introduction des comptes : elles restent anonymes.
  VB.state.reservations.forEach(r => { if (r.accountId === undefined) r.accountId = null; });
  VB.state.invoices = VB.loadInvoices();
  if (VB.state.invoices.length === 0) {
    VB.state.reservations.forEach(r => {
      if (r.paymentStatus === 'paid' && !r.invoiceNumber) {
        r.invoiceNumber = VB.issueInvoice(r, r.paymentMethod).number;
      }
    });
    VB.saveReservations();
  }
};
