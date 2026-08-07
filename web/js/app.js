/* Routeur, brouillon de réservation et gestion des évènements. */

window.VB = window.VB || {};

/* ---------- Brouillon ---------- */

VB.newDraft = () => ({
  start: VB.addDays(new Date(), 1),
  end: VB.addDays(new Date(), 2),
  visibleMonth: VB.startOfDay(new Date()),
  selectingEnd: false,
  quantity: 1,
  pricingOptionId: VB.BIKE.pricingOptions[0].id,
  includesDelivery: false,
  firstName: '', lastName: '', countryCode: VB.DEFAULT_COUNTRY_CODE,
  phone: '', email: '', notes: '',
  acceptedTerms: false
});

VB.draft = null;
VB.currentOption = d => VB.BIKE.pricingOptions.find(o => o.id === d.pricingOptionId) || VB.BIKE.pricingOptions[0];
VB.computeTotal = d => VB.round2(VB.currentOption(d).price * d.quantity + (d.includesDelivery ? VB.BIKE.deliveryFee : 0));
VB.clampQuantity = d => {
  const avail = VB.availableRange(d.start, d.end);
  d.quantity = avail > 0 ? Math.min(d.quantity, avail) : 1;
};

/* ---------- Routage ---------- */

VB.navigate = route => {
  VB.state.route = route;
  VB.render();
  window.scrollTo({ top: 0, behavior: 'instant' in window ? 'instant' : 'auto' });
};

VB.render = () => {
  const root = document.getElementById('app');
  const r = VB.state.route;

  switch (r.name) {
    case 'catalog': root.innerHTML = VB.viewCatalog(); break;
    case 'bike': root.innerHTML = VB.viewBike(); break;
    case 'booking': root.innerHTML = VB.viewBooking(VB.draft); break;
    case 'checkout': root.innerHTML = VB.viewCheckout(VB.draft); break;
    case 'confirmation': root.innerHTML = VB.viewConfirmation(r.reservation, r.invoice); break;
    case 'reservations': root.innerHTML = VB.viewReservations(); break;
    case 'reservation': root.innerHTML = VB.viewReservationDetail(r.id); break;
    case 'invoice': root.innerHTML = VB.viewInvoice(r.id); break;
    case 'legal': root.innerHTML = VB.viewLegalIndex(); break;
    case 'legalDoc': root.innerHTML = VB.viewLegalDoc(r.id); break;
    default: root.innerHTML = VB.viewCatalog();
  }

  // Onglet actif : les écrans enfants restent rattachés à leur section.
  const section =
    ['catalog', 'bike', 'booking', 'checkout', 'confirmation'].includes(r.name) ? 'catalog'
    : ['reservations', 'reservation', 'invoice'].includes(r.name) ? 'reservations'
    : 'legal';
  document.querySelectorAll('.nav-link').forEach(btn => {
    if (btn.dataset.nav === section) btn.setAttribute('aria-current', 'page');
    else btn.removeAttribute('aria-current');
  });

  if (r.name === 'checkout') VB.refreshCardButton();
};

/* ---------- Validation du formulaire ---------- */

VB.FIELD_IDS = {
  firstName: 'fieldFirstName', lastName: 'fieldLastName',
  phone: 'fieldPhone', email: 'fieldEmail', terms: 'consentRow'
};

VB.validationProblems = () => {
  const d = VB.draft;
  const problems = [];
  if (!d.firstName.trim()) problems.push('firstName');
  if (!d.lastName.trim()) problems.push('lastName');
  if (!VB.isValidPhone(d.countryCode, d.phone)) problems.push('phone');
  if (!VB.isValidEmail(d.email)) problems.push('email');
  const avail = VB.availableRange(d.start, d.end);
  if (avail <= 0 || d.quantity > avail) problems.push('availability');
  if (!d.acceptedTerms) problems.push('terms');
  return problems;
};

VB.alertMessage = problems => {
  const missing = [];
  if (problems.includes('firstName')) missing.push('votre prénom');
  if (problems.includes('lastName')) missing.push('votre nom');
  if (problems.includes('phone')) missing.push('un numéro de téléphone valide');
  if (problems.includes('email')) missing.push('une adresse e-mail valide');
  let msg = '';
  if (missing.length) msg += `Merci de renseigner ${VB.joinFr(missing)}.`;
  if (problems.includes('availability')) {
    if (msg) msg += ' ';
    msg += "Il ne reste pas assez de vélos disponibles sur la période choisie : ajustez les dates ou la quantité.";
  }
  if (problems.includes('terms')) {
    if (msg) msg += ' ';
    msg += "Merci d'accepter les conditions générales de location.";
  }
  return msg;
};

