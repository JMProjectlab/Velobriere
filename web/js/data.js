/* Données de référence : catalogue, indicatifs, textes légaux.
   Miroir de Velobriere/Data/*.swift et Velobriere/Models/*.swift. */

window.VB = window.VB || {};

VB.BIKE = {
  id: 'e-actv-100-lf-c2',
  brand: 'Decathlon',
  name: 'E-ACTV 100 LF C2',
  tagline: 'Vélo à assistance électrique, cadre bas',
  highlights: [
    'Cadre bas, facile à enfourcher',
    'Assistance électrique pour rouler sans effort',
    'Confortable pour les balades autour de la Brière',
    'Idéal pour découvrir marais, villages et chemins',
    "Jusqu'à 4 vélos disponibles en simultané",
    'Casque et antivol inclus dans toutes les locations'
  ],
  pricingOptions: [
    { id: 'half-day', label: 'Demi-journée', price: 25 },
    { id: 'day', label: 'Journée', price: 39 },
    { id: 'weekend', label: 'Week-end', price: 69 },
    { id: 'week', label: 'Semaine', price: 169 }
  ],
  deliveryFee: 10,
  deliveryRadiusKm: 10,
  totalUnits: 4,
  productURL: 'https://www.decathlonpro.fr/e-actv-100-lf-c2-id-8983925.html'
};

VB.COUNTRY_CODES = [
  { code: '+33', flag: '🇫🇷', label: 'France' },
  { code: '+32', flag: '🇧🇪', label: 'Belgique' },
  { code: '+41', flag: '🇨🇭', label: 'Suisse' },
  { code: '+352', flag: '🇱🇺', label: 'Luxembourg' },
  { code: '+49', flag: '🇩🇪', label: 'Allemagne' },
  { code: '+44', flag: '🇬🇧', label: 'Royaume-Uni' },
  { code: '+31', flag: '🇳🇱', label: 'Pays-Bas' },
  { code: '+34', flag: '🇪🇸', label: 'Espagne' },
  { code: '+39', flag: '🇮🇹', label: 'Italie' },
  { code: '+351', flag: '🇵🇹', label: 'Portugal' },
  { code: '+353', flag: '🇮🇪', label: 'Irlande' },
  { code: '+1', flag: '🇺🇸', label: 'États-Unis / Canada' }
];
VB.DEFAULT_COUNTRY_CODE = '+33';

VB.CONTACT = {
  name: 'Vélo Brière',
  address: '135 Kermouraud',
  postal: '44410 Saint-Lyphard',
  phone: '06 07 34 37 97',
  phoneHref: 'tel:+33607343797'
};

/* ⚠️ Squelettes juridiques : chaque « [À COMPLÉTER : … ] » doit être renseigné
   par Vélo Brière, puis l'ensemble relu par un professionnel du droit. */
VB.PLACEHOLDER_MARKER = '[À COMPLÉTER';
VB.VAT_NOTE = "[À COMPLÉTER : régime de TVA — taux applicable, ou mention « TVA non applicable, art. 293 B du CGI » en franchise en base]";
VB.SELLER_NOTE = "[À COMPLÉTER : forme juridique, SIRET, RCS et n° de TVA intracommunautaire]";

