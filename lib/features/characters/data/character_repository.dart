import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/reference_data_cache.dart';
import '../../../core/network/connectivity_checker.dart';
import '../domain/character_detail.dart';
import '../domain/character_failure.dart';
import '../domain/character_summary.dart';
import '../domain/currency_kind.dart';
import '../domain/inventory_catalog_item.dart';
import '../domain/level_up_apply_result.dart';
import '../domain/level_up_choice_kind.dart';
import '../domain/level_up_choice_selection.dart';
import '../domain/level_up_level_data.dart';
import '../domain/level_up_subclass_option.dart';
import '../domain/portrait_storage_path_resolver.dart';
import '../domain/rest_type.dart';
import '../domain/reward_item_draft.dart';
import '../domain/spell_slot_progression.dart';
import '../domain/write_outcome.dart';
import 'character_detail_row_mapper.dart';
import 'character_error_mapper.dart';
import 'character_inventory_row_mapper.dart';
import 'character_row_mapper.dart';
import 'character_skill_row_mapper.dart';
import 'character_spell_row_mapper.dart';
import 'class_feature_row_mapper.dart';
import 'inventory_catalog_row_mapper.dart';
import 'level_up_choice_row_mapper.dart';

/// Langue d'affichage des noms de race/classe, en dur pour l'instant : l'app
/// démarre en français uniquement (`docs/cahier-des-charges/07-source-donnees-i18n.md`),
/// aucune gestion de locale n'existe encore côté client. À remplacer par une
/// vraie préférence de langue le jour où l'anglais est introduit.
const String _locale = 'fr';

/// Passerelle vers les personnages du joueur connecté.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que `AuthRepository`
/// (`features/auth/data/auth_repository.dart`).
abstract class CharacterRepository {
  /// Récupère tous les personnages du joueur connecté, dans leur ordre de
  /// création.
  Future<List<CharacterSummary>> fetchCharacters();

  /// Récupère le détail complet d'un personnage (onglet "Personnage" de la
  /// fiche, `presentation/character_detail_screen.dart`). Lève une
  /// [CharacterFailure] si [characterId] n'existe pas ou n'appartient pas au
  /// joueur connecté (RLS) — les deux cas sont indistinguables côté client
  /// par construction (la policy RLS filtre la ligne avant qu'elle
  /// n'atteigne PostgREST), ce qui est le comportement voulu : ne jamais
  /// laisser deviner qu'un personnage existe chez un autre joueur.
  Future<CharacterDetail> fetchCharacterDetail(String characterId);

