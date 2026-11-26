# Spec : butin de groupe aligné sur l'inventaire (décision 91 et compléments du 26/11/2026)

Rédigée par `direction-artistique` le 26/11/2026 (lecture seule), décisions de Matthias en §7. Ticket : « Nexus : butin de
groupe, même système que l'inventaire (ajout, fiche, modifier, attribuer, retirer) ». Niveau **parchemin** (onglet de
l'écran Groupe, `parchmentBg`) ; aucune maquette ne couvre les groupes (`10-design-system.md` §8) : on calque
l'inventaire, sans nouveau token.

**Fait établi** : les écritures du butin ne passent **pas** par la file hors ligne (appels Supabase directs,
`group_repository.dart:710-818`, aucun code hors ligne dans `lib/features/groups/`, butin non mis en cache).

## 1. Ligne du butin

- `_TreasureItemRow` (`group_treasure_tab_body.dart:141`) remplacée par `CharacterInventoryItemCard` (badge de
  catégorie, « {catégorie} · x{qté} », poids), via un adaptateur `GroupTreasureItem → CharacterInventoryItem` (non
  équipé, non harmonisé). Entrée ancienne sans catégorie : badge générique `Icons.inventory_2_outlined` en `textMuted`.
- **Toucher la carte entière ouvre la fiche** (même pendant `isBusy`). **Le raccourci « S'attribuer » de la ligne est
  retiré** (décision de Matthias).

## 2. Fiche d'un objet du butin

Gabarit du panneau Infos (`item_info_panel.dart`) : `showModalBottomSheet`, `heightFactor 0.88`, `SheetHeaderBar` (nom
en majuscules), contenu défilant (`padding lg`), pied fixe.

**Contenu** : lignes `_ItemInfoRow` séparées par `SheetActionDivider` : **Provenance** (Catalogue ou Objet
personnalisé), **Quantité** (×N), puis les lignes déjà prévues par le panneau Infos (type, poids, coût, bonus magique,
harmonisation, dégâts, catégorie, portée, propriétés, CA, bonus de Dex ou de bouclier, rareté). Sans personnage : ni
« Attaque » ni « Set », harmonisation affichée « Requise » (`itemInfoPanelAttunementRequiredValue`). Puis titre
`DESCRIPTION` (`DisplayText` 11, `textSecondary`) et le texte (`body` 14, hauteur 1.4) ou « Aucune description
disponible. ». **Ne rien dupliquer** : extraire le corps de `_ItemInfoPanelContent` (lignes + description) en widget
public avec un paramètre `withoutCharacter`, utilisé par le panneau Infos et par la fiche du butin.

**Pied** (`fromLTRB(lg, sm, lg, lg)`, écarts `sm`) : `PrimaryButton` **S'attribuer** pleine largeur (désactivé pour un
MJ sans personnage, avec une légende `body` 12 `textSecondary` en dessous) ; en dessous, une rangée :
`SecondaryButton(surface: parchment, icon: Icons.edit)` **Modifier** et `DestructiveButton(icon: Icons.delete_outline)`
**Retirer du butin** (en dernier, à droite). Texte agrandi ≥ 1,5 : les trois boutons s'empilent (règle `_isLargeText`).
Pendant `isBusy` et **hors connexion** : les trois sont désactivés (voir §5). La fiche se ferme en renvoyant l'action
choisie ; `group_screen.dart` exécute la suite (convention du dépôt).

**MJ sans personnage** : il peut **modifier et retirer** (tout membre, décision 91 ; cohérent avec la bannière « tu peux
gérer le butin commun »), pas s'attribuer.

## 3. Ajouter et modifier avec le système de l'inventaire

**Partagé** (la destination devient un paramètre) :
- **Ajout** : `pickInventoryAdditions(enriched: true, attunedCount: null)` (catalogue + objet personnalisé en deux temps :
  arme, armure, bouclier, autre), le résultat écrit dans le butin au lieu de l'inventaire. **Garder la sélection
  multiple dans le catalogue** (demande du 27/09).
- **Modification d'un objet personnalisé** : `showCustomItemFormSheet(initial:)` ; généraliser
  `customItemInitialValuesOf` (aujourd'hui lié à `CharacterInventoryItem`). Un objet sans type (toutes les entrées
  actuelles) s'ouvre en mode « Enrichir », comme dans l'inventaire.
- **Sheet de quantité** : rendre public `_ItemQuantitySheetContent` (titre, valeur initiale, minimum, maximum, libellé du
  bouton) : ajout depuis le catalogue, attribution (`claim_group_treasure_item_sheet.dart` en est une copie : la
  remplacer), quantité du butin.
- **Confirmation de retrait** : `showRemoveInventoryItemConfirmationDialog` avec titre et corps en paramètres.

**Diffère encore** (pas de personnage) : pas d'Équiper, d'attaque calculée, de maîtrise ni d'« Harmoniser maintenant »
(`attunedCount: null`) ; **la quantité se modifie dans le formulaire** (nouveau paramètre ; l'inventaire la masque en
édition, `custom_item_form_sheet.dart:639`) ; pour un objet du **catalogue**, « Modifier » n'ouvre que la sheet de
quantité (min 1, sans max, bouton « Enregistrer »), description et détails en lecture seule ; **quantité 0
impossible** (on retire par « Retirer du butin »).

**Monnaie du butin : modifiable** (décision de Matthias) : ajouter, ajuster ou retirer des pièces **comme dans
l'inventaire** (même composant de tuiles de monnaie et même saisie que l'inventaire, `#242` : saisie directe, conversion),
en plus de « Répartir » qui reste. Pied du butin : `_AddRowButtons` de l'inventaire (tuile `DashedAddTile` « Objet » et
l'accès monnaie au même gabarit que dans l'inventaire).

