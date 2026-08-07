/* Logique métier : dates, disponibilité, tarifs, annulation, facturation.
   Miroir de CancellationPolicy.swift, ReservationStore.swift et InvoiceStore.swift. */

window.VB = window.VB || {};

/* ---------- Dates ---------- */

VB.startOfDay = d => { const x = new Date(d); x.setHours(0, 0, 0, 0); return x; };
VB.addDays = (d, n) => { const x = VB.startOfDay(d); x.setDate(x.getDate() + n); return x; };
VB.sameDay = (a, b) => VB.startOfDay(a).getTime() === VB.startOfDay(b).getTime();

VB.toISO = d => {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
};
VB.fromISO = iso => { const [y, m, d] = iso.split('-').map(Number); return new Date(y, m - 1, d); };

VB.capitalize = s => s.charAt(0).toUpperCase() + s.slice(1);
VB.formatShort = d => VB.capitalize(new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short' }).format(d));
VB.formatLong = d => new Intl.DateTimeFormat('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' }).format(d);
VB.formatDate = d => new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }).format(d);
VB.formatEUR = n => n.toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' });
VB.round2 = n => Math.round(n * 100) / 100;

/* ---------- Disponibilité ---------- */

VB.reservedQuantity = day => {
  const d = VB.startOfDay(day).getTime();
  return VB.state.reservations
    .filter(r => r.status !== 'cancelled')
    .filter(r => VB.startOfDay(r.start).getTime() <= d && d <= VB.startOfDay(r.end).getTime())
    .reduce((sum, r) => sum + r.quantity, 0);
};

VB.availableOn = day => Math.max(0, VB.BIKE.totalUnits - VB.reservedQuantity(day));

/** Disponibilité minimale sur la période : le jour le plus chargé fait foi. */
VB.availableRange = (start, end) => {
  let d = VB.startOfDay(start);
  const last = VB.startOfDay(end);
  if (d > last) return VB.availableOn(d);
  let min = Infinity;
  while (d <= last) {
    min = Math.min(min, VB.availableOn(d));
    d = VB.addDays(d, 1);
  }
  return min;
};

VB.levelFor = (n, total) => (n <= 0 ? 'full' : n < total ? 'limited' : 'good');

/* ---------- Annulation ----------
   > 2 jours avant le départ : sans frais.
   De 2 jours au jour du départ : 50 % retenus.
   Location déjà commencée : aucun remboursement. */

VB.CANCELLATION = { feeWindowDays: 2 };

VB.daysUntilStart = startDate =>
  Math.round((VB.startOfDay(startDate).getTime() - VB.startOfDay(new Date()).getTime()) / 86400000);

VB.hasStarted = startDate => VB.daysUntilStart(startDate) < 0;

VB.cancellationTier = startDate => {
  const d = VB.daysUntilStart(startDate);
  if (d < 0) return 'started';
  if (d <= VB.CANCELLATION.feeWindowDays) return 'partial';
  return 'free';
};

VB.tierRatio = tier => (tier === 'started' ? 1 : tier === 'partial' ? 0.5 : 0);
VB.incursCancellationFee = startDate => VB.cancellationTier(startDate) !== 'free';
VB.cancellationFee = (amount, startDate) => VB.round2(amount * VB.tierRatio(VB.cancellationTier(startDate)));
VB.cancellationRefund = (amount, startDate) => VB.round2(amount - VB.cancellationFee(amount, startDate));

VB.cancellationNoticeTitle = startDate => {
  const d = VB.daysUntilStart(startDate);
  switch (VB.cancellationTier(startDate)) {
    case 'started': return 'Location en cours';
    case 'partial': return d <= 0 ? 'Votre location débute aujourd’hui' : `Départ dans ${d} jour${d > 1 ? 's' : ''}`;
    default: return `Départ dans ${d} jours`;
  }
};

VB.cancellationNoticeBody = (amount, startDate) => {
  switch (VB.cancellationTier(startDate)) {
    case 'started':
      return "La location a commencé : elle ne peut plus être remboursée. Une annulation ne donnera lieu à aucun remboursement.";
    case 'partial':
      return `Vous êtes dans la période de frais d'annulation : toute annulation entraîne une retenue de 50 %, soit ${VB.formatEUR(VB.cancellationFee(amount, startDate))}.`;
    default:
      return "L'annulation est encore sans frais.";
  }
};

VB.cancellationWarning = (amount, startDate) => {
  const d = VB.daysUntilStart(startDate);
  const fee = VB.cancellationFee(amount, startDate);
  const refund = VB.cancellationRefund(amount, startDate);
  switch (VB.cancellationTier(startDate)) {
    case 'started':
      return `Votre location a déjà commencé : elle ne peut pas être remboursée. En confirmant, la réservation sera annulée et aucun remboursement ne sera effectué (${VB.formatEUR(amount)} restent dus).`;
    case 'partial': {
      const delay = d <= 0 ? 'Votre location débute aujourd’hui' : `Votre location débute dans ${d} jour${d > 1 ? 's' : ''}`;
      return `${delay}. À moins de ${VB.CANCELLATION.feeWindowDays} jours du départ, des frais d'annulation de 50 % s'appliquent : ${VB.formatEUR(fee)} seront retenus et ${VB.formatEUR(refund)} vous seront remboursés.`;
    }
    default:
      return `Votre location débute dans ${d} jours. L'annulation est sans frais : vous serez remboursé de ${VB.formatEUR(amount)}.`;
  }
};