  /// Écrit directement `characters.current_hp`/`temporary_hp` — pas de
  /// brouillon local, contrairement à l'assistant de création : ce
  /// personnage existe déjà. Le calcul des nouvelles valeurs (absorption des
  /// PV temporaires, plafond à `max_hp`...) est fait en amont par
  /// `domain/hp_adjustment.dart`, cette méthode ne fait qu'écrire le
  /// résultat déjà calculé.
  ///
  /// **Mode hors-ligne (voir `docs/cahier-des-charges/01-architecture-technique.md`,
  /// section "Mode hors-ligne")** : vérifie la connectivité *avant* de
  /// tenter la requête réseau (jamais deviné depuis le type d'exception
  /// levée par un échec réseau — plus robuste, voir
  /// `core/network/connectivity_checker.dart`).
  /// - Connectivité absente : ne tente même pas le réseau, met directement
  ///   l'écriture en file d'attente locale (`PendingCharacterWriteQueue`,
  ///   upsert — une nouvelle écriture en attente pour ce personnage
  ///   remplace la précédente, jamais un ajout à une liste) et retourne
  ///   [WriteOutcome.queued], sans jamais lever d'exception pour ce cas : le
  ///   joueur ne doit jamais voir une erreur pour une simple absence de
  ///   réseau.
  /// - Connectivité présente : tente l'écriture réseau normalement. Un échec
  ///   à ce stade (vrai problème serveur, pas un souci de connectivité)
  ///   relance une [CharacterFailure] normalement, **n'est jamais mis en
  ///   file** — mettre en file un échec qui n'est pas dû à l'absence de
  ///   réseau masquerait un vrai bug en le faisant échouer silencieusement
  ///   en boucle à chaque tentative de synchro future. Un succès retourne
  ///   [WriteOutcome.synced].
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  });

  /// Envoie [bytes] (déjà recadrées en carré, voir
  /// `presentation/widgets/portrait_crop_screen.dart`) dans le bucket
  /// `character-portraits` (RLS écriture restreinte à `{user_id}/...`,
  /// lecture publique), puis met à jour `characters.portrait_url` avec
  /// l'URL publique résultante. Retourne cette URL.
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  });

  /// Supprime le fichier de portrait actuel du bucket (best-effort si
  /// [portraitUrl] ne pointe pas vers ce bucket, ex. une URL externe saisie
  /// via le flux "Utiliser une URL" — voir
  /// `domain/portrait_storage_path_resolver.dart`) puis met
  /// `characters.portrait_url` à `null`.
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  });

  /// Écrit directement `characters.xp` avec [newXp] (déjà calculé par
  /// l'appelant — `xp actuel + montant saisi`, voir
  /// `presentation/widgets/add_xp_sheet.dart`) : même principe que
  /// [updateHp], aucun calcul métier fait ici.
  ///
  /// Mode hors-ligne : mêmes règles exactement que [updateHp] (voir sa
  /// documentation) — payload mis en file `{newXp: ...}` si la connectivité
  /// est absente. Note pour l'appelant
  /// (`presentation/character_detail_screen.dart::_addXp`) : ne jamais
  /// déclencher l'ouverture automatique de l'écran de montée de niveau sur
  /// un [WriteOutcome.queued], l'XP n'étant alors pas encore confirmée côté
  /// serveur.
  Future<WriteOutcome> addXp({required String characterId, required int newXp});

  /// Écrit directement `character_spell_slots.slots_used` pour
  /// [characterId]/[slotLevel] avec [slotsUsed] (déjà calculé par l'appelant
  /// — valeur actuelle + 1, voir
  /// `presentation/character_detail_screen.dart::_castSpell`) : même
  /// principe que [updateHp]/[addXp], aucun calcul métier fait ici. Action
  /// "Lancer" d'un sort niveau ≥ 1 (sheet d'actions de sort,
  /// `presentation/widgets/spell_action_sheet.dart`) — un sort niveau 0 ne
  /// passe jamais par cette méthode (rien à persister, voir la spec de la
  /// tâche qui l'a introduite).
  ///
  /// Mode hors-ligne (décision chef de projet) : contrairement à
  /// [updateHp]/[addXp], cette écriture n'est **jamais** mise dans
  /// [PendingCharacterWriteQueue] (scopée explicitement à `hp`/`xp`, voir sa
  /// documentation de classe) — absence de connectivité détectée via
  /// [ConnectivityChecker] retourne directement [WriteOutcome.queued] sans
  /// tenter le réseau, mais **sans persister** l'intention nulle part : elle
  /// n'est donc jamais synchronisée automatiquement au retour du réseau
  /// (contrairement à ce que son nom pourrait suggérer). L'appelant affiche
  /// tout de même le même message "hors ligne" que [updateHp]/[addXp] (même
  /// [WriteOutcome], voir la spec de la tâche), par cohérence d'affichage —
  /// **pas** parce que la donnée sera un jour synchronisée.
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  });

  /// Écrit (upsert) `character_feature_uses.uses_remaining` pour
  /// [characterId]/[classFeatureId] avec [usesRemaining] (déjà calculé par
  /// l'appelant — valeur actuelle - 1, voir
  /// `presentation/character_detail_screen.dart::_useClassFeature`) : même
  /// principe que [castSpell]. Action "Utiliser" d'une aptitude de classe à
  /// usage limité (sheet d'actions d'aptitude,
  /// `presentation/widgets/class_feature_action_sheet.dart`).
  ///
  /// Upsert (jamais un simple `UPDATE`) : même rationale que
  /// `SupabaseCharacterRepository._resetFeatureUses` — une aptitude jamais
  /// encore utilisée n'a pas de ligne `character_feature_uses` existante.
  ///
  /// Mode hors-ligne : mêmes règles exactement que [castSpell] (voir sa
  /// documentation), y compris la limite assumée (pas de persistance/synchro
  /// différée).
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  });

  /// Action "Utiliser" un objet consommable de l'onglet "Inventaire" (sheet
  /// d'actions d'objet, `presentation/widgets/item_action_sheet.dart`) :
  /// écrit `character_inventory.quantity = newQuantity` si
  /// `newQuantity > 0`, ou supprime la ligne si `newQuantity <= 0` —
  /// décision UX tranchée par le chef de projet : une quantité tombée à 0
  /// n'est jamais conservée telle quelle, la ligne disparaît de
  /// l'inventaire. [newQuantity] est déjà calculé par l'appelant (quantité
  /// actuelle - 1), même principe que [castSpell]/[useClassFeature].
  ///
  /// Mode hors ligne : mêmes règles exactement que [castSpell]/
  /// [useClassFeature] (jamais mise en file, voir leur documentation) —
  /// décision chef de projet explicite pour toutes les écritures de
  /// l'onglet "Inventaire" introduites avec cette méthode.
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  });

  /// Action "Équiper"/"Déséquiper" — écrit `character_inventory.equipped`
  /// tel quel, aucun calcul ici (même principe que [updateHp]). Ne touche
  /// jamais un champ de classe d'armure (n'existe nulle part dans
  /// [CharacterDetail] à cette itération, voir la spec de la tâche).
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  });

  /// Action "Retirer" (avec confirmation côté sheet) — supprime la ligne
  /// `character_inventory` [inventoryId].
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  });

  /// Ajustement de monnaie (sheet déclenchée par une stat box de tête
  /// d'onglet, `presentation/widgets/currency_adjustment_sheet.dart`) :
  /// écrit la nouvelle valeur *absolue* [newAmount] déjà calculée par
  /// l'appelant pour la colonne `characters.currency_*` de [currency] — même
  /// principe que [updateHp]/[addXp].
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  });

  /// Ajout d'un objet du catalogue (sheet "Depuis le catalogue",
  /// `presentation/widgets/add_item_flow.dart`) — insère une nouvelle ligne
  /// `character_inventory` pour [itemId]/[quantity]. Insère toujours une
  /// nouvelle ligne plutôt que de fusionner avec une ligne existante du même
  /// [itemId] (pas demandé par la spec de la tâche, et deux lots distincts
  /// du même objet — ex. équipé vs non équipé — doivent pouvoir coexister).
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  });

  /// Ajout d'un objet personnalisé (sheet "Objet personnalisé") — insère une
  /// nouvelle ligne `character_inventory` avec `custom_name`, `item_id`
  /// nul.
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
  });

  /// Ajoute une récompense (bouton "cadeau" du bandeau de l'onglet
  /// "Inventaire", `presentation/widgets/add_reward_sheet.dart`) : au plus
  /// un `UPDATE` (monnaie, si [newCurrencyTotals] est non vide — valeurs
  /// déjà calculées par l'appelant, mêmes principe que [adjustCurrency]) et
  /// un `INSERT` batché (tous les [items] en un seul appel, jamais un par
  /// ligne — spec de la tâche : "un seul appel réseau à la validation").
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  });

  /// Catalogue complet des objets `items` (nom résolu, catégorie, coût,
  /// poids) — sheets "Depuis le catalogue" (onglet "Inventaire" et sheet
  /// "Ajouter une récompense", même flux réutilisé en mode collecte locale,
  /// voir `presentation/widgets/add_item_flow.dart`). Aucun filtre par
  /// catégorie côté requête : le regroupement/tri par catégorie est fait
  /// côté écran, même principe que `equipment_step_screen.dart::_shopSection`.
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog();

  /// Aptitudes/choix `class_features` de la classe [classId] au niveau
  /// [targetLevel] — écran "Montée de niveau"
  /// (`presentation/level_up_screen.dart`), étapes "Aptitudes de classe
  /// automatiques", "Choix à faire" (increment 2) et vérification de
  /// blocage (voir `domain/level_up_block_reason.dart`).
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  });

  /// Applique une montée de niveau déjà validée par le joueur (écran
  /// "Montée de niveau", récapitulatif) : incrémente
  /// `character_classes.level`, ajoute [hpGain] à `characters.max_hp`/
  /// `current_hp`, insère une ligne `character_level_hp`, et — depuis
  /// l'increment 2 — écrit [choice] s'il est fourni (étape "Choix à faire") :
  /// - [LevelUpChoiceKind.abilityScoreImprovement] : upsert
  ///   `character_ability_scores.score` (score final = score actuel +
  ///   allocation) **et** insert `character_ability_increases` (une ligne
  ///   par caractéristique augmentée, `source: 'asi'`) — les deux tables
  ///   doivent être écrites, voir la documentation de
  ///   [LevelUpChoiceSelection.abilityAllocations].
  /// - [LevelUpChoiceKind.subclass] : `character_classes.subclass_id`,
  ///   combiné dans le même `UPDATE` que `level`.
  /// - [LevelUpChoiceKind.fightingStyle]/[LevelUpChoiceKind.favoredEnemy] :
  ///   insert `character_class_options`.
  ///
  /// Depuis l'increment 3 (étape "Sorts") : recalcule aussi
  /// `character_spell_slots` pour la classe primaire, depuis zéro (upsert
  /// complet pour le nouveau niveau, jamais un delta — voir
  /// `domain/spell_slot_progression.dart::SpellSlotProgression.slotsForLevel`
  /// et la documentation de [_upsertSpellSlots]). [className] est requis
  /// pour ce recalcul (déjà résolu par l'appelant, voir `LevelUpStepData`
  /// côté `presentation/providers/level_up_provider.dart`) : ni
  /// `character_classes` ni `classes` ne portent le nom de classe
  /// directement exploitable ici (résolu via `translations`, voir la
  /// documentation de classe de [SupabaseCharacterRepository]).
  ///
  /// [hpRolled] et [hpGain] sont déjà calculés par l'appelant (voir
  /// `domain/level_up_hit_points_calculator.dart`), cette méthode ne fait
  /// qu'écrire le résultat déjà calculé — même principe que [updateHp].
  ///
  /// Ne touche jamais `characters.xp` : soit l'XP a déjà été écrite par
  /// [addXp] (déclenchement automatique au franchissement d'un seuil), soit
  /// le déclenchement est manuel et l'XP ne doit pas bouger (voir la spec de
  /// la tâche qui a produit cette méthode).
  ///
  /// Lève une [CharacterFailure] si le personnage n'a pas exactement une
  /// ligne `character_classes` (aucune classe, ou multiclassage — non pris
  /// en charge par la montée de niveau automatique à cet incrément).
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  });

  /// Applique un repos (lien "Prendre un repos", onglet "Personnage" —
  /// `presentation/widgets/rest_sheet.dart`), voir [RestType] pour l'effet
  /// exact de chaque valeur :
  /// - [RestType.long] : `characters.current_hp = max_hp`,
  ///   `characters.temporary_hp = 0` ; recalcule (upsert) tous les
  ///   `character_spell_slots` de la classe primaire pour son niveau actuel
  ///   (`slots_used` toujours remis à 0), même fonction de progression que
  ///   [applyLevelUp] ; et réinitialise (upsert)
  ///   `character_feature_uses.uses_remaining` pour toutes les
  ///   `class_features` de **toutes** les classes du personnage
  ///   (multiclassage inclus) atteintes par leur niveau respectif, quel que
  ///   soit leur `rest_type`.
  /// - [RestType.short] : réinitialise uniquement (upsert) les
  ///   `character_feature_uses` (toutes classes, multiclassage inclus)
  ///   dont le `rest_type` correspondant vaut `'repos_court'`. Ne touche ni
  ///   les PV ni `character_spell_slots`.
  ///
  /// [className] : même rôle et même rationale que sur [applyLevelUp] (voir
  /// sa documentation) — nécessaire au recalcul de
  /// `character_spell_slots` pour un repos long, résolu par l'appelant
  /// depuis la classe primaire (`character_detail_screen.dart`). Ignoré
  /// pour un repos court (aucun recalcul de sorts).
  ///
  /// `character_spell_slots`/`character_feature_uses` ne sont jamais
  /// initialisées à la création de personnage (gaps pré-existants
  /// documentés) : un personnage sans aucune classe ou sans aucune ligne
  /// préexistante n'a simplement rien à réinitialiser sur ces tables,
  /// jamais une erreur.
  ///
  /// Isolation cross-utilisateur : même garantie que le reste de ce
  /// fichier (vérification explicite de `characters.owner_id`, RLS en
  /// filet de sécurité).
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  });

  /// Supprime le rattachement [characterCampaignId] (`character_campaigns`)
  /// — lien "Quitter l'histoire", carte "Aventures" de l'onglet
  /// "Personnage" (`presentation/widgets/character_adventures_card.dart`).
  ///
  /// Aucun filtre explicite sur `owner_id` ici contrairement au reste de ce
  /// fichier : `character_campaigns` n'a pas de colonne `owner_id` propre
  /// (voir `20260830100100_create_character_campaigns.sql` côté dépôt web),
  /// la RLS (`owns_character(character_id)`) est donc la seule garantie
  /// d'isolation pour cette écriture, pas un filet de sécurité redondant
  /// côté client comme ailleurs dans ce fichier.
  Future<void> leaveStory({required String characterCampaignId});
}

