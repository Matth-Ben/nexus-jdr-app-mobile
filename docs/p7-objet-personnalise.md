# P7 — Objet personnalisé enrichi (spec DA + RAW consolidée)

Décision de Matthias (12/11/2026) : « Pour faciliter l'ajout d'objet personnalisé, demander au début **quel type d'objet** pour
proposer les champs associés (ex : une armure il faudra renseigner la CA mais pour une arme on est sur des dégâts et le type de
dé). De cette manière on pourra créer facilement des objets tout en ayant la logique des règles. » Champs retenus : **poids,
bonus magique +1/+2/+3, classe d'armure de base, harmonisation requise, types de dégâts**. Réponses : **armes personnalisées
équipables avec bonus d'attaque et de dégâts calculés** ; **édition d'un objet existant en dernière PR** ; **« Objet magique
ou autre » reste simple** (nom, description, poids, harmonisation, sans bonus de CA) ; **enchaîner les PR 0 à 4**. Migrations
dans le dépôt **web** (`H:/Projets/Labo/markdown-editor/supabase/migrations`), **appliquées par Matthias** (jamais par Claude
ni un agent). L'app ne lit les nouvelles colonnes qu'après leur application en production.
Défauts retenus (ambiguïtés RAW remontées par `regles-dnd`) : armure : CA de base **obligatoire** ; bonus magique réservé à
arme/armure/bouclier, **liste fermée 0/+1/+2/+3** ; plusieurs armures/boucliers équipés : même comportement que le catalogue
(le premier de chaque emplacement) ; **13 types de dégâts** (tranchant, perforant, contondant, acide, feu, foudre, froid,
force, nécrotique, poison, psychique, radiant, tonnerre ; valeur stockée en français minuscule singulier comme
`weapon_properties.damage_type`) ; dés multiples type 1d8 + 1d6 feu : hors périmètre ; poids en **kg** (conversion existante,
0,45 vs 0,5 kg/lb non tranchée) ; harmonisation : max 3 déjà imposé (`CharacterDetail.attunementCap`), un objet qui requiert
l'harmonisation sans l'être perd son **bonus magique** (pas sa CA de base) ; maîtrise d'une arme/armure personnalisée : évaluée
seulement si la catégorie est renseignée, sinon `unknown` (jamais deviné).

