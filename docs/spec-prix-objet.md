# Spec : prix d'un objet modifiable partout (inventaire, butin, surcharge du catalogue)

Rédigée par `direction-artistique` le 27/11/2026 (lecture seule). Ticket Project #7 « Nexus : prix d'un objet modifiable
partout (inventaire, butin, surcharge du catalogue) ». Décision de Matthias : **« Partout, modifiable »** — un prix
(montant + une des 5 devises `cp`/`sp`/`ep`/`gp`/`pp`) se fixe sur tout objet personnalisé (inventaire et butin) et peut
**surcharger** le coût officiel d'un objet du catalogue (utile notamment pour les ~250 objets magiques sans coût
officiel). Pas de vente/échange : juste afficher/fixer un prix. Niveau **parchemin** partout (toutes les sheets
concernées sont déjà sur `parchmentBg`/`parchmentCard` — `item_info_panel.dart:300`, `custom_item_form_sheet.dart:373`,
`item_action_sheet.dart:134`) : aucun changement de niveau, pas de nouveau token de fond.

## 0. Vocabulaire déjà établi à réutiliser tel quel

- **5 devises** : `CurrencyKind` (`domain/currency_kind.dart`), `unitLabel` = PP/PO/PE/PA/PC (abréviations déjà
  affichées partout : stat boxes, conversion, ajustement). **Pas de nouveau libellé** — même abréviations, même ordre
  (platine, or, électrum, argent, cuivre).
- **Saisie d'un montant** : `NumericAmountStepper` (`core/widgets/numeric_amount_stepper.dart`), déjà utilisé par
  `currency_adjustment_sheet.dart` et `currency_conversion_sheet.dart` (`value`/`max`/`onChanged`/`decrementLabel`/
  `incrementLabel`/`fieldLabel`/`autofocus`) : bornes `[0, 999999]` comme `_maxAddAmount`
  (`currency_adjustment_sheet.dart:17`), zone de tap déjà ≥44 px.
- **Sélecteur de devise** : le motif `_chips` de `currency_conversion_sheet.dart:135-159` (5 `ChoiceChip`,
  `MaterialTapTargetSize.padded`, label `'${currency.unitLabel}'`) — **à extraire en widget partagé** (ex.
  `CurrencyPickerChips`, `core/widgets/`) plutôt que dupliqué une 3ᵉ fois : aujourd'hui dupliqué entre `from`/`to` dans
  ce seul fichier, un prix en est le 3ᵉ usage. Mêmes chips, sans le `· {solde}` (pas pertinent pour un prix).

## 1. Où afficher le prix (fiche d'un objet, inventaire et butin)

Dans `_ItemInfoPanelContent` (`item_info_panel.dart:152-173`) et son équivalent butin (section 2 de
`docs/spec-butin-groupe.md`, même corps extrait en widget public `withoutCharacter`) : la ligne `_ItemInfoRow` « Coût »
existante (`item.costAmount`) devient une ligne **« Prix »** à 3 états, toujours à la même position dans la liste
(juste après le poids, avant le bonus magique — ordre inchangé) :

1. **Prix officiel sans surcharge** (objet du catalogue, `item.costAmount` non nul, pas de surcharge posée) :
   formatage **devise-agnostique** (actuellement codé en dur `"{cost} po"`, `itemInfoPanelCostValue`,
   `app_fr.arb:3844`) : remplacé par un formateur générique `{montant} {unitLabel}`, avec `CurrencyKind.unitLabel`
   (PP/PO/PE/PA/PC, majuscules) — **changement visuel accepté par Matthias le 27/11/2026** (trouvé par `qa-testeur` :
   la ligne « le rendu visuel ne change pas » ci-dessous était une supposition erronée de cette spec, pas une
   exigence ; le prix d'un objet du catalogue passe de « 15 po » à « 15 PO », cohérent avec les tuiles de monnaie, la
   conversion et l'ajustement qui utilisent déjà ces majuscules partout ailleurs dans l'app). Aucune correction de
   code nécessaire : l'implémentation de `dev-flutter` produisait déjà ce résultat.