/// Implémentation réelle, basée sur `Supabase.instance.client`.
///
/// La table `characters` est protégée par RLS (`owner_id = auth.uid()`,
/// voir `02-modele-donnees.md`) : le filtre explicite sur `owner_id`
/// ci-dessous est donc redondant avec la policy serveur, mais gardé pour la
/// clarté de la requête (et pour ne jamais dépendre implicitement d'une
/// policy qu'on ne voit pas depuis ce dépôt).
///
/// Note : les noms de race/classe sont résolus via la table `translations`
/// (colonnes réelles `entity_type`, `entity_id`, `field_name`, `locale`,
/// `value`) plutôt que par un `select` imbriqué unique. `translations` est
/// une table
/// polymorphe (un même `entity_id` peut désigner une ligne de `races`, de
/// `classes`, etc. selon `entity_type`) : PostgREST ne peut pas déduire de
/// relation de clé étrangère pour l'embarquer automatiquement dans le
/// `select` de `characters`. On récupère donc d'abord les personnages (avec
/// leurs `race_id`/`class_id` bruts), puis on résout les noms en une requête
/// `translations` par type d'entité, filtrée sur les identifiants
/// effectivement rencontrés.
///
/// ## Cache hors-ligne de la fiche personnage ouverte ([fetchCharacterDetail])
///
/// Même stratégie "réseau d'abord, cache en secours" que
/// `SupabaseCharacterCreationRepository` (`character_creation/data/
/// character_creation_repository.dart`, voir sa doc de classe pour le
/// rationale détaillé) : [fetchCharacterDetail] regroupe toutes les lignes
/// brutes nécessaires (row `characters` principal + toutes les
/// sous-requêtes de traduction/résolution) dans un seul payload JSON, écrit
/// dans [_cache] (best-effort) après un succès réseau, puis passe ce même
/// payload par [_mapCharacterDetailPayload] — le mapper pur partagé par les
/// deux chemins (réseau et cache), jamais de logique de parsing dupliquée.
///
/// Seule [fetchCharacterDetail] utilise ce cache : les autres méthodes de ce
/// repository restent des appels réseau directs sans repli (écritures, ou
/// lectures hors périmètre de la fiche elle-même comme
/// [fetchLevelUpLevelData] — voir la consigne de la tâche qui a introduit ce
/// cache).
///
/// **Isolation par utilisateur (décision chef de projet, non négociable)** :
/// la clé de cache est `'character_detail:$ownerId:$characterId'`, jamais
/// `'character_detail:$characterId'` seul. Contrairement aux catalogues de
/// référence (données publiques), la fiche personnage est une donnée privée
/// protégée par RLS — sans le `ownerId` dans la clé, un changement de compte
/// sur le même appareil pourrait, dans un scénario improbable mais réel (un
/// futur lien profond vers une route `characterId`, réseau indisponible à ce
/// moment précis), faire relire les données mises en cache par un *autre*
/// joueur, sans jamais repasser par la vérification RLS. Pas besoin de vider
/// le cache à la déconnexion : une clé scoped par `ownerId` suffit, un autre
/// compte ne retombe jamais sur la même entrée.
class SupabaseCharacterRepository implements CharacterRepository {
  /// [_pendingWrites]/[_connectivityChecker] requis explicitement (pas de
  /// valeur par défaut fabriquée en interne) : même philosophie que le reste
  /// de ce dépôt ("échouer/exiger explicitement plutôt que deviner", voir
  /// par ex. `_requireOwnerId`/`_applyAbilityScoreImprovement`) — et
  /// nécessaire en pratique pour les tests, qui doivent pouvoir injecter un
  /// [ConnectivityChecker] factice sans jamais toucher au canal de
  /// plateforme réel de `connectivity_plus` (indisponible dans `flutter
  /// test`).
  SupabaseCharacterRepository(
    this._client,
    this._cache,
    this._pendingWrites,
    this._connectivityChecker,
  );

