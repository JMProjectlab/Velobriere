# Ker Vélo Brière — guide de l'agent

Réservation de vélos électriques pour un loueur réel à Saint-Lyphard. Ce que
fait l'application et ce qui est implémenté : [README](README.md).

Ce fichier dit **où ranger quoi** et **ce qu'il ne faut pas casser**.

---

## Où va quoi

| Tu veux… | Ça se passe dans |
|---|---|
| Toucher à une règle métier (annulation, tarif, facture, stock) | **les deux** : `Velobriere/Models/` et `web/js/domain.js` |
| Écran iOS | `Velobriere/Views/<Domaine>/` |
| Écran web | `web/js/views.js`, styles dans `web/css/styles.css` |
| Persistance iOS | `Velobriere/Data/` |
| Persistance web | `web/js/store.js`, comptes dans `web/js/accounts.js` |
| Catalogue, données de départ | `Velobriere/Models/Bike.swift` **et** `web/js/data.js` |
| Couleurs, typographie, composants | `Velobriere/DesignSystem/` et `web/css/styles.css` |
| Charte graphique (référence) | `brand/charte-graphique.html` |

## Les règles à ne pas casser

### 1. La règle métier existe en double, et les deux côtés changent ensemble

C'est le point le plus important de ce dépôt. Annulation, tarification,
facturation et suivi de stock par taille sont écrits **deux fois** : en Swift
dans `Velobriere/Models/`, en JavaScript dans `web/js/domain.js`.

Une correction d'un seul côté produit deux applications qui ne disent pas la
même chose au même client. Ça ne casse aucun test, ça ne se voit pas dans le
diff, et ça se découvre sur une facture fausse.

**Toute PR qui touche une règle métier touche les deux fichiers, ou explique
pourquoi non.** Si tu ne peux en faire qu'un, dis-le explicitement plutôt que de
laisser croire que c'est fait.

C'est un arbitrage assumé, pas une négligence — le raisonnement est dans le
second cerveau, dépôt `Brain`. Ici on n'en garde que la conséquence opératoire.

### 2. Le stock est suivi par taille

Réserver un S/M ne réduit pas la disponibilité des L/XL. Deux exemplaires
chacune. Toute logique de disponibilité qui raisonne sur « le vélo » et non sur
« la variante » est fausse.

### 3. Le nom va changer, l'identifiant de lot non

Un deuxième renommage est annoncé. Le bundle id `com.velobriere.app` et son
successeur `com.kervelobriere.app` ne sont **pas modifiables** une fois une
fiche App Store créée. Ne propose jamais de « corriger » un bundle id pour
l'aligner sur un nouveau nom : ça se paie par une nouvelle fiche.

### 4. Le déploiement web se déclenche tout seul

`.github/workflows/deploy-web.yml` publie sur GitHub Pages à chaque push sur
`main` touchant `web/**`. Une modification web fusionnée **est en ligne**, chez
un vrai loueur. Il n'y a pas d'étape de validation entre les deux.

Pour prévisualiser avant fusion : déclencher le workflow manuellement depuis
l'onglet Actions, sur la branche.

### 5. La charte n'est lue par personne

`brand/charte-graphique.html` est un document de référence. Aucune des deux
applications ne la lit : les couleurs et la typographie y sont recopiées à la
main. Quand tu changes une couleur, la charte ne suit pas toute seule — et
l'écart ne se voit nulle part.

## Vérifier avant de pousser

```bash
node --check web/js/domain.js web/js/app.js web/js/views.js   # syntaxe
python3 -m http.server -d web 8000                            # essai local
```

**Le côté iOS ne compile pas ici.** Ce dépôt a été préparé sans Xcode et aucune
session Linux ne peut vérifier le Swift. Une modification Swift part donc non
vérifiée : dis-le dans la PR, et laisse la compilation au Mac.

Il n'y a pas de tests automatisés dans ce dépôt. Une règle métier modifiée se
vérifie à la main, des deux côtés, sur un cas où les deux doivent tomber
d'accord.

## Ce qui n'entre pas dans ce dépôt

Aucune donnée réelle de client du loueur : nom, adresse, courriel, téléphone,
moyen de paiement. Le dépôt est public. Les jeux d'essai sont inventés et le
restent.

Aucune clé de service Firebase, aucun fichier `GoogleService-Info.plist`.

## Le reste du contexte

Le raisonnement — pourquoi la duplication, quand elle devient une dette, le
cadre non facturé avec les propriétaires — vit dans le second cerveau, dépôt
`Brain`. Ce guide ne le duplique pas : il en applique les conséquences.