VB.LEGAL_DOCS = [
  {
    id: 'mentions-legales',
    title: 'Mentions légales',
    summary: "Identification de l'éditeur de l'application et de l'hébergeur des données.",
    lastUpdated: '[À COMPLÉTER : date de mise à jour]',
    sections: [
      { heading: "Éditeur de l'application", body:
`Vélo Brière — location de vélos électriques
135 Kermouraud, 44410 Saint-Lyphard, France
Téléphone : 06 07 34 37 97

Forme juridique : [À COMPLÉTER : SARL, EI, SAS…]
Capital social : [À COMPLÉTER : montant, si société]
SIRET : [À COMPLÉTER : numéro SIRET]
RCS : [À COMPLÉTER : ville et numéro d'immatriculation]
N° TVA intracommunautaire : [À COMPLÉTER : ou mention « non applicable, art. 293 B du CGI » si franchise en base]
Adresse e-mail : [À COMPLÉTER : adresse de contact]
Directeur de la publication : [À COMPLÉTER : nom et prénom]` },
      { heading: 'Hébergement des données', body:
`Dans cette version, les demandes de réservation sont enregistrées uniquement dans le navigateur de l'utilisateur. Aucune donnée n'est transmise à un serveur distant.

Lorsqu'un service de réception des réservations sera mis en place, l'hébergeur sera :
[À COMPLÉTER : raison sociale, adresse et téléphone de l'hébergeur]` },
      { heading: 'Propriété intellectuelle', body:
`La marque Vélo Brière, son logo, sa charte graphique ainsi que les contenus de l'application sont protégés. Toute reproduction, même partielle, sans autorisation écrite préalable est interdite.

Les marques et visuels des vélos présentés appartiennent à leurs titulaires respectifs.` },
      { heading: 'Nous contacter', body:
`Pour toute question relative à l'application ou à une réservation :
Téléphone : 06 07 34 37 97
E-mail : [À COMPLÉTER : adresse de contact]` }
    ]
  },
  {
    id: 'confidentialite',
    title: 'Politique de confidentialité',
    summary: 'Quelles données sont collectées, pourquoi, combien de temps, et vos droits.',
    lastUpdated: '[À COMPLÉTER : date de mise à jour]',
    sections: [
      { heading: 'Responsable du traitement', body:
`Vélo Brière, 135 Kermouraud, 44410 Saint-Lyphard.
Contact : [À COMPLÉTER : adresse e-mail dédiée aux demandes RGPD]

Compte tenu de la taille de l'activité, aucun délégué à la protection des données (DPO) n'a été désigné.` },
      { heading: 'Données collectées', body:
`Lors d'une demande de réservation, l'application recueille :
• votre prénom et votre nom ;
• votre indicatif pays et votre numéro de téléphone ;
• votre adresse e-mail ;
• les dates, la formule et le nombre de vélos souhaités ;
• les remarques que vous saisissez librement.

L'application ne collecte aucune donnée de localisation, n'utilise aucun traceur publicitaire et ne réalise aucune mesure d'audience.` },
      { heading: 'Finalité et base légale', body:
`Ces données servent exclusivement à traiter votre demande de réservation, à vous recontacter pour la confirmer et à exécuter la location.

La base légale est l'exécution de mesures précontractuelles et du contrat de location, au sens de l'article 6.1.b du RGPD.` },
      { heading: 'Où sont stockées vos données', body:
`Dans cette version, vos données restent enregistrées dans votre navigateur et ne sont transmises à aucun serveur. Vider les données du site les efface.

[À COMPLÉTER : à réécrire dès qu'un service d'envoi des réservations sera mis en place — préciser le destinataire, l'hébergeur et le lieu d'hébergement des données.]` },
      { heading: 'Destinataires', body:
`Vos données sont destinées aux seules personnes habilitées de Vélo Brière chargées de la gestion des locations. Elles ne sont ni vendues, ni cédées, ni transmises à des tiers à des fins commerciales.

[À COMPLÉTER : lister les éventuels sous-traitants — outil d'e-mailing, prestataire de paiement, logiciel de gestion.]` },
      { heading: 'Durée de conservation', body:
`[À COMPLÉTER : durée retenue — par exemple 3 ans à compter de la dernière location pour les données clients, et la durée légale applicable pour les pièces comptables.]` },
      { heading: 'Vos droits', body:
`Vous disposez d'un droit d'accès, de rectification, d'effacement, de limitation et d'opposition, ainsi que d'un droit à la portabilité de vos données.

Pour les exercer, écrivez à [À COMPLÉTER : adresse e-mail dédiée] ou à l'adresse postale ci-dessus. Une réponse vous sera apportée dans un délai d'un mois.

Si vous estimez que vos droits ne sont pas respectés, vous pouvez introduire une réclamation auprès de la CNIL (www.cnil.fr).` },
      { heading: 'Sécurité', body:
`[À COMPLÉTER : décrire les mesures de sécurité mises en place côté serveur lorsque celui-ci existera — chiffrement, contrôle d'accès, sauvegardes.]` }
    ]
  },
  {
    id: 'cgl',
    title: 'Conditions générales de location',
    summary: 'Réservation, tarifs, garantie, responsabilité, annulation et restitution.',
    lastUpdated: '[À COMPLÉTER : date de mise à jour]',
    sections: [
      { heading: '1. Objet', body:
`Les présentes conditions régissent la location de vélos à assistance électrique proposée par Vélo Brière, à l'exclusion de toute autre condition.

Toute réservation implique l'acceptation sans réserve des présentes conditions.` },
      { heading: '2. Réservation', body:
`Le contrat est formé au paiement de la réservation. Vélo Brière vous recontacte pour arrêter les modalités de retrait ou de livraison.

Âge minimum du locataire : [À COMPLÉTER : âge requis]
Pièces à présenter au retrait : [À COMPLÉTER : pièce d'identité, justificatif de domicile…]` },
      { heading: '3. Tarifs', body:
`• Demi-journée : 25 €
• Journée : 39 €
• Week-end : 69 €
• Semaine : 169 €

Le casque et l'antivol sont inclus dans toutes les locations.
La livraison est proposée en option à 10 €, dans un rayon de 10 km.

Tarifs en euros, par vélo. [À COMPLÉTER : préciser TTC ou HT et le taux de TVA applicable, ou la mention de franchise en base.]` },
      { heading: '4. Dépôt de garantie', body:
`[À COMPLÉTER : montant du dépôt de garantie, forme — empreinte bancaire, chèque non encaissé —, et délai de restitution après retour du vélo.]` },
      { heading: "5. Conditions d'utilisation", body:
`Le locataire s'engage à :
• respecter le code de la route ;
• ne pas prêter le vélo à un tiers non déclaré ;
• utiliser systématiquement l'antivol fourni lors de tout stationnement ;
• ne pas transporter de passager ni de charge excédant les préconisations du constructeur ;
• ne pas pratiquer d'usage sportif intensif ou tout-terrain.

Le port du casque est obligatoire pour les enfants de moins de 12 ans. Il est vivement recommandé à tous ; un casque est fourni avec chaque vélo.

Les vélos sont des vélos à assistance électrique conformes à la réglementation applicable, dont l'assistance se coupe à 25 km/h. Toute tentative de débridage est interdite et engage la seule responsabilité du locataire.` },
      { heading: '6. Responsabilité, vol et détérioration', body:
`Le vélo est remis en bon état de fonctionnement. Un état des lieux est établi au départ et au retour.

Le locataire est responsable du vélo et des accessoires pendant toute la durée de la location.

[À COMPLÉTER : conditions de prise en charge en cas de vol — dépôt de plainte, franchise applicable, restitution de l'antivol.]
[À COMPLÉTER : conditions de facturation en cas de casse ou de détérioration.]` },
      { heading: '7. Assurance', body:
`Vélo Brière est couvert par une assurance responsabilité civile professionnelle :
[À COMPLÉTER : nom de l'assureur, numéro de contrat et étendue géographique.]

[À COMPLÉTER : préciser ce qui reste à la charge du locataire et si sa propre responsabilité civile est requise.]` },
      { heading: '8. Annulation et rétractation', body:
`Conditions appliquées par l'application :
• annulation à plus de 2 jours du départ : remboursement intégral ;
• annulation à 2 jours ou moins du départ, jour du départ inclus : 50 % du montant sont retenus ;
• location déjà commencée : aucun remboursement.

Le remboursement est effectué sur le moyen de paiement d'origine et donne lieu à l'émission d'un avoir.

⚠️ Point à faire valider par un juriste : la réservation à distance ouvre en principe un droit de rétractation de 14 jours. Le Code de la consommation prévoit une exception pour les activités de loisirs devant être fournies à une date ou une période déterminée, susceptible de s'appliquer ici. Si l'exception s'applique, elle doit être expressément portée à la connaissance du client.` },
      { heading: '9. Restitution', body:
`Le vélo est restitué à la date, à l'heure et au lieu convenus, dans l'état où il a été remis.

[À COMPLÉTER : pénalité applicable en cas de retard et conditions de restitution anticipée.]` },
      { heading: '10. Données personnelles', body:
`Le traitement des données personnelles est décrit dans la politique de confidentialité, accessible depuis cette même rubrique.` },
      { heading: '11. Réclamations et litiges', body:
`Toute réclamation peut être adressée à [À COMPLÉTER : adresse e-mail de contact].

Conformément au Code de la consommation, le client peut recourir gratuitement à un médiateur de la consommation :
[À COMPLÉTER : nom, adresse et site du médiateur auquel Vélo Brière adhère.]

Les présentes conditions sont soumises au droit français.` }
    ]
  }
];
