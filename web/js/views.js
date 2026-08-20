/* Rendu des écrans. Chaque vue renvoie du HTML ; les gestionnaires sont
   attachés après insertion (voir app.js). */

window.VB = window.VB || {};

VB.esc = s => String(s).replace(/[&<>"']/g, c =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

VB.docNeedsCompletion = doc => doc.sections.some(s => s.body.includes(VB.PLACEHOLDER_MARKER));

/* ---------- Catalogue ---------- */

VB.viewCatalog = () => {
  const bike = VB.BIKE;
  const avail = VB.availableOn(new Date());
  const level = VB.levelFor(avail, bike.totalUnits);
  const from = Math.min(...bike.pricingOptions.map(o => o.price));

  return `
    <div class="page-head">
      <p class="eyebrow">Location de vélos électriques</p>
      <h1>Réservez votre vélo</h1>
      <p class="lede">Balades électriques au cœur de la Brière, entre marais, villages et chemins.
      Casque et antivol inclus, livraison possible dans un rayon de ${bike.deliveryRadiusKm} km.</p>
    </div>

    <div class="catalog-grid">
      <button class="bike-card" data-action="open-bike">
        <img class="bike-thumb" src="${VB.BIKE.variants[0].image}" alt="${VB.esc(VB.BIKE.name)}" loading="lazy">
        <span class="eyebrow" style="margin:0;">${VB.esc(bike.brand)}</span>
        <span class="bike-name">${VB.esc(bike.name)}</span>
        <span class="bike-tagline">${VB.esc(bike.tagline)}</span>
        <span class="bike-sizes">${bike.variants.map(v => `${VB.esc(v.size)} · ${VB.esc(v.color)}`).join('  —  ')}</span>
        <span class="bike-meta">
          <span class="price">À partir de ${VB.formatEUR(from)}</span>
          <span class="avail-pill ${level}"><i></i>${avail}/${bike.totalUnits} disponibles</span>
        </span>
      </button>
    </div>
  `;
};

/* ---------- Fiche vélo ---------- */

VB.viewBike = () => {
  const bike = VB.BIKE;
  const variant = VB.variantById(VB.selectedVariantId);
  const avail = VB.availableOn(new Date(), variant.id);
  const level = VB.levelFor(avail, variant.units);

  return `
    <button class="back-link" data-action="go-catalog">‹ Tous les vélos</button>

    <div class="split">
      <div>
        <div class="hero-visual">
          <img src="${variant.image}" alt="${VB.esc(bike.name)} taille ${VB.esc(variant.size)}, ${VB.esc(variant.color)}">
        </div>

        <div class="size-picker" role="group" aria-label="Taille du vélo">
          ${bike.variants.map(v => {
            const a = VB.availableOn(new Date(), v.id);
            return `
            <button class="size-option" data-variant="${v.id}" aria-pressed="${v.id === variant.id}">
              <img src="${v.image}" alt="" loading="lazy">
              <span class="size-name">${VB.esc(v.size)}</span>
              <span class="size-color">${VB.esc(v.color)}</span>
              <span class="avail-pill ${VB.levelFor(a, v.units)}"><i></i>${a}/${v.units}</span>
            </button>`;
          }).join('')}
        </div>
        <p class="visual-note">Un doute sur la taille ? Appelez-nous au
          <a href="${VB.CONTACT.phoneHref}">${VB.esc(VB.CONTACT.phone)}</a>.</p>

        <div class="page-head" style="margin-top:26px;">
          <p class="eyebrow">${VB.esc(bike.brand)}</p>
          <h1>${VB.esc(bike.name)}</h1>
          <p class="lede">${VB.esc(bike.tagline)}</p>
          <p style="margin:12px 0 0;">
            <span class="avail-pill ${level}"><i></i>Taille ${VB.esc(variant.size)} — ${avail}/${variant.units} disponibles aujourd'hui</span>
          </p>
        </div>

        <div class="card">
          <p class="section-label">Points forts</p>
          <ul class="highlights">
            ${bike.highlights.map(h => `<li><span class="dot"></span>${VB.esc(h)}</li>`).join('')}
          </ul>
        </div>
      </div>

      <div class="split-sticky">
        <div class="card">
          <p class="section-label">Tarifs</p>
          ${bike.pricingOptions.map(o => `
            <div class="price-row">
              <span class="label">${VB.esc(o.label)}</span>
              <span class="amount">${VB.formatEUR(o.price)}</span>
            </div>`).join('')}
          <p class="fine-print">Casque et antivol inclus dans toutes les locations.<br>
          Livraison en option : +${VB.formatEUR(bike.deliveryFee)} (rayon ${bike.deliveryRadiusKm} km).</p>
          <button class="btn btn-primary btn-block" style="margin-top:18px;" data-action="start-booking">
            Réserver ce vélo
          </button>
          <p style="text-align:center; margin:12px 0 0;">
            <a href="${VB.esc(bike.productURL)}" target="_blank" rel="noopener" style="font-size:13px; font-weight:600;">
              Voir la fiche produit Decathlon ↗
            </a>
          </p>
        </div>
      </div>
    </div>
  `;
};

/* ---------- Calendrier ---------- */

VB.renderCalendar = draft => {
  const cal = draft.visibleMonth;
  const year = cal.getFullYear(), month = cal.getMonth();
  const first = new Date(year, month, 1);
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const leading = (first.getDay() + 6) % 7;
  const today = VB.startOfDay(new Date());
  const monthLabel = VB.capitalize(new Intl.DateTimeFormat('fr-FR', { month: 'long', year: 'numeric' }).format(cal));
  const canGoBack = !(cal.getFullYear() === today.getFullYear() && cal.getMonth() === today.getMonth());
  const start = VB.startOfDay(draft.start), end = VB.startOfDay(draft.end);

  let cells = '';
  for (let i = 0; i < leading; i++) cells += '<span class="day-cell empty"></span>';
  for (let d = 1; d <= daysInMonth; d++) {
    const date = new Date(year, month, d);
    const iso = VB.toISO(date);
    const isPast = date < today;
    const avail = VB.availableOn(date, draft.variantId);
    const isEdge = VB.sameDay(date, start) || VB.sameDay(date, end);
    const inRange = date >= start && date <= end;
    const level = VB.levelFor(avail, VB.unitsFor(draft.variantId));
    const disabled = isPast || avail <= 0;
    const classes = ['day-cell'];
    if (isPast) classes.push('past');
    if (isEdge) classes.push('edge'); else if (inRange) classes.push('in-range');
    const label = `${d} ${monthLabel} — ${isPast ? 'passé' : avail + ' vélo' + (avail > 1 ? 's' : '') + ' disponible' + (avail > 1 ? 's' : '')}`;
    cells += `
      <button type="button" class="${classes.join(' ')}" ${disabled ? 'disabled' : ''}
              data-day="${iso}" aria-label="${VB.esc(label)}">
        <span class="day-num">${d}</span>
        <span class="day-dot ${isPast ? '' : level}"></span>
      </button>`;
  }

  const rangeAvail = VB.availableRange(draft.start, draft.end, draft.variantId);
  const ok = rangeAvail > 0;
  const size = VB.variantById(draft.variantId).size;

  return `
    <div class="cal-head">
      <button type="button" class="cal-nav" data-month="-1" ${canGoBack ? '' : 'disabled'} aria-label="Mois précédent">‹</button>
      <span class="cal-month">${VB.esc(monthLabel)}</span>
      <button type="button" class="cal-nav" data-month="1" aria-label="Mois suivant">›</button>
    </div>
    <div class="cal-weekdays">${['L','M','M','J','V','S','D'].map(w => `<span>${w}</span>`).join('')}</div>
    <div class="cal-grid">${cells}</div>
    <div class="cal-legend">
      <span><i class="good"></i>Disponible</span>
      <span><i class="limited"></i>Places limitées</span>
      <span><i class="full"></i>Complet</span>
    </div>
    <p class="cal-summary ${ok ? 'ok' : 'ko'}">
      <span>${ok ? '✓' : '⚠'}</span>
      <span>${ok
        ? `${rangeAvail} vélo${rangeAvail > 1 ? 's' : ''} en ${VB.esc(size)} disponible${rangeAvail > 1 ? 's' : ''} sur la période choisie`
        : `Taille ${VB.esc(size)} complète sur une partie de cette période`}</span>
    </p>
  `;
};

/* ---------- Résumé tarifaire ---------- */

VB.renderSummary = draft => {
  const option = VB.currentOption(draft);
  const base = VB.round2(option.price * draft.quantity);
  const total = VB.computeTotal(draft);
  return `
    <div class="summary-line"><span>Taille ${VB.esc(VB.variantById(draft.variantId).size)}</span><span class="amt"></span></div>
    <div class="summary-line"><span>${VB.esc(option.label)} × ${draft.quantity}</span><span class="amt">${VB.formatEUR(base)}</span></div>
    ${draft.includesDelivery ? `<div class="summary-line"><span>Livraison</span><span class="amt">${VB.formatEUR(VB.BIKE.deliveryFee)}</span></div>` : ''}
    <div class="summary-total"><span>Total</span><span class="amt">${VB.formatEUR(total)}</span></div>
  `;
};

VB.renderStepper = draft => {
  const max = Math.max(1, VB.availableRange(draft.start, draft.end, draft.variantId));
  return `
    <button type="button" class="stepper-btn" data-qty="-1" ${draft.quantity <= 1 ? 'disabled' : ''} aria-label="Retirer un vélo">−</button>
    <span class="stepper-value">${draft.quantity}</span>
    <button type="button" class="stepper-btn" data-qty="1" ${draft.quantity >= max ? 'disabled' : ''} aria-label="Ajouter un vélo">+</button>
    <span class="stepper-label">vélo${draft.quantity > 1 ? 's' : ''}</span>
  `;
};

/* ---------- Réservation ---------- */

VB.viewBooking = draft => {
  const bike = VB.BIKE;
  const rangeAvail = VB.availableRange(draft.start, draft.end, draft.variantId);

  return `
    <button class="back-link" data-action="open-bike">‹ Retour au vélo</button>
    <div class="page-head">
      <h1>Réserver</h1>
      <p class="lede">${VB.esc(bike.name)} — choisissez vos dates, votre formule, puis réglez en ligne.</p>
    </div>

    <div id="formAlert" class="form-alert" role="alert"></div>

    <div class="split">
      <div class="stack">
        <div class="card">
          <p class="section-label">Taille</p>
          <div class="size-picker" id="sizePicker" role="group" aria-label="Taille du vélo">
            ${bike.variants.map(v => {
              const a = VB.availableRange(draft.start, draft.end, v.id);
              return `
              <button class="size-option" data-variant="${v.id}" aria-pressed="${v.id === draft.variantId}">
                <img src="${v.image}" alt="" loading="lazy">
                <span class="size-name">${VB.esc(v.size)}</span>
                <span class="size-color">${VB.esc(v.color)}</span>
                <span class="avail-pill ${VB.levelFor(a, v.units)}"><i></i>${a}/${v.units}</span>
              </button>`;
            }).join('')}
          </div>
        </div>

        <div class="card">
          <p class="section-label">Dates · taille ${VB.esc(VB.variantById(draft.variantId).size)}</p>
          <div id="calendar">${VB.renderCalendar(draft)}</div>
        </div>

        <div class="card">
          <p class="section-label">Formule</p>
          <div class="segmented" role="group" aria-label="Durée de location">
            ${bike.pricingOptions.map(o => `
              <button type="button" class="segment" data-option="${o.id}"
                      aria-pressed="${o.id === draft.pricingOptionId}">${VB.esc(o.label)}</button>`).join('')}
          </div>
          <label class="toggle-row">
            <input type="checkbox" id="fieldDelivery" ${draft.includesDelivery ? 'checked' : ''}>
            <span class="toggle-track"></span>
            <span class="toggle-label">Livraison à domicile (+${VB.formatEUR(bike.deliveryFee)} · rayon ${bike.deliveryRadiusKm} km)</span>
          </label>
        </div>

        <div class="card">
          <p class="section-label">Nombre de vélos</p>
          <div class="stepper" id="stepper">${VB.renderStepper(draft)}</div>
          <p class="fine-print" id="stepperWarning" style="${rangeAvail > 0 ? 'display:none' : 'color:var(--warning)'}">
            Complet sur cette période. Merci de choisir d'autres dates.
          </p>
        </div>

        <div class="card">
          <p class="section-label">Vos coordonnées</p>
          <div class="two-col">
            <div class="field-group">
              <label class="field-label" for="fieldFirstName">Prénom</label>
              <input class="field" id="fieldFirstName" autocomplete="given-name" value="${VB.esc(draft.firstName)}">
            </div>
            <div class="field-group">
              <label class="field-label" for="fieldLastName">Nom</label>
              <input class="field" id="fieldLastName" autocomplete="family-name" value="${VB.esc(draft.lastName)}">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label" for="fieldPhone">Téléphone</label>
            <div class="field-row">
              <select class="field" id="fieldCountryCode" aria-label="Indicatif pays">
                ${VB.COUNTRY_CODES.map(c => `<option value="${c.code}" ${c.code === draft.countryCode ? 'selected' : ''}>${c.flag} ${c.code}</option>`).join('')}
              </select>
              <input class="field" id="fieldPhone" type="tel" autocomplete="tel" value="${VB.esc(draft.phone)}">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label" for="fieldEmail">E-mail</label>
            <input class="field" id="fieldEmail" type="email" autocomplete="email" value="${VB.esc(draft.email)}">
          </div>
          <p class="fine-print">Ces informations servent uniquement à traiter votre réservation et à vous recontacter.
            Elles restent enregistrées dans votre navigateur.
            <button class="btn-link" data-legal="confidentialite">En savoir plus sur vos données</button>
          </p>
        </div>

        <div class="card">
          <p class="section-label">Remarques</p>
          <textarea class="field" id="fieldNotes" placeholder="Taille, itinéraire souhaité, horaire de retrait…">${VB.esc(draft.notes)}</textarea>
        </div>
      </div>

      <div class="split-sticky stack">
        <div class="card">
          <p class="section-label">Résumé</p>
          <div id="summary">${VB.renderSummary(draft)}</div>
        </div>

        <div class="card">
          <label class="consent-row" id="consentRow">
            <input type="checkbox" id="fieldTerms" ${draft.acceptedTerms ? 'checked' : ''}>
            <span class="consent-box">✓</span>
            <span class="consent-text">J'ai lu et j'accepte les conditions générales de location.</span>
          </label>
          <p style="margin:10px 0 0;">
            <button class="btn-link" data-legal="cgl">Lire les conditions générales de location</button>
          </p>
          <button class="btn btn-primary btn-block" style="margin-top:18px;" data-action="go-checkout">
            Continuer vers le paiement
          </button>
        </div>
      </div>
    </div>
  `;
};

/* ---------- Paiement ---------- */

VB.viewCheckout = draft => {
  const option = VB.currentOption(draft);
  const base = VB.round2(option.price * draft.quantity);
  const total = VB.computeTotal(draft);

  return `
    <button class="back-link" data-action="back-to-booking">‹ Modifier ma réservation</button>
    <div class="page-head">
      <h1>Paiement</h1>
      <p class="lede">Dernière étape : réglez votre location pour la confirmer.</p>
    </div>

    <div class="split">
      <div class="stack">
        <div class="notice notice-warning">
          <span aria-hidden="true">⚠</span>
          <span><strong>Paiement simulé</strong> — aucun montant n'est réellement débité.
          Le branchement d'un prestataire (Stripe, SumUp…) reste à faire.</span>
        </div>

        <div class="card">
          <p class="section-label">Moyen de paiement</p>
          <button class="applepay-btn" id="applePayBtn" data-pay="applePay">
            <span aria-hidden="true"></span><span>Pay</span>
          </button>

          <div class="pay-divider">ou payer par carte</div>

          <div class="field-group">
            <label class="field-label" for="cardNumber">Numéro de carte</label>
            <input class="field" id="cardNumber" inputmode="numeric" placeholder="1234 5678 9012 3456" autocomplete="off">
          </div>
          <div class="two-col">
            <div class="field-group">
              <label class="field-label" for="cardExpiry">Expiration</label>
              <input class="field" id="cardExpiry" inputmode="numeric" placeholder="MM/AA" autocomplete="off">
            </div>
            <div class="field-group">
              <label class="field-label" for="cardCVC">CVC</label>
              <input class="field" id="cardCVC" inputmode="numeric" placeholder="123" autocomplete="off">
            </div>
          </div>
          <button class="btn btn-primary btn-block" id="payCardBtn" style="margin-top:16px;" data-pay="card" disabled>
            Payer ${VB.formatEUR(total)}
          </button>
          <p class="fine-print">Aucune donnée de carte n'est transmise ni conservée : ce formulaire est une maquette.
          En production, la saisie doit être confiée au SDK du prestataire de paiement.</p>
        </div>
      </div>

      <div class="split-sticky">
        <div class="card">
          <p class="section-label">Votre commande</p>
          <div class="summary-line"><span>${VB.esc(VB.BIKE.name)} — taille ${VB.esc(VB.variantById(draft.variantId).size)}</span><span class="amt"></span></div>
          <div class="summary-line"><span>Du ${VB.formatShort(draft.start)} au ${VB.formatShort(draft.end)}</span><span class="amt"></span></div>
          <div class="summary-line"><span>${VB.esc(option.label)} × ${draft.quantity}</span><span class="amt">${VB.formatEUR(base)}</span></div>
          ${draft.includesDelivery ? `<div class="summary-line"><span>Livraison</span><span class="amt">${VB.formatEUR(VB.BIKE.deliveryFee)}</span></div>` : ''}
          <div class="summary-total"><span>Total à payer</span><span class="amt">${VB.formatEUR(total)}</span></div>
          <p class="fine-print">Le paiement vaut acceptation des conditions générales de location.
          En cas d'annulation à moins de ${VB.CANCELLATION.feeWindowDays} jours du départ, 50 % du montant est retenu ;
          une location commencée n'est pas remboursable.</p>
        </div>
      </div>
    </div>
  `;
};

/* ---------- Confirmation ---------- */

VB.viewConfirmation = (reservation, invoice) => `
  <div class="confirmation">
    <div class="check-badge" aria-hidden="true">✓</div>
    <h1>Réservation confirmée</h1>
    <p>${VB.esc(VB.BIKE.name)} · du ${VB.formatLong(reservation.start)} au ${VB.formatLong(reservation.end)}</p>
    <p class="amount-line">${VB.esc(reservation.pricingLabel)} · Total ${VB.formatEUR(reservation.totalPrice)}</p>
    ${invoice ? `<p>Facture <strong>${VB.esc(invoice.number)}</strong> — disponible dans « Mes réservations ».</p>` : ''}
    <div class="actions">
      <button class="btn btn-primary" data-action="go-reservations">Voir mes réservations</button>
      <button class="btn btn-secondary" data-action="go-catalog">Retour au catalogue</button>
    </div>
  </div>
`;

/* ---------- Mes réservations ---------- */

VB.statusLabel = r => {
  if (r.status === 'confirmed') return 'Confirmée · payée';
  if (r.status === 'cancelled') {
    return r.cancellationFee > 0
      ? `Annulée · ${VB.formatEUR(r.refundedAmount || 0)} remboursés`
      : 'Annulée · remboursement intégral';
  }
  return 'En attente de paiement';
};

VB.viewReservations = () => {
  const account = VB.Accounts.current();
  const list = [...VB.visibleReservations()].sort((a, b) => a.start - b.start);

  // Invitation à créer un compte : seulement hors connexion, et seulement
  // s'il y a quelque chose à rattacher.
  const claimBanner = !account && list.length > 0 ? `
    <div class="notice notice-info" style="margin-bottom:20px;">
      <span aria-hidden="true">ℹ</span>
      <span>Ces réservations ne sont rattachées à aucun compte.
      <button class="btn-link" data-action="go-signup">Créez un compte</button> avec la même adresse e-mail
      pour les retrouver après vous être déconnecté.</span>
    </div>` : '';

  if (list.length === 0) {
    return `
      <div class="empty-state">
        <div class="glyph" aria-hidden="true">📅</div>
        <h2>Aucune réservation</h2>
        <p>${account
          ? "Aucune réservation rattachée à votre compte pour le moment."
          : "Vos réservations apparaîtront ici une fois payées depuis la fiche d'un vélo."}</p>
        <p style="margin-top:20px;">
          <button class="btn btn-primary" data-action="go-catalog">Réserver un vélo</button>
          ${account ? '' : '<button class="btn btn-secondary" data-action="go-signin" style="margin-left:10px;">J\'ai déjà un compte</button>'}
        </p>
      </div>`;
  }

  return `
    <div class="page-head">
      <h1>Mes réservations</h1>
      <p class="lede">${account
        ? `Locations rattachées au compte ${VB.esc(account.email)}.`
        : 'Retrouvez vos locations, vos factures et vos avoirs.'}</p>
    </div>
    ${claimBanner}
    <div class="reservation-list">
      ${list.map(r => `
        <div class="reservation-card">
          <span class="status-dot ${r.status}"></span>
          <button class="reservation-open" data-reservation="${r.id}">
            <span class="reservation-title">${VB.esc(VB.BIKE.name)}</span>
            <span class="reservation-dates">${VB.formatShort(r.start)} → ${VB.formatShort(r.end)} · ${r.quantity} vélo${r.quantity > 1 ? 's' : ''} · taille ${VB.esc(r.variantLabel || '—')}</span>
            <span class="reservation-amount">${VB.esc(r.pricingLabel)} · ${VB.formatEUR(r.totalPrice)}</span>
          </button>
          <span class="status-badge ${r.status}">${r.status === 'cancelled' ? 'Annulée' : 'Payée'}</span>
          ${r.status === 'cancelled'
            ? `<button class="btn btn-secondary" data-remove="${r.id}">Retirer</button>`
            : `<button class="btn btn-danger" data-cancel="${r.id}">Annuler</button>`}
        </div>`).join('')}
    </div>
  `;
};

VB.viewReservationDetail = id => {
  const r = VB.reservationById(id);
  if (!r) return VB.viewReservations();
  const docs = VB.invoicesFor(r.id);
  const showNotice = r.status !== 'cancelled' && VB.incursCancellationFee(r.start);

  return `
    <button class="back-link" data-action="go-reservations">‹ Mes réservations</button>
    <div class="page-head">
      <h1>Réservation</h1>
      <p><span class="status-badge ${r.status}">${r.status === 'cancelled' ? 'Annulée' : 'Payée'}</span></p>
    </div>

    <div class="split">
      <div class="stack">
        <div class="card">
          <p class="section-label">Votre location</p>
          <div class="detail-row"><span class="k">Vélo</span><span class="v">${VB.esc(VB.BIKE.name)}</span></div>
          <div class="detail-row"><span class="k">Taille</span><span class="v">${VB.esc(r.variantLabel || '—')}</span></div>
          <div class="detail-row"><span class="k">Du</span><span class="v">${VB.formatDate(r.start)}</span></div>
          <div class="detail-row"><span class="k">Au</span><span class="v">${VB.formatDate(r.end)}</span></div>
          <div class="detail-row"><span class="k">Formule</span><span class="v">${VB.esc(r.pricingLabel)}</span></div>
          <div class="detail-row"><span class="k">Vélos</span><span class="v">${r.quantity}</span></div>
          ${r.includesDelivery ? '<div class="detail-row"><span class="k">Livraison</span><span class="v">Incluse</span></div>' : ''}
          <div class="summary-total"><span>Montant payé</span><span class="amt">${VB.formatEUR(r.totalPrice)}</span></div>
          ${r.paymentMethod ? `<p class="fine-print">Réglé par ${r.paymentMethod === 'applePay' ? 'Apple Pay' : 'carte bancaire'}.</p>` : ''}
        </div>

        ${r.status === 'cancelled' ? `
        <div class="card">
          <p class="section-label">Annulation</p>
          ${r.cancelledAt ? `<div class="detail-row"><span class="k">Annulée le</span><span class="v">${VB.formatDate(r.cancelledAt)}</span></div>` : ''}
          ${r.cancellationFee > 0 ? `<div class="detail-row"><span class="k">Frais retenus</span><span class="v">${VB.formatEUR(r.cancellationFee)}</span></div>` : ''}
          <div class="summary-total"><span>Remboursé</span><span class="amt">${VB.formatEUR(r.refundedAmount || 0)}</span></div>
        </div>` : ''}

        <div class="card">
          <p class="section-label">Coordonnées</p>
          <div class="detail-row"><span class="k">Client</span><span class="v">${VB.esc(r.firstName)} ${VB.esc(r.lastName)}</span></div>
          <div class="detail-row"><span class="k">Téléphone</span><span class="v">${VB.esc(r.countryCode)} ${VB.esc(r.phone)}</span></div>
          <div class="detail-row"><span class="k">E-mail</span><span class="v">${VB.esc(r.email)}</span></div>
          ${r.notes ? `<div class="detail-row"><span class="k">Remarques</span><span class="v">${VB.esc(r.notes)}</span></div>` : ''}
        </div>
      </div>

      <div class="split-sticky stack">
        ${showNotice ? `
        <div class="notice notice-warning">
          <span aria-hidden="true">⚠</span>
          <span><strong>${VB.esc(VB.cancellationNoticeTitle(r.start))}.</strong>
          ${VB.esc(VB.cancellationNoticeBody(r.totalPrice, r.start))}</span>
        </div>` : ''}

        <div class="card">
          <p class="section-label">Factures et avoirs</p>
          ${docs.length === 0
            ? '<p class="invoice-note">Aucun document pour cette réservation.</p>'
            : docs.map(inv => `
              <button class="doc-link" data-invoice="${inv.id}">
                <span>
                  <span class="doc-name">${inv.kind === 'creditNote' ? 'Avoir' : 'Facture'} ${VB.esc(inv.number)}</span>
                  <span class="doc-amount">${VB.formatEUR(VB.invoiceTotal(inv))} · ${VB.formatDate(inv.issuedAt)}</span>
                </span>
                <span class="chevron" aria-hidden="true">›</span>
              </button>`).join('')}
        </div>

        ${r.status !== 'cancelled'
          ? `<button class="btn btn-danger btn-block" data-cancel="${r.id}">Annuler ma réservation</button>`
          : ''}
      </div>
    </div>
  `;
};

/* ---------- Facture / avoir ---------- */

VB.viewInvoice = id => {
  const inv = VB.state.invoices.find(i => i.id === id);
  if (!inv) return VB.viewReservations();
  const isCredit = inv.kind === 'creditNote';

  return `
    <button class="back-link" data-action="back-to-reservation" data-reservation="${inv.reservationId}">‹ Retour à la réservation</button>
    <div class="page-head">
      <p class="eyebrow">${isCredit ? 'Avoir' : 'Facture'}</p>
      <h1>${VB.esc(inv.number)}</h1>
      <p class="lede">Émis le ${VB.formatDate(inv.issuedAt)}${inv.relatedInvoiceNumber ? ` — se rapporte à la facture ${VB.esc(inv.relatedInvoiceNumber)}` : ''}</p>
    </div>

    <div class="split">
      <div class="card">
        <p class="section-label">Détail</p>
        ${inv.lines.map(l => l.quantity === 0
          ? `<p class="invoice-note">${VB.esc(l.label)}</p>`
          : `<div class="invoice-line">
               <span>
                 <span class="lbl">${VB.esc(l.label)}</span>
                 ${l.quantity > 1 ? `<span class="qty">${l.quantity} × ${VB.formatEUR(l.unitPrice)}</span>` : ''}
               </span>
               <span class="amt">${VB.formatEUR(VB.round2(l.unitPrice * l.quantity))}</span>
             </div>`).join('')}
        <div class="summary-total">
          <span>${isCredit ? 'Total remboursé' : 'Total'}</span>
          <span class="amt">${VB.formatEUR(VB.invoiceTotal(inv))}</span>
        </div>
        <p class="invoice-todo">${VB.esc(VB.VAT_NOTE)}</p>
        ${inv.paymentMethodLabel ? `<p class="fine-print">Réglé par ${VB.esc(inv.paymentMethodLabel)}.</p>` : ''}
        ${isCredit ? '<p class="fine-print">Le remboursement est effectué sur le moyen de paiement d’origine.</p>' : ''}
      </div>

      <div class="stack">
        <div class="card">
          <p class="section-label">Émetteur</p>
          <p class="invoice-note">${VB.esc(VB.CONTACT.name)}
${VB.esc(VB.CONTACT.address)}
${VB.esc(VB.CONTACT.postal)}
${VB.esc(VB.CONTACT.phone)}</p>
          <p class="invoice-todo">${VB.esc(VB.SELLER_NOTE)}</p>
        </div>
        <div class="card">
          <p class="section-label">Client</p>
          <p class="invoice-note">${VB.esc(inv.customerName)}
${VB.esc(inv.customerEmail || '')}</p>
        </div>
      </div>
    </div>
  `;
};

/* ---------- Informations légales ---------- */

VB.viewLegalIndex = () => `
  <div class="page-head">
    <h1>Informations</h1>
    <p class="lede">Informations légales de Ker Vélo Brière et détail du traitement de vos données.</p>
  </div>
  <div class="legal-grid">
    ${VB.LEGAL_DOCS.map(doc => `
      <button class="legal-card" data-legal="${doc.id}">
        <span class="legal-card-title">${VB.esc(doc.title)}${VB.docNeedsCompletion(doc) ? '<i class="todo-dot"></i>' : ''}</span>
        <span class="legal-card-summary">${VB.esc(doc.summary)}</span>
      </button>`).join('')}
  </div>

  <div class="card" style="margin-top:26px; max-width:420px;">
    <p class="section-label">Nous contacter</p>
    <p class="invoice-note">${VB.esc(VB.CONTACT.name)}
${VB.esc(VB.CONTACT.address)}
${VB.esc(VB.CONTACT.postal)}</p>
    <p style="margin:10px 0 0;"><a href="${VB.CONTACT.phoneHref}" style="font-weight:600;">${VB.esc(VB.CONTACT.phone)}</a></p>
  </div>
`;

VB.viewLegalDoc = id => {
  const doc = VB.LEGAL_DOCS.find(d => d.id === id);
  if (!doc) return VB.viewLegalIndex();
  return `
    <button class="back-link" data-action="go-legal">‹ Informations</button>
    <div class="page-head">
      <h1>${VB.esc(doc.title)}</h1>
      <p class="lede">Dernière mise à jour : ${VB.esc(doc.lastUpdated)}</p>
    </div>
    ${VB.docNeedsCompletion(doc) ? `
      <div class="notice notice-warning" style="margin-bottom:20px;">
        <span aria-hidden="true">⚠</span>
        <span>Document incomplet : les passages signalés « À COMPLÉTER » doivent être renseignés,
        puis l'ensemble relu par un professionnel du droit avant mise en ligne.</span>
      </div>` : ''}
    ${doc.sections.map(s => {
      const todo = s.body.includes(VB.PLACEHOLDER_MARKER);
      return `
      <div class="card legal-section ${todo ? 'todo' : ''}">
        <div class="legal-section-head">
          <span class="legal-section-title">${VB.esc(s.heading)}</span>
          ${todo ? '<span class="todo-badge">À compléter</span>' : ''}
        </div>
        <p class="legal-body">${VB.esc(s.body)}</p>
      </div>`;
    }).join('')}
  `;
};

/* ---------- Comptes ---------- */

VB.viewAuth = mode => {
  const isSignUp = mode === 'signup';
  return `
    <div class="auth-wrap">
      <div class="page-head">
        <p class="eyebrow">${isSignUp ? 'Créer un compte' : 'Se connecter'}</p>
        <h1>${isSignUp ? 'Créez votre compte' : 'Bon retour parmi nous'}</h1>
        <p class="lede">${isSignUp
          ? "Votre compte regroupe vos réservations, vos factures et vos avoirs, et pré-remplit vos coordonnées."
          : "Connectez-vous pour retrouver vos réservations et vos factures."}</p>
      </div>

      <div id="formAlert" class="form-alert" role="alert"></div>

      <div class="card">
        ${isSignUp ? `
          <div class="two-col">
            <div class="field-group">
              <label class="field-label" for="authFirstName">Prénom</label>
              <input class="field" id="authFirstName" autocomplete="given-name">
            </div>
            <div class="field-group">
              <label class="field-label" for="authLastName">Nom</label>
              <input class="field" id="authLastName" autocomplete="family-name">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label" for="authPhone">Téléphone</label>
            <div class="field-row">
              <select class="field" id="authCountryCode" aria-label="Indicatif pays">
                ${VB.COUNTRY_CODES.map(c => `<option value="${c.code}" ${c.code === VB.DEFAULT_COUNTRY_CODE ? 'selected' : ''}>${c.flag} ${c.code}</option>`).join('')}
              </select>
              <input class="field" id="authPhone" type="tel" autocomplete="tel">
            </div>
          </div>` : ''}

        <div class="field-group">
          <label class="field-label" for="authEmail">Adresse e-mail</label>
          <input class="field" id="authEmail" type="email" autocomplete="email">
        </div>

        <div class="field-group">
          <label class="field-label" for="authPassword">Mot de passe</label>
          <input class="field" id="authPassword" type="password"
                 autocomplete="${isSignUp ? 'new-password' : 'current-password'}">
          ${isSignUp ? `<span class="field-hint">Au moins ${VB.PASSWORD_MIN_LENGTH} caractères.</span>` : ''}
        </div>

        ${isSignUp ? `
        <div class="field-group">
          <label class="field-label" for="authPassword2">Confirmer le mot de passe</label>
          <input class="field" id="authPassword2" type="password" autocomplete="new-password">
        </div>` : ''}

        <button class="btn btn-primary btn-block" style="margin-top:18px;"
                data-auth="${isSignUp ? 'signup' : 'signin'}">
          ${isSignUp ? 'Créer mon compte' : 'Se connecter'}
        </button>

        <p class="auth-switch">
          ${isSignUp
            ? `Vous avez déjà un compte ? <button class="btn-link" data-action="go-signin">Se connecter</button>`
            : `Pas encore de compte ? <button class="btn-link" data-action="go-signup">En créer un</button>`}
        </p>
      </div>

      <div class="notice notice-info" style="margin-top:18px;">
        <span aria-hidden="true">ℹ</span>
        <span><strong>Démonstration</strong> — le compte est enregistré dans ce navigateur uniquement.
        Il ne permet pas encore de retrouver ses réservations depuis un autre appareil :
        cela demandera un serveur.</span>
      </div>
    </div>
  `;
};

VB.viewAccount = () => {
  const account = VB.Accounts.current();
  if (!account) return VB.viewAuth('signin');
  const mine = VB.visibleReservations();
  const active = mine.filter(r => r.status !== 'cancelled').length;

  return `
    <div class="page-head">
      <p class="eyebrow">Mon compte</p>
      <h1>${VB.esc(account.firstName)} ${VB.esc(account.lastName)}</h1>
      <p class="lede">Compte créé le ${VB.formatDate(account.createdAt)}.</p>
    </div>

    <div id="formAlert" class="form-alert" role="alert"></div>

    <div class="split">
      <div class="stack">
        <div class="card">
          <p class="section-label">Coordonnées</p>
          <div class="detail-row"><span class="k">Prénom</span><span class="v">${VB.esc(account.firstName)}</span></div>
          <div class="detail-row"><span class="k">Nom</span><span class="v">${VB.esc(account.lastName)}</span></div>
          <div class="detail-row"><span class="k">E-mail</span><span class="v">${VB.esc(account.email)}</span></div>
          <div class="detail-row"><span class="k">Téléphone</span><span class="v">${VB.esc(account.countryCode)} ${VB.esc(account.phone)}</span></div>
        </div>

        <div class="card">
          <p class="section-label">Changer de mot de passe</p>
          <div class="field-group">
            <label class="field-label" for="pwCurrent">Mot de passe actuel</label>
            <input class="field" id="pwCurrent" type="password" autocomplete="current-password">
          </div>
          <div class="field-group">
            <label class="field-label" for="pwNew">Nouveau mot de passe</label>
            <input class="field" id="pwNew" type="password" autocomplete="new-password">
            <span class="field-hint">Au moins ${VB.PASSWORD_MIN_LENGTH} caractères.</span>
          </div>
          <button class="btn btn-secondary btn-block" style="margin-top:14px;" data-auth="change-password">
            Mettre à jour le mot de passe
          </button>
        </div>
      </div>

      <div class="split-sticky stack">
        <div class="card">
          <p class="section-label">Vos locations</p>
          <div class="detail-row"><span class="k">Réservations actives</span><span class="v">${active}</span></div>
          <div class="detail-row"><span class="k">Total enregistré</span><span class="v">${mine.length}</span></div>
          <button class="btn btn-primary btn-block" style="margin-top:14px;" data-action="go-reservations">
            Voir mes réservations
          </button>
        </div>

        <button class="btn btn-secondary btn-block" data-auth="signout">Se déconnecter</button>
      </div>
    </div>
  `;
};

/* ---------- Page d'accueil ---------- */

/* Icônes tracées à la couleur courante : elles suivent le thème,
   contrairement aux émojis qui imposent leurs propres couleurs. */
VB.ICONS = {
  bike: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <circle cx="5.5" cy="17.5" r="3.3"></circle><circle cx="18.3" cy="17.5" r="3.3"></circle>
    <path d="M5.5 17.5 10 9h4l3 4.5 4.8 4"></path><path d="M8.2 9h3"></path></svg>`,
  calendar: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <rect x="4" y="5.5" width="16" height="15" rx="2.6"></rect>
    <path d="M4 10h16M8 3.5v3.5M16 3.5v3.5"></path>
    <path d="M8 14.2h.01M12 14.2h.01M16 14.2h.01M8 17.4h.01M12 17.4h.01"></path></svg>`,
  person: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <circle cx="12" cy="8.2" r="3.7"></circle>
    <path d="M4.8 20.2c.9-3.6 3.8-5.6 7.2-5.6s6.3 2 7.2 5.6"></path></svg>`,
  info: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <circle cx="12" cy="12" r="9"></circle><path d="M12 11v5.5"></path><path d="M12 7.6h.01"></path></svg>`
};



VB.viewHome = () => {
  const account = VB.Accounts.current();
  const avail = VB.availableOn(new Date());
  const level = VB.levelFor(avail, VB.BIKE.totalUnits);
  const mine = VB.visibleReservations().filter(r => r.status !== 'cancelled').length;

  const entries = [
    {
      nav: 'catalog',
      icon: VB.ICONS.bike,
      title: 'Vélos',
      desc: `Deux tailles : S/M et L/XL. Tarifs et réservation.`,
      meta: `<span class="avail-pill ${level}"><i></i>${avail}/${VB.BIKE.totalUnits} disponibles</span>`,
      primary: true
    },
    {
      nav: 'reservations',
      icon: VB.ICONS.calendar,
      title: 'Mes réservations',
      desc: 'Vos locations, vos factures et vos avoirs.',
      meta: mine > 0
        ? `<span class="home-count">${mine} en cours</span>`
        : `<span class="home-muted">Aucune en cours</span>`
    },
    account
      ? {
          nav: 'account',
          icon: VB.ICONS.person,
          title: 'Mon compte',
          desc: 'Vos coordonnées et votre mot de passe.',
          meta: `<span class="home-muted">${VB.esc(account.email)}</span>`
        }
      : {
          action: 'go-signin',
          icon: VB.ICONS.person,
          title: 'Se connecter',
          desc: 'Retrouvez vos réservations passées.',
          meta: `<span class="home-muted">Ou créer un compte</span>`
        },
    {
      nav: 'legal',
      icon: VB.ICONS.info,
      title: 'Informations',
      desc: 'Mentions légales, confidentialité et CGL.',
      meta: `<span class="home-muted">Nous contacter</span>`
    }
  ];

  return `
    <div class="home">
      <div class="home-hero">
        <div class="home-logo">
          <img src="assets/logo.jpg" alt="Ker Vélo Brière — vélo électrique au bord des marais de Brière" width="480" height="480">
        </div>
        <h1 class="home-title">KER VÉLO BRIÈRE</h1>
        <p class="home-tagline">Location de vélos électriques</p>
        <p class="home-lede">Balades électriques au cœur de la Brière, entre marais, villages et chemins.
        Casque et antivol inclus, livraison possible dans un rayon de ${VB.BIKE.deliveryRadiusKm} km.</p>
      </div>

      <div class="home-grid">
        ${entries.map(e => `
          <button class="home-card ${e.primary ? 'home-card-primary' : ''}"
                  ${e.nav ? `data-nav="${e.nav}"` : `data-action="${e.action}"`}>
            <span class="home-card-icon">${e.icon}</span>
            <span class="home-card-title">${VB.esc(e.title)}</span>
            <span class="home-card-desc">${VB.esc(e.desc)}</span>
            <span class="home-card-meta">${e.meta}</span>
          </button>`).join('')}
      </div>

      <p class="home-contact">
        ${VB.esc(VB.CONTACT.address)}, ${VB.esc(VB.CONTACT.postal)} ·
        <a href="${VB.CONTACT.phoneHref}">${VB.esc(VB.CONTACT.phone)}</a>
      </p>
    </div>
  `;
};