VB.cancellationResultMessage = (fee, refund, creditNoteNumber) => {
  if (refund <= 0) {
    return "Votre réservation est annulée. La location ayant déjà commencé, aucun remboursement n'est effectué.";
  }
  const avoir = creditNoteNumber ? ` L'avoir ${creditNoteNumber} est disponible dans le détail de la réservation.` : '';
  return fee > 0
    ? `Votre réservation est annulée. ${VB.formatEUR(fee)} ont été retenus au titre des frais d'annulation ; ${VB.formatEUR(refund)} vous sont remboursés.${avoir}`
    : `Votre réservation est annulée et intégralement remboursée (${VB.formatEUR(refund)}).${avoir}`;
};

/* ---------- Validation ---------- */

VB.isValidEmail = email =>
  /^[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*\.[A-Za-z]{2,}$/
    .test(email.trim());

VB.isValidPhone = (countryCode, rawNumber) => {
  const digits = rawNumber.replace(/[\s.\-()]/g, '');
  if (!/^\d+$/.test(digits)) return false;
  if (countryCode === VB.DEFAULT_COUNTRY_CODE) {
    return (digits.length === 10 && digits.startsWith('0')) || digits.length === 9;
  }
  return digits.length >= 6 && digits.length <= 14;
};

VB.joinFr = items => {
  if (items.length === 0) return '';
  if (items.length === 1) return items[0];
  return items.slice(0, -1).join(', ') + ' et ' + items[items.length - 1];
};

/* ---------- Facturation ----------
   Numérotation séquentielle, chronologique et sans rupture, par type et par année. */

VB.nextInvoiceNumber = kind => {
  const prefix = kind === 'creditNote' ? 'AV' : 'FA';
  const year = new Date().getFullYear();
  const key = `${prefix}-${year}`;
  let counters = {};
  try { counters = JSON.parse(localStorage.getItem(VB.INVOICE_COUNTER_KEY)) || {}; } catch (e) { counters = {}; }
  const next = (counters[key] || 0) + 1;
  counters[key] = next;
  try { localStorage.setItem(VB.INVOICE_COUNTER_KEY, JSON.stringify(counters)); } catch (e) { /* stockage indisponible */ }
  return `${prefix}-${year}-${String(next).padStart(4, '0')}`;
};

VB.invoiceTotal = inv => VB.round2(inv.lines.reduce((sum, l) => sum + l.unitPrice * l.quantity, 0));

VB.invoicesFor = reservationId =>
  VB.state.invoices.filter(i => i.reservationId === reservationId).sort((a, b) => a.issuedAt - b.issuedAt);

VB.issueInvoice = (reservation, method) => {
  const lines = [{
    label: `Location ${VB.BIKE.name} — ${reservation.pricingLabel}`,
    quantity: reservation.quantity,
    unitPrice: reservation.pricePerUnit
  }];
  if (reservation.includesDelivery) {
    lines.push({ label: 'Livraison à domicile', quantity: 1, unitPrice: reservation.deliveryFee });
  }
  const invoice = {
    id: 'i-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
    number: VB.nextInvoiceNumber('invoice'),
    kind: 'invoice',
    issuedAt: new Date(),
    reservationId: reservation.id,
    customerName: `${reservation.firstName} ${reservation.lastName}`,
    customerEmail: reservation.email,
    lines,
    relatedInvoiceNumber: null,
    paymentMethodLabel: method === 'applePay' ? 'Apple Pay' : 'Carte bancaire'
  };
  VB.state.invoices.push(invoice);
  VB.saveInvoices();
  return invoice;
};

VB.issueCreditNote = (reservation, refundAmount, feeAmount) => {
  const lines = [{
    label: 'Remboursement — annulation de la réservation',
    quantity: 1,
    unitPrice: refundAmount
  }];
  if (feeAmount > 0) {
    lines.push({
      label: `Frais d'annulation retenus (50 %, annulation à moins de ${VB.CANCELLATION.feeWindowDays} jours) : ${VB.formatEUR(feeAmount)} — non remboursés`,
      quantity: 0,
      unitPrice: 0
    });
  }
  const creditNote = {
    id: 'i-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
    number: VB.nextInvoiceNumber('creditNote'),
    kind: 'creditNote',
    issuedAt: new Date(),
    reservationId: reservation.id,
    customerName: `${reservation.firstName} ${reservation.lastName}`,
    customerEmail: reservation.email,
    lines,
    relatedInvoiceNumber: reservation.invoiceNumber || null,
    paymentMethodLabel: null
  };
  VB.state.invoices.push(creditNote);
  VB.saveInvoices();
  return creditNote;
};

/* ---------- Paiement ----------
   ⚠️ SIMULÉ : n'encaisse aucun argent réel. Voir web/README.md pour ce
   qu'implique le branchement d'un vrai prestataire. */

VB.chargePayment = (amount, method) => new Promise(resolve => {
  setTimeout(() => resolve({
    method,
    amount,
    transactionReference: 'SIMU-' + Math.random().toString(36).slice(2, 10).toUpperCase(),
    processedAt: new Date()
  }), 900);
});
