/* Routeur, brouillon de réservation et gestion des évènements. */

window.VB = window.VB || {};

/* ---------- Brouillon ---------- */

VB.newDraft = () => {
  const account = VB.Accounts.current();
  return {
    start: VB.addDays(new Date(), 1),
    end: VB.addDays(new Date(), 2),
    visibleMonth: VB.startOfDay(new Date()),
    selectingEnd: false,
    quantity: 1,
    variantId: VB.selectedVariantId || VB.BIKE.variants[0].id,
    pricingOptionId: VB.BIKE.pricingOptions[0].id,
    includesDelivery: false,
    firstName: account ? account.firstName : '',
    lastName: account ? account.lastName : '',
    countryCode: account ? account.countryCode : VB.DEFAULT_COUNTRY_CODE,
    phone: account ? account.phone : '',
    email: account ? account.email : '',
    notes: '',
    acceptedTerms: false
  };
};

VB.draft = null;
/** Taille retenue sur la fiche vélo, reprise à l'ouverture du formulaire. */
VB.selectedVariantId = VB.BIKE.variants[0].id;
VB.currentOption = d => VB.BIKE.pricingOptions.find(o => o.id === d.pricingOptionId) || VB.BIKE.pricingOptions[0];
VB.computeTotal = d => VB.round2(VB.currentOption(d).price * d.quantity + (d.includesDelivery ? VB.BIKE.deliveryFee : 0));
VB.clampQuantity = d => {
  const avail = VB.availableRange(d.start, d.end, d.variantId);
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
    case 'home': root.innerHTML = VB.viewHome(); break;
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
    case 'signin': root.innerHTML = VB.viewAuth('signin'); break;
    case 'signup': root.innerHTML = VB.viewAuth('signup'); break;
    case 'account': root.innerHTML = VB.viewAccount(); break;
    default: root.innerHTML = VB.viewCatalog();
  }

  // Onglet actif : les écrans enfants restent rattachés à leur section.
  const section =
    r.name === 'home' ? 'home'
    : ['catalog', 'bike', 'booking', 'checkout', 'confirmation'].includes(r.name) ? 'catalog'
    : ['reservations', 'reservation', 'invoice'].includes(r.name) ? 'reservations'
    : ['signin', 'signup', 'account'].includes(r.name) ? 'account'
    : 'legal';
  document.querySelectorAll('.nav-link').forEach(btn => {
    if (btn.dataset.nav === section) btn.setAttribute('aria-current', 'page');
    else btn.removeAttribute('aria-current');
  });

  VB.renderAuthNav();
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
  const avail = VB.availableRange(d.start, d.end, d.variantId);
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
  if (warn) warn.style.display = VB.availableRange(VB.draft.start, VB.draft.end, VB.draft.variantId) > 0 ? 'none' : '';
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