2. **Prix surchargé** (objet du catalogue avec une surcharge posée, **ou** objet personnalisé avec un prix fixé) :
   même ligne, valeur dans la devise choisie (ex. « 15 pa »), **plus une pastille « Modifié »** juste après la valeur
   — *nouvelle pastille à ajouter au design system* (voir §7, point à valider) : gabarit de `NotProficientBadge`
   (`core/widgets/not_proficient_badge.dart`) mais **ton neutre, pas d'alerte** — fond `parchmentCard`, contour
   `woodLight` (pas `accentBrick`), icône `Icons.edit` 12 px `textSecondary`, texte `body` 11 px `textSecondary`
   (jamais `woodDark` : ce n'est pas un avertissement). Elle n'apparaît **que** quand le prix affiché diffère du prix
   « par défaut » du catalogue (donc jamais sur un objet personnalisé, qui n'a pas de prix par défaut à surcharger).
3. **Aucun prix connu** (objet personnalisé sans prix fixé, ou objet du catalogue sans coût officiel ni surcharge —
   le cas des objets magiques) : **afficher la ligne avec « Non estimé »** plutôt que la masquer (décision à
   confirmer, voir §7) — c'est le cas que ce ticket cherche justement à rendre visible et actionnable. Dans un
   contexte où l'écriture est possible (objet du personnage courant, ou objet du butin modifiable), ajouter à droite
   de « Non estimé » un lien **« Fixer un prix »** (même gabarit que `_ToggleAttunedLink`,
   `item_info_panel.dart:446-505` : `body` 13 w700 `textSecondary`, icône `Icons.sell_outlined` 14 px, zone de tap
   ≥44 px) qui ouvre directement l'éditeur de prix pertinent (§2). En lecture seule (`readOnly: true`, ex. arme
   équipée vue depuis l'onglet Personnage) : juste « Non estimé », sans lien.

## 2. Comment le fixer/modifier

### a. Objet personnalisé (`custom_item_form_sheet.dart`)

Nouveau champ **dans `AdvancedSection`** (`custom_item_form_sheet.dart:616-638`), au même niveau que le poids — un
prix est une donnée secondaire optionnelle, comme le poids et l'harmonisation, jamais un champ obligatoire de l'étape
2. Position : juste après `_weightField` (ligne 628), avant `_attunementFields` :

- `_label(l10n.customItemPriceSectionLabel)` (« Prix »).
- `NumericAmountStepper` centré (même recette que `currency_adjustment_sheet.dart:162-170`), `max: 999999`.
- `_label(l10n.customItemPriceCurrencySectionLabel)` (« Devise »), puis `CurrencyPickerChips` (§0), devise par défaut
  **or** (cohérent avec l'affichage actuel toujours en « po »).
- **Optionnel** : montant à `0` (valeur de départ du stepper, comme `_amount = 0` dans les sheets de monnaie) =
  **aucun prix stocké**, pas « objet gratuit » (même convention que le poids : `parseCustomItemWeightInput` retourne
  `null` si vide — ici, `0` est l'équivalent du « vide » pour un stepper qui ne connaît pas l'absence de valeur). Ce
  point est à confirmer explicitement par Matthias (§7) : il change la sémantique de « 0 » par rapport aux sheets de
  monnaie existantes, où `0` est un solde réel valide.
- `_hasAdvancedValue` (ligne 301) doit intégrer ce nouveau champ (section dépliée par défaut si un prix est déjà
  renseigné en édition), même règle que les autres champs de cette méthode.

### b. Objet du catalogue — surcharge

**Constat** : contrairement à ce que suggérait le contexte de la tâche, il n'existe **aucune** action « Modifier »
pour un objet du catalogue dans la sheet d'actions de l'inventaire solo aujourd'hui (`customItemEditModeOf` retourne
toujours `null` pour un objet non personnalisé, `custom_item_edit_rules.dart:19-24` ; `item_action_sheet.dart:346`
n'affiche la ligne que si `editMode != null`). Ce ticket doit donc **ajouter** cette entrée, uniquement pour le prix
(la quantité d'un objet du catalogue déjà possédé ne se modifie toujours pas autrement — hors périmètre) :

- `item_action_sheet.dart` : ajouter une `SheetActionRow` « Modifier » (icône `Icons.edit`) pour **tout** objet du
  catalogue quand un nouveau callback `onEditItemPrice` est fourni, juste avant la ligne « Retirer » (même position
  relative que l'actuelle ligne « Modifier »/« Enrichir » des objets personnalisés, ligne 346).
- Nouvelle sheet légère, **autonome** (ne touche pas à `_ItemQuantitySheetContent`, puisque ce contexte n'a pas de
  quantité à éditer) : titre « Prix de {nom} », légende `body` 12 `textMuted` rappelant le prix officiel actuel s'il
  existe (« Prix officiel : X po »), puis le même bloc stepper + `CurrencyPickerChips` que §2a, pré-rempli avec la
  surcharge actuelle si elle existe (sinon vide/0, **pas** le prix officiel pré-converti — aucune règle de conversion
  fiable d'un montant décimal en or vers un entier dans une autre devise). Pied : `SecondaryButton` Annuler +
  `PrimaryButton` Enregistrer (même gabarit que `currency_adjustment_sheet.dart:182-199`).

### c. Butin de groupe

**Dépendance vérifiée par le chef de projet le 27/11/2026, directement sur `origin/main`** (la copie locale utilisée
pour écrire cette spec était obsolète sur ce point précis — voir note en tête de document) : `showItemQuantitySheet`/
`ItemQuantitySheet` sont **déjà publiques** et `group_treasure_item_sheet.dart` existe (PR #314, mergée). La
généralisation attendue par `docs/spec-butin-groupe.md` §3 est donc **livrée**, sans dépendance restante.

La fiche d'un objet du butin prévoit, pour un objet du catalogue, que « Modifier » ouvre cette sheet de quantité
publique. Ce ticket **ajoute** à cette même sheet une section « Prix » optionnelle, identique au bloc de §2a/2b
(stepper + `CurrencyPickerChips`), affichée **sous** le stepper de quantité, séparée par un `SheetActionDivider`. Pour
un objet personnalisé du butin, le prix se fixe dans `custom_item_form_sheet.dart` généralisé (même formulaire que
l'inventaire, voir `docs/spec-butin-groupe.md` §3) — donc directement couvert par §2a, aucune duplication.

### d. Retirer une surcharge

Dans la sheet de §2b : un lien **« Retirer la surcharge »** (même gabarit que `_ToggleAttunedLink`, visible
uniquement si une surcharge existe déjà) au-dessus du pied de boutons. Tap → remet l'amount à 0/devise par défaut et
ferme directement la sheet (pas de dialogue de confirmation : non destructif, le prix officiel n'est jamais perdu),
snackbar de confirmation. Pas de bouton « Enregistrer » à presser en plus — cohérent avec l'absence de confirmation
sur le lien « Ne plus harmoniser » du panneau Infos.

## 3. États

- **Hors ligne, inventaire** : le prix (personnalisé ou surcharge) est une colonne `character_inventory` comme
  `custom_weight`/`custom_requires_attunement` — passe par la **même file hors ligne** que ces champs, aucun nouvel
  état d'exception.
- **Hors ligne, butin** : toute écriture du butin est déjà désactivée hors connexion (`docs/spec-butin-groupe.md` §5,
  pas de file hors ligne pour le butin) — « Modifier » (donc le prix) suit cette règle existante, même message
  `groupTreasureOfflineError`. Pas de comportement spécifique à inventer.
- **Valeur invalide/négative** : `NumericAmountStepper` borne déjà `[0, 999999]` sans négatif possible par
  construction (même composant que la monnaie) — aucun nouvel état d'erreur à afficher.
- **Montant à 0** : voir §2a — aucun prix stocké (à confirmer, §7), bouton Enregistrer toujours actif (0 est une
  valeur valide de « suppression du prix »).
- **Chargement/erreur réseau** de la sauvegarde : mêmes gabarits que les sheets voisines (snackbar d'erreur comme
  `showCurrencyAdjustmentSheet`/`showCustomItemFormSheet`), rien de spécifique au prix.

## 4. Accessibilité

- Chips de devise : `MaterialTapTargetSize.padded` comme `currency_conversion_sheet.dart:147` (zone ≥44 px, le
  `ChoiceChip` Material fait 32 px par défaut).
- Pastille « Modifié » : texte 11 px (plancher autorisé), jamais en dessous.
- Contraste : `textSecondary` sur `parchmentCard` déjà validé AA ailleurs dans ce panneau (cf. commentaire
  `currency_conversion_sheet.dart:284-286`) — aucune nouvelle combinaison de couleurs introduite.
- Lien « Fixer un prix »/« Retirer la surcharge » : `Semantics(button: true)` comme les liens existants du panneau.

## 5. Textes (.arb)

Le module personnages ne tutoie pas, le module groupes tutoie (constat confirmé sur les clés `groupTreasure*`
existantes, ex. `groupTreasureClaimNoCharacterCaption` : « Il te faut... »). Nouvelles clés, ton aligné sur le module
porteur :

| Clé | FR (inventaire/catalogue) | FR (butin, tutoie) |
|---|---|---|
| `itemPriceLabel` | Prix | *(réutilise la même clé, pas de doublon)* |
| `itemPriceValue` | {amount} {unit} | — |
| `itemPriceNotEstimatedValue` | Non estimé | — |
| `itemPriceOverriddenBadge` | Modifié | — |
| `itemPriceSetLink` | Fixer un prix | `groupTreasureItemPriceSetLink` : Fixe un prix |
| `itemPriceOverrideSheetTitle` | Prix de {itemName} | *(même sheet généralisée, même clé)* |
| `itemPriceOverrideOfficialCaption` | Prix officiel : {officialPrice} | — |
| `itemPriceOverrideRemoveLink` | Retirer la surcharge | `groupTreasureItemPriceOverrideRemoveLink` : Retire la surcharge |
| `itemPriceOverrideRemovedSnack` | Prix réinitialisé. | `groupTreasureItemPriceOverrideRemovedSnack` : Prix réinitialisé. |
| `itemPriceOverrideSaveButton` | Enregistrer | *(réutilise `groupTreasureUpdatedSnack` existante après écriture)* |
| `customItemPriceSectionLabel` | Prix | *(formulaire partagé, une seule clé)* |
| `customItemPriceCurrencySectionLabel` | Devise | *(idem)* |

Clés existantes à réutiliser : `itemInfoPanelCostLabel` (devient le libellé « Prix », ou garder « Coût » — à trancher,
voir §7), toutes les clés `currencyConversionSheet*`/`currencyAdjustmentSheet*` pour le vocabulaire des chips si
réutilisées telles quelles par le widget extrait.

## 6. Composants réutilisés tels quels

`_ItemInfoRow`, `NumericAmountStepper`, `AdvancedSection`, `SheetHeaderBar`, `PrimaryButton`/`SecondaryButton`,
`SheetActionRow`/`SheetActionDivider`, le motif `_chips` de `currency_conversion_sheet.dart` (à extraire), le gabarit
de `_ToggleAttunedLink` (pour les deux liens de ce ticket). Aucun nouveau token de couleur/espacement/rayon requis.

## 7. Décisions (tranchées le 27/11/2026)

1. **Prix absent → « Non estimé » + lien « Fixer un prix »** (décision de Matthias) : retenu.
2. **Montant à 0 = aucun prix stocké** (pas « objet gratuit ») : retenu (décision du chef de projet, par défaut à
   faible risque).
3. **Nouvelle pastille « Modifié »** (gabarit `NotProficientBadge` neutre, §1.2) : retenu.
4. **Libellé de la ligne** : renommée « Prix » partout (`itemInfoPanelCostLabel` → `itemPriceLabel`).
5. **Entrée « Modifier » nouvelle sur un objet du catalogue dans l'inventaire solo** (§2b) : ne sert **que** le prix,
   jamais la quantité (hors périmètre de ce ticket).
6. **Dépendance butin** (§2c) : vérifiée directement sur `origin/main` le 27/11/2026 — déjà livrée (voir §2c). Aucune
   dépendance restante.
7. **Stockage des données** : deux colonnes `price_override_amount`/`price_override_currency` sur
   `character_inventory` (servent à la fois de prix pour un objet personnalisé et de surcharge pour un objet du
   catalogue), et les deux clés jsonb équivalentes côté `group_treasure.items`. Retenu, confié à
   `dev-backend-supabase`.
