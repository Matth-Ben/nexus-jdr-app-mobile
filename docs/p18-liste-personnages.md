# P18 — Liste des personnages : annulation d'archivage, PV/CA sur la carte, tri (spec DA)

Décision de Matthias (11/11/2026) : annuler l'archivage + PV/CA sur la carte + tri ; **pas de duplication**.
Défauts retenus (points à trancher de la DA) : requête de liste enrichie acceptée ; « Dernière ouverture »
**local** par appareil et par compte (pas de migration web) ; les groupes en jeu / archivés / morts restent
toujours dans cet ordre, le tri ne s'applique qu'au sein de chaque groupe ; PV/CA masqués sur les archivés
et les morts ; snackbar « {name} archivé » avec le nom ; PV en attente hors ligne superposés sur la carte si
le coût est faible, sinon dette ; liste uniquement (pas de snackbar d'annulation depuis la fiche).

## 1. Annuler l'archivage
- Après un `setArchived(isArchived: true)` **réussi** depuis `character_card_action_sheet.dart`
  (`_toggleArchived`) : snackbar « {name} archivé » + « Annuler ». Aucun snackbar pour « Désarchiver » ni
  en cas d'échec (messages d'erreur existants conservés). L'archivage reste **immédiat côté serveur** ;
  annuler = `setArchived(isArchived: false)` puis `invalidate(charactersProvider)`. Ne pas différer l'écriture.
- Extraire le patron de `showSpellSlotUsedSnackBar` (P9) vers `lib/core/widgets/undo_snack_bar.dart` :
  `showUndoSnackBar(context, message, undoLabel, announcement, onUndo)` (bouton `DisplayText` control,
  ≥ 44, `goldStart`, `Semantics(liveRegion)`, 6 s / 10 s sous `accessibleNavigation`, `hideCurrentSnackBar`,
  garde anti-double appui). `showSpellSlotUsedSnackBar` devient un appelant, sans changement de comportement.
  Pas de `SnackBarAction`.
- Le snackbar survit à la navigation : capturer avant l'`await` le repository et le `ProviderContainer`
  (`ProviderScope.containerOf(context)`) pour l'annulation, pas le `WidgetRef` de la liste.