## État du code (le code est en avance)
Un formulaire existe déjà (`add_item_flow.dart` `_CustomItemPickerContent` ~l.763-1065) : bascule « Objet simple / Arme », dé de
dégâts (faces 4/6/8/10/12/20), 3 types de dégâts, propriétés en texte libre ; colonnes déjà en base (migration
`20261025090000`) : `custom_description`, `custom_damage_dice` (« NdM »), `custom_damage_type`, `custom_properties` (jsonb).
Lacunes : poids absent (`unitWeight`/`totalWeight` nuls pour un objet personnalisé), `armorProperties` lu seulement depuis
`items` (un objet personnalisé n'entre jamais dans la CA), `acBonus` nul, `requiresAttunement` toujours faux (UI masque
l'harmonisation des objets personnalisés : `item_info_panel.dart:135`, `item_action_sheet.dart:207`),
`ArmorProficiencyRules._gearOf` renvoie `null` si `isCustom` (P10 : `unknown`), `isEquippableItem` exige `!isCustom`
(`item_action_sheet.dart:67`), `WeaponAttackCalculator.isProficient` compare le **nom** de l'objet (une arme personnalisée
n'est jamais « maîtrisée »), le bonus magique d'arme n'est pas calculé (même pour le catalogue : « Non couvert »), aucune action
« Modifier », pas de composant « section repliable ». Même flux utilisé par « Ajouter une récompense » et le butin de groupe
(`pickInventoryAdditions`). Astuce d'architecture : pour un objet personnalisé armure/bouclier, le mapper construit un
`CharacterInventoryArmorProperties` (`acBase`, `acDexBonus` dérivé de la catégorie, `slot` `'armure'`/`'bouclier'`), donc
`ArmorClassCalculator`, la liste (P18) et les groupes fonctionnent presque sans changement ; seul ajout : `magicBonus`.

## Données (dépôt web) — colonnes à ajouter à `public.character_inventory`
`custom_kind` text null in ('arme','armure','bouclier','autre') ; `custom_magic_bonus` smallint null between 0 and 3 (null = 0) ;
`custom_ac_base` smallint null between 0 and 30 (bonus pour un bouclier) ; `custom_armor_category` text null in
('legere','intermediaire','lourde') ; `custom_weight` numeric(7,2) null >= 0 (kg par unité) ; `custom_requires_attunement`
boolean not null default false ; **pour l'arme (armes équipables avec attaque calculée)** : `custom_weapon_category` text null
in ('courante','guerre') et `custom_weapon_range` text null in ('melee','distance') (choix de la caractéristique et maîtrise) ;
élargir un éventuel CHECK de `custom_damage_type` aux 13 types. Cohérence : toutes ces colonnes nulles/`false` si `item_id`
non nul ; armure ⇒ `custom_ac_base` et `custom_armor_category` non nuls ; bouclier ⇒ `custom_ac_base` non nul ; bonus magique
non nul seulement pour arme/armure/bouclier. Aucun backfill (le type d'un ancien objet est déduit à la lecture :
`kind ?? (damageDice != null ? 'arme' : null)`), aucune nouvelle politique RLS. Fonctions de fiche partagée
(`build_character_sheet_json` / `get_shared_character`, cf. migrations `20261025100000` et `20261110090000`) : exposer les
nouvelles colonnes. Lectures côté app à compléter : `character_repository.dart` (~1883, 1650, 5123), `group_repository.dart`
(~480-486, sinon la CA des membres ignore l'armure personnalisée), `shared_character_mapper.dart` (~470), export RGPD
(`data_export_repository.dart`). Butin de groupe et import XML/création : forme simple conservée (`enriched: false`).

## Flux (DA) — une feuille modale 0,85 à deux états internes
**Étape 1 « TYPE D'OBJET »** (`DisplayText` title) : quatre tuiles verticales ≥ 64 (recette `_CatalogItemRow` : `AccentIconBadge`
40×40 + nom + sous-titre, `parchmentCard`, bordure `woodLight`, chevron, pas de radio ni défaut) : Arme (dégâts, type,
bonus magique), Armure (catégorie, CA, bonus), Bouclier (bonus de CA, bonus magique), Objet magique ou autre (nom, poids,
harmonisation) ; icônes `InventoryCategoryRules.iconFor` ; pied : Annuler. **Étape 2** : ligne « Type : Arme » + bouton
« Changer » (≥ 44, conserve nom/quantité/poids/harmonisation/description) ; ordre : Nom* → champs du type → `AdvancedSection` →
Quantité → pied (Annuler / Ajouter).
- **Arme** (visible) : nom* (≤ 200), dés `StepperCounter` 1..10 + faces d4/d6/d8/d10/d12 (d20 retiré de l'ajout ; un 1d20 déjà
  stocké reste affiché), défaut 1d6, **type de dégâts*** obligatoire sans défaut (13 valeurs, physiques d'abord) ; catégorie
  d'arme (courante/de guerre) et portée (corps à corps/distance) ; Avancé : bonus magique (`SegmentedToggle` Aucun/+1/+2/+3),
  propriétés (texte libre), poids, harmonisation, description.
- **Armure** (visible) : nom*, catégorie* (légère/intermédiaire/lourde, défaut légère), CA de base* (défaut 11/14/16 selon la
  catégorie tant que non modifié ; légende « Légère 11-12, intermédiaire 12-15, lourde 14-18 » : aide, jamais une limite), ligne
  lecture seule « Bonus de Dextérité : illimité / plafonné à +2 / aucun » (`InventoryArmorDexBonusFormatter`) ; Avancé : bonus
  magique, poids, harmonisation, description.
- **Bouclier** (visible) : nom*, bonus de CA* (défaut +2) ; Avancé : bonus magique, poids, harmonisation, description.
- **Objet magique ou autre** : nom*, description/notes ; Avancé : poids, harmonisation.
- **`AdvancedSection`** (nouveau composant) : en-tête ≥ 48 `expand_more/less` « Options avancées », replié par défaut,
  `Semantics(expanded)`, déplié automatiquement si erreur ou valeur non vide en édition.
- **Harmonisation** : `SwitchListTile` « Nécessite une harmonisation » (≥ 56) ; si activé et `attunedCount` connu : second
  interrupteur « Harmoniser maintenant » désactivé par défaut et à `attunedCount >= attunementCap (3)` avec légende
  `liveRegion` « Vous avez déjà 3 objets harmonisés. Cet objet sera créé non harmonisé… » ; la création n'est jamais bloquée.
- **Validations** : nom non vide ; arme : type de dégâts choisi ; armure/bouclier : CA valide ; bornes dés 1..10, CA armure 1..30,
  bonus de bouclier 1..5, poids 0..9999,99 (virgule ou point, vide = non renseigné) ; erreur inline texte explicite ; ligne
  `liveRegion` au-dessus du pied « Il manque : nom, type de dégâts » ; bouton Ajouter désactivé tant qu'invalide.
- **`MagicBonusBadge`** (`core/widgets/magic_bonus_badge.dart`, gabarit `NotProficientBadge`) : `parchmentCard`, contour `goldEnd`,
  `Icons.auto_awesome` 12 px + « +1 » `font.body` 11 w800 `woodDark`, `Semantics(label: 'Bonus magique +1')`, affichée si ≥ 1.
- **Carte d'inventaire** : nom + `DiceTypeBadge` + `MagicBonusBadge` + `NotProficientBadge` (se replie à ×2) ; sous-titre :
  « Arme · tranchant · x1 », « Armure intermédiaire · CA 15 · x1 », « Bouclier · +2 CA · x1 », « Objet personnalisé · x1 » ;
  harmonisation requise non harmonisée : `Icons.link_off` 12 px `textMuted` + sémantique (tous les objets, catalogue compris).
- **Détail** (`item_info_panel.dart`) : lignes Type, Poids unitaire, Bonus magique, Dégâts (« 1d8+1 tranchant »), Attaque
  (« dont +1 magique »), CA de base, Bonus Dex, Harmonisation ; légende « Bonus magique inactif tant que l'objet n'est pas
  harmonisé. » (CA de base de l'armure reste comptée) ; `attunable = !readOnly && requiresAttunement` (retire `!isCustom`) ;
  objet non enrichi : rendu strictement inchangé.
- **Actions** : « Modifier » / « Enrichir » (PR 4) ; `isEquippableItem` : équipable si objet personnalisé de type armure, bouclier
  **ou arme** (décision de Matthias).

## Règles
- **CA** : légère = base + Dex complet ; intermédiaire = base + Dex max +2 ; lourde = base seule ; bouclier = bonus (+2 par
  défaut), jamais de Dex ; + bonus magique de l'armure équipée + bonus magique du bouclier équipé, seulement si
  `equipped && (!requiresAttunement || isAttuned)`. `_firstEquippedWithArmorProperties` renvoie l'objet (pour `magicBonus`).
- **Attaque** : `d20 + mod. de caractéristique + maîtrise (si maîtrisé) + bonus magique` ; **dégâts** : `dés + mod. de
  caractéristique + bonus magique` (jamais la maîtrise). Caractéristique : Force en corps à corps, Dex à distance, finesse
  (propriété) = la meilleure des deux (comportement existant du calculateur). Maîtrise d'arme : selon `custom_weapon_category`
  (courante/de guerre) comparée aux maîtrises du personnage comme pour le catalogue ; catégorie non renseignée → maîtrise **non
  évaluée** (ne pas deviner : pas de bonus de maîtrise ajouté, légende « maîtrise non évaluée »). Le bonus magique est
  suspendu si l'objet requiert l'harmonisation sans l'être. Le calcul doit aussi profiter aux armes du **catalogue** si elles
  portent un bonus (`WeaponAttackCalculator` « Non couvert » aujourd'hui) : à ne faire que si les données catalogue existent (ne
  pas inventer).
- **Maîtrise d'armure (P10)** : `_gearOf` accepte un objet personnalisé s'il a une catégorie d'armure/bouclier renseignée.
- **Poids** : `unitWeight = custom_weight` (kg/unité), `totalWeight = unitWeight × quantité` ; vide = `null` (jamais « 0 kg »).
- **File hors ligne `inventory_item`** (`offline_inventory_writes.dart`) : nouvelles clés de payload optionnelles
  (`customKind`, `customMagicBonus`, `customAcBase`, `customArmorCategory`, `customWeight`, `customRequiresAttunement`,
  `customWeaponCategory`, `customWeaponRange`), `toInsertColumns`, `toRow`, validations à l'enfilage ET au rejeu (kind dans
  l'ensemble, bonus 0..3, CA 0..30, catégories, poids 0..9999,99), anciens payloads rejouables ; **la migration doit être
  appliquée en distant AVANT la sortie de l'app** (PostgREST refuse les colonnes inconnues au rejeu) ; édition hors ligne :
  nouvelle op `updateCustom` (instantané complet, dernière écriture gagnante).
- **Accessibilité** : cibles ≥ 44 (tuiles de type ≥ 64, dropdowns ≥ 48, interrupteurs ≥ 56, en-tête avancé ≥ 48), ordre de
  focus Nom → champs du type → Avancé → Quantité → Annuler → Ajouter, plancher 11 px, ×2,0/×3,0 sur 320 dp (feuille défilante,
  pied en colonne dès textScale ≥ 1,5, sélecteurs de catégorie/bonus en liste verticale `SelectableOptionTile` au même seuil),
  claviers numériques, jamais la couleur seule.
- **Clés .arb** (préfixe `customItem…`, `inventoryCardSubtitle…`, `itemInfoPanel…` : titres, types, catégories, libellés de
  champs, erreurs, légendes, sémantiques, à dériver du texte ci-dessus) ; retirer les chaînes `addItemFlowCustom…` devenues
  inutiles.

## Phasage (une PR chacune : dev-flutter → qa-testeur → code-reviewer)
**PR 0** tests du calculateur de CA et de `ArmorProficiencyRules` (dette `retours-utilisateurs.md` l.232 ; aussi le don « Maître
des armures intermédiaires » : plafond de Dex +3 non géré, D215). **PR 1** migration web + `build_character_sheet_json`, puis
lecture côté app (modèle, mappers fiche/partagée/groupes/liste, poids dans la jauge) ; aucun changement d'UI visible hors poids.
**PR 2** feuille en deux temps pour Arme et Autre, `AdvancedSection`, poids, bonus magique, harmonisation, `MagicBonusBadge`,
carte et détail, clés de file, validations, **armes équipables avec attaque/dégâts calculés**. **PR 3** Armure et Bouclier
(formulaire + CA + équipement + P10 + CA groupes et liste). **PR 4** édition / enrichissement d'un objet existant
(+ op `updateCustom` en file).