VB.doCancel = async id => {
  VB.closeDialog();
  const r = VB.reservationById(id);
  if (!r) return;

  // En mode Firebase, l'annulation rend les vélos au stock dans la même
  // transaction qui marque la réservation annulée. Si elle échoue, on
  // n'émet aucun avoir : mieux vaut ne rien faire qu'un remboursement
  // pour une réservation restée active côté serveur.
  if (VB.Remote?.active && VB.Accounts.currentId()) {
    try {
      await VB.Remote.cancelReservation(r);
    } catch (error) {
      VB.notify("Annulation impossible : " + (error?.message || 'réessayez dans un instant.'));
      return;
    }
  }

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
  if (VB.Remote?.active && VB.Accounts.currentId()) {
    // Le détail comptable de l'annulation (frais, avoir) rejoint le serveur.
    VB.Remote.updateReservation(r).catch(e => console.warn('[VB] Avoir non synchronisé :', e));
  }
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

  // Avant d'encaisser : le stock a pu changer depuis l'ouverture du
  // formulaire. Refuser ici coûte un message ; refuser après avoir encaissé
  // coûte un remboursement à faire à la main.
  const problem = VB.validateDraft(VB.draft);
  if (problem) {
    VB.showPaymentProblem(problem);
    return;
  }

  const applePayBtn = document.getElementById('applePayBtn');
  const cardBtn = document.getElementById('payCardBtn');
  // Les libellés sont dynamiques (« Payer 78,00 € ») : on les relève avant de
  // les remplacer, pour pouvoir les remettre tels quels en cas de refus.
  VB._payLabels = {
    applePay: applePayBtn?.innerHTML ?? null,
    card: cardBtn?.textContent ?? null
  };
  [applePayBtn, cardBtn].forEach(b => { if (b) b.disabled = true; });
  if (method === 'applePay' && applePayBtn) applePayBtn.innerHTML = '<span class="spinner"></span>';
  else if (cardBtn) cardBtn.textContent = 'Paiement en cours…';

  const result = await VB.chargePayment(VB.computeTotal(VB.draft), method);
  const d = VB.draft;
  const option = VB.currentOption(d);

  const reservation = {
    id: 'r-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
    start: d.start, end: d.end, quantity: d.quantity,
    variantId: d.variantId, variantLabel: VB.variantById(d.variantId).size,
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

  reservation.accountId = VB.Accounts.currentId();

  // Enregistrement. En mode Firebase, c'est la transaction qui fait autorité :
  // elle relit le stock au moment de l'écriture, donc deux réservations
  // simultanées ne peuvent pas passer toutes les deux. Le contrôle local
  // ci-dessous ne sert qu'à donner un message immédiat en mode hors-ligne.
  if (VB.Remote?.active && VB.Accounts.currentId()) {
    try {
      await VB.Remote.commitReservation(reservation);
    } catch (error) {
      VB.showPaymentProblem(
        (error?.message || 'Enregistrement impossible.')
        + " Aucune réservation n'a été enregistrée et aucune facture n'a été émise."
      );
      return;
    }
  } else {
    // Dernier contrôle, après l'attente du paiement : c'est pendant cette
    // attente que le stock peut avoir été pris. Aucune facture n'est émise si
    // la réservation n'est pas enregistrable.
    const lateProblem = VB.validateDraft(reservation);
    if (lateProblem) {
      VB.showPaymentProblem(
        lateProblem + " Aucune réservation n'a été enregistrée et aucune facture n'a été émise."
      );
      return;
    }
  }

  const invoice = VB.issueInvoice(reservation, method);
  reservation.invoiceNumber = invoice.number;
  VB.state.reservations.push(reservation);
  VB.saveReservations();
  // La réservation distante porte désormais le numéro de facture.
  if (VB.Remote?.active && VB.Accounts.currentId()) {
    VB.Remote.updateReservation(reservation).catch(e => console.warn('[VB] Facture non synchronisée :', e));
  }
  VB.navigate({ name: 'confirmation', reservation, invoice });
};

/** Affiche un refus au-dessus des boutons de paiement et les réactive. */
VB.showPaymentProblem = message => {
  const applePayBtn = document.getElementById('applePayBtn');
  const cardBtn = document.getElementById('payCardBtn');
  const labels = VB._payLabels || {};
  if (applePayBtn) {
    applePayBtn.disabled = false;
    if (labels.applePay != null) applePayBtn.innerHTML = labels.applePay;
  }
  if (cardBtn) {
    cardBtn.disabled = !VB.isCardFormValid();
    if (labels.card != null) cardBtn.textContent = labels.card;
  }

  let slot = document.getElementById('paymentProblem');
  if (!slot) {
    slot = document.createElement('div');
    slot.id = 'paymentProblem';
    slot.className = 'notice notice-warning';
    slot.setAttribute('role', 'alert');
    const anchor = cardBtn || applePayBtn;
    anchor?.parentNode?.insertBefore(slot, anchor);
  }
  slot.textContent = message;
  slot.scrollIntoView({ block: 'center', behavior: 'smooth' });
};


/* ---------- Comptes : en-tête et actions ---------- */

VB.renderAuthNav = () => {
  const slot = document.getElementById('authNav');
  if (!slot) return;
  const account = VB.Accounts.current();
  slot.innerHTML = account
    ? `<button class="nav-link account-chip" data-nav="account" type="button" title="${VB.esc(account.email)}">
         <span class="account-avatar" aria-hidden="true">${VB.esc(account.firstName.charAt(0).toUpperCase() || '?')}</span>
         <span class="account-chip-name">${VB.esc(account.firstName)}</span>
       </button>`
    : `<button class="nav-link" data-action="go-signin" type="button">Se connecter</button>`;
};

VB.showAuthError = message => {
  const el = document.getElementById('formAlert');
  if (!el) return;
  el.textContent = '⚠ ' + message;
  el.classList.add('visible');
  el.scrollIntoView({ behavior: 'smooth', block: 'center' });
};

VB.hideAuthError = () => document.getElementById('formAlert')?.classList.remove('visible');

VB.val = id => (document.getElementById(id)?.value || '');

VB.handleSignUp = async () => {
  VB.hideAuthError();
  const firstName = VB.val('authFirstName').trim();
  const lastName = VB.val('authLastName').trim();
  const email = VB.val('authEmail').trim();
  const countryCode = VB.val('authCountryCode') || VB.DEFAULT_COUNTRY_CODE;
  const phone = VB.val('authPhone').trim();
  const password = VB.val('authPassword');
  const password2 = VB.val('authPassword2');

  const missing = [];
  if (!firstName) missing.push('votre prénom');
  if (!lastName) missing.push('votre nom');
  if (!VB.isValidPhone(countryCode, phone)) missing.push('un numéro de téléphone valide');
  if (!VB.isValidEmail(email)) missing.push('une adresse e-mail valide');
  if (missing.length) return VB.showAuthError(`Merci de renseigner ${VB.joinFr(missing)}.`);

  const pwProblem = VB.passwordProblem(password);
  if (pwProblem) return VB.showAuthError(pwProblem);
  if (password !== password2) return VB.showAuthError('Les deux mots de passe ne correspondent pas.');

  const result = await VB.Accounts.signUp({ firstName, lastName, email, countryCode, phone, password });
  if (!result.ok) return VB.showAuthError(result.error);

  VB.Accounts.setSession(result.account.id);
  const claimed = VB.claimGuestReservations(result.account);
  VB.navigate({ name: 'reservations' });
  VB.openDialog({
    title: 'Compte créé',
    message: claimed > 0
      ? `Bienvenue ${result.account.firstName} ! ${claimed} réservation${claimed > 1 ? 's' : ''} faite${claimed > 1 ? 's' : ''} avec cette adresse e-mail ${claimed > 1 ? 'ont' : 'a'} été rattachée${claimed > 1 ? 's' : ''} à votre compte.`
      : `Bienvenue ${result.account.firstName} ! Vos prochaines réservations seront rattachées à ce compte.`,
    confirmLabel: 'OK', cancelLabel: 'Fermer', danger: false,
    onConfirm: () => VB.closeDialog()
  });
};

VB.handleSignIn = async () => {
  VB.hideAuthError();
  const email = VB.val('authEmail').trim();
  const password = VB.val('authPassword');
  if (!email || !password) return VB.showAuthError('Merci de renseigner votre adresse e-mail et votre mot de passe.');

  const result = await VB.Accounts.signIn(email, password);
  if (!result.ok) return VB.showAuthError(result.error);

  VB.Accounts.setSession(result.account.id);
  const claimed = VB.claimGuestReservations(result.account);
  VB.navigate({ name: 'reservations' });
  if (claimed > 0) {
    VB.openDialog({
      title: 'Réservations retrouvées',
      message: `${claimed} réservation${claimed > 1 ? 's' : ''} faite${claimed > 1 ? 's' : ''} sans compte avec cette adresse e-mail ${claimed > 1 ? 'ont' : 'a'} été rattachée${claimed > 1 ? 's' : ''} à votre compte.`,
      confirmLabel: 'OK', cancelLabel: 'Fermer', danger: false,
      onConfirm: () => VB.closeDialog()
    });
  }
};

VB.handleSignOut = () => VB.openDialog({
  title: 'Se déconnecter ?',
  message: "Vos réservations restent enregistrées et vous les retrouverez à la prochaine connexion sur ce navigateur.",
  confirmLabel: 'Se déconnecter',
  cancelLabel: 'Rester connecté',
  danger: true,
  onConfirm: () => {
    VB.closeDialog();
    VB.Accounts.clearSession();
    VB.navigate({ name: 'catalog' });
  }
});

VB.handleChangePassword = async () => {
  VB.hideAuthError();
  const account = VB.Accounts.current();
  if (!account) return;
  const current = VB.val('pwCurrent');
  const next = VB.val('pwNew');

  const pwProblem = VB.passwordProblem(next);
  if (pwProblem) return VB.showAuthError(pwProblem);

  const result = await VB.Accounts.changePassword(account.id, current, next);
  if (!result.ok) return VB.showAuthError(result.error);

  VB.render();
  VB.openDialog({
    title: 'Mot de passe mis à jour',
    message: 'Votre nouveau mot de passe est actif.',
    confirmLabel: 'OK', cancelLabel: 'Fermer', danger: false,
    onConfirm: () => VB.closeDialog()
  });
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
    const t = e.target.closest('[data-action], [data-nav], [data-legal], [data-reservation], [data-invoice], [data-cancel], [data-remove], [data-option], [data-day], [data-month], [data-qty], [data-pay], [data-auth], [data-variant]');
    if (!t) return;

    // Navigation principale
    if (t.dataset.nav) {
      const map = {
        home: { name: 'home' },
        catalog: { name: 'catalog' },
        reservations: { name: 'reservations' },
        legal: { name: 'legal' },
        account: VB.Accounts.currentId() ? { name: 'account' } : { name: 'signin' }
      };
      return VB.navigate(map[t.dataset.nav]);
    }

    switch (t.dataset.action) {
      case 'open-bike': return VB.navigate({ name: 'bike' });
      case 'go-catalog': return VB.navigate({ name: 'catalog' });
      case 'go-home': return VB.navigate({ name: 'home' });
      case 'go-reservations': return VB.navigate({ name: 'reservations' });
      case 'go-legal': return VB.navigate({ name: 'legal' });
      case 'go-signin': return VB.navigate({ name: 'signin' });
      case 'go-signup': return VB.navigate({ name: 'signup' });
      case 'go-account': return VB.navigate({ name: 'account' });
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
    if (t.dataset.auth) {
      switch (t.dataset.auth) {
        case 'signup': return VB.handleSignUp();
        case 'signin': return VB.handleSignIn();
        case 'signout': return VB.handleSignOut();
        case 'change-password': return VB.handleChangePassword();
      }
    }

    // Choix de la taille : sur la fiche vélo (avant réservation) ou dans le formulaire
    if (t.dataset.variant) {
      VB.selectedVariantId = t.dataset.variant;
      if (VB.state.route.name === 'booking' && VB.draft) {
        VB.draft.variantId = t.dataset.variant;
        VB.clampQuantity(VB.draft);
        VB.render();          // le calendrier et les stocks changent de taille
      } else {
        VB.render();          // fiche vélo : photo et disponibilité suivent
      }
      return;
    }

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
      const max = Math.max(1, VB.availableRange(d.start, d.end, d.variantId));
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
    if (e.key === 'Enter' && e.target.matches('#authEmail, #authPassword, #authPassword2, #authFirstName, #authLastName, #authPhone')) {
      e.preventDefault();
      const btn = document.querySelector('[data-auth="signup"], [data-auth="signin"]');
      if (btn) btn.click();
    }
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

  // Sans `firebase-config.js` renseigné, cet appel ne télécharge rien et ne
  // change rien : le site reste en mode local. Voir SETUP-FIREBASE.md.
  VB.Remote?.init()
    .then(actif => {
      if (!actif) return;
      // La session Firebase est restaurée de façon asynchrone : au premier
      // rendu, personne n'est encore connecté. On réaffiche quand l'état
      // d'authentification arrive, puis à chaque connexion ou déconnexion.
      VB.Remote.onAuthChanged(async user => {
        await VB.Accounts._onAuthChanged(user);

        if (user) {
          // À partir d'ici, le serveur fait autorité : les réservations
          // affichées sont celles du compte, vues depuis n'importe quel
          // appareil. C'est ce qui manquait pour que le client et le loueur
          // regardent la même chose.
          VB.Remote.watchReservations(list => {
            VB.state.reservations = list;
            VB.render();
          });
        } else {
          // Déconnecté : retour aux réservations de ce navigateur.
          VB.Remote.stopWatching();
          VB.state.reservations = VB.loadReservations();
        }
        VB.render();
      });
    })
    .catch(e => console.warn('[VB] Firebase indisponible :', e));
};

document.addEventListener('DOMContentLoaded', VB.boot);