VB.showFormAlert = problems => {
  const el = document.getElementById('formAlert');
  if (!el) return;
  el.textContent = '⚠ ' + VB.alertMessage(problems);
  el.classList.add('visible');
  Object.entries(VB.FIELD_IDS).forEach(([key, id]) => {
    document.getElementById(id)?.classList.toggle('field-error', problems.includes(key));
  });
  el.scrollIntoView({ behavior: 'smooth', block: 'center' });
};

VB.hideFormAlert = () => {
  const el = document.getElementById('formAlert');
  if (!el) return;
  el.classList.remove('visible');
  Object.values(VB.FIELD_IDS).forEach(id => document.getElementById(id)?.classList.remove('field-error'));
};

VB.refreshValidation = () => {
  const el = document.getElementById('formAlert');
  if (!el || !el.classList.contains('visible')) return; // ne réagit qu'après une tentative
  const problems = VB.validationProblems();
  if (problems.length === 0) VB.hideFormAlert(); else VB.showFormAlert(problems);
};

/* ---------- Rafraîchissements partiels ---------- */

VB.refreshCalendar = () => {
  const el = document.getElementById('calendar');
  if (el) el.innerHTML = VB.renderCalendar(VB.draft);
};
VB.refreshSummary = () => {
  const el = document.getElementById('summary');
  if (el) el.innerHTML = VB.renderSummary(VB.draft);
};
VB.refreshStepper = () => {
  const el = document.getElementById('stepper');
  if (el) el.innerHTML = VB.renderStepper(VB.draft);
  const warn = document.getElementById('stepperWarning');
  if (warn) warn.style.display = VB.availableRange(VB.draft.start, VB.draft.end) > 0 ? 'none' : '';
};

/* ---------- Boîte de dialogue ---------- */

VB.openDialog = ({ title, message, confirmLabel, cancelLabel, danger, onConfirm }) => {
  const backdrop = document.getElementById('dialogBackdrop');
  document.getElementById('dialogTitle').textContent = title;
  document.getElementById('dialogMessage').textContent = message;
  const confirmBtn = document.getElementById('dialogConfirm');
  confirmBtn.textContent = confirmLabel;
  confirmBtn.className = 'btn ' + (danger ? 'btn-danger' : 'btn-primary');
  confirmBtn.onclick = onConfirm;
  document.getElementById('dialogCancel').textContent = cancelLabel;
  backdrop.classList.add('open');
  confirmBtn.focus();
};

VB.closeDialog = () => document.getElementById('dialogBackdrop').classList.remove('open');

VB.notify = message => VB.openDialog({
  title: 'Réservation annulée',
  message,
  confirmLabel: 'OK',
  cancelLabel: 'Fermer',
  danger: false,
  onConfirm: () => VB.closeDialog()
});

/* ---------- Annulation ---------- */

VB.askCancel = id => {
  const r = VB.reservationById(id);
  if (!r) return;
  VB.openDialog({
    title: 'Annuler cette réservation ?',
    message: VB.cancellationWarning(r.totalPrice, r.start),
    confirmLabel: "Confirmer l'annulation",
    cancelLabel: 'Conserver ma réservation',
    danger: true,
    onConfirm: () => VB.doCancel(id)
  });
};

VB.doCancel = id => {
  VB.closeDialog();
  const r = VB.reservationById(id);
  if (!r) return;

  const fee = VB.cancellationFee(r.totalPrice, r.start);
  const refund = VB.cancellationRefund(r.totalPrice, r.start);
  // Rien à rembourser (location commencée) : pas d'avoir à émettre.
  const creditNote = refund > 0 ? VB.issueCreditNote(r, refund, fee) : null;

  r.status = 'cancelled';
  r.cancelledAt = new Date();
  r.cancellationFee = fee;
  r.refundedAmount = refund;
  r.creditNoteNumber = creditNote ? creditNote.number : null;
  if (r.paymentStatus === 'paid') r.paymentStatus = 'refunded';
  VB.saveReservations();
  VB.render();
  VB.notify(VB.cancellationResultMessage(fee, refund, creditNote ? creditNote.number : null));
};

VB.askRemove = id => VB.openDialog({
  title: 'Retirer cette réservation ?',
  message: 'La réservation disparaîtra de cette liste. Les factures et avoirs déjà émis sont conservés.',
  confirmLabel: 'Retirer',
  cancelLabel: 'Conserver',
  danger: true,
  onConfirm: () => {
    VB.closeDialog();
    VB.removeReservation(id);
    VB.navigate({ name: 'reservations' });
  }
});