- États : annulation réussie = silencieuse ; hors ligne au moment d'annuler = `characterOfflineNotPersistedMessage`
  (le personnage reste archivé, jamais de mise en file : `setArchived` n'en passe pas) ; erreur = message
  générique existant ; hors ligne à l'archivage = refus actuel, donc pas de snackbar.
- Libellés : `characterListArchivedSnackBarMessage(name)` FR « {name} archivé » / EN « {name} archived » ;
  `characterListArchivedSnackBarAnnouncement(name)` FR « {name} archivé. Bouton Annuler disponible. » /
  EN « {name} archived. Undo button available. » ; bouton : clé « Annuler » / « Undo » déjà utilisée par P9.

## 2. PV / CA sur la carte
- `CharacterSummary` : champs nullables `int? currentHp`, `int? maxHp`, `int? armorClass` (régénérer freezed).
  `null` = ne pas afficher (ancien cache), jamais « 0/0 ». Étendre le `select` de `fetchCharacters`
  (`current_hp, max_hp, armor_class_bonus`, `subclass_id` des classes, `character_ability_scores`,
  `character_class_options`, `character_inventory(... items(... armor_properties(...)))`, 2 requêtes
  `translations` sous-classes/aptitudes), calqué sur `group_repository.dart:~471-484`. **Ne pas copier la
  logique de CA une 3e fois** : extraire un helper partagé (ex. `ArmorClassResolver.fromRows(...)`) utilisé par
  `CharacterDetail.armorClass`, `GroupMemberRowMapper.toGroupMember` et la liste, avec `armor_class_bonus`.
- Hors ligne : valeurs du cache ; superposer les écritures PV en attente si le coût est faible
  (comme `_withPendingWrites`), sinon consigner l'écart en dette.
- Ligne entre « Race · Classe · Niv. » et la jauge XP : `Wrap(spacing: sm, runSpacing: xs)` de deux éléments
  (icône 16 px décorative `textSecondary` + texte `AppTypography.body(fontSize: 13, w700, textPrimary)`),
  jamais `font.display`, pas de fond ni de bordure, pas de jauge PV, pas de PV temporaires.
- États : en jeu PV > 0 → « PV 12/20 » + « CA 15 » ; en jeu 0 PV (pas mort) → `ZeroHpIndicator` (sorti
  de `character_vitals_card.dart` vers un widget partagé public, rendu inchangé) + « CA 15 » ; mort ou archivé →
  ligne masquée ; valeurs nulles → éléments omis (ligne omise si les trois sont nuls) ; hors ligne : valeurs du
  cache sans marquage ; mode sélection inchangé. Jamais « Inconscient » sur la liste (vocabulaire « À 0 PV »).
- Sémantique : un `Semantics(label)` par élément + `ExcludeSemantics` : « Points de vie : 12 sur 20 »,
  « Classe d'armure : 15 », « À 0 points de vie sur 20 ». Plancher 11 px, 320 dp et ×2,0 : retour à la ligne,
  sans troncature.
- Libellés : `characterCardHpValue(current, max)` « PV {current}/{max} » / « HP {current}/{max} » ;
  `characterCardArmorClassValue(value)` « CA {value} » / « AC {value} » ; `characterCardHpSemantics`
  « Points de vie : {current} sur {max} » / « Hit points: {current} of {max} » ;
  `characterCardArmorClassSemantics` « Classe d'armure : {value} » / « Armor class: {value} » ;
  `characterCardZeroHpSemantics(max)` « À 0 points de vie sur {max} » / « At 0 hit points out of {max} » ;
  réutiliser `characterVitalsCardZeroHpLabel` pour « À 0 PV ».

## 3. Tri
- Dans la feuille de filtre existante (icône entonnoir) : nouvelle section « TRIER PAR » **en tête**, mêmes
  styles que « STATUT »/« CLASSE » ; composant `SelectableOptionTile` (choix exclusif, `subtitleMaxLines: null`),
  pas `SegmentedToggle`. Titre « FILTRER ET TRIER » / « FILTER AND SORT ».
- Options : `defaultOrder` (« Par défaut » / « Default », sous-titre « En jeu, archivés, puis morts, par date de
  création »), `name` (« Nom (A → Z) » / « Name (A → Z) », « Au sein de chaque groupe »), `lastOpened`
  (« Dernière ouverture » / « Last opened », « Les plus récents d'abord, au sein de chaque groupe »).
  Sous-titres EN : « Active, archived, then dead, by creation date », « Within each group »,
  « Most recent first, within each group ».
- Règle : les 3 groupes restent dans l'ordre en jeu / archivés / morts ; le tri s'applique **au sein** de chaque
  groupe. Nom : insensible à la casse et aux accents (réutiliser l'utilitaire de `spell_name_filter.dart` /
  `skill_name_filter.dart`), tri stable. « Dernière ouverture » : horodatage **local** `{characterId: epochMs}`
  scopé par `ownerId`, écrit à l'ouverture de la **fiche** (`character_detail_screen.dart`), jamais ouvert =
  dernier de son groupe (ordre de création conservé), purge des identifiants absents à chaque chargement,
  pas de synchro entre appareils.
- Par session, non persisté (comme les filtres de classe/statut) ; seul l'horodatage d'ouverture est persisté.
- Architecture : `enum CharacterListSort { defaultOrder, name, lastOpened }` + `CharacterListSorter.sortBy(list,
  mode, lastOpened)` dans le domaine ; tri par défaut toujours appliqué par le repository
  (`CharacterListSorter.sort`, aussi utilisé par `data_export_repository.dart:86`) ; le choix est appliqué dans
  l'écran après `CharacterListFilter.apply`. `CharacterListFilterSelection` gagne `sort` ; « Réinitialiser »
  remet `defaultOrder`, `_hasSelection` en tient compte ; `_resetSearch` ne touche pas au tri.
- Pastille dorée `_FilterActiveDot` aussi quand `sort != defaultOrder` ; valeur sémantique du bouton
  « Filtre ou tri actif » / « Filter or sort active » ; libellé « Filtrer et trier les personnages » /
  « Filter and sort characters ». Un tri seul ne déclenche jamais l'état vide « recherche sans résultat ».
- Clés : `characterListFilterSheetTitle` (modifiée), `characterListFilterSheetSortSection` « TRIER PAR » /
  « SORT BY », `characterListSortDefault|Name|LastOpenedTitle/Subtitle`, `characterListFilterButtonLabel` et
  `characterListFilterButtonActiveValue` (modifiées).

## Accessibilité transverse
Cibles ≥ 44, grande police ×2,0 sur 320 dp, polices pixel plafonnées par palier, plancher 11 px, jamais la
couleur seule, annonces `liveRegion`.