  final SupabaseClient _client;
  final ReferenceDataCache _cache;
  final PendingCharacterWriteQueue _pendingWrites;
  final ConnectivityChecker _connectivityChecker;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async {
    final ownerId = _requireOwnerId();

    try {
      final characterRows = await _client
          .from('characters')
          .select('''
            id,
            name,
            portrait_url,
            xp,
            race_id,
            character_classes(class_id, level, is_primary)
          ''')
          .eq('owner_id', ownerId)
          .order('created_at');

      final raceIds = CharacterRowMapper.collectRaceIds(characterRows);
      final classIds = CharacterRowMapper.collectClassIds(characterRows);

      final raceNames = await _fetchTranslatedNames(
        entityType: 'race',
        entityIds: raceIds,
      );
      final classNames = await _fetchTranslatedNames(
        entityType: 'class',
        entityIds: classIds,
      );

      return characterRows
          .map(
            (row) => CharacterRowMapper.toSummary(
              row,
              raceNames: raceNames,
              classNames: classNames,
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    final ownerId = _requireOwnerId();
    // Scopée par ownerId — voir la documentation de classe
    // ("Isolation par utilisateur").
    final cacheKey = 'character_detail:$ownerId:$characterId';

    try {
      final row = await _client
          .from('characters')
          .select('''
            id,
            name,
            portrait_url,
            xp,
            current_hp,
            max_hp,
            temporary_hp,
            race_id,
            subrace_id,
            race_custom_text,
            background_id,
            alignment_id,
            sexe,
            age,
            height,
            weight,
            eyes,
            skin,
            hair,
            currency_gp,
            currency_pp,
            currency_ep,
            currency_sp,
            currency_cp,
            appearance_text,
            traits_text,
            ideals_text,
            bonds_text,
            flaws_text,
            backstory_text,
            allies_text,
            features_text,
            treasure_text,
            character_classes(class_id, level, is_primary, classes(saving_throw_proficiencies, hit_die)),
            character_ability_scores(ability_id, score),
            character_skill_proficiencies(skill_id, proficiency),
            character_tool_proficiencies(tool_id, custom_text),
            character_languages(language_id),
            character_spells(spell_id, status),
            character_spell_slots(slot_level, slots_total, slots_used),
            character_feature_uses(class_feature_id, uses_remaining),
            character_inventory(
              id, item_id, custom_name, quantity, equipped, notes,
              items(
                category, weight, cost, rarity, requires_attunement, consumable,
                weapon_properties(damage_dice, damage_type, properties, range),
                armor_properties(ac_base, ac_dex_bonus, strength_requirement, stealth_disadvantage)
              )
            ),
            character_campaigns(id, story_id, stories(title, cover_image_path))
          ''')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (row == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }

      final payload = await _buildCharacterDetailPayload(row);
      await _writeCacheBestEffort(cacheKey, payload);
      return _mapCharacterDetailPayload(payload);
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        cacheKey,
        _mapCharacterDetailPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterError(error);
    } catch (_) {
      final cached = await _mappedFromCache(
        cacheKey,
        _mapCharacterDetailPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async {
    final ownerId = _requireOwnerId();

    if (!await _connectivityChecker.hasConnection()) {
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': currentHp, 'temporaryHp': temporaryHp},
      );
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .update({'current_hp': currentHp, 'temporary_hp': temporaryHp})
          .eq('id', characterId)
          .eq('owner_id', ownerId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) async {
    final ownerId = _requireOwnerId();
    // Un nom de fichier horodaté (plutôt qu'un chemin fixe par personnage)
    // évite tout problème de cache CDN/navigateur sur l'URL publique après
    // un remplacement de portrait — voir `removePortrait` pour la
    // suppression explicite de l'ancien fichier par le joueur.
    final path =
        '$ownerId/$characterId/${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await _client.storage
          .from(PortraitStoragePathResolver.bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
      final publicUrl = _client.storage
          .from(PortraitStoragePathResolver.bucket)
          .getPublicUrl(path);

      await _client
          .from('characters')
          .update({'portrait_url': publicUrl})
          .eq('id', characterId)
          .eq('owner_id', ownerId);

      return publicUrl;
    } on StorageException catch (error) {
      throw CharacterFailure(
        error.message.isNotEmpty
            ? error.message
            : "Impossible d'envoyer le portrait. Réessayez.",
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {
    final ownerId = _requireOwnerId();
    try {
      final path = PortraitStoragePathResolver.resolve(portraitUrl);
      if (path != null) {
        await _client.storage.from(PortraitStoragePathResolver.bucket).remove([
          path,
        ]);
      }
      await _client
          .from('characters')
          .update({'portrait_url': null})
          .eq('id', characterId)
          .eq('owner_id', ownerId);
    } on StorageException catch (error) {
      throw CharacterFailure(
        error.message.isNotEmpty
            ? error.message
            : 'Impossible de retirer le portrait. Réessayez.',
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) async {
    final ownerId = _requireOwnerId();

    if (!await _connectivityChecker.hasConnection()) {
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': newXp},
      );
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .update({'xp': newXp})
          .eq('id', characterId)
          .eq('owner_id', ownerId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) async {
    final ownerId = _requireOwnerId();

    // Voir la documentation de [CharacterRepository.castSpell] : jamais mis
    // en file, ce cas retourne directement [WriteOutcome.queued] sans écrire
    // nulle part.
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      final characterRow = await _client
          .from('characters')
          .select('id')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();
      if (characterRow == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }

      await _client
          .from('character_spell_slots')
          .update({'slots_used': slotsUsed})
          .eq('character_id', characterId)
          .eq('slot_level', slotLevel);
      return WriteOutcome.synced;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) async {
    final ownerId = _requireOwnerId();

    // Voir la documentation de [CharacterRepository.useClassFeature]/
    // [CharacterRepository.castSpell] : jamais mis en file.
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      final characterRow = await _client
          .from('characters')
          .select('id')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();
      if (characterRow == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }

      await _client.from('character_feature_uses').upsert({
        'character_id': characterId,
        'class_feature_id': classFeatureId,
        'uses_remaining': usesRemaining,
      }, onConflict: 'character_id,class_feature_id');
      return WriteOutcome.synced;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  }) async {
    // Session uniquement — voir la documentation de classe ("Isolation
    // cross-utilisateur") : `character_inventory` n'a pas de colonne
    // `owner_id` propre, la RLS (`owns_character(character_id)`) est la
    // garantie d'isolation, même principe que [leaveStory]. Le filtre
    // `.eq('character_id', characterId)` ci-dessous reste une redondance
    // défensive côté client, pas un filet de sécurité indispensable.
    _requireOwnerId();

    // Voir la documentation de [CharacterRepository.useInventoryItem] :
    // jamais mis en file.
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      if (newQuantity <= 0) {
        await _client
            .from('character_inventory')
            .delete()
            .eq('id', inventoryId)
            .eq('character_id', characterId);
      } else {
        await _client
            .from('character_inventory')
            .update({'quantity': newQuantity})
            .eq('id', inventoryId)
            .eq('character_id', characterId);
      }
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('character_inventory')
          .update({'equipped': equipped})
          .eq('id', inventoryId)
          .eq('character_id', characterId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('character_inventory')
          .delete()
          .eq('id', inventoryId)
          .eq('character_id', characterId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) async {
    // `characters` porte bien `owner_id` (contrairement à
    // `character_inventory`) : même filtre explicite que [updateHp]/[addXp].
    final ownerId = _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .update({currency.columnName: newAmount})
          .eq('id', characterId)
          .eq('owner_id', ownerId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client.from('character_inventory').insert({
        'character_id': characterId,
        'item_id': itemId,
        'quantity': quantity,
      });
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client.from('character_inventory').insert({
        'character_id': characterId,
        'custom_name': customName,
        'quantity': quantity,
      });
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) async {
    final ownerId = _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      if (newCurrencyTotals.isNotEmpty) {
        await _client
            .from('characters')
            .update({
              for (final entry in newCurrencyTotals.entries)
                entry.key.columnName: entry.value,
            })
            .eq('id', characterId)
            .eq('owner_id', ownerId);
      }

      if (items.isNotEmpty) {
        await _client.from('character_inventory').insert([
          for (final item in items)
            {
              'character_id': characterId,
              if (item.itemId != null) 'item_id': item.itemId,
              if (item.customName != null) 'custom_name': item.customName,
              'quantity': item.quantity,
            },
        ]);
      }
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async {
    try {
      final rows = await _client
          .from('items')
          .select('id, category, weight, cost')
          .order('id', ascending: true);
      final names = await _fetchTranslatedNames(
        entityType: 'item',
        entityIds: InventoryCatalogRowMapper.collectIds(rows),
      );
      return InventoryCatalogRowMapper.toInventoryCatalogItems(
        rows,
        names: names,
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) async {
    try {
      final featureRows = await _client
          .from('class_features')
          .select('id, level, choice_type, uses_per_rest')
          .eq('class_id', classId)
          .eq('level', targetLevel)
          .order('id', ascending: true);

      final choiceRow = featureRows.firstWhere(
        (row) => row['choice_type'] != null,
        orElse: () => const <String, dynamic>{},
      );
      final automaticRows = [
        for (final row in featureRows)
          if (row['choice_type'] == null) row,
      ];

      final featureNames = await _fetchTranslatedNames(
        entityType: 'class_feature',
        entityIds: ClassFeatureRowMapper.collectIds(automaticRows),
      );

      final choiceType = choiceRow.isEmpty
          ? null
          : choiceRow['choice_type'] as String?;
      final choiceClassFeatureId = choiceRow.isEmpty
          ? null
          : (choiceRow['id'] as num).toInt();

      // `'sous_classe'` uniquement : les 2 autres choix résolus (increment 2,
      // `style_combat`/`ennemi_jure`) n'ont pas de table de référence en
      // base, voir `domain/level_up_choice_options.dart` (listes codées en
      // dur, résolues directement dans l'écran).
      final availableSubclasses = choiceType == 'sous_classe'
          ? await _fetchAvailableSubclasses(
              classId: classId,
              targetLevel: targetLevel,
            )
          : const <LevelUpSubclassOption>[];

      return LevelUpLevelData(
        choiceType: choiceType,
        choiceClassFeatureId: choiceClassFeatureId,
        availableSubclasses: availableSubclasses,
        automaticFeatures: [
          for (final row in automaticRows)
            ClassFeatureRowMapper.toCharacterClassFeature(
              row,
              names: featureNames,
              // Aucune utilisation à afficher ici (pas la carte "Aptitudes
              // de classe" de l'onglet Compétences) : map vide, jamais
              // consommée puisque ces aptitudes viennent d'être obtenues.
              usesRemaining: const {},
            ),
        ],
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  /// Sous-classes disponibles pour [classId] à [targetLevel]
  /// (`subclasses.available_from_level = targetLevel`), noms/descriptions
  /// résolus via `translations` — étape "Choix à faire", variante
  /// [LevelUpChoiceKind.subclass]. Appelée uniquement quand
  /// `fetchLevelUpLevelData` a déjà déterminé `choiceType == 'sous_classe'`
  /// pour ce niveau (une requête réseau évitée pour tous les autres cas).
  Future<List<LevelUpSubclassOption>> _fetchAvailableSubclasses({
    required Object classId,
    required int targetLevel,
  }) async {
    final rows = await _client
        .from('subclasses')
        .select('id, available_from_level')
        .eq('class_id', classId)
        .eq('available_from_level', targetLevel)
        .order('id', ascending: true);

    final ids = LevelUpChoiceRowMapper.collectSubclassIds(rows);
    final names = await _fetchTranslatedNames(
      entityType: 'subclass',
      entityIds: ids,
    );
    final descriptions = await _fetchTranslatedField(
      entityType: 'subclass',
      fieldName: 'description',
      entityIds: ids,
    );

    return LevelUpChoiceRowMapper.toSubclassOptions(
      rows,
      names: names,
      descriptions: descriptions,
    );
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) async {
    final ownerId = _requireOwnerId();
    try {
      final classRows = await _client
          .from('character_classes')
          .select('id, level')
          .eq('character_id', characterId);
      if (classRows.length != 1) {
        throw const CharacterFailure(
          'Montée de niveau non prise en charge pour un personnage '
          'multiclassé, ou personnage sans classe.',
        );
      }
      final classRow = classRows.single;
      final newLevel = (classRow['level'] as num).toInt() + 1;

      final characterRow = await _client
          .from('characters')
          .select('max_hp, current_hp')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();
      if (characterRow == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }
      final newMaxHp = (characterRow['max_hp'] as num).toInt() + hpGain;
      final newCurrentHp = (characterRow['current_hp'] as num).toInt() + hpGain;

      // Compromis assumé, même rationale que
      // `CharacterCreationRepository.createCharacter` (voir sa
      // documentation) : pas de RPC Postgres atomique à cet incrément, ces
      // écritures sont séquentielles côté client. Ordre choisi pour limiter
      // les dégâts d'un échec partiel :
      // 1. `characters` d'abord (si cet update échoue, rien d'autre n'a
      //    encore été écrit) ;
      // 2. `character_classes.level` (si celui-ci échoue après le premier,
      //    l'incohérence reste limitée à un `max_hp`/`current_hp` déjà
      //    incrémentés sans changement de niveau ni d'historique — visible
      //    et corrigible manuellement, jamais un personnage fantôme).
      //    Increment 2 : le choix `subclass_id` est combiné dans ce même
      //    `UPDATE` quand [choice] est une sous-classe, plutôt qu'un appel
      //    séparé — même écriture, même niveau de risque, une requête de
      //    moins.
      // 3. `character_spell_slots` (increment 3, étape "Sorts" — voir
      //    [_upsertSpellSlots]), placé ici plutôt qu'après le choix : ce
      //    recalcul ne dépend que de `className`/`newLevel`, jamais de
      //    [choice], donc rien ne justifie de le faire attendre derrière un
      //    choix optionnel. Même donnée de jeu vivante que le choix
      //    ci-dessous (pas un pur historique) : un échec à cette étape doit
      //    laisser le niveau déjà incrémenté (visible, corrigible), même
      //    rationale que 4.
      // 4. Le choix restant (ASI ou `character_class_options`), s'il y en a
      //    un — placé ici (juste après le niveau, avant l'historique PV) car
      //    c'est une donnée de jeu vivante au moins aussi significative que
      //    le niveau lui-même (contrairement à `character_level_hp`, pur
      //    historique) : mieux vaut qu'un échec à cette étape laisse le
      //    niveau déjà incrémenté (visible, corrigible) plutôt que de la
      //    reporter après l'historique, qui doit rester la toute dernière
      //    écriture (voir 5.).
      // 5. `character_level_hp`, purement un historique, toujours en
      //    dernier. Contrairement à `createCharacter`, aucun nettoyage
      //    ("best effort") n'est possible ici : il n'y a pas de ligne
      //    fraîchement créée à supprimer, seulement des colonnes déjà
      //    existantes mises à jour.
      await _client
          .from('characters')
          .update({'max_hp': newMaxHp, 'current_hp': newCurrentHp})
          .eq('id', characterId)
          .eq('owner_id', ownerId);

      final classUpdate = <String, dynamic>{'level': newLevel};
      if (choice != null && choice.kind == LevelUpChoiceKind.subclass) {
        classUpdate['subclass_id'] = choice.subclassId;
      }
      await _client
          .from('character_classes')
          .update(classUpdate)
          .eq('id', classRow['id']);

      await _upsertSpellSlots(
        characterId: characterId,
        className: className,
        newLevel: newLevel,
      );

      if (choice != null) {
        await _applyChoice(
          characterId: characterId,
          level: newLevel,
          choice: choice,
        );
      }

      await _client.from('character_level_hp').insert({
        'character_id': characterId,
        'level': newLevel,
        'hp_rolled': hpRolled,
        'method': hpMethod,
      });

      return LevelUpApplyResult(
        newLevel: newLevel,
        newMaxHp: newMaxHp,
        newCurrentHp: newCurrentHp,
      );
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  }) async {
    final ownerId = _requireOwnerId();
    try {
      // Vérification d'appartenance explicite en tout premier — avant toute
      // écriture, y compris pour un repos court qui ne touche jamais
      // `characters` : sans ce garde-fou, un repos court n'aurait aucune
      // requête filtrée sur `owner_id`, ne reposant que sur la RLS de
      // `character_classes`/`class_features` (lecture seule) pour
      // l'isolation — insuffisant pour l'écriture `character_feature_uses`
      // qui suit. Récupère aussi `max_hp`, nécessaire au repos long.
      final characterRow = await _client
          .from('characters')
          .select('max_hp')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();
      if (characterRow == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }

      // Toutes les classes du personnage (multiclassage inclus) — utilisées
      // à la fois pour retrouver la classe primaire (repos long, recalcul
      // des emplacements de sorts) et pour réinitialiser les aptitudes de
      // *toutes* les classes (voir [_resetFeatureUses] : la lecture de la
      // fiche, `_buildCharacterDetailPayload`/`_mapCharacterDetailPayload`,
      // gère déjà explicitement ce cas, un repos doit suivre la même règle
      // plutôt qu'ignorer silencieusement les classes secondaires).
      final classRows = await _client
          .from('character_classes')
          .select('class_id, level, is_primary')
          .eq('character_id', characterId);

      if (type == RestType.long) {
        final maxHp = (characterRow['max_hp'] as num).toInt();
        await _client
            .from('characters')
            .update({'current_hp': maxHp, 'temporary_hp': 0})
            .eq('id', characterId)
            .eq('owner_id', ownerId);

        // Recalcul des emplacements de sorts : classe primaire uniquement
        // (pas de calcul multiclassé), même convention déjà établie pour
        // les emplacements de sorts à la montée de niveau ([applyLevelUp]
        // rejette d'ailleurs explicitement un personnage multiclassé) —
        // contrairement à la réinitialisation des aptitudes ci-dessous, qui
        // doit couvrir toutes les classes.
        final primaryClassRow = classRows.firstWhere(
          (row) => row['is_primary'] == true,
          orElse: () => const <String, dynamic>{},
        );
        if (primaryClassRow.isNotEmpty) {
          await _resetSpellSlots(
            characterId: characterId,
            className: className,
            totalLevel: (primaryClassRow['level'] as num).toInt(),
          );
        }
      }

      if (classRows.isNotEmpty) {
        final classIds = <Object>{
          for (final row in classRows) row['class_id'] as Object,
        };
        final classLevels = <String, int>{
          for (final row in classRows)
            (row['class_id'] as Object).toString(): (row['level'] as num)
                .toInt(),
        };
        await _resetFeatureUses(
          characterId: characterId,
          classIds: classIds,
          classLevels: classLevels,
          onlyShortRest: type == RestType.short,
        );
      }
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) async {
    // Garde-fou session — voir la documentation de
    // [CharacterRepository.leaveStory] : ce filtre n'est *pas* réutilisé
    // dans la requête ci-dessous (aucune colonne `owner_id` sur
    // `character_campaigns`), la RLS reste la seule garantie réelle.
    _requireOwnerId();
    try {
      await _client
          .from('character_campaigns')
          .delete()
          .eq('id', characterCampaignId);
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  /// Repos long uniquement : réinitialise `character_spell_slots` pour la
  /// classe primaire ([className]) à son niveau actuel ([totalLevel]), en
  /// recalculant les totaux via [SpellSlotProgression.slotsForLevel] — même
  /// fonction que [_upsertSpellSlots] (montée de niveau) — plutôt que de se
  /// contenter de remettre à 0 les lignes déjà existantes.
  ///
  /// Décision chef de projet (revue QA) : un simple `UPDATE` sur les lignes
  /// déjà existantes est insuffisant, parce que `character_spell_slots`
  /// n'est écrite nulle part à la création de personnage — seulement par
  /// [_upsertSpellSlots] lors d'une montée de niveau passée par l'app. Un
  /// personnage lanceur de sorts qui n'a jamais monté de niveau via l'app
  /// (cas réel, y compris après un futur import XML, Phase 3) a donc zéro
  /// ligne `character_spell_slots` : un simple `UPDATE` ne ferait alors
  /// rien, et un repos long resterait sans effet visible sur ses
  /// emplacements de sorts.
  ///
  /// `slots_used` est toujours remis à 0 (jamais préservé, contrairement à
  /// [_upsertSpellSlots] où une montée de niveau ne doit pas effacer une
  /// consommation déjà faite) : c'est tout le sens d'un repos long. Aucune
  /// ligne écrite pour un niveau de sort à 0, même convention que
  /// [_upsertSpellSlots]/`CharacterDetailRowMapper.parseSpellSlots`. Ne fait
  /// rien pour une classe non lanceuse ou l'Occultiste, même limite que
  /// [_upsertSpellSlots].
  Future<void> _resetSpellSlots({
    required String characterId,
    required String className,
    required int totalLevel,
  }) async {
    final totals = SpellSlotProgression.slotsForLevel(className, totalLevel);
    final payload = [
      for (var i = 0; i < totals.length; i++)
        if (totals[i] > 0)
          {
            'character_id': characterId,
            'slot_level': i + 1,
            'slots_total': totals[i],
            'slots_used': 0,
          },
    ];
    if (payload.isEmpty) return;

    await _client
        .from('character_spell_slots')
        .upsert(payload, onConflict: 'character_id,slot_level');
  }

  /// Réinitialise (upsert) `character_feature_uses.uses_remaining` pour les
  /// `class_features` de **toutes** les classes du personnage ([classIds])
  /// atteintes par leur niveau respectif ([classLevels]) — personnage
  /// multiclassé inclus. Réutilise littéralement
  /// [ClassFeatureRowMapper.filterAttained], même règle de filtrage que la
  /// lecture de la fiche (`_buildCharacterDetailPayload`/
  /// `_mapCharacterDetailPayload`, qui gère déjà explicitement ce cas pour la
  /// même raison : "pour un personnage multiclassé où plusieurs
  /// `class_id`... sont mélangés").
  ///
  /// [onlyShortRest] détermine quelles aptitudes à usage limité sont
  /// rechargées (voir [_rechargedAmount]) : `false` pour un repos long
  /// (toutes, quel que soit leur `rest_type`), `true` pour un repos court
  /// (seulement `rest_type == 'repos_court'`).
  ///
  /// Upsert (jamais un simple `UPDATE`) : `character_feature_uses` n'est
  /// jamais initialisée à la création de personnage ni à la montée de
  /// niveau (gap pré-existant documenté, voir `_upsertSpellSlots`) — une
  /// aptitude jamais encore utilisée n'a donc pas de ligne, et doit malgré
  /// tout ressortir avec son plein total après un repos. `onConflict`
  /// explicite sur la clé primaire composite réelle de la table
  /// (`character_id, class_feature_id` — voir `02-modele-donnees.md`),
  /// même principe que [_upsertSpellSlots].
  Future<void> _resetFeatureUses({
    required String characterId,
    required Set<Object> classIds,
    required Map<String, int> classLevels,
    required bool onlyShortRest,
  }) async {
    if (classIds.isEmpty) return;

    final featureRows = await _client
        .from('class_features')
        .select('id, class_id, level, uses_per_rest')
        .inFilter('class_id', classIds.toList());

    final attainedRows = ClassFeatureRowMapper.filterAttained(
      featureRows,
      classLevels: classLevels,
    );

    final payload = [
      for (final row in attainedRows)
        if (_rechargedAmount(
              row['uses_per_rest'] as Map<String, dynamic>?,
              onlyShortRest: onlyShortRest,
            )
            case final amount?)
          {
            'character_id': characterId,
            'class_feature_id': row['id'],
            'uses_remaining': amount,
          },
    ];
    if (payload.isEmpty) return;

    await _client
        .from('character_feature_uses')
        .upsert(payload, onConflict: 'character_id,class_feature_id');
  }

  /// Total d'utilisations à écrire pour l'aptitude décrite par [usesPerRest]
  /// si ce repos doit la recharger, `null` sinon — jamais rien à écrire dans
  /// `character_feature_uses` dans ce cas (aptitude non rechargée par ce
  /// type de repos, ou pas d'usage limité du tout).
  ///
  /// `null` dans 2 cas distincts, tous deux traités identiquement (aucune
  /// ligne écrite) :
  /// - [usesPerRest] lui-même `null` — aptitude passive, voir
  ///   `CharacterClassFeature.isPassive`.
  /// - `uses_per_rest->>'amount'` absent alors que `rest_type` est renseigné
  ///   — cas réel constaté côté seed (ex. `class_features.id = 6`,
  ///   `{amount: null, rest_type: 'repos_court'}`, vérifié contre le stack
  ///   local) : même convention que
  ///   `ClassFeatureRowMapper.toCharacterClassFeature` (`usesMax` nul ⇒
  ///   `isPassive`), pour ne jamais écrire un total inconnu.
  int? _rechargedAmount(
    Map<String, dynamic>? usesPerRest, {
    required bool onlyShortRest,
  }) {
    if (usesPerRest == null) return null;
    if (onlyShortRest && usesPerRest['rest_type'] != 'repos_court') {
      return null;
    }
    return (usesPerRest['amount'] as num?)?.toInt();
  }

  /// Recalcule `character_spell_slots` pour la classe primaire au nouveau
  /// niveau [newLevel] — increment 3, étape "Sorts". **Recalcul complet
  /// depuis zéro** (upsert de tous les paliers dont le total théorique à
  /// [newLevel] est `> 0`), jamais un delta incrémental : contrairement au
  /// reste de cette méthode, `character_spell_slots` n'est écrit nulle part
  /// ailleurs dans ce dépôt (ni à la création de personnage), donc l'état
  /// antérieur en base n'est pas fiable comme point de départ (voir le point
  /// critique de la spec visuelle direction-artistique de l'étape "Sorts",
  /// `presentation/level_up_screen.dart`).
  ///
  /// Aucune ligne écrite pour un niveau de sort à 0 — même convention que la
  /// lecture existante (`CharacterDetailRowMapper.parseSpellSlots` : absence
  /// de ligne == 0).
  ///
  /// Préserve `slots_used` d'une ligne déjà existante (un joueur peut avoir
  /// déjà consommé des emplacements avant de monter de niveau) tant qu'il
  /// reste cohérent avec le nouveau total (`slots_used <= slots_total`) ; le
  /// replie sur `slots_total` sinon plutôt que de laisser une valeur
  /// incohérente ou de planter — ne devrait jamais arriver en pratique (les
  /// totaux ne font que croître avec le niveau).
  ///
  /// Ne fait rien pour une classe non lanceuse ou l'Occultiste (magie de
  /// pacte, mécanisme différent, hors périmètre visuel de cet incrément) :
  /// [SpellSlotProgression.slotsForLevel] retourne alors 9 zéros, donc
  /// [nonZeroLevels] est vide.
  Future<void> _upsertSpellSlots({
    required String characterId,
    required String className,
    required int newLevel,
  }) async {
    final totals = SpellSlotProgression.slotsForLevel(className, newLevel);
    final nonZeroLevels = [
      for (var i = 0; i < totals.length; i++)
        if (totals[i] > 0) i + 1,
    ];
    if (nonZeroLevels.isEmpty) {
      return;
    }

    final existingRows = await _client
        .from('character_spell_slots')
        .select('slot_level, slots_used')
        .eq('character_id', characterId)
        .inFilter('slot_level', nonZeroLevels);
    final usedByLevel = <int, int>{
      for (final row in existingRows)
        (row['slot_level'] as num).toInt():
            (row['slots_used'] as num?)?.toInt() ?? 0,
    };

    final payload = [
      for (final spellLevel in nonZeroLevels)
        _spellSlotUpsertRow(
          characterId: characterId,
          spellLevel: spellLevel,
          total: totals[spellLevel - 1],
          existingUsed: usedByLevel[spellLevel] ?? 0,
        ),
    ];

    // `onConflict` explicite sur la clé primaire réelle de la table
    // (`character_spell_slots_pkey`, `(character_id, slot_level)` — vérifié
    // contre le schéma du stack Supabase local) : sans lui, `upsert` de ce
    // package retombe sur la contrainte `UNIQUE`/`PRIMARY KEY` par défaut de
    // la table, ce qui fonctionnerait ici aussi, mais le rendre explicite
    // documente l'intention et évite une ambiguïté si une autre contrainte
    // unique était ajoutée un jour.
    await _client
        .from('character_spell_slots')
        .upsert(payload, onConflict: 'character_id,slot_level');
  }

  /// Une ligne de payload `character_spell_slots` — factorisé hors de
  /// [_upsertSpellSlots] pour isoler le filet de sécurité `slots_used`
  /// (documenté sur l'appelant) dans un simple `return`, plutôt qu'une
  /// expression de collection `for` moins lisible.
  Map<String, dynamic> _spellSlotUpsertRow({
    required String characterId,
    required int spellLevel,
    required int total,
    required int existingUsed,
  }) {
    final used = existingUsed > total ? total : existingUsed;
    return {
      'character_id': characterId,
      'slot_level': spellLevel,
      'slots_total': total,
      'slots_used': used,
    };
  }

  /// Écrit [choice] pour la table concernée — voir la documentation de
  /// [CharacterRepository.applyLevelUp]. Ne fait rien pour
  /// [LevelUpChoiceKind.subclass] : déjà écrit dans le même `UPDATE` que
  /// `character_classes.level` par l'appelant.
  Future<void> _applyChoice({
    required String characterId,
    required int level,
    required LevelUpChoiceSelection choice,
  }) async {
    switch (choice.kind) {
      case LevelUpChoiceKind.subclass:
        return;
      case LevelUpChoiceKind.abilityScoreImprovement:
        await _applyAbilityScoreImprovement(
          characterId: characterId,
          level: level,
          allocations: choice.abilityAllocations!,
        );
      case LevelUpChoiceKind.fightingStyle:
      case LevelUpChoiceKind.favoredEnemy:
        await _client.from('character_class_options').insert({
          'character_id': characterId,
          'class_feature_id': choice.classFeatureId,
          'level': level,
          'chosen_value': choice.chosenValue,
        });
    }
  }

  /// Écrit une augmentation de caractéristique sur **les deux** tables
  /// concernées (voir l'avertissement de la tâche qui a produit cette
  /// méthode) :
  /// 1. `character_ability_scores.score` — la table des scores
  ///    actuels/vivants, celle que lit tout le reste de l'app
  ///    (`CharacterDetail.abilityScores`, modificateurs, jets de
  ///    sauvegarde...). Le score final est recalculé ici depuis le score
  ///    *actuellement* en base (relu juste avant, jamais fait confiance à
  ///    une valeur mise en cache côté écran) + l'allocation — même principe
  ///    que `newMaxHp`/`newCurrentHp` ci-dessus (delta appliqué à une valeur
  ///    fraîchement relue, pas une expression SQL : PostgREST ne supporte
  ///    pas `score = score + increase` dans un payload `UPDATE`).
  /// 2. `character_ability_increases` — historique/audit, une ligne par
  ///    caractéristique augmentée (`source: 'asi'`). N'alimente aucun
  ///    affichage : oublier cette table ne casse rien de visible
  ///    immédiatement, d'où l'insistance de la documentation de la tâche à
  ///    ne jamais l'omettre.
  ///
  /// [allocations] ne contient que les caractéristiques effectivement
  /// augmentées (1 ou 2 entrées, jamais de valeur à 0 — voir
  /// [LevelUpChoiceSelection.abilityAllocations]). Avec une répartition
  /// "+1/+1" sur deux caractéristiques, la boucle ci-dessous écrit les deux
  /// séquentiellement (pas de transaction/RPC, même compromis assumé que le
  /// reste de cette méthode) : un échec réseau entre les deux itérations
  /// laisserait une seule caractéristique augmentée alors que le niveau/PV
  /// auraient déjà été appliqués — incohérence mineure et déjà dans la même
  /// famille de compromis que `createCharacter`, pas une régression propre à
  /// cette méthode.
  Future<void> _applyAbilityScoreImprovement({
    required String characterId,
    required int level,
    required Map<String, int> allocations,
  }) async {
    final abilityIds = allocations.keys.toList();
    final currentRows = await _client
        .from('character_ability_scores')
        .select('ability_id, score')
        .eq('character_id', characterId)
        .inFilter('ability_id', abilityIds);
    final currentScores = <String, int>{
      for (final row in currentRows)
        row['ability_id'] as String: (row['score'] as num).toInt(),
    };

    for (final abilityId in abilityIds) {
      final increase = allocations[abilityId]!;
      final currentScore = currentScores[abilityId];
      if (currentScore == null) {
        // Ne devrait pas arriver (une ligne `character_ability_scores`
        // existe pour les 6 caractéristiques dès la création, voir
        // `character_creation_repository.dart::createCharacter`) : échoue
        // explicitement plutôt que de deviner un score de départ, même
        // philosophie que `hitDie` (`CharacterDetailClassRow`).
        throw CharacterFailure(
          "Score actuel introuvable pour la caractéristique '$abilityId' : "
          "impossible d'appliquer l'augmentation de caractéristique.",
        );
      }
      final newScore = currentScore + increase;
      if (newScore > 20) {
        // Plafond RAW 5e : un score de caractéristique ne dépasse jamais 20.
        // Filet de sécurité serveur — l'écran (`level_up_screen.dart`)
        // désactive déjà le stepper avant d'atteindre ce cas, mais cette
        // méthode ne doit jamais faire confiance uniquement à l'UI pour une
        // écriture. Échoue explicitement plutôt que de plafonner
        // silencieusement à 20 : un plafonnage silencieux livrerait moins de
        // points que promis sans jamais le signaler au joueur.
        throw CharacterFailure(
          "Caractéristique '$abilityId' déjà à $currentScore : "
          'impossible de dépasser le plafond de 20.',
        );
      }

      await _client
          .from('character_ability_scores')
          .update({'score': newScore})
          .eq('character_id', characterId)
          .eq('ability_id', abilityId);

      await _client.from('character_ability_increases').insert({
        'character_id': characterId,
        'level': level,
        'ability_id': abilityId,
        'increase': increase,
        'source': 'asi',
      });
    }
  }

  /// Identifiant du joueur connecté, ou lève une [CharacterFailure] "session
  /// expirée" — factorisé depuis [fetchCharacters] pour être réutilisé par
  /// toutes les méthodes ajoutées pour la fiche personnage.
  String _requireOwnerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
      );
    }
    return ownerId;
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `entityType`
  /// dont l'identifiant est dans [entityIds]. Retourne une map vide sans
  /// requête si [entityIds] est vide (rien à résoudre). Le parsing de la
  /// réponse est délégué à [CharacterRowMapper.parseTranslatedNames] (testé
  /// indépendamment du réseau).
  Future<Map<String, String>> _fetchTranslatedNames({
    required String entityType,
    required Set<String> entityIds,
  }) {
    return _fetchTranslatedField(
      entityType: entityType,
      fieldName: 'name',
      entityIds: entityIds,
    );
  }

  /// Généralisation de [_fetchTranslatedNames] à un [fieldName] arbitraire
  /// (ex. `'description'` pour les sous-classes de l'étape "Choix à faire",
  /// increment 2) — même règles (map vide sans requête si [entityIds] est
  /// vide, parsing délégué à [CharacterRowMapper.parseTranslatedNames]).
  Future<Map<String, String>> _fetchTranslatedField({
    required String entityType,
    required String fieldName,
    required Set<String> entityIds,
  }) async {
    final rows = await _fetchTranslationRows(
      entityType: entityType,
      fieldName: fieldName,
      entityIds: entityIds,
    );
    return CharacterRowMapper.parseTranslatedNames(rows);
  }

  /// Récupère les lignes brutes de `translations` (colonnes réelles
  /// `entity_id`/`value`) pour [entityType]/[fieldName] dont l'identifiant
  /// est dans [entityIds]. Retourne une liste vide sans requête si
  /// [entityIds] est vide.
  ///
  /// Séparée de [_fetchTranslatedField] (qui l'appelle puis parse le
  /// résultat) pour que [_buildCharacterDetailPayload] puisse mettre en
  /// cache les lignes brutes plutôt que la map déjà résolue — même principe
  /// que `SupabaseCharacterCreationRepository._fetchTranslationRows`
  /// (`character_creation/data/character_creation_repository.dart`) : le
  /// parsing reste le point unique partagé entre le chemin réseau et le
  /// chemin cache (voir [_mapCharacterDetailPayload]).
  Future<List<Map<String, dynamic>>> _fetchTranslationRows({
    required String entityType,
    required String fieldName,
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const [];
    }

    return await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', entityType)
        .eq('field_name', fieldName)
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());
  }

  /// Construit le payload complet mis en cache par [fetchCharacterDetail] :
  /// [row] (le row `characters` principal, avec ses relations déjà
  /// imbriquées par le `select`) accompagné de toutes les lignes brutes de
  /// sous-requêtes nécessaires à la reconstruction complète d'un
  /// [CharacterDetail] (traductions, `skills`, `class_features`, `spells`).
  /// Jamais de mapping ici (voir [_mapCharacterDetailPayload], le seul point
  /// de mapping, partagé par le chemin réseau et le chemin cache).
  Future<Map<String, dynamic>> _buildCharacterDetailPayload(
    Map<String, dynamic> row,
  ) async {
    final raceNameRows = await _fetchTranslationRows(
      entityType: 'race',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectRaceIds(row),
    );
    final subraceNameRows = await _fetchTranslationRows(
      entityType: 'subrace',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectSubraceIds(row),
    );
    final classNameRows = await _fetchTranslationRows(
      entityType: 'class',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectClassIds(row),
    );
    final backgroundNameRows = await _fetchTranslationRows(
      entityType: 'background',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectBackgroundIds(row),
    );
    final alignmentNameRows = await _fetchTranslationRows(
      entityType: 'alignment',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectAlignmentIds(row),
    );

    // Les 18 [CharacterSkillRow] de l'onglet "Compétences" : `skills` est
    // une table de référence à peuplement fixe (pas liée à `characters`),
    // donc interrogée intégralement ici plutôt qu'embarquée dans le `select`
    // principal — contrairement à `character_skill_proficiencies`, qui
    // l'est (relation réelle vers `characters`).
    //
    // `ascending: true` explicite : le package `postgrest` (2.9.1) a un
    // défaut `ascending: false` contre-intuitif pour `.order(...)` — bug
    // trouvé en corrigeant le même défaut plus bas sur `class_features`
    // (revue QA) : sans ce paramètre, les 18 compétences ressortaient dans
    // l'ordre alphabétique français *inversé* plutôt que l'ordre attendu
    // (voir la maquette de `character_skills_card.dart`).
    final skillRows = await _client
        .from('skills')
        .select('id, ability_id')
        .order('id', ascending: true);
    final skillNameRows = await _fetchTranslationRows(
      entityType: 'skill',
      fieldName: 'name',
      entityIds: CharacterSkillRowMapper.collectIds(skillRows),
    );

    // Aptitudes de classe, carte "APTITUDES DE CLASSE" — `class_features`
    // n'est pas liée directement à `characters` (seulement via `classes`),
    // donc interrogée séparément, filtrée sur les `class_id` du personnage.
    // Aucune requête (ni `class_features` ni `translations`) si le
    // personnage n'a aucune classe (brouillon incomplet) : listes vides.
    //
    // `.order('level', ascending: true)` : affichage déterministe,
    // important pour un personnage multiclassé où plusieurs `class_id`
    // (donc plusieurs jeux d'aptitudes) sont mélangés dans une même
    // requête — sans quoi PostgREST ne garantit aucun ordre particulier.
    // Signalé en revue QA. `ascending: true` explicite, pas la valeur par
    // défaut, même correctif que `skills` ci-dessus.
    final classIds = CharacterDetailRowMapper.collectClassIdsRaw(row);
    var classFeatureRows = const <Map<String, dynamic>>[];
    var classFeatureNameRows = const <Map<String, dynamic>>[];
    if (classIds.isNotEmpty) {
      classFeatureRows = await _client
          .from('class_features')
          .select('id, class_id, level, uses_per_rest, description')
          .inFilter('class_id', classIds.toList())
          .order('level', ascending: true);
      final attainedRows = ClassFeatureRowMapper.filterAttained(
        classFeatureRows,
        classLevels: CharacterDetailRowMapper.collectClassLevels(row),
      );
      classFeatureNameRows = await _fetchTranslationRows(
        entityType: 'class_feature',
        fieldName: 'name',
        entityIds: ClassFeatureRowMapper.collectIds(attainedRows),
      );
    }

    // Noms de maîtrise d'outils, carte "MAÎTRISES D'OUTILS" —
    // `character_tool_proficiencies` est déjà embarquée dans [row] (relation
    // réelle vers `characters`), seuls les noms d'outils du catalogue
    // restent à résoudre via `translations`.
    final toolNameRows = await _fetchTranslationRows(
      entityType: 'tool',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectToolIds(
        CharacterDetailRowMapper.toolProficiencyRowsOf(row),
      ).map((id) => id.toString()).toSet(),
    );

    // Noms de langues connues, carte "LANGUES CONNUES" — même principe que
    // les outils ci-dessus.
    final languageNameRows = await _fetchTranslationRows(
      entityType: 'language',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectLanguageIds(
        CharacterDetailRowMapper.languageRowsOf(row),
      ).map((id) => id.toString()).toSet(),
    );

    // Sorts connus/préparés, section "SORTS" — `character_spells` est déjà
    // embarquée dans [row], seuls `spells.level`/`school` et les noms
    // restent à résoudre. Aucune requête si le personnage n'a aucun sort.
    // `spells` n'a pas de colonne `description` directe (vérifié contre
    // `20260825090300_create_reference_spells_items_tables.sql` côté dépôt
    // web) — elle vit dans `translations` au même titre que le nom, même
    // pattern que `itemDescriptionRows` ci-dessous pour les objets.
    final spellIds = CharacterSpellRowMapper.collectSpellIds(
      CharacterDetailRowMapper.characterSpellRowsOf(row),
    );
    var spellRows = const <Map<String, dynamic>>[];
    var spellNameRows = const <Map<String, dynamic>>[];
    var spellDescriptionRows = const <Map<String, dynamic>>[];
    if (spellIds.isNotEmpty) {
      spellRows = await _client
          .from('spells')
          .select(
            'id, level, school, casting_time, range, components, '
            'duration, concentration',
          )
          .inFilter('id', spellIds.toList());
      final spellIdStrings = spellIds.map((id) => id.toString()).toSet();
      spellNameRows = await _fetchTranslationRows(
        entityType: 'spell',
        fieldName: 'name',
        entityIds: spellIdStrings,
      );
      spellDescriptionRows = await _fetchTranslationRows(
        entityType: 'spell',
        fieldName: 'description',
        entityIds: spellIdStrings,
      );
    }

    // Inventaire résolu, onglet "Inventaire" — `character_inventory` est
    // déjà embarquée dans [row], `items` avec elle (relation de clé
    // étrangère réelle, contrairement à `translations`) : seuls les noms
    // d'objets du catalogue restent à résoudre via `translations`.
    final inventoryItemIds = CharacterInventoryRowMapper.collectItemIds(
      CharacterInventoryRowMapper.rowsOf(row),
    );
    final itemNameRows = await _fetchTranslationRows(
      entityType: 'item',
      fieldName: 'name',
      entityIds: inventoryItemIds,
    );
    // Description de chaque objet du catalogue présent dans l'inventaire —
    // même pattern de résolution que `itemNameRows` : `items` n'a pas de
    // colonne `description` directe (contrairement à `weight`/`cost`/
    // `rarity`...), elle vit dans `translations` (vérifié contre
    // `20260825091000_seed_items_equipment.sql` côté dépôt web, chaque
    // objet y insère sa description via `translations` au même titre que
    // son nom).
    final itemDescriptionRows = await _fetchTranslationRows(
      entityType: 'item',
      fieldName: 'description',
      entityIds: inventoryItemIds,
    );

    return <String, dynamic>{
      'row': row,
      'raceNameRows': raceNameRows,
      'subraceNameRows': subraceNameRows,
      'classNameRows': classNameRows,
      'backgroundNameRows': backgroundNameRows,
      'alignmentNameRows': alignmentNameRows,
      'skillRows': skillRows,
      'skillNameRows': skillNameRows,
      'classFeatureRows': classFeatureRows,
      'classFeatureNameRows': classFeatureNameRows,
      'toolNameRows': toolNameRows,
      'languageNameRows': languageNameRows,
      'spellRows': spellRows,
      'spellNameRows': spellNameRows,
      'spellDescriptionRows': spellDescriptionRows,
      'itemNameRows': itemNameRows,
      'itemDescriptionRows': itemDescriptionRows,
    };
  }

  /// Reconstruit un [CharacterDetail] complet à partir d'un [payload] déjà
  /// construit par [_buildCharacterDetailPayload] — jamais d'accès réseau
  /// ici, seul point de mapping partagé par le chemin réseau (juste après un
  /// succès) et le chemin cache (`_mappedFromCache`, dans
  /// [fetchCharacterDetail]).
  CharacterDetail _mapCharacterDetailPayload(Map<String, dynamic> payload) {
    final row = Map<String, dynamic>.from(payload['row'] as Map);

    final raceNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['raceNameRows']),
    );
    final subraceNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['subraceNameRows']),
    );
    final classNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['classNameRows']),
    );
    final backgroundNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['backgroundNameRows']),
    );
    final alignmentNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['alignmentNameRows']),
    );

    final skillNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['skillNameRows']),
    );
    final skills = CharacterSkillRowMapper.toCharacterSkillRows(
      _rowsOf(payload['skillRows']),
      names: skillNames,
      proficiencies: CharacterSkillRowMapper.parseProficiencies(
        CharacterDetailRowMapper.skillProficiencyRowsOf(row),
      ),
    );

    final attainedFeatureRows = ClassFeatureRowMapper.filterAttained(
      _rowsOf(payload['classFeatureRows']),
      classLevels: CharacterDetailRowMapper.collectClassLevels(row),
    );
    final classFeatureNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['classFeatureNameRows']),
    );
    final usesRemaining = ClassFeatureRowMapper.parseUsesRemaining(
      CharacterDetailRowMapper.featureUsesRowsOf(row),
    );
    final classFeatures = [
      for (final featureRow in attainedFeatureRows)
        ClassFeatureRowMapper.toCharacterClassFeature(
          featureRow,
          names: classFeatureNames,
          usesRemaining: usesRemaining,
        ),
    ];

    final toolNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['toolNameRows']),
    );
    final toolProficiencyNames =
        CharacterDetailRowMapper.parseToolProficiencyNames(
          CharacterDetailRowMapper.toolProficiencyRowsOf(row),
          toolNames: toolNames,
        );

    final languageNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['languageNameRows']),
    );
    final knownLanguageNames = CharacterDetailRowMapper.parseLanguageNames(
      CharacterDetailRowMapper.languageRowsOf(row),
      languageNames: languageNames,
    );

    final spellNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['spellNameRows']),
    );
    final spellDescriptions = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['spellDescriptionRows']),
    );
    final spells = CharacterSpellRowMapper.toCharacterSpellEntries(
      _rowsOf(payload['spellRows']),
      names: spellNames,
      descriptions: spellDescriptions,
      statuses: CharacterSpellRowMapper.parseStatuses(
        CharacterDetailRowMapper.characterSpellRowsOf(row),
      ),
    );