/* ---------- Paiement ---------- */

VB.isCardFormValid = () => {
  const digits = id => (document.getElementById(id)?.value || '').replace(/\D/g, '');
  return digits('cardNumber').length >= 13
    && digits('cardExpiry').length === 4
    && [3, 4].includes(digits('cardCVC').length);
};

VB.refreshCardButton = () => {
  const btn = document.getElementById('payCardBtn');
  if (btn) btn.disabled = !VB.isCardFormValid();
};

VB.pay = async method => {
  if (method === 'card' && !VB.isCardFormValid()) return;

  const applePayBtn = document.getElementById('applePayBtn');
  const cardBtn = document.getElementById('payCardBtn');
  [applePayBtn, cardBtn].forEach(b => { if (b) b.disabled = true; });
  if (method === 'applePay' && applePayBtn) applePayBtn.innerHTML = '<span class="spinner"></span>';
  else if (cardBtn) cardBtn.textContent = 'Paiement en cours…';

  const result = await VB.chargePayment(VB.computeTotal(VB.draft), method);
  const d = VB.draft;
  const option = VB.currentOption(d);

  const reservation = {
    id: 'r-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
    start: d.start, end: d.end, quantity: d.quantity,
    pricingLabel: option.label, pricePerUnit: option.price,
    includesDelivery: d.includesDelivery, deliveryFee: VB.BIKE.deliveryFee,
    totalPrice: VB.computeTotal(d),
    firstName: d.firstName.trim(), lastName: d.lastName.trim().toUpperCase(),
    countryCode: d.countryCode, phone: d.phone.trim(), email: d.email.trim(),
    notes: d.notes.trim(),
    createdAt: new Date(), acceptedTermsAt: new Date(),
    status: 'confirmed', paymentStatus: 'paid', paymentMethod: method,
    paymentReference: result.transactionReference, paidAt: result.processedAt,
    invoiceNumber: null,
    cancelledAt: null, cancellationFee: null, refundedAmount: null, creditNoteNumber: null
  };

  const invoice = VB.issueInvoice(reservation, method);
  reservation.invoiceNumber = invoice.number;
  VB.state.reservations.push(reservation);
  VB.saveReservations();
  VB.navigate({ name: 'confirmation', reservation, invoice });
};

/* ---------- Thème ---------- */

VB.THEME_KEY = 'velobriere-web-theme';

VB.applyTheme = theme => {
  if (theme === 'light' || theme === 'dark') document.documentElement.setAttribute('data-theme', theme);
  else document.documentElement.removeAttribute('data-theme');
  const btn = document.getElementById('themeToggle');
  if (btn) {
    const isDark = theme === 'dark'
      || (!theme && window.matchMedia('(prefers-color-scheme: dark)').matches);
    btn.textContent = isDark ? '☀' : '☾';
    btn.setAttribute('aria-label', isDark ? 'Passer en thème clair' : 'Passer en thème sombre');
  }
};

VB.toggleTheme = () => {
  const current = document.documentElement.getAttribute('data-theme');
  const isDark = current === 'dark'
    || (!current && window.matchMedia('(prefers-color-scheme: dark)').matches);
  const next = isDark ? 'light' : 'dark';
  try { localStorage.setItem(VB.THEME_KEY, next); } catch (e) { /* stockage indisponible */ }
  VB.applyTheme(next);
};

/* ---------- Évènements (délégation) ---------- */