**Disparaît** : `add_to_group_treasure_sheet.dart` (section OBJETS, `_TreasureDraftItemRow`, forme simple
`enriched: false`, validation groupée) et le bouton unique « Ajouter au butin du groupe ».

**Récompense de l'inventaire** (décision de Matthias, **dans cette PR**) : elle utilise encore la forme simple de l'objet
personnalisé ; la passer au formulaire en deux temps (même formulaire partagé).

**Données** : chaque objet du butin porte sa description, ses détails d'arme et d'armure, les champs `custom_*` et sa
catégorie (clés jsonb de `group_treasure.items`, mêmes noms que les colonnes de `character_inventory`) et un
**identifiant stable `entry_id`** (choix du chef de projet : renommer un objet ne doit pas casser `matches`, qui compare
le nom ; attribuer un `entry_id` aux entrées anciennes à la première écriture). L'**attribution** recopie toutes ces
données dans `character_inventory` (aujourd'hui seulement identifiant, nom et quantité, l. 797). Une lecture par `item_id`
est nécessaire pour la description d'un objet du catalogue.

## 4. Retirer

Dialogue (`SecondaryButton` Annuler, `DestructiveButton` Retirer) ; tous les exemplaires de l'objet sont retirés ; puis
la fiche se ferme, snackbar, liste rechargée (`ref.invalidate`). Les autres membres voient le changement à leur prochain
chargement (pas de temps réel sur le butin).

## 5. États

Chargement de la description d'un objet du catalogue : `CircularProgressIndicator(woodMedium)` à la place du texte
(actions actives). Erreur de lecture : message + `TextButton` Réessayer (≥ 44 px) dans la zone DESCRIPTION. Erreur
d'écriture : snackbar. **Hors connexion** (décision de Matthias) : Ajouter, Modifier, Retirer, S'attribuer et les
actions de monnaie **désactivés**, avec un message (pas de file hors ligne pour le butin : données partagées). **Objet
modifié ou attribué entre-temps** : relire `items` juste avant d'écrire (comme `claimTreasureItem`) ; si l'objet a
disparu ou ne correspond plus (par `entry_id`), ne rien écrire, recharger, message.

## 6. Textes (le butin tutoie)

Le butin n'a aujourd'hui aucune clé `.arb` (textes en dur) : les migrer. Nouvelles clés :

| Clé | FR | EN |
|---|---|---|
| `groupTreasureItemSourceLabel` | Provenance | Source |
| `groupTreasureItemSourceCatalog` | Catalogue | Catalog |
| `groupTreasureItemQuantityLabel` | Quantité | Quantity |
| `groupTreasureClaimButton` | S'attribuer | Claim |
| `groupTreasureClaimSheetTitle` | S'attribuer {itemName} | Claim {itemName} |
| `groupTreasureClaimNoCharacterCaption` | Il te faut un personnage dans ce groupe pour t'attribuer un objet. | You need a character in this group to claim an item. |
| `groupTreasureRemoveButton` | Retirer du butin | Remove from loot |
| `groupTreasureRemoveConfirmTitle` | Retirer {itemName} du butin ? | Remove {itemName} from the loot? |
| `groupTreasureRemoveConfirmBody` | {quantity, plural, =1{L'objet disparaît du butin pour tout le groupe.} other{Les {quantity} exemplaires disparaissent du butin pour tout le groupe.}} Cette action est définitive. | {quantity, plural, =1{The item disappears from the loot for the whole group.} other{All {quantity} copies disappear from the loot for the whole group.}} This can't be undone. |
| `groupTreasureRemovedSnack` | {itemName} retiré du butin. | {itemName} removed from the loot. |
| `groupTreasureUpdatedSnack` | Objet modifié. | Item updated. |
| `groupTreasureQuantitySheetTitle` | Quantité de {itemName} | Quantity of {itemName} |
| `groupTreasureStaleError` | Un autre membre vient de modifier ou d'attribuer cet objet. Vérifie et recommence. | Another member just changed or claimed this item. Check and try again. |
| `groupTreasureOfflineError` | Pas de connexion : le butin n'a pas été modifié. Réessaie une fois connecté. | No connection: the loot wasn't changed. Try again once you're online. |
| `groupTreasureDetailsLoadError` | Impossible de charger la description. | Couldn't load the description. |

Clés existantes à réutiliser : `addItemFlowCustomEntryLabel`, `itemActionSheetEditLabel`,
`itemActionSheetRemoveConfirmationCancelButton` / `…ConfirmButton`, `customItemSaveButton`, `itemInfoPanelDescription*`,
`characterInventoryTabBodyAddItemButtonLabel`, `addItemFlowCatalogOfflineRetryButton`, et celles de la monnaie de
l'inventaire.

## 7. Décisions de Matthias (26/11/2026)

1. Toucher un objet ouvre sa fiche ; **pas de raccourci « S'attribuer »** sur la ligne.
2. **Hors connexion : actions désactivées** (pas de file hors ligne pour le butin).
3. **Monnaie du butin modifiable** comme dans l'inventaire (en plus de « Répartir »).
4. **Récompense de l'inventaire alignée dans cette PR** sur le formulaire en deux temps.
5. Tout membre peut modifier ou retirer ; tous les champs d'un objet personnalisé ; ajout et modification = même système
   que l'inventaire (décision 91).