    final itemNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['itemNameRows']),
    );
    final itemDescriptions = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['itemDescriptionRows']),
    );
    final inventory = CharacterInventoryRowMapper.toCharacterInventoryItems(
      CharacterInventoryRowMapper.rowsOf(row),
      names: itemNames,
      descriptions: itemDescriptions,
    );

    final adventures = CharacterDetailRowMapper.parseAdventures(
      row,
      resolveCoverUrl: _resolveStoryCoverUrl,
    );

    return CharacterDetailRowMapper.toCharacterDetail(
      row,
      raceNames: raceNames,
      subraceNames: subraceNames,
      classNames: classNames,
      backgroundNames: backgroundNames,
      alignmentNames: alignmentNames,
      skills: skills,
      classFeatures: classFeatures,
      toolProficiencyNames: toolProficiencyNames,
      knownLanguageNames: knownLanguageNames,
      spells: spells,
      spellSlots: CharacterDetailRowMapper.parseSpellSlots(row),
      inventory: inventory,
      adventures: adventures,
    );
  }

  /// Bucket Storage des couvertures d'histoire (dépôt web,
  /// `20260716212008_create_stories.sql`) — lecture publique, jamais écrit
  /// depuis ce dépôt (voir `features/join_story/data/story_invite_repository.dart`,
  /// qui résout la même URL pour le flux "Rejoindre une histoire").
  static const String _storyCoversBucket = 'story-covers';

  /// Résout `stories.cover_image_path` (chemin de stockage brut) en URL
  /// publique — appelable même sur le chemin cache (pas d'accès réseau,
  /// simple construction de chaîne à partir de l'URL du projet Supabase),
  /// même principe que le reste de [_mapCharacterDetailPayload].
  String? _resolveStoryCoverUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from(_storyCoversBucket).getPublicUrl(path);
  }

  /// Écrit [payload] dans [_cache] sous [key]. Best-effort : une écriture
  /// cache en échec (ex. disque plein) ne doit jamais faire échouer un fetch
  /// réseau qui a lui-même réussi — avalée silencieusement, même principe
  /// que `SupabaseCharacterCreationRepository._writeCacheBestEffort`.
  Future<void> _writeCacheBestEffort(
    String key,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _cache.put(key, payload);
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }

  /// Relit [key] depuis [_cache] et la passe par [mapPayload]
  /// ([_mapCharacterDetailPayload], le même mapper que le chemin réseau) si
  /// une entrée existe. Retourne `null` si aucune entrée de cache n'existe,
  /// ou si la lecture/le mapping échoue (cache corrompu, format inattendu) —
  /// traité comme "pas de cache" par l'appelant, qui relance alors l'erreur
  /// réseau d'origine plutôt que de propager une erreur de cache qui
  /// masquerait la vraie cause. Même principe que
  /// `SupabaseCharacterCreationRepository._mappedFromCache`.
  Future<T?> _mappedFromCache<T>(
    String key,
    T Function(Map<String, dynamic> payload) mapPayload,
  ) async {
    try {
      final cached = await _cache.get(key);
      if (cached is Map<String, dynamic>) {
        return mapPayload(cached);
      }
    } catch (_) {
      // Traité comme "pas de cache" — voir la documentation de cette
      // méthode.
    }
    return null;
  }

  /// Normalise une valeur potentiellement issue de `jsonDecode` (types
  /// `dynamic` non garantis, notamment sur les maps imbriquées) ou
  /// directement d'une réponse PostgREST (`List<Map<String, dynamic>>` déjà
  /// bien typée) en `List<Map<String, dynamic>>`. Une valeur absente ou d'un
  /// type inattendu retombe sur une liste vide plutôt que de crasher — même
  /// principe défensif que
  /// `SupabaseCharacterCreationRepository._rowsOf`.
  static List<Map<String, dynamic>> _rowsOf(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Object>()
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