VB.bindEvents = () => {
  document.addEventListener('click', e => {
    const t = e.target.closest('[data-action], [data-nav], [data-legal], [data-reservation], [data-invoice], [data-cancel], [data-remove], [data-option], [data-day], [data-month], [data-qty], [data-pay]');
    if (!t) return;

    // Navigation principale
    if (t.dataset.nav) {
      const map = { catalog: { name: 'catalog' }, reservations: { name: 'reservations' }, legal: { name: 'legal' } };
      return VB.navigate(map[t.dataset.nav]);
    }

    switch (t.dataset.action) {
      case 'open-bike': return VB.navigate({ name: 'bike' });
      case 'go-catalog': return VB.navigate({ name: 'catalog' });
      case 'go-reservations': return VB.navigate({ name: 'reservations' });
      case 'go-legal': return VB.navigate({ name: 'legal' });
      case 'start-booking':
        VB.draft = VB.newDraft();
        VB.clampQuantity(VB.draft);
        return VB.navigate({ name: 'booking' });
      case 'back-to-booking': return VB.navigate({ name: 'booking' });
      case 'back-to-reservation': return VB.navigate({ name: 'reservation', id: t.dataset.reservation });
      case 'go-checkout': {
        const problems = VB.validationProblems();
        if (problems.length) return VB.showFormAlert(problems);
        VB.hideFormAlert();
        return VB.navigate({ name: 'checkout' });
      }
    }

    if (t.dataset.legal) return VB.navigate({ name: 'legalDoc', id: t.dataset.legal });
    if (t.dataset.reservation && !t.dataset.action) return VB.navigate({ name: 'reservation', id: t.dataset.reservation });
    if (t.dataset.invoice) return VB.navigate({ name: 'invoice', id: t.dataset.invoice });
    if (t.dataset.cancel) return VB.askCancel(t.dataset.cancel);
    if (t.dataset.remove) return VB.askRemove(t.dataset.remove);
    if (t.dataset.pay) return VB.pay(t.dataset.pay);

    // Formulaire de réservation
    if (t.dataset.option) {
      VB.draft.pricingOptionId = t.dataset.option;
      document.querySelectorAll('[data-option]').forEach(b =>
        b.setAttribute('aria-pressed', b.dataset.option === t.dataset.option));
      VB.refreshSummary();
      return VB.refreshValidation();
    }
    if (t.dataset.month) {
      const delta = Number(t.dataset.month);
      VB.draft.visibleMonth = new Date(VB.draft.visibleMonth.getFullYear(), VB.draft.visibleMonth.getMonth() + delta, 1);
      return VB.refreshCalendar();
    }
    if (t.dataset.day) {
      const day = VB.fromISO(t.dataset.day);
      const d = VB.draft;
      if (d.selectingEnd && day >= VB.startOfDay(d.start)) { d.end = day; d.selectingEnd = false; }
      else { d.start = day; d.end = day; d.selectingEnd = true; }
      VB.clampQuantity(d);
      VB.refreshCalendar(); VB.refreshStepper(); VB.refreshSummary();
      return VB.refreshValidation();
    }
    if (t.dataset.qty) {
      const d = VB.draft;
      const max = Math.max(1, VB.availableRange(d.start, d.end));
      d.quantity = Math.min(max, Math.max(1, d.quantity + Number(t.dataset.qty)));
      VB.refreshStepper(); VB.refreshSummary();
      return VB.refreshValidation();
    }
  });

  // Saisie
  document.addEventListener('input', e => {
    const id = e.target.id;
    if (!VB.draft && !['cardNumber', 'cardExpiry', 'cardCVC'].includes(id)) return;

    switch (id) {
      case 'fieldFirstName': VB.draft.firstName = e.target.value; break;
      case 'fieldLastName': VB.draft.lastName = e.target.value.toUpperCase(); break;
      case 'fieldPhone': VB.draft.phone = e.target.value; break;
      case 'fieldEmail': VB.draft.email = e.target.value; break;
      case 'fieldNotes': VB.draft.notes = e.target.value; return;
      case 'cardNumber': case 'cardExpiry': case 'cardCVC': return VB.refreshCardButton();
      default: return;
    }
    VB.refreshValidation();
  });

  document.addEventListener('change', e => {
    if (!VB.draft) return;
    if (e.target.id === 'fieldCountryCode') { VB.draft.countryCode = e.target.value; VB.refreshValidation(); }
    if (e.target.id === 'fieldDelivery') { VB.draft.includesDelivery = e.target.checked; VB.refreshSummary(); VB.refreshValidation(); }
    if (e.target.id === 'fieldTerms') { VB.draft.acceptedTerms = e.target.checked; VB.refreshValidation(); }
  });

  document.getElementById('dialogCancel').addEventListener('click', VB.closeDialog);
  document.getElementById('dialogBackdrop').addEventListener('click', e => {
    if (e.target.id === 'dialogBackdrop') VB.closeDialog();
  });
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') VB.closeDialog();
  });

  document.getElementById('themeToggle').addEventListener('click', VB.toggleTheme);
  document.getElementById('demoReset').addEventListener('click', VB.resetDemo);
};

/* ---------- Démarrage ---------- */

VB.boot = () => {
  let stored = null;
  try { stored = localStorage.getItem(VB.THEME_KEY); } catch (e) { /* stockage indisponible */ }
  VB.applyTheme(stored);
  VB.bootstrapData();
  VB.bindEvents();
  VB.render();
};

document.addEventListener('DOMContentLoaded', VB.boot);
