import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/reference_data_cache.dart';
import '../../../core/crash_reporting/crash_reporter.dart';
import '../../../core/rules/character_class.dart';
import '../../../core/rules/spell_status.dart';
import '../../../core/utils/french_text_normalizer.dart';
import '../../../core/network/connectivity_checker.dart';
import '../../character_creation/domain/ability_score_rules.dart';
import '../../character_creation/domain/spellcasting_rules.dart';
import '../domain/character_class_feature.dart';
import '../domain/character_detail.dart';
import '../domain/character_failure.dart';
import '../domain/character_list_sorter.dart';
import '../domain/character_spell_slot.dart';
import '../domain/character_summary.dart';
import '../domain/hit_point_bonus_rules.dart';
import '../domain/currency_kind.dart';
import '../domain/gallery_photo_storage_path_resolver.dart';
import '../domain/inventory_catalog_item.dart';
import '../domain/level_up_apply_result.dart';
import '../domain/level_up_choice_kind.dart';
import '../domain/level_up_choice_selection.dart';
import '../domain/level_up_elemental_discipline_option.dart';
import '../domain/level_up_feat_option.dart';
import '../domain/level_up_invocation_option.dart';
import '../domain/level_up_level_data.dart';
import '../domain/level_up_maneuver_option.dart';
import '../domain/level_up_subclass_option.dart';
import '../domain/multiclass_prerequisites.dart';
import '../domain/portrait_storage_path_resolver.dart';
import '../domain/prepared_caster_spell_list.dart';
import '../domain/prepared_spells_limit.dart';
import '../domain/rest_type.dart';
import '../domain/reward_item_draft.dart';
import '../domain/spell_slot_progression.dart';
import '../domain/subclass_spell_grant_resolver.dart';
import '../domain/warlock_pact.dart';
import '../domain/weapon_slot.dart';
import '../domain/write_outcome.dart';
import 'character_detail_cache.dart';
import 'character_detail_row_mapper.dart';
import 'character_error_mapper.dart';
import 'character_inventory_row_mapper.dart';
import 'character_row_mapper.dart';
import 'character_skill_row_mapper.dart';
import 'character_spell_row_mapper.dart';
import 'class_feature_row_mapper.dart';
import 'inventory_catalog_row_mapper.dart';
import 'level_up_choice_row_mapper.dart';
import 'level_up_elemental_discipline_row_mapper.dart';
import 'level_up_feat_row_mapper.dart';
import 'level_up_invocation_row_mapper.dart';
import 'level_up_maneuver_row_mapper.dart';
import 'pact_weapon_row_mapper.dart';
import 'pending_character_write_syncer.dart';

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
  ///
  /// La fiche renvoyée tient compte des écritures [updateHp]/[addXp] encore
  /// en attente de synchronisation (mode hors-ligne) : `currentHp`/
  /// `temporaryHp`/`xp` valent alors la valeur mise en file, pas la valeur
  /// serveur ou cache qu'elle remplacera — l'appelant peut donc toujours
  /// calculer un nouvel ajustement à partir de la fiche reçue.
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
  ///   [WriteOutcome.synced] et retire de la file l'éventuelle écriture du
  ///   même type restée en attente pour ce personnage : désormais périmée
  ///   (valeurs absolues), elle écraserait sinon cette écriture plus
  ///   récente à la synchronisation suivante.
  ///   Exception à cette dernière règle (dette D12) : une requête réseau qui
  ///   expire (`TimeoutException`, levée par le délai global de
  ///   `core/network/timeout_http_client.dart` — voir sa documentation) est,
  ///   elle, mise en file exactement comme une connectivité absente — une
  ///   interface réseau déclarée "active" par [ConnectivityChecker] ne
  ///   garantit jamais un accès effectif de bout en bout (Wi-Fi sans débit,
  ///   signal faible...), ce cas est donc traité comme tel plutôt que comme
  ///   un vrai problème serveur.
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  });

  /// Écrit directement `characters.is_dead` — lien "Marquer comme
  /// mort"/"Ressusciter" de l'onglet "Personnage" (`CharacterVitalsCard`,
  /// chantier "Système de groupe",
  /// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2) :
  /// bascule manuelle, réversible, sans confirmation à double étape (spec de
  /// la tâche). Aucun calcul métier ici, même principe que [updateHp].
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem] (jamais mise en
  /// file — écriture jugée suffisamment secondaire pour ne pas mériter sa
  /// propre entrée dans `PendingCharacterWriteQueue`, même choix que le
  /// reste des écritures de l'onglet "Inventaire").
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  });

  /// Écrit directement `characters.is_archived` — lien "Archiver ce
  /// personnage"/"Désarchiver" de l'onglet "Personnage"
  /// (`CharacterVitalsCard`) — même contrat que [setDead] (mode hors-ligne
  /// inclus, voir sa documentation), simple flag sans effet sur le reste de
  /// la fiche.
  Future<WriteOutcome> setArchived({
    required String characterId,
    required bool isArchived,
  });

  /// Écrit directement `characters.inspiration` — pastille "Inspiration" de
  /// l'onglet "Personnage" (`CharacterStatPillsRow`) — même contrat que
  /// [setDead]/[setArchived] (mode hors-ligne inclus, voir la documentation
  /// de [setDead]), simple flag sans effet sur le reste de la fiche.
  Future<WriteOutcome> setInspiration({
    required String characterId,
    required bool inspiration,
  });

  /// Supprime définitivement [characterId] — action "Supprimer le
  /// personnage" du menu "…" de l'onglet "Personnage", déjà confirmée par
  /// l'appelant (dialogue de confirmation, voir
  /// `character_detail_screen.dart::_deleteCharacter`) avant d'atteindre
  /// cette méthode. `DELETE FROM characters` cascade côté base vers les ~15
  /// tables "Personnages" liées (`on delete cascade`, voir les migrations du
  /// dépôt web) et la policy RLS "Owner can delete their characters" — aucun
  /// nettoyage manuel nécessaire ici. Ne supprime PAS les fichiers déjà
  /// envoyés dans le bucket Storage (portrait, galerie) : orphelins acceptés,
  /// même compromis que le reste de ce dépôt pour les suppressions en
  /// cascade (pas de nettoyage Storage best-effort ici, contrairement à
  /// [removeAvatar] côté profil qui connaît un unique fichier).
  ///
  /// Mode hors ligne : mêmes règles que [setDead]/[setArchived] (jamais mise
  /// en file, voir la documentation de [setDead]).
  Future<WriteOutcome> deleteCharacter({required String characterId});

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

  /// Envoie [bytes] dans le bucket `character-gallery-photos` (RLS écriture
  /// restreinte à `{user_id}/...`, lecture publique — voir
  /// `domain/gallery_photo_storage_path_resolver.dart`), puis insère une
  /// ligne `character_photos` avec l'URL publique résultante. Contrairement
  /// à [uploadPortrait] : un nouvel `INSERT` (jamais un remplacement),
  /// [bytes] ne sont jamais recadrées en amont (pas de crop imposé, la
  /// galerie accepte des photos de toute proportion — voir la spec de la
  /// tâche "Galerie de photos", `docs/cahier-des-charges/`
  /// 11-fonctionnalites-a-ajouter.md section "Onglet Histoire").
  ///
  /// Mode hors-ligne : aucune gestion dédiée, même principe que
  /// [uploadPortrait] (upload binaire, ne se prête pas à
  /// [PendingCharacterWriteQueue]) — l'appel réseau échoue simplement,
  /// remonté comme n'importe quelle autre [CharacterFailure].
  Future<void> addGalleryPhoto({
    required String characterId,
    required Uint8List bytes,
  });

  /// Supprime le fichier [url] du bucket (best-effort, même principe que
  /// [removePortrait] pour une URL externe non reconnue) puis la ligne
  /// `character_photos` [photoId].
  Future<void> removeGalleryPhoto({
    required String characterId,
    required String photoId,
    required String url,
  });

  /// Insère une nouvelle entrée `character_journal_entries` — voir
  /// `presentation/widgets/character_journal_entry_edit_sheet.dart`.
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem] (retourne
  /// [WriteOutcome.queued] sans persister nulle part, jamais synchronisé
  /// automatiquement — décision chef de projet, même périmètre volontairement
  /// restreint de [PendingCharacterWriteQueue] que le reste de la fiche en
  /// dehors de PV/XP).
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  });

  /// Remplace le texte de l'entrée [entryId] par [body] — même sheet que
  /// [addJournalEntry] (mode édition plutôt qu'ajout).
  ///
  /// Mode hors ligne : mêmes règles que [addJournalEntry].
  Future<WriteOutcome> updateJournalEntry({
    required String characterId,
    required String entryId,
    required String body,
  });

  /// Supprime l'entrée [entryId] (avec confirmation côté sheet d'actions,
  /// même principe que [removeInventoryItem]).
  ///
  /// Mode hors ligne : mêmes règles que [addJournalEntry].
  Future<WriteOutcome> removeJournalEntry({
    required String characterId,
    required String entryId,
  });

  /// Écrit directement `characters.xp` avec [newXp] (déjà calculé par
  /// l'appelant — `xp actuel + montant saisi`, voir
  /// `presentation/widgets/add_xp_sheet.dart`) : même principe que
  /// [updateHp], aucun calcul métier fait ici.
  ///
  /// Mode hors-ligne : mêmes règles exactement que [updateHp] (voir sa
  /// documentation, y compris l'exception D12 pour une requête réseau qui
  /// expire) — payload mis en file `{newXp: ...}` si la connectivité est
  /// absente. Note pour l'appelant
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
  /// Mode hors-ligne (D11 du registre de dette technique, décision chef de
  /// projet du 09/10/2026 — **étend** un comportement antérieur plus strict,
  /// voir ci-dessous) : mêmes règles exactement que [updateHp]/[addXp]
  /// (connectivité absente -> mise en file réelle dans
  /// [PendingCharacterWriteQueue], kind [PendingCharacterWriteKind.spellSlot],
  /// `targetId` discriminant par niveau d'emplacement/pacte — voir la doc de
  /// classe de [PendingCharacterWriteKind] — et [WriteOutcome.queued] ;
  /// connectivité présente -> écriture réseau normale, [WriteOutcome.synced],
  /// y compris l'exception D12 pour une requête qui expire). **Avant cette
  /// extension**, cette écriture n'était jamais mise en file : absence de
  /// connectivité retournait directement [WriteOutcome.queued] sans jamais
  /// rien persister, perdant silencieusement l'intention du joueur malgré un
  /// message laissant croire à une synchronisation future (voir D11 dans
  /// `docs/dette-technique.md`).
  ///
  /// [isPactSlot] : `true` si [slotLevel]/[slotsUsed] concernent la magie de
  /// pacte de l'Occultiste (`character_pact_slots`) plutôt qu'un emplacement
  /// classique (`character_spell_slots`, comportement par défaut) — voir
  /// `domain/spell_slot_progression.dart` pour le rationale de la séparation
  /// des deux tables. Même principe d'écriture dans les deux cas (valeur
  /// absolue déjà calculée par l'appelant), seule la table cible change.
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  });

  /// Écrit directement `character_spells.is_favorite` — étoile de
  /// `_SpellRow` (`presentation/widgets/character_spells_section.dart`),
  /// épinglage pour accès rapide en combat
  /// (`docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
  /// "Onglet Sorts"). Même contrat que [setDead]/[setArchived] (mode
  /// hors-ligne inclus) : simple flag, jamais mis en file d'attente.
  Future<WriteOutcome> setSpellFavorite({
    required String characterId,
    required int spellId,
    required bool isFavorite,
  });

  /// Écrit directement `character_spells.status` ('connu' ↔ 'préparé') —
  /// bascule "Préparer ce sort"/"Ne plus préparer" du panneau "Infos"
  /// (`presentation/widgets/spell_info_panel.dart`) et de la sheet "Préparer
  /// mes sorts" (`presentation/widgets/prepare_spells_sheet.dart`), voir
  /// `domain/spell_status_formatter.dart` pour les règles (jamais appelée
  /// pour un sort mineur ou inné).
  ///
  /// **Limite de sorts préparés RAW 5e désormais bloquante** (décision de
  /// Matthias du 09/10/2026, précisée le 10/10 après analyse RAW de l'agent
  /// `regles-dnd`, voir `docs/dette-technique.md`, D40 et « Décisions en
  /// attente » point 4) : [prepared] à `true` pour un sort PAS déjà préparé
  /// vérifie d'abord que la classe d'origine de [spellId] n'a pas déjà
  /// atteint sa propre limite ([PreparedSpellsLimit.limitFor]) — lève une
  /// [CharacterFailure] explicite (nom de la classe, décompte/limite) si
  /// c'est le cas, AVANT toute écriture. Dé-préparer ([prepared] à `false`)
  /// ne vérifie jamais rien : toujours permis, aucune limite ne s'applique à
  /// la baisse. RAW, chaque classe qui prépare calcule sa propre limite
  /// séparément (PHB, « Multiclassing — Spells Known and Prepared »), jamais
  /// un total fusionné : un personnage multiclassé avec deux classes qui
  /// préparent ou plus (ex. Clerc/Paladin) est donc couvert, pas seulement
  /// le cas mono-classe. Voir `_resolvePreparingClassAndEnforceLimit` pour
  /// le détail des requêtes dédiées (volontairement PAS
  /// `fetchCharacterDetail`, bien plus lourd et qui aurait aussi forcé à
  /// réécrire tous les tests déjà en place sur cette méthode) — y compris
  /// l'exclusion des sorts par ailleurs accordés par une sous-classe du
  /// décompte (D77, corrigé le 13/10/2026). La classe ainsi résolue est
  /// aussi écrite comme `source_class_id` sur l'éventuelle NOUVELLE ligne
  /// créée plus bas (D40 : cette colonne n'était encore jamais écrite à
  /// l'insertion).
  ///
  /// Garde côté écriture : une ligne au statut 'inné' n'est jamais modifiée,
  /// et un sort qui n'a que des lignes 'inné' ne reçoit aucune nouvelle
  /// ligne (rien n'est écrit, [WriteOutcome.synced] quand même : la base est
  /// déjà dans l'état voulu pour un sort inné).
  Future<WriteOutcome> setSpellPrepared({
    required String characterId,
    required int spellId,
    required bool prepared,
  });

  /// Écrit `character_spells.innate_uses_spent` (usages DÉPENSÉS depuis le
  /// dernier repos long) pour le sort inné [spellId] de [characterId], avec
  /// [usesSpent] déjà calculé par l'appelant — valeur absolue, même principe
  /// que [castSpell]/[useClassFeature] (voir
  /// `presentation/character_detail_screen.dart::_castInnateSpell`). Action
  /// "Lancer" d'un sort inné de niveau >= 1, qui se lance sans emplacement
  /// (`domain/innate_spell_usage.dart`) : aucun emplacement n'est touché.
  ///
  /// Seules les lignes au statut 'inné' du sort sont mises à jour (toutes,
  /// s'il y en a plusieurs : aucune contrainte d'unicité en base) — jamais
  /// une ligne ordinaire du même sort. La remise à zéro est faite par
  /// [applyRest] au repos long.
  ///
  /// Mode hors-ligne : mêmes règles exactement que [castSpell] (voir sa
  /// documentation, y compris D11) — mise en file réelle, kind
  /// [PendingCharacterWriteKind.innateSpell], `targetId` = [spellId].
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
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
  /// documentation, y compris D11) — mise en file réelle, kind
  /// [PendingCharacterWriteKind.classFeature], `targetId` = [classFeatureId].
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
  /// Quand [equipped] est `false`, écrit aussi `weapon_slot = null` — pour
  /// qu'une arme déséquipée n'apparaisse plus assignée à aucun set (voir
  /// [WeaponSlot]). Quand [equipped] est `true`, ne touche jamais
  /// `weapon_slot` : ce chemin ne sert plus à équiper une arme (voir
  /// [equipWeaponToSlot]), seulement une armure/un bouclier, catégories
  /// pour lesquelles `weapon_slot` n'a de toute façon aucun sens.
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  });

  /// Action "Équiper" une arme dans un set (`weapon_slot`) — écrit
  /// `equipped = true, weapon_slot = slot.value`. L'appelant a déjà décidé
  /// quelles autres armes du même set déséquiper au préalable (voir
  /// `WeaponSlotRules.itemsToAutoUnequip`, appelé côté
  /// `character_detail_screen.dart` avant cet appel, via
  /// [setInventoryItemEquipped] pour chacune) — cette méthode ne fait que la
  /// dernière écriture (équiper la nouvelle arme dans le set choisi).
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem] (jamais mise en
  /// file, voir sa documentation).
  Future<WriteOutcome> equipWeaponToSlot({
    required String characterId,
    required String inventoryId,
    required WeaponSlot slot,
  });

  /// Action "Harmoniser cet objet"/"Ne plus harmoniser" — écrit
  /// `character_inventory.is_attuned` tel quel, aucun calcul ici (même
  /// principe que [setInventoryItemEquipped]). Le plafond de
  /// `CharacterDetail.attunementCap` (3, RAW 5e) est vérifié côté UI avant
  /// l'appel (voir `presentation/widgets/item_action_sheet.dart`/
  /// `item_info_panel.dart`), jamais ici.
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem].
  Future<WriteOutcome> setInventoryItemAttuned({
    required String characterId,
    required String inventoryId,
    required bool attuned,
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

  /// Dons `feats` NON déjà possédés par [characterId] (`character_feats`),
  /// triés alphabétiquement (cohérent avec le catalogue de sorts) — étape
  /// "Choix à faire" de la montée de niveau, sous-mode "don" (niveaux ASI
  /// 4/8/12/16/19, voir `domain/level_up_choice_kind.dart`). Nom/description
  /// résolus via `translations` (`entity_type = 'feat'`), prérequis textuel
  /// extrait de `feats.prerequisites->>'text'` (`null` si absent) — voir
  /// `domain/level_up_feat_option.dart`.
  Future<List<LevelUpFeatOption>> fetchAvailableFeats({
    required String characterId,
  });

  /// Invocations occultistes `invocations` NON déjà connues de
  /// [characterId] (`character_invocations`), triées alphabétiquement — étape
  /// "Invocations" de la montée de niveau (Occultiste, voir
  /// `domain/invocations_known_progression.dart`). Même résolution que
  /// [fetchAvailableFeats] (`entity_type = 'invocation'`,
  /// `invocations.prerequisites->>'text'`) — voir
  /// `domain/level_up_invocation_option.dart`.
  Future<List<LevelUpInvocationOption>> fetchAvailableInvocations({
    required String characterId,
  });

  /// Disciplines élémentaires `class_options` (`option_type =
  /// 'discipline_elementaire'`) de la sous-classe [subclassId] dont
  /// `min_level <= targetLevel`, NON déjà connues de [characterId] — étape
  /// "Disciplines élémentaires" de la montée de niveau (Moine, Voie des
  /// quatre éléments, voir
  /// `domain/elemental_disciplines_known_progression.dart`). "Déjà connue"
  /// se lit sur `character_class_options.chosen_value` pour la ligne
  /// `class_features` dont `choice_type = 'discipline_elementaire'` —
  /// repérée par ce `choice_type` SEUL (valeur globalement unique dans toute
  /// la base à ce jour, confirmée par `regles-dnd` : aucune autre
  /// sous-classe du jeu n'a de disciplines élémentaires), jamais via
  /// `.eq('class_id', classId)` : `class_features.class_id` est NULL sur
  /// cette ligne (ligne de sous-classe, seul `subclass_id` est rempli) — un
  /// filtre `.eq('class_id', classId)` ne la retrouve structurellement
  /// jamais en PostgREST/SQL (`col = valeur` ne matche jamais NULL), ce qui
  /// a causé une régression (voir D85 du registre de dette technique,
  /// `docs/dette-technique.md`) : `applyLevelUp` levait systématiquement une
  /// [CharacterFailure] dès qu'une discipline élémentaire était choisie, et
  /// cette méthode considérait TOUJOURS qu'aucune discipline n'était déjà
  /// connue. [classId] est néanmoins conservé dans la signature pour la
  /// symétrie avec [fetchAvailableManeuvers] (même forme d'appel côté
  /// `presentation/providers/level_up_provider.dart`), bien qu'il ne soit
  /// pas utilisé par cette résolution. Même résolution par nom que
  /// l'écriture, voir `applyLevelUp.elementalDisciplineNames`. Noms/
  /// descriptions résolus via `translations` (`entity_type = 'class_option'`)
  /// — voir `domain/level_up_elemental_discipline_option.dart`.
  Future<List<LevelUpElementalDisciplineOption>>
  fetchAvailableElementalDisciplines({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  });

  /// Manœuvres `class_options` (`option_type = 'manoeuvre'`) de la
  /// sous-classe [subclassId] dont `min_level <= targetLevel`, NON déjà
  /// connues de [characterId] — étape "Manœuvres" de la montée de niveau
  /// (Guerrier, Maître de guerre, voir
  /// `domain/maneuvers_known_progression.dart`). "Déjà connue" se lit sur
  /// `character_class_options.chosen_value` pour la ligne `class_features`
  /// dont `choice_type = 'manoeuvre'` — repérée par ce `choice_type` SEUL
  /// (valeur globalement unique dans toute la base à ce jour, confirmée par
  /// `regles-dnd` : aucune autre sous-classe du jeu n'a de manœuvres),
  /// jamais par [classId] ni [subclassId] : contrairement à
  /// [fetchAvailableElementalDisciplines] (qui résout sa propre ligne
  /// `class_features` via `.eq('class_id', classId)`, alors que
  /// `class_features.class_id` est NULL sur une ligne de sous-classe comme
  /// celle-ci — voir D85 du registre de dette technique,
  /// `docs/dette-technique.md`, soupçon non confirmé faute d'accès direct à
  /// la base pour cet agent), cette méthode ne dépend d'aucun filtre
  /// `class_id`/`subclass_id` pour cette résolution précise. [classId] est
  /// néanmoins conservé dans la signature pour la symétrie avec
  /// [fetchAvailableElementalDisciplines] (même forme d'appel côté
  /// `presentation/providers/level_up_provider.dart`), bien qu'il ne soit
  /// pas utilisé par cette implémentation. Noms/descriptions résolus via
  /// `translations` (`entity_type = 'class_option'`) — voir
  /// `domain/level_up_maneuver_option.dart`.
  Future<List<LevelUpManeuverOption>> fetchAvailableManeuvers({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  });

  /// Applique une montée de niveau déjà validée par le joueur (écran
  /// "Montée de niveau", récapitulatif). Deux branches, selon
  /// [isMulticlassing] :
  /// - `false` (continuer, comportement historique) : incrémente
  ///   `character_classes.level` de la ligne dont `class_id` vaut [classId]
  ///   (identifiée explicitement, plutôt que de supposer une seule ligne —
  ///   voir le changement de comportement ci-dessous).
  /// - `true` (multiclasser) : insère une NOUVELLE ligne `character_classes`
  ///   (`character_id`, `class_id: classId`, `level: 1`, `is_primary: false`,
  ///   `hit_dice_spent: 0`) — [className] doit être le nom de CETTE nouvelle
  ///   classe. Revérifie [MulticlassPrerequisites.meetsRequirement] pour la
  ///   nouvelle classe ET pour toutes les classes déjà possédées (défense en
  ///   profondeur : l'UI filtre déjà ces options en amont, mais cette
  ///   méthode ne fait jamais confiance uniquement à l'UI pour une écriture,
  ///   même discipline que le plafond ASI à 20 ci-dessous) — lève une
  ///   [CharacterFailure] explicite si un prérequis n'est pas rempli, ou si
  ///   le personnage possède déjà cette classe.
  ///
  /// **Changement de comportement (multiclassage)** : accepte désormais un
  /// personnage avec plusieurs lignes `character_classes` — l'ancien filet de
  /// sécurité ("exactement une ligne, sinon `CharacterFailure`") a été levé.
  ///
  /// Dans les deux branches : ajoute [hpGain] à `characters.max_hp`/
  /// `current_hp`, insère une ligne `character_level_hp` (`level` = niveau
  /// TOTAL du personnage après écriture, jamais le niveau interne à une
  /// classe précise — voir `domain/level_up_apply_result.dart::LevelUpApplyResult.newLevel`,
  /// même convention), et écrit [choice] s'il est fourni (étape "Choix à
  /// faire") :
  /// - [LevelUpChoiceKind.abilityScoreImprovement] : deux variantes
  ///   mutuellement exclusives, selon [LevelUpChoiceSelection.featId] :
  ///   - `null` (répartition de caractéristiques, comportement historique) :
  ///     upsert `character_ability_scores.score` (score final = score actuel
  ///     + allocation) **et** insert `character_ability_increases` (une
  ///     ligne par caractéristique augmentée, `source: 'asi'`, `level` =
  ///     niveau interne à la classe qui progresse — jamais le niveau total)
  ///     — les deux tables doivent être écrites, voir la documentation de
  ///     [LevelUpChoiceSelection.abilityAllocations].
  ///   - non nul (don choisi en alternative à l'ASI, spec visuelle
  ///     direction-artistique section 1) : insert `character_feats`
  ///     (`character_id`, `feat_id`, `level_taken` = niveau interne à la
  ///     classe qui progresse) — ni `character_ability_scores` ni
  ///     `character_ability_increases` ne sont touchées dans ce cas.
  /// - [LevelUpChoiceKind.subclass] : `character_classes.subclass_id`,
  ///   combiné dans le même `UPDATE`/`INSERT` que `level` (sur la ligne
  ///   fraîchement créée en cas de multiclassage, pas sur la classe
  ///   primaire).
  /// - [LevelUpChoiceKind.fightingStyle]/[LevelUpChoiceKind.favoredEnemy]/
  ///   [LevelUpChoiceKind.pact] : insert `character_class_options`
  ///   (`chosen_value` = `'chaine'`/`'lame'`/`'grimoire'` pour le pacte).
  ///
  /// Recalcule aussi `character_spell_slots`, depuis zéro (upsert complet
  /// pour le nouveau niveau, jamais un delta — voir
  /// `domain/spell_slot_progression.dart::SpellSlotProgression.resolveChangesForLevelUp`
  /// et la documentation de [_upsertSpellSlots]) : calcul combiné multiclasse
  /// dès que le personnage compte 2 classes lanceuses "non-pacte" après ce
  /// niveau, sinon comportement mono-classe historique inchangé.
  ///
  /// [initialSpellIds] : sorts/cantrips nouvellement appris à écrire dans
  /// `character_spells` (`status` dérivé de [className] via
  /// `SpellcastingRules.statusFor`, `source_class_id: classId`) — déjà
  /// résolus en identifiants par l'appelant (le catalogue de sorts est déjà
  /// chargé côté écran, voir `presentation/providers/level_up_provider.dart`).
  /// **Nom conservé tel quel malgré la généralisation** (chantier "sorts
  /// connus par niveau", voir `domain/spells_known_progression.dart`) : ce
  /// paramètre couvrait à l'origine uniquement les sorts de départ d'une
  /// nouvelle classe "à sorts connus" démarrée au niveau 1
  /// (`LevelUpStepData.requiresSpellSelection`, multiclassage), il couvre
  /// désormais aussi les nouveaux sorts/cantrips appris à N'IMPORTE QUEL
  /// niveau > 1 d'une classe "à sorts connus" continuée — la mécanique
  /// d'écriture est rigoureusement identique dans les deux cas (même table,
  /// mêmes colonnes), seul l'appelant change la provenance des identifiants.
  /// Renommer aurait forcé une mise à jour mécanique des ~18 doubles de test
  /// qui implémentent cette interface pour un gain de clarté marginal — non
  /// fait, décision à valider par le chef de projet si le nom prête à
  /// confusion. Toujours vide hors de ces deux cas.
  ///
  /// Revérifiés contre les lignes ORDINAIRES ('connu'/'préparé') DÉJÀ
  /// EXISTANTES juste avant l'écriture (voir [_fetchAlreadyOrdinarySpellIds])
  /// — jamais contre une ligne 'inné' existante : décision de Matthias du
  /// 12/10/2026, symétrique de celle du 10/10/2026 sur [racialInnateSpellIds]
  /// (D43 du registre de dette technique, `docs/dette-technique.md`) — un
  /// sort déjà connu UNIQUEMENT via sa route innée (trait racial) garde
  /// malgré tout le droit à sa ligne ORDINAIRE séparée, les deux routes RAW
  /// étant indépendantes. Avant cette décision, filtrer ici contre TOUT sort
  /// déjà connu (`_fetchKnownSpellIds`, toute route confondue, retirée)
  /// produisait le même résultat que le bug D43 par un chemin différent (la
  /// ligne ordinaire n'était simplement jamais écrite).
  ///
  /// [invocationIds] : invocations occultistes nouvellement choisies à
  /// écrire dans `character_invocations` (`character_id`, `invocation_id`)
  /// — étape "Invocations" (Occultiste, voir
  /// `domain/invocations_known_progression.dart`), déjà résolues en
  /// identifiants par l'appelant. Toujours vide hors de ce cas.
  ///
  /// [elementalDisciplineNames] : disciplines élémentaires nouvellement
  /// choisies (Moine, Voie des quatre éléments, voir
  /// `domain/elemental_disciplines_known_progression.dart`), par NOM déjà
  /// résolu par l'appelant (`LevelUpElementalDisciplineOption.name`) —
  /// écrites dans `character_class_options` (`chosen_value` = ce nom, même
  /// convention texte libre que les styles de combat/ennemis jurés, jamais
  /// un identifiant à résoudre : `character_class_options` n'a pas de
  /// colonne dédiée à un FK vers `class_options`). `class_feature_id`
  /// résolu via la ligne `class_features` dont `choice_type =
  /// 'discipline_elementaire'` — repérée par ce `choice_type` SEUL (valeur
  /// globalement unique dans toute la base, confirmée par `regles-dnd`),
  /// **jamais via `.eq('class_id', classId)`** : `class_features.class_id`
  /// est NULL sur cette ligne de sous-classe, un tel filtre ne la retrouve
  /// structurellement jamais (`col = valeur` ne matche jamais NULL en
  /// PostgREST/SQL) — voir D85 du registre de dette technique,
  /// `docs/dette-technique.md`, et la documentation de
  /// [fetchAvailableElementalDisciplines]. Une seule ligne existe en base à
  /// ce jour — réutilisée pour CHAQUE palier 3/6/11/17, jamais une par
  /// palier, voir `domain/level_up_block_reason.dart`) ; `level` = niveau
  /// interne à la classe qui progresse (même convention que
  /// [LevelUpChoiceKind.fightingStyle]/[LevelUpChoiceKind.favoredEnemy]).
  /// Lève une [CharacterFailure] si aucune ligne `class_features` de ce
  /// `choice_type` n'existe en base alors que cette liste est non vide (ne
  /// devrait jamais arriver : l'appelant ne déclenche cette étape que si le
  /// personnage progresse effectivement en Moine Voie des quatre éléments).
  /// Toujours vide hors de ce cas.
  ///
  /// [maneuverNames] : manœuvres nouvellement choisies (Guerrier, Maître de
  /// guerre, voir `domain/maneuvers_known_progression.dart`), par NOM déjà
  /// résolu par l'appelant (`LevelUpManeuverOption.name`) — même convention
  /// texte libre que [elementalDisciplineNames] ci-dessus, écrites dans
  /// `character_class_options`. **Résolution du `class_feature_id` plus
  /// prudente que [elementalDisciplineNames]** : la ligne `class_features`
  /// dont `choice_type = 'manoeuvre'` est repérée SEULE (ce `choice_type`
  /// est globalement unique dans toute la base, confirmé par `regles-dnd`),
  /// jamais via `.eq('class_id', classId)` — `class_features.class_id` est
  /// NULL sur cette ligne de sous-classe (voir D85 du registre de dette
  /// technique, `docs/dette-technique.md`, même situation que
  /// `discipline_elementaire`/`sort_domaine`/`sort_mineur_bonus` : un
  /// filtre `.eq('class_id', classId)` ne la retrouverait jamais). `level` =
  /// niveau interne à la classe qui progresse (même convention que
  /// [elementalDisciplineNames]). Lève une [CharacterFailure] si aucune
  /// ligne `class_features` de ce `choice_type` n'existe en base alors que
  /// cette liste est non vide (ne devrait jamais arriver). Toujours vide
  /// hors de ce cas.
  ///
  /// [racialInnateSpellIds] : sorts innés raciaux (`racial_innate_spells`,
  /// lignes sans choix de lignée) devenus accessibles à ce nouveau niveau
  /// TOTAL, déjà résolus par
  /// `presentation/providers/level_up_provider.dart`
  /// (`LevelUpStepData.newRacialInnateSpells`, qui les filtre déjà contre les
  /// sorts DÉJÀ INNÉS de [characterId] — jamais contre tout sort connu,
  /// toute route confondue, depuis la décision de Matthias du 10/10/2026,
  /// cohérente avec D43 du registre de dette technique,
  /// `docs/dette-technique.md` : un sort à la fois inné et connu/préparé
  /// garde ses deux routes, voir plus bas) — contrairement à
  /// [initialSpellIds]/[invocationIds], jamais un choix du joueur : écrits
  /// avec `status: 'inné'` et `source_class_id: null` (jamais celui de
  /// [classId], qui n'a aucun rapport avec une race). Revérifiés contre
  /// `character_spells` juste avant l'écriture (même discipline défensive
  /// que [_applyAbilityScoreImprovement] pour le plafond ASI à 20), mais
  /// UNIQUEMENT contre les lignes déjà 'inné' (jamais contre une ligne
  /// ordinaire du même sort, voir [_fetchAlreadyInnateSpellIds]) : ne
  /// jamais réécrire une ligne 'inné' déjà existante (ça violerait l'index
  /// unique partiel dédié, D10), même si l'appelant s'est basé sur une
  /// lecture périmée — mais toujours écrire la ligne 'inné' même si une
  /// ligne ORDINAIRE du même sort existe déjà (D43 : les deux routes
  /// coexistent, chacune sous son propre index unique partiel, jamais en
  /// conflit l'une avec l'autre). Toujours vide hors de ce cas.
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
  /// D35 du registre de dette technique : en tout premier, avant toute
  /// lecture/écriture, synchronise la file hors ligne PV/XP
  /// (`SupabaseCharacterRepository._blockIfPendingHpOrXpWrites`) et lève une
  /// [CharacterFailure] si un ajustement reste en attente pour
  /// [characterId] une fois cette synchronisation tentée — cette méthode
  /// relit `current_hp`/`max_hp` depuis le serveur pour y ajouter [hpGain],
  /// et ne doit jamais partir d'une valeur que la synchronisation différée
  /// réécrirait ensuite par-dessus.
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required Object classId,
    required String className,
    required bool isMulticlassing,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
    List<int> initialSpellIds = const [],
    List<int> invocationIds = const [],
    List<String> elementalDisciplineNames = const [],
    List<String> maneuverNames = const [],
    List<int> racialInnateSpellIds = const [],
  });

  /// Applique un repos (lien "Prendre un repos", onglet "Personnage" —
  /// `presentation/widgets/rest_sheet.dart`), voir [RestType] pour l'effet
  /// exact de chaque valeur :
  /// - [RestType.long] : `characters.current_hp = max_hp`,
  ///   `characters.temporary_hp = 0`, `characters.last_long_rest_at = now()`
  ///   (chantier "Notifications" —
  ///   `docs/cahier-des-charges/15-profil-parametres.md` section 3, alimente
  ///   le rappel de repos long côté backend) ; recalcule (upsert) tous les
  ///   `character_spell_slots` à partir de **toutes** les classes du
  ///   personnage (niveau de lanceur combiné multiclasse,
  ///   `SpellSlotProgression.totalsForClasses`, même règle que
  ///   [applyLevelUp]), `slots_used` toujours remis à 0 — y compris sur une
  ///   ligne existante d'un niveau de sort hors calcul, dont le total est
  ///   laissé tel quel ; réinitialise (upsert)
  ///   `character_feature_uses.uses_remaining` pour toutes les
  ///   `class_features` de **toutes** les classes du personnage
  ///   (multiclassage inclus) ET de leurs éventuelles sous-classes déjà
  ///   choisies, atteintes par leur niveau respectif, quel que soit leur
  ///   `rest_type` ; et récupère (RAW 5e) des dés de vie sur la
  ///   classe primaire : `character_classes.hit_dice_spent = max(0,
  ///   hit_dice_spent - max(1, level ~/ 2))`. Purement silencieux côté UI
  ///   (aucun retour transporté par cette méthode ne le reflète) — voir la
  ///   spec visuelle direction-artistique de `rest_sheet.dart`. Remet aussi
  ///   à 0 `character_spells.innate_uses_spent` (sorts innés lancés sans
  ///   emplacement, voir [setInnateSpellUsesSpent]) — juste après les
  ///   emplacements de sorts et AVANT la récupération des dés de vie, seule
  ///   écriture relative du repos long : un échec de cette remise à zéro ne
  ///   laisse derrière lui que des écritures rejouables. Récupère aussi
  ///   (RAW 5e) des dés de vie, voir [hitDiceRecoveredByClassId].
  /// - [RestType.short] : réinitialise uniquement (upsert) les
  ///   `character_feature_uses` (toutes classes et sous-classes,
  ///   multiclassage inclus) dont le `rest_type` correspondant vaut
  ///   `'repos_court'`. Ne touche à
  ///   `characters.current_hp`/`character_classes.hit_dice_spent` que si
  ///   [hitDiceSpentByClassId] n'est pas vide (règle RAW 5e "dépenser un ou
  ///   plusieurs dés de vie", déjà entièrement calculée côté appelant — voir
  ///   [hitDiceSpentByClassId]/[appliedGain] ci-dessous) ; ne touche jamais
  ///   `character_spell_slots` ni `character_spells.innate_uses_spent`.
  ///
  /// [hitDiceSpentByClassId] : nombre de dés de vie dépensés à ce repos
  /// court, par `character_classes.class_id` (en chaîne, voir
  /// `domain/hit_dice_pool.dart::HitDicePool.classId`) — toujours vide pour
  /// un repos long (voir `RestSheetResult`). Chaque entrée incrémente
  /// `character_classes.hit_dice_spent` de LA ligne correspondante
  /// (plafonné à `level`, cohérent avec la contrainte SQL
  /// `hit_dice_spent <= level`), **même si [appliedGain] vaut 0** (RAW : un
  /// dé de vie dépensé reste dépensé même si le jet ne restaure aucun PV,
  /// ex. PV déjà au maximum). Déjà entièrement calculé côté appelant (le
  /// joueur choisit lui-même, pool par pool, combien de dés de CHAQUE classe
  /// il dépense — décision chef de projet du 10/10/2026, voir
  /// `presentation/widgets/rest_sheet.dart`) : cette méthode ne fait
  /// qu'écrire le résultat déjà calculé, jamais une validation RAW
  /// supplémentaire (même principe que [appliedGain] ci-dessous).
  ///
  /// [hitDiceRecoveredByClassId] : nombre de dés de vie récupérés à ce repos
  /// long, par `class_id` — toujours vide pour un repos court. Chaque
  /// entrée décrémente `character_classes.hit_dice_spent` de LA ligne
  /// correspondante (plancher 0). Déjà entièrement calculé côté appelant
  /// (`domain/hit_dice_recovery_calculator.dart` : la moitié du niveau
  /// TOTAL du personnage, au moins 1, répartie automatiquement si un seul
  /// pool a des dés dépensés ou si la récupération suffit à tout restaurer,
  /// au choix du joueur sinon) — même principe que
  /// [hitDiceSpentByClassId] : cette méthode écrit, ne recalcule jamais.
  ///
  /// [appliedGain] : delta de PV déjà calculé par l'appelant
  /// (`HitDiceSpendCalculator.appliedGain`, déjà plafonné à `max_hp` à
  /// partir de la valeur locale connue) — cette méthode ne fait qu'ajouter
  /// ce delta à la valeur *serveur* de `characters.current_hp` (jamais un
  /// `UPDATE` en valeur absolue), puis reclampe à `max_hp` par sécurité :
  /// même principe que [applyLevelUp] (`hpGain` ajouté à une lecture fraîche
  /// de `current_hp`), pour ne jamais écraser silencieusement un ajustement
  /// PV plus à jour qu'une simple réaffirmation de la valeur locale
  /// n'aurait pas vu passer. Compromis assumé identique à [applyLevelUp]
  /// (pas de RPC Postgres atomique, écritures séquentielles côté client) :
  /// la lecture de `current_hp`/`max_hp` qui alimente ce calcul est donc
  /// placée en dernier, juste avant l'`UPDATE` qui la consomme — les autres
  /// étapes internes (lecture de `character_classes`, écriture de
  /// `hit_dice_spent`) sont faites avant elle plutôt qu'après, pour réduire
  /// la fenêtre de course à un seul aller-retour réseau au lieu de
  /// plusieurs. Même discipline appliquée à la relecture de `max_hp` du
  /// repos long, bien que son écriture (`current_hp = max_hp`) soit
  /// idempotente et donc moins exposée.
  ///
  /// [className] : même rôle et même rationale que sur [applyLevelUp] (voir
  /// sa documentation) — nom de la classe **primaire**, résolu par
  /// l'appelant (`character_detail_screen.dart`), utilisé pour le recalcul
  /// de `character_spell_slots` au repos long. Les autres classes d'un
  /// personnage multiclassé sont nommées par cette méthode elle-même
  /// (`translations`), jamais par l'appelant. Ignoré pour un repos court
  /// (aucun recalcul de sorts).
  ///
  /// `character_spell_slots`/`character_feature_uses` ne sont jamais
  /// initialisées à la création de personnage (gaps pré-existants
  /// documentés) : un personnage sans aucune classe ou sans aucune ligne
  /// préexistante n'a simplement rien à réinitialiser sur ces tables,
  /// jamais une erreur. Même chose pour `hit_dice_spent`/dés de vie : une
  /// entrée de [hitDiceSpentByClassId]/[hitDiceRecoveredByClassId] dont le
  /// `class_id` ne correspond à aucune ligne `character_classes` du
  /// personnage est simplement ignorée (défensif — ne devrait jamais
  /// survenir, l'appelant construisant ces maps depuis les mêmes classes).
  ///
  /// `character_pact_slots` (magie de pacte de l'Occultiste, voir
  /// [_resetPactSlot]) : recalculée pour les DEUX types de repos
  /// (contrairement à `character_spell_slots`, repos long uniquement), et
  /// résolue depuis **toutes** les classes du personnage (l'Occultiste peut
  /// être une classe secondaire), pas seulement la primaire.
  ///
  /// Isolation cross-utilisateur : même garantie que le reste de ce
  /// fichier (vérification explicite de `characters.owner_id`, RLS en
  /// filet de sécurité).
  ///
  /// D35 du registre de dette technique : même garde-fou qu'[applyLevelUp]
  /// (voir sa documentation), appelé en tout premier avant même la
  /// vérification d'appartenance ci-dessus — **mais seulement quand cette
  /// méthode va effectivement relire/réécrire `current_hp` plus bas** : un
  /// repos long (toujours), ou un repos court avec [diceSpent] strictement
  /// positif. Un repos court avec `diceSpent == 0` ne touche jamais
  /// `current_hp`/`max_hp` (voir la branche `RestType.short` ci-dessus) et
  /// n'a donc aucune raison d'être bloqué par un ajustement PV/XP hors ligne
  /// encore en attente pour ce personnage — bloquer ce cas dégraderait
  /// l'UX sans jamais lire de valeur périmée.
  ///
  /// Mode hors-ligne (D11 du registre de dette technique, décision chef de
  /// projet du 09/10/2026) : contrairement à [applyLevelUp] (hors périmètre
  /// de cette décision, voir D05), cette méthode rejoint [updateHp]/[addXp]/
  /// [castSpell]/[setInnateSpellUsesSpent]/[useClassFeature] dans une vraie
  /// mise en file. Connectivité absente -> mise en file
  /// ([PendingCharacterWriteQueue], kind [PendingCharacterWriteKind.rest],
  /// `targetId` vide — au plus un repos en attente par personnage, voir sa
  /// documentation de classe) des paramètres [type]/[className]/[diceSpent]/
  /// [appliedGain] tels quels, [WriteOutcome.queued] **sans tenter aucune
  /// lecture/écriture serveur** (donc sans déclencher le D35 ci-dessus, qui
  /// ferait un aller-retour réseau best-effort pour rien) ; connectivité
  /// présente -> exécution normale (D35 inclus) et [WriteOutcome.synced].
  /// Au retour du réseau, `PendingCharacterWriteSyncer` rejoue l'entrée en
  /// appelant exactement la même logique que le chemin en ligne
  /// (`SupabaseCharacterRepository.applyRestOnline`, voir sa documentation)
  /// — y compris le garde-fou D35, puisqu'à ce moment-là d'éventuelles
  /// écritures PV/XP peuvent encore traîner pour le même personnage.
  ///
  /// **Limite assumée** : contrairement à [updateHp]/[addXp]/[castSpell]/...,
  /// un repos mis en file n'est **jamais** superposé par
  /// `fetchCharacterDetail` tant qu'il n'est pas synchronisé (voir
  /// `SupabaseCharacterRepository._withPendingWrites`) — un repos recalcule
  /// de nombreuses valeurs dérivées (emplacements de sorts, dés de vie...)
  /// qu'il faudrait sinon réimplémenter côté client pour un seul affichage
  /// hors ligne. Sans effet pratique tant que l'écran reste ouvert (son état
  /// optimiste local, `character_detail_screen.dart`, continue d'afficher le
  /// résultat attendu) ; seule une fiche fermée puis rouverte hors ligne
  /// après un repos mis en file réaffiche l'état *avant* ce repos jusqu'à sa
  /// synchronisation.
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
  });

  /// Écrit les 9 colonnes texte libre de l'onglet "Histoire"
  /// (`characters.appearance_text`/`traits_text`/`ideals_text`/`bonds_text`/
  /// `flaws_text`/`backstory_text`/`allies_text`/`features_text`/
  /// `treasure_text`) en un seul `UPDATE` — sheet d'édition
  /// `presentation/widgets/character_story_edit_sheet.dart`. Contrairement à
  /// [addReward] (`UPDATE` monnaie + `INSERT` objets distincts, risque
  /// d'échec partiel documenté sur sa propre doc), les 9 colonnes ici
  /// appartiennent toutes à la même ligne `characters` : un seul appel
  /// réseau couvre tout, aucun risque d'échec partiel possible.
  ///
  /// Chaque paramètre est déjà `trim`é par l'appelant (la sheet d'édition),
  /// `null` signifiant "champ vidé par le joueur" — même convention que
  /// `AppearanceAndBackstoryStepScreen._submit` (étape 8/9 de l'assistant de
  /// création). **Écart assumé avec cette convention côté écriture réseau** :
  /// `characters.*_text` sont `not null default ''` en base (vérifié par
  /// `CharacterCreationRepository.createCharacter`, voir son commentaire —
  /// un premier essai avec une valeur `null` littérale a échoué avec "null
  /// value ... violates not-null constraint") — écrire `null` ici ferait
  /// donc échouer *chaque* sauvegarde d'un champ tout juste vidé. Cette
  /// méthode coalesce donc chaque valeur `null` vers `''` juste avant
  /// l'écriture, exactement comme `createCharacter` le fait déjà pour ces
  /// mêmes colonnes : jamais un `null` littéral envoyé à PostgREST pour ces
  /// 9 colonnes.
  ///
  /// Mode hors ligne : mêmes règles que [useInventoryItem] (jamais mise en
  /// file — `PendingCharacterWriteQueue` reste scopée à `hp`/`xp`, voir la
  /// documentation de classe de `PendingCharacterWriteKind`).
  Future<WriteOutcome> updateStoryFields({
    required String characterId,
    String? appearanceText,
    String? traitsText,
    String? idealsText,
    String? bondsText,
    String? flawsText,
    String? backstoryText,
    String? alliesText,
    String? featuresText,
    String? treasureText,
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
/// Les écritures PV/XP encore en file (`PendingCharacterWriteQueue`) sont
/// superposées au résultat renvoyé, quel que soit le chemin (réseau ou
/// cache) — voir [_withPendingWrites]. Le cache, lui, ne contient jamais que
/// le dernier état serveur connu : outre chaque lecture réseau réussie, une
/// écriture PV/XP confirmée par le serveur (en ligne, ou synchronisée par
/// `PendingCharacterWriteSyncer`) y reporte les colonnes qu'elle vient
/// d'écrire (`CharacterDetailCache.applyConfirmedColumns`), jamais une
/// valeur seulement mise en file.
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

  /// Clé, forme et correction ciblée de l'entrée de cache de la fiche — voir
  /// [CharacterDetailCache].
  late final CharacterDetailCache _detailCache = CharacterDetailCache(_cache);

  /// Construit à partir des dépendances déjà injectées ci-dessus (même
  /// principe que [_detailCache]) plutôt qu'un paramètre de constructeur
  /// supplémentaire : [PendingCharacterWriteSyncer] ne prend en entrée que
  /// [_client]/[_pendingWrites]/[_cache]/`this` (voir ci-dessous, D11), tous
  /// déjà présents ici — pas de nouvelle dépendance réelle à faire exiger
  /// explicitement par les ~60 sites de construction de test de cette classe
  /// pour un simple réassemblage d'objets déjà disponibles. `this` est
  /// passable sans risque dans un initialiseur `late final` : il n'est
  /// utilisé par [PendingCharacterWriteSyncer] qu'au moment où [sync] est
  /// effectivement appelée (pour rejouer un repos mis en file, voir
  /// [applyRestOnline]), bien après la fin de ce constructeur.
  ///
  /// Instance distincte de celle construite par
  /// `character_providers.dart::pendingCharacterWriteSyncerProvider`, mais
  /// sans conséquence : [PendingCharacterWriteSyncer] lui-même n'a aucun état
  /// mutable propre (le verrouillage anti-concurrence D33 vit dans
  /// [_pendingWrites], toujours la même instance partagée entre
  /// `SupabaseCharacterRepository` et le coordinateur de synchro — voir les
  /// providers `keepAlive` de `cache_providers.dart`) ; les deux instances se
  /// comportent donc de façon strictement identique vis-à-vis de la même
  /// file, y compris la nouvelle instance de `SupabaseCharacterRepository`
  /// que `pendingCharacterWriteSyncerProvider` construit pour son propre
  /// `this` (voir la doc de classe de [PendingCharacterWriteSyncer]).
  late final PendingCharacterWriteSyncer _pendingWriteSyncer =
      PendingCharacterWriteSyncer(_client, _pendingWrites, _cache, this);

  /// Kinds couverts par le garde-fou D35 ci-dessous — volontairement
  /// restreint à `hp`/`xp`, voir [_blockIfPendingHpOrXpWrites] pour le
  /// rationale complet (deadlock corrigé en revue QA, D11).
  static const _hpOrXpKinds = {
    PendingCharacterWriteKind.hp,
    PendingCharacterWriteKind.xp,
  };

  /// D35 du registre de dette technique : avant [applyRest]/[applyLevelUp],
  /// qui relisent toutes deux `characters.current_hp`/`max_hp` depuis le
  /// serveur pour y appliquer un delta, force d'abord la synchronisation
  /// (best-effort, voir [PendingCharacterWriteSyncer.sync]) de tout
  /// ajustement PV/XP encore en file pour CE personnage — sans cela, ces deux
  /// opérations partiraient d'une valeur serveur périmée, que la
  /// synchronisation différée réécrirait ensuite par-dessus avec une valeur
  /// elle-même périmée après coup.
  ///
  /// **Restreint explicitement à `hp`/`xp`** (`onlyKinds: _hpOrXpKinds`, et
  /// même filtre appliqué à la relecture [stillPending] ci-dessous) —
  /// jusqu'à D11 (09/10/2026), `PendingCharacterWriteKind` ne contenait que
  /// `hp`/`xp`, donc cette restriction était vraie par construction sans
  /// avoir besoin d'être explicite. Depuis que `spellSlot`/`innateSpell`/
  /// `classFeature`/`rest` existent, l'absence de ce filtre causait deux
  /// défauts trouvés en revue QA :
  /// 1. **Deadlock** : [applyRestOnline] (appelée par [applyRest] en ligne
  ///    ET par `PendingCharacterWriteSyncer.sync` pour rejouer un repos mis
  ///    en file) applique ce garde-fou en tout premier pour un repos long
  ///    (ou `appliedGain > 0`). Un `sync()` NON filtré, appelé DEPUIS
  ///    L'INTÉRIEUR du rejeu d'une entrée `rest` déjà tenue par
  ///    `PendingCharacterWriteQueue.runExclusive(characterId, rest, '')`,
  ///    retenterait cette même clé (l'entrée `rest` est toujours en file à
  ///    ce stade, retirée seulement après le succès d'[applyRestOnline]) —
  ///    attente circulaire sur le verrou en mémoire, jamais résolue. Le
  ///    filtrer sur `hp`/`xp` élimine cette ré-entrée : la synchronisation
  ///    imbriquée ne retente plus jamais la clé `rest`/`spellSlot`/
  ///    `innateSpell`/`classFeature` déjà tenue par l'appelant englobant.
  /// 2. **Message trompeur** : sans ce filtre, une entrée `classFeature` (ou
  ///    toute autre) encore en file pour CE personnage (ex. resynchro en
  ///    échec transitoire) faisait échouer [applyRest]/[applyLevelUp] avec
  ///    le message « Des ajustements de PV/XP sont encore en attente... »
  ///    même quand aucun PV/XP n'était en cause.
  ///
  /// [PendingCharacterWriteSyncer.sync] est best-effort sur TOUT le compte,
  /// jamais garanti d'avoir vidé les entrées de [characterId] précisément
  /// (vraiment hors ligne, ou refus non rejouable pas encore abandonné D34) :
  /// une fois la synchronisation tentée, revérifie donc explicitement
  /// [PendingCharacterWriteQueue.forCharacter] pour CE personnage — s'il y
  /// reste une entrée `hp`/`xp`, bloque l'opération avec une
  /// [CharacterFailure] explicite plutôt que de continuer sur une valeur
  /// potentiellement périmée. [applyRest]/[applyLevelUp] sont déjà des
  /// opérations en ligne uniquement (aucun repli hors ligne existant avant
  /// D11, et [applyLevelUp] reste hors périmètre de cette extension, voir
  /// D05) : ce garde-fou rend simplement leur contrat plus strict pour
  /// `hp`/`xp`, il ne le change pas.
  ///
  /// Appelée en tout début de chaque méthode, avant toute lecture/écriture —
  /// y compris avant la vérification d'appartenance du personnage, qui suit
  /// de toute façon normalement derrière (`CharacterFailure` sinon).
  Future<void> _blockIfPendingHpOrXpWrites({
    required String ownerId,
    required String characterId,
  }) async {
    await _pendingWriteSyncer.sync(onlyKinds: _hpOrXpKinds);

    final stillPending = await _pendingWrites.forCharacter(
      ownerId: ownerId,
      characterId: characterId,
    );
    if (stillPending.any((write) => _hpOrXpKinds.contains(write.kind))) {
      throw const CharacterFailure(
        'Des ajustements de PV/XP sont encore en attente de '
        'synchronisation — réessayez une fois la connexion rétablie.',
      );
    }
  }

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
            is_dead,
            is_archived,
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

      final summaries = characterRows
          .map(
            (row) => CharacterRowMapper.toSummary(
              row,
              raceNames: raceNames,
              classNames: classNames,
            ),
          )
          .toList();
      return CharacterListSorter.sort(summaries);
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
    final cacheKey = CharacterDetailCache.keyFor(
      ownerId: ownerId,
      characterId: characterId,
    );

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
            is_dead,
            is_archived,
            inspiration,
            share_token,
            race_id,
            subrace_id,
            lineage_id,
            race_custom_text,
            background_id,
            background_custom_text,
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
            character_classes(class_id, subclass_id, level, is_primary, hit_dice_spent, classes(saving_throw_proficiencies, hit_die, armor_proficiencies, weapon_proficiencies)),
            character_ability_scores(ability_id, score),
            character_skill_proficiencies(skill_id, proficiency),
            character_tool_proficiencies(tool_id, custom_text),
            character_languages(language_id),
            character_spells(spell_id, status, is_favorite, source_class_id, innate_uses_spent),
            character_spell_slots(slot_level, slots_total, slots_used),
            character_pact_slots(slot_level, slots_total, slots_used),
            character_feature_uses(class_feature_id, uses_remaining),
            character_class_options(class_feature_id, level, chosen_value),
            character_race_choices(kind, skill_id, tool_id),
            character_invocations(invocation_id),
            character_feats(feat_id),
            character_inventory(
              id, item_id, custom_name, quantity, equipped, weapon_slot, is_attuned, notes,
              items(
                category, weight, cost, rarity, requires_attunement, consumable,
                ac_bonus, ac_bonus_kind,
                weapon_properties(damage_dice, damage_type, properties, range),
                armor_properties(ac_base, ac_dex_bonus, strength_requirement, stealth_disadvantage, slot)
              )
            ),
            character_campaigns(id, story_id, stories(title, cover_image_path, gm_display_name:stories_gm_display_name)),
            character_photos(id, url, created_at),
            character_journal_entries(id, body, created_at)
          ''')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (row == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }

      final payload = await _buildCharacterDetailPayload(row);
      // Le cache garde l'état serveur brut : les écritures en attente ne
      // sont superposées qu'au résultat renvoyé (voir [_withPendingWrites]).
      await _writeCacheBestEffort(cacheKey, payload);
      return await _withPendingWrites(
        _mapCharacterDetailPayload(payload),
        ownerId: ownerId,
        characterId: characterId,
      );
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        cacheKey,
        _mapCharacterDetailPayload,
      );
      if (cached != null) {
        return _withPendingWrites(
          cached,
          ownerId: ownerId,
          characterId: characterId,
        );
      }
      throw mapCharacterError(error);
    } catch (_) {
      final cached = await _mappedFromCache(
        cacheKey,
        _mapCharacterDetailPayload,
      );
      if (cached != null) {
        return _withPendingWrites(
          cached,
          ownerId: ownerId,
          characterId: characterId,
        );
      }
      throw mapUnknownCharacterError();
    }
  }

  /// Superpose à [detail] (fiche relue du serveur ou du cache) les écritures
  /// encore en attente de synchronisation pour ce personnage et ce compte
  /// (`PendingCharacterWriteQueue.forCharacter`) : tant qu'une écriture mise
  /// en file n'est pas partie, la fiche renvoyée doit refléter cette
  /// écriture, pas la valeur serveur/cache qu'elle va remplacer.
  ///
  /// Sans cette superposition, une fiche fermée puis rouverte hors ligne
  /// réaffichait les PV/l'XP d'avant l'ajustement ; l'ajustement suivant,
  /// calculé par l'écran en valeur absolue à partir de cette base périmée,
  /// remplaçait l'entrée en file et le premier ajustement était perdu sans
  /// message (voir `character_repository_pending_writes_test.dart`). Même
  /// perte en ligne, si la fiche était relue après le retour du réseau mais
  /// avant que la synchronisation n'ait abouti.
  ///
  /// Depuis D11 (09/10/2026), couvre aussi [PendingCharacterWriteKind
  /// .spellSlot]/[PendingCharacterWriteKind.innateSpell]/
  /// [PendingCharacterWriteKind.classFeature] — même rationale, appliquée à
  /// l'entrée du tableau/de la liste correspondante plutôt qu'à un champ
  /// scalaire de [detail] directement. Une entrée dont la cible
  /// (niveau d'emplacement, sort, aptitude) n'existe plus dans [detail] est
  /// silencieusement ignorée (ex. sort retiré depuis un autre appareil) :
  /// rien à superposer, jamais une erreur.
  ///
  /// **Exception** : [PendingCharacterWriteKind.rest] n'est volontairement
  /// JAMAIS superposée ici (voir la doc de classe de
  /// [PendingCharacterWriteKind]) — reproduire côté client tout ce qu'un
  /// repos recalcule sur le serveur (emplacements de sorts, dés de vie,
  /// aptitudes...) dupliquerait une grande partie de
  /// [SupabaseCharacterRepository.applyRestOnline] pour un gain cantonné au
  /// cas déjà couvert par l'état optimiste local de l'écran
  /// (`character_detail_screen.dart`, tant qu'il reste monté) : une fiche
  /// fermée puis rouverte hors ligne après un repos mis en file continue
  /// d'afficher l'état *avant* ce repos jusqu'à sa synchronisation — limite
  /// assumée, documentée sur `CharacterRepository.applyRest`.
  ///
  /// La file reste la seule source des écritures en attente : le cache de
  /// la fiche n'est jamais modifié ici. Une fois la synchronisation réussie,
  /// l'entrée disparaît de la file et le serveur porte exactement la valeur
  /// qui était superposée — la fiche relue ne change donc pas. Si la
  /// synchronisation échoue, l'entrée reste et continue d'être superposée.
  ///
  /// Limite assumée (comportement de synchronisation inchangé) : aucune
  /// résolution de conflit. Si le personnage a été modifié entre-temps
  /// depuis un autre appareil, la valeur en file masque la valeur serveur à
  /// l'affichage puis l'écrase à la synchronisation ("dernière écriture
  /// gagne") ; les champs sans entrée en file gardent leur valeur serveur.
  ///
  /// Lecture locale uniquement (aucune requête réseau), best-effort : une
  /// lecture de file en échec ou un payload illisible ne doit jamais
  /// empêcher d'afficher la fiche — [detail] est alors renvoyé tel quel.
  Future<CharacterDetail> _withPendingWrites(
    CharacterDetail detail, {
    required String ownerId,
    required String characterId,
  }) async {
    try {
      final pending = await _pendingWrites.forCharacter(
        ownerId: ownerId,
        characterId: characterId,
      );
      var result = detail;
      for (final write in pending) {
        switch (write.kind) {
          case PendingCharacterWriteKind.hp:
            final currentHp = write.payload['currentHp'];
            final temporaryHp = write.payload['temporaryHp'];
            if (currentHp is num && temporaryHp is num) {
              result = result.copyWith(
                currentHp: currentHp.toInt(),
                temporaryHp: temporaryHp.toInt(),
              );
            }
          case PendingCharacterWriteKind.xp:
            final newXp = write.payload['newXp'];
            if (newXp is num) {
              result = result.copyWith(xp: newXp.toInt());
            }
          case PendingCharacterWriteKind.spellSlot:
            final slotLevel = write.payload['slotLevel'];
            final slotsUsed = write.payload['slotsUsed'];
            final isPactSlot = write.payload['isPactSlot'] == true;
            if (slotLevel is! num || slotsUsed is! num) break;
            if (isPactSlot) {
              final pact = result.pactSpellSlot;
              if (pact != null && pact.level == slotLevel.toInt()) {
                result = result.copyWith(
                  pactSpellSlot: CharacterSpellSlot(
                    level: pact.level,
                    total: pact.total,
                    used: slotsUsed.toInt(),
                    isPact: true,
                  ),
                );
              }
            } else {
              result = result.copyWith(
                spellSlots: [
                  for (final slot in result.spellSlots)
                    if (slot.level == slotLevel.toInt())
                      CharacterSpellSlot(
                        level: slot.level,
                        total: slot.total,
                        used: slotsUsed.toInt(),
                      )
                    else
                      slot,
                ],
              );
            }
          case PendingCharacterWriteKind.innateSpell:
            final spellId = write.payload['spellId'];
            final usesSpent = write.payload['usesSpent'];
            if (spellId is! num || usesSpent is! num) break;
            result = result.copyWith(
              spells: [
                for (final spell in result.spells)
                  if (spell.id == spellId.toInt())
                    spell.copyWithInnateUsesSpent(usesSpent.toInt())
                  else
                    spell,
              ],
            );
          case PendingCharacterWriteKind.classFeature:
            final classFeatureId = write.payload['classFeatureId'];
            final usesRemaining = write.payload['usesRemaining'];
            if (classFeatureId is! num || usesRemaining is! num) break;
            result = result.copyWith(
              classFeatures: [
                for (final feature in result.classFeatures)
                  if (feature.id == classFeatureId.toInt())
                    CharacterClassFeature(
                      id: feature.id,
                      name: feature.name,
                      level: feature.level,
                      usesMax: feature.usesMax,
                      usesRemaining: usesRemaining.toInt(),
                      restType: feature.restType,
                      description: feature.description,
                    )
                  else
                    feature,
              ],
            );
          case PendingCharacterWriteKind.rest:
          // Jamais superposée — voir la documentation de cette méthode.
        }
      }
      return result;
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
      return detail;
    }
  }

  /// Relève, juste avant une écriture PV/XP **en ligne**, l'entrée [kind]
  /// éventuellement restée en file pour ce personnage (réseau revenu mais
  /// synchronisation pas encore passée, ou en échec) — `null` s'il n'y en a
  /// pas. À passer à [_recordConfirmedWrite] une fois l'écriture réussie.
  ///
  /// Appelée uniquement depuis l'intérieur de
  /// `PendingCharacterWriteQueue.runExclusive` (voir `updateHp`/`addXp` et,
  /// depuis D11, `castSpell`/`setInnateSpellUsesSpent`/`useClassFeature`/
  /// `applyRest`) : aucune synchronisation de la file ne peut donc être en
  /// vol pour la même clé `(characterId, kind, targetId)` entre cette lecture
  /// et la fin de l'écriture en ligne qui suit (D33 du registre de dette
  /// technique) — sans ce verrou, cette lecture pouvait être périmée dès la
  /// ligne suivante.
  ///
  /// [targetId] : `''` pour `hp`/`xp`/`rest`, voir
  /// [PendingCharacterWrite.targetId] pour sa forme exacte selon [kind].
  ///
  /// Lecture locale uniquement, best-effort : en cas d'échec, rien ne sera
  /// retiré de la file après l'écriture.
  Future<PendingCharacterWrite?> _pendingWriteBeforeOnlineWrite({
    required String characterId,
    required String ownerId,
    required PendingCharacterWriteKind kind,
    required String targetId,
  }) async {
    try {
      final pending = await _pendingWrites.forCharacter(
        ownerId: ownerId,
        characterId: characterId,
      );
      for (final write in pending) {
        if (write.kind == kind && write.targetId == targetId) return write;
      }
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
    return null;
  }

  /// `targetId` (voir [PendingCharacterWrite.targetId]) d'un emplacement de
  /// sort mis en file par [castSpell] : distingue [slotLevel] ET la table
  /// visée ([isPactSlot]) — un même niveau d'emplacement classique
  /// (`character_spell_slots`) et de pacte (`character_pact_slots`) ne doit
  /// jamais partager une entrée, ce sont deux pools indépendants (voir
  /// `domain/spell_slot_progression.dart`).
  String _spellSlotTargetId({
    required int slotLevel,
    required bool isPactSlot,
  }) => '${isPactSlot ? 'pact' : 'std'}_$slotLevel';

  /// Suites locales d'une écriture **en ligne** réussie ([columns], quand
  /// fourni, est le corps de l'`UPDATE` `characters` que le serveur vient
  /// d'accepter) :
  ///
  /// 1. retire de la file [supersededWrite], l'entrée du même type/cible
  ///    relevée **avant** l'écriture ([_pendingWriteBeforeOnlineWrite]) :
  ///    toutes les méthodes qui appellent cette méthode écrivent des valeurs
  ///    absolues, cette entrée est donc périmée — la laisser ferait réécrire
  ///    l'ancienne valeur par-dessus la nouvelle à la synchronisation
  ///    suivante, et la ferait réapparaître d'ici là dans la fiche relue
  ///    ([_withPendingWrites]). Le retrait est conditionnel
  ///    (`PendingCharacterWriteQueue.removeIfUnchanged`) : une entrée mise en
  ///    file **pendant** l'écriture réseau (connectivité retombée, nouveau
  ///    tap) est plus récente que celle-ci et doit rester ;
  /// 2. si [columns] est fourni, le reporte dans le cache de la fiche
  ///    (`CharacterDetailCache.applyConfirmedColumns`) — si la relecture qui
  ///    suit échoue (réseau retombé), la fiche relue depuis le cache porte
  ///    quand même la valeur écrite, pas celle d'avant. `null` pour
  ///    `castSpell`/`setInnateSpellUsesSpent`/`useClassFeature`/`applyRest`
  ///    (D11) : ces écritures ne touchent jamais `characters` directement
  ///    (`character_spell_slots`/`character_spells`/`character_feature_uses`/
  ///    multi-tables), et [CharacterDetailCache] ne sait patcher que la ligne
  ///    `characters` brute — voir la doc de classe de
  ///    [PendingCharacterWriteKind] pour la limite assumée que ça implique
  ///    (pas de correction du cache fiche fermée, seule la file superposée
  ///    par [_withPendingWrites] reste la source de vérité hors ligne).
  ///
  /// Opérations locales uniquement, best-effort : l'écriture serveur a déjà
  /// réussi, un échec ici ne doit pas la faire passer pour un échec.
  Future<void> _recordConfirmedWrite({
    required String characterId,
    required String ownerId,
    required Map<String, dynamic>? columns,
    required PendingCharacterWrite? supersededWrite,
  }) async {
    // Retrait d'abord, cache ensuite (ordre inverse de celui de
    // `PendingCharacterWriteSyncer.sync`) : tant qu'elle est en file,
    // l'entrée périmée peut être relevée par une synchro ou, si l'app est
    // tuée ici, superposée puis réécrite sur le serveur au redémarrage —
    // écrasant l'écriture qui vient d'être confirmée. Dans cet ordre, le
    // pire cas n'est qu'un cache en retard d'une écriture, corrigé à la
    // prochaine lecture en ligne.
    if (supersededWrite != null) {
      try {
        await _pendingWrites.removeIfUnchanged(supersededWrite);
      } catch (_) {
        // Best-effort : voir la documentation de cette méthode.
      }
    }
    if (columns != null) {
      await _detailCache.applyConfirmedColumns(
        ownerId: ownerId,
        characterId: characterId,
        columns: columns,
      );
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
        targetId: '',
        payload: {'currentHp': currentHp, 'temporaryHp': temporaryHp},
      );
      return WriteOutcome.queued;
    }

    // Verrouillé (D33) : jamais en vol en même temps qu'une synchronisation
    // de la file pour ce même personnage et ce même type — voir la doc de
    // classe de `PendingCharacterWriteQueue.runExclusive`.
    try {
      await _pendingWrites.runExclusive(
        characterId: characterId,
        kind: PendingCharacterWriteKind.hp,
        targetId: '',
        action: () async {
          final supersededWrite = await _pendingWriteBeforeOnlineWrite(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.hp,
            targetId: '',
          );
          final columns = <String, dynamic>{
            'current_hp': currentHp,
            'temporary_hp': temporaryHp,
          };
          await _client
              .from('characters')
              .update(columns)
              .eq('id', characterId)
              .eq('owner_id', ownerId);
          await _recordConfirmedWrite(
            characterId: characterId,
            ownerId: ownerId,
            columns: columns,
            supersededWrite: supersededWrite,
          );
        },
      );
      return WriteOutcome.synced;
    } on TimeoutException {
      // Dette D12 : `ConnectivityChecker.hasConnection()` a déclaré une
      // interface active (sinon on ne serait jamais arrivé ici, voir la
      // branche ci-dessus), mais la requête réseau elle-même n'a jamais
      // abouti dans le délai global (`TimeoutHttpClient`,
      // `core/network/timeout_http_client.dart`) — un Wi-Fi sans débit réel
      // ou un signal faible, typiquement. Traité comme une absence de
      // connectivité (même mise en file que `!hasConnection()` ci-dessus)
      // plutôt que comme une [CharacterFailure] dure : contrairement à un
      // vrai échec serveur (`PostgrestException`/`catch` ci-dessous, jamais
      // mis en file, voir leur documentation), rien n'indique ici qu'un
      // nouvel essai échouerait de la même façon.
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.hp,
        targetId: '',
        payload: {'currentHp': currentHp, 'temporaryHp': temporaryHp},
      );
      return WriteOutcome.queued;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : la mise à jour PV elle-même a
      // pu réussir côté serveur avant qu'une étape locale inattendue
      // (`_recordConfirmedWrite`) échoue — un bug silencieux ici
      // désynchroniserait durablement le cache/la file hors-ligne sans
      // jamais être signalé.
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  }) async {
    final ownerId = _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .update({'is_dead': isDead})
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
  Future<WriteOutcome> setArchived({
    required String characterId,
    required bool isArchived,
  }) async {
    final ownerId = _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .update({'is_archived': isArchived})
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
  Future<WriteOutcome> deleteCharacter({required String characterId}) async {
    final ownerId = _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .delete()
          .eq('id', characterId)
          .eq('owner_id', ownerId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : suppression de personnage,
      // écriture destructive — un bug silencieux ici ne doit jamais rester
      // invisible.
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> setInspiration({
    required String characterId,
    required bool inspiration,
  }) async {
    final ownerId = _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .update({'inspiration': inspiration})
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
  Future<void> addGalleryPhoto({
    required String characterId,
    required Uint8List bytes,
  }) async {
    final ownerId = _requireOwnerId();
    // Nom de fichier horodaté, même principe que [uploadPortrait] — chaque
    // appel ajoute un nouveau fichier, jamais de remplacement (`upsert`
    // laissé à sa valeur par défaut `false`, contrairement à
    // [uploadPortrait]).
    final path =
        '$ownerId/$characterId/${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await _client.storage
          .from(GalleryPhotoStoragePathResolver.bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
      final publicUrl = _client.storage
          .from(GalleryPhotoStoragePathResolver.bucket)
          .getPublicUrl(path);

      await _client.from('character_photos').insert({
        'character_id': characterId,
        'url': publicUrl,
      });
    } on StorageException catch (error) {
      throw CharacterFailure(
        error.message.isNotEmpty
            ? error.message
            : "Impossible d'envoyer la photo. Réessayez.",
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<void> removeGalleryPhoto({
    required String characterId,
    required String photoId,
    required String url,
  }) async {
    _requireOwnerId();
    try {
      final path = GalleryPhotoStoragePathResolver.resolve(url);
      if (path != null) {
        await _client.storage
            .from(GalleryPhotoStoragePathResolver.bucket)
            .remove([path]);
      }
      await _client
          .from('character_photos')
          .delete()
          .eq('id', photoId)
          .eq('character_id', characterId);
    } on StorageException catch (error) {
      throw CharacterFailure(
        error.message.isNotEmpty
            ? error.message
            : 'Impossible de retirer cette photo. Réessayez.',
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client.from('character_journal_entries').insert({
        'character_id': characterId,
        'body': body,
      });
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> updateJournalEntry({
    required String characterId,
    required String entryId,
    required String body,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('character_journal_entries')
          .update({'body': body})
          .eq('id', entryId)
          .eq('character_id', characterId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> removeJournalEntry({
    required String characterId,
    required String entryId,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('character_journal_entries')
          .delete()
          .eq('id', entryId)
          .eq('character_id', characterId);
      return WriteOutcome.synced;
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
        targetId: '',
        payload: {'newXp': newXp},
      );
      return WriteOutcome.queued;
    }

    // Verrouillé (D33) : même rationale que `updateHp`.
    try {
      await _pendingWrites.runExclusive(
        characterId: characterId,
        kind: PendingCharacterWriteKind.xp,
        targetId: '',
        action: () async {
          final supersededWrite = await _pendingWriteBeforeOnlineWrite(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.xp,
            targetId: '',
          );
          final columns = <String, dynamic>{'xp': newXp};
          await _client
              .from('characters')
              .update(columns)
              .eq('id', characterId)
              .eq('owner_id', ownerId);
          await _recordConfirmedWrite(
            characterId: characterId,
            ownerId: ownerId,
            columns: columns,
            supersededWrite: supersededWrite,
          );
        },
      );
      return WriteOutcome.synced;
    } on TimeoutException {
      // Dette D12 : même rationale que [updateHp] ci-dessus (voir sa
      // documentation) — la connectivité était déclarée active, mais la
      // requête réseau n'a jamais abouti dans le délai global
      // (`TimeoutHttpClient`). Traité comme une absence de connectivité,
      // jamais comme une [CharacterFailure] dure.
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.xp,
        targetId: '',
        payload: {'newXp': newXp},
      );
      return WriteOutcome.queued;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : même rationale que [updateHp]
      // ci-dessus (écriture XP éventuellement confirmée côté serveur avant
      // un échec local inattendu).
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  }) async {
    final ownerId = _requireOwnerId();
    final targetId = _spellSlotTargetId(
      slotLevel: slotLevel,
      isPactSlot: isPactSlot,
    );

    // D11 du registre de dette technique (09/10/2026) : mise en file réelle,
    // même principe que [updateHp]/[addXp] — voir la documentation de
    // [CharacterRepository.castSpell].
    if (!await _connectivityChecker.hasConnection()) {
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: targetId,
        payload: {
          'slotLevel': slotLevel,
          'slotsUsed': slotsUsed,
          'isPactSlot': isPactSlot,
        },
      );
      return WriteOutcome.queued;
    }

    // Verrouillé (D33) : même rationale que `updateHp`, clé élargie à
    // `targetId` (deux sorts différents du même personnage ne s'attendent
    // jamais entre eux, voir la doc de classe de `PendingCharacterWriteQueue
    // .runExclusive`).
    try {
      await _pendingWrites.runExclusive(
        characterId: characterId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: targetId,
        action: () async {
          final characterRow = await _client
              .from('characters')
              .select('id')
              .eq('id', characterId)
              .eq('owner_id', ownerId)
              .maybeSingle();
          if (characterRow == null) {
            throw const CharacterFailure('Personnage introuvable.');
          }

          final supersededWrite = await _pendingWriteBeforeOnlineWrite(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.spellSlot,
            targetId: targetId,
          );
          await _client
              .from(
                isPactSlot ? 'character_pact_slots' : 'character_spell_slots',
              )
              .update({'slots_used': slotsUsed})
              .eq('character_id', characterId)
              .eq('slot_level', slotLevel);
          // `columns: null` : voir la documentation de
          // [_recordConfirmedWrite] (aucune colonne `characters` à patcher
          // dans le cache de la fiche pour ce kind).
          await _recordConfirmedWrite(
            characterId: characterId,
            ownerId: ownerId,
            columns: null,
            supersededWrite: supersededWrite,
          );
        },
      );
      return WriteOutcome.synced;
    } on TimeoutException {
      // Dette D12 : même rationale que [updateHp] (voir sa documentation).
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: targetId,
        payload: {
          'slotLevel': slotLevel,
          'slotsUsed': slotsUsed,
          'isPactSlot': isPactSlot,
        },
      );
      return WriteOutcome.queued;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : même rationale que [updateHp].
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> setSpellFavorite({
    required String characterId,
    required int spellId,
    required bool isFavorite,
  }) async {
    // `character_spells` n'a pas de colonne `owner_id` propre, la RLS
    // (`owns_character(character_id)`) est la garantie d'isolation — même
    // principe que [useInventoryItem]. `_requireOwnerId()` sert uniquement à
    // s'assurer qu'une session existe.
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('character_spells')
          .update({'is_favorite': isFavorite})
          .eq('character_id', characterId)
          .eq('spell_id', spellId);
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> setSpellPrepared({
    required String characterId,
    required int spellId,
    required bool prepared,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    // Vérification bloquante AVANT toute écriture, et volontairement HORS du
    // `try`/`catch` ci-dessous : une [CharacterFailure] levée ici doit se
    // propager telle quelle à l'appelant (même convention que les autres
    // écritures de ce dépôt, ex. `applyLevelUp`), pas être ré-enveloppée par
    // `mapUnknownCharacterError()` comme le ferait le `catch (_)` générique
    // de ce bloc s'il l'attrapait. Jamais appelée pour dé-préparer : voir la
    // doc de classe de [CharacterRepository.setSpellPrepared].
    final resolvedSourceClassId = prepared
        ? await _resolvePreparingClassAndEnforceLimit(
            characterId: characterId,
            spellId: spellId,
          )
        : null;

    try {
      final updated = await _client
          .from('character_spells')
          .update({
            'status':
                (prepared ? SpellStatus.prepared : SpellStatus.known).value,
          })
          .eq('character_id', characterId)
          .eq('spell_id', spellId)
          // Jamais une ligne 'inné' : un sort inné n'a pas de préparation,
          // et la passer à 'préparé' puis 'connu' serait sans retour. Si le
          // sort a des lignes en double (une innée, une ordinaire), seule la
          // ligne ordinaire bouge.
          .neq('status', SpellStatus.innate.value)
          .select('id');
      // Sort de la liste de classe d'un lanceur à préparation, sans ligne
      // `character_spells` tant qu'il n'a jamais été préparé (voir
      // `_fetchPreparedCasterClassListSpellRows`) : la créer. Pas d'upsert
      // possible : la contrainte unique posée par D10
      // (`character_spells_unique_ordinary_per_spell`) est partielle (ne
      // porte que sur les lignes non-innées) et PostgREST n'expose pas de
      // moyen de cibler un upsert sur une contrainte partielle plutôt que
      // sur la clé primaire.
      if (updated.isEmpty && prepared) {
        // Aucune ligne modifiée : soit le sort n'a aucune ligne, soit il
        // n'a que des lignes 'inné' (exclues ci-dessus). Dans ce second
        // cas, ne rien écrire — surtout pas une ligne en double.
        final existing = await _client
            .from('character_spells')
            .select('id')
            .eq('character_id', characterId)
            .eq('spell_id', spellId)
            .limit(1);
        if (existing.isNotEmpty) return WriteOutcome.synced;
        try {
          await _client.from('character_spells').insert({
            'character_id': characterId,
            'spell_id': spellId,
            'status': SpellStatus.prepared.value,
            // D40 (`docs/dette-technique.md`) : cette colonne n'était encore
            // jamais écrite à l'insertion avant ce chantier — `null` si la
            // résolution ci-dessus n'a pas pu déterminer de classe (fail
            // open, voir sa documentation), jamais une valeur devinée.
            'source_class_id': resolvedSourceClassId,
          });
        } on PostgrestException catch (error) {
          // D42 : course entre la vérification `existing` ci-dessus et cet
          // insert — un appel concurrent (double appui rapide, ou synchro
          // hors ligne qui se déclenche en même temps qu'une action en
          // ligne) peut passer la même vérification avant que cet insert ne
          // soit confirmé. Depuis la contrainte unique posée par D10
          // (`character_spells_unique_ordinary_per_spell`, au plus une
          // ligne non-innée par (character_id, spell_id)), c'est désormais
          // cet insert qui échoue avec '23505' plutôt que de créer un
          // doublon silencieux. L'état voulu par le joueur (ce sort est
          // préparé) est de toute façon atteint — par cet appel ou par celui
          // qui a gagné la course — donc un succès, pas une erreur à
          // afficher. On vérifie le nom de la contrainte (pas seulement le
          // code '23505') pour ne jamais masquer une vraie violation
          // d'unicité sur une autre contrainte si cette table en gagnait une
          // un jour ; à ce jour c'est la seule contrainte unique sur les
          // lignes non-innées de `character_spells`.
          final isExpectedRaceCondition =
              error.code == '23505' &&
              error.message.contains(
                'character_spells_unique_ordinary_per_spell',
              );
          if (!isExpectedRaceCondition) rethrow;
        }
      }
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  /// Avant d'écrire `status: 'préparé'` pour un NOUVEAU sort (jamais pour
  /// dé-préparer, voir la doc de [setSpellPrepared]) : vérifie que la classe
  /// d'origine de [spellId] n'a pas déjà atteint sa propre limite RAW de
  /// sorts préparés (PHB, « Multiclassing — Spells Known and Prepared » :
  /// chaque classe qui prépare calcule sa propre limite séparément, jamais
  /// un total fusionné — voir `domain/prepared_spells_limit.dart`). Lève une
  /// [CharacterFailure] explicite (nom de la classe, décompte/limite) si la
  /// limite est déjà atteinte ou dépassée.
  ///
  /// Renvoie la classe d'origine résolue pour [spellId] (à écrire comme
  /// `source_class_id` sur l'éventuelle nouvelle ligne `character_spells`,
  /// voir [setSpellPrepared], D40 du registre de dette technique) — `null`
  /// si le personnage n'a aucune classe qui prépare (ne devrait pas arriver :
  /// un sort sans classe qui prépare n'est jamais proposé à la préparation
  /// par l'UI) ou si l'origine reste ambiguë après résolution (voir plus
  /// bas) : dans les deux cas, **fail-open** — ne bloque jamais sur une
  /// donnée qu'elle n'arrive pas à interpréter, seulement sur une limite
  /// RAW effectivement dépassée.
  ///
  /// **Requêtes dédiées, volontairement PAS `fetchCharacterDetail`** (la
  /// fiche complète, bien plus lourde : inventaire, compétences... tout ce
  /// dont cette vérification n'a pas besoin — et qui aurait aussi forcé à
  /// réécrire tous les tests déjà en place sur [setSpellPrepared], qui ne
  /// simulent QUE les appels `character_spells`). Coût pour le cas courant
  /// (une seule classe qui prépare, pas de sous-classe accordant de sort) :
  /// 3 requêtes (`character_classes`, `character_ability_scores` via
  /// [_fetchAllAbilityScores], `character_spells` déjà préparés) — une de
  /// plus (`subclass_spells`) dès qu'une sous-classe est choisie (voir D77
  /// ci-dessous), 2 de plus en multiclassage si l'origine n'est pas déjà
  /// connue (voir ci-dessous). [CharacterClass.fromId] donne le nom
  /// français de chaque classe sans requête `translations` supplémentaire
  /// (dette D04).
  ///
  /// **D77 (`docs/dette-technique.md`), corrigé le 13/10/2026** : cette
  /// vérification retranche désormais, exactement comme
  /// `CharacterDetail.preparedSpellCount`/`PreparedSpellsLimit.limitsByClass`
  /// (logique de référence, utilisée par l'affichage), un sort par ailleurs
  /// accordé automatiquement par une sous-classe (domaine de Clerc, serment
  /// de Paladin) qui porterait AUSSI une ligne ordinaire `character_spells`
  /// à 'préparé' (recoupement : un sort choisi normalement avant de devenir
  /// un sort de domaine/serment) — voir le calcul de `grantedSpellIds`
  /// ci-dessous, transmis à [_preparedSpellCountsByClass]. Avant ce
  /// correctif, trouvé par l'agent `regles-dnd` en relecture : l'écran
  /// pouvait présenter ce sort comme encore cochable (exclu du décompte
  /// affiché) alors que le serveur le comptait quand même, rejetant une
  /// action que l'écran venait de montrer comme permise.
  Future<Object?> _resolvePreparingClassAndEnforceLimit({
    required String characterId,
    required int spellId,
  }) async {
    final classRows = await _client
        .from('character_classes')
        .select('class_id, level, subclass_id')
        .eq('character_id', characterId);

    final preparingClasses =
        <({Object classId, String className, int level})>[];
    // D77 (`docs/dette-technique.md`) : un sort choisi normalement PUIS
    // devenu accordé par une sous-classe (domaine de Clerc, serment de
    // Paladin) ne doit jamais compter dans la limite, exactement comme côté
    // affichage (`CharacterSpellEntry.isAlwaysPrepared`/`grantSource`,
    // `PreparedSpellsLimit._countsTowardPreparedLimit`) — sans cette
    // exclusion, le serveur pouvait rejeter un sort que l'écran présentait
    // pourtant comme encore cochable (contradiction visible par le joueur).
    // Toutes les lignes `character_classes` comptent ici (pas seulement
    // celles qui préparent) : `SubclassSpellGrantResolver` ne filtre pas
    // non plus par ce critère ailleurs dans le code.
    final subclassProgress = <({int subclassId, int classLevel})>[];
    for (final row in classRows) {
      final classId = row['class_id'];
      final subclassId = row['subclass_id'];
      final level = (row['level'] as num?)?.toInt() ?? 0;
      if (subclassId is num) {
        subclassProgress.add((
          subclassId: subclassId.toInt(),
          classLevel: level,
        ));
      }
      final characterClass = CharacterClass.fromId(classId);
      if (characterClass == null) continue;
      if (!PreparedSpellsLimit.preparesSpells(characterClass.frenchName)) {
        continue;
      }
      preparingClasses.add((
        classId: classId as Object,
        className: characterClass.frenchName,
        level: level,
      ));
    }
    if (preparingClasses.isEmpty) return null;

    var grantedSpellIds = const <int>{};
    if (subclassProgress.isNotEmpty) {
      final grantRows = await _client
          .from('subclass_spells')
          .select('subclass_id, spell_id, class_level')
          .eq('grant_kind', 'always_prepared')
          .inFilter('subclass_id', [
            for (final p in subclassProgress) p.subclassId,
          ]);
      final ids = <int>{};
      for (final grant in grantRows) {
        final grantSubclassId = grant['subclass_id'];
        final grantSpellId = grant['spell_id'];
        final grantClassLevel = grant['class_level'];
        if (grantSubclassId is! num ||
            grantSpellId is! num ||
            grantClassLevel is! num) {
          continue;
        }
        final applies = subclassProgress.any(
          (p) =>
              p.subclassId == grantSubclassId.toInt() &&
              grantClassLevel.toInt() <= p.classLevel,
        );
        if (applies) ids.add(grantSpellId.toInt());
      }
      grantedSpellIds = ids;
    }

    final abilityScores = await _fetchAllAbilityScores(characterId);
    final countsByClassId = await _preparedSpellCountsByClass(
      characterId: characterId,
      classIds: [for (final c in preparingClasses) c.classId],
      excludedSpellIds: grantedSpellIds,
    );

    int limitOf(({Object classId, String className, int level}) target) =>
        PreparedSpellsLimit.limitFor(
          className: target.className,
          classLevel: target.level,
          abilityModifier: AbilityScoreRules.abilityModifier(
            abilityScores[PreparedSpellsLimit.abilityKeyFor(
                  target.className,
                )] ??
                10,
          ),
        ) ??
        1;

    Object? resolvedClassId;
    if (preparingClasses.length == 1) {
      // Cas courant, zéro requête supplémentaire par rapport à avant ce
      // chantier : une seule classe candidate, aucune ambiguïté possible.
      resolvedClassId = preparingClasses.single.classId;
    } else {
      // Multiclassage avec 2+ classes qui préparent (ex. Clerc/Paladin) :
      // l'origine DÉJÀ connue pour CE sort (n'importe quel statut, jamais
      // une ligne 'inné' — même garde que [setSpellPrepared]) est
      // autoritaire, jamais recalculée.
      final existingSourceRow = await _client
          .from('character_spells')
          .select('source_class_id')
          .eq('character_id', characterId)
          .eq('spell_id', spellId)
          .neq('status', SpellStatus.innate.value)
          .not('source_class_id', 'is', null)
          .limit(1)
          .maybeSingle();
      final existingSourceClassId = existingSourceRow?['source_class_id'];
      if (existingSourceClassId != null) {
        resolvedClassId = existingSourceClassId;
      } else {
        // Jamais préparé/choisi depuis aucune classe : sort de la liste
        // complète d'un lanceur à préparation (Clerc/Druide/Paladin/
        // Artificier) encore sans ligne pour ce sort. Résout via
        // `spell_classes` (liste RAW de la classe), restreint aux classes
        // PRÉPARANTES du personnage.
        final spellClassRows = await _client
            .from('spell_classes')
            .select('class_id')
            .eq('spell_id', spellId)
            .inFilter('class_id', [
              for (final c in preparingClasses) c.classId,
            ]);
        final candidateIds = {
          for (final row in spellClassRows) row['class_id'].toString(),
        };
        final candidates = [
          for (final c in preparingClasses)
            if (candidateIds.contains(c.classId.toString())) c,
        ];
        if (candidates.length == 1) {
          resolvedClassId = candidates.single.classId;
        } else if (candidates.length > 1) {
          // Ambiguïté RAW réelle (sort présent sur la liste de PLUSIEURS
          // classes préparantes du personnage, ex. Clerc/Druide partageant
          // un sort) : RAW laisserait le joueur choisir de quelle classe il
          // le prépare, notre UI ne propose pas ce choix — attribution par
          // défaut à celle qui a encore de la place, documentée pour la
          // revue RAW ; si aucune n'en a, à la première de la liste (le
          // rejet qui suit nommera alors cette classe).
          ({Object classId, String className, int level})? withRoom;
          for (final c in candidates) {
            final count = countsByClassId[c.classId.toString()] ?? 0;
            if (count < limitOf(c)) {
              withRoom = c;
              break;
            }
          }
          resolvedClassId = (withRoom ?? candidates.first).classId;
        }
        // `candidates.isEmpty` : origine réellement inconnue (ne devrait pas
        // arriver pour un sort proposé par l'UI) — `resolvedClassId` reste
        // `null`, fail-open (voir la doc de classe).
      }
    }

    if (resolvedClassId == null) return null;
    final target = preparingClasses.firstWhere(
      (c) => c.classId.toString() == resolvedClassId.toString(),
    );
    final limit = limitOf(target);
    final currentCount = countsByClassId[target.classId.toString()] ?? 0;
    if (currentCount >= limit) {
      throw CharacterFailure(
        'Limite de sorts préparés atteinte pour ${target.className} '
        '($currentCount/$limit) : ne plus préparer un sort de cette classe '
        "avant d'en préparer un nouveau.",
      );
    }
    return resolvedClassId;
  }

  /// `{classId.toString(): count}` — sorts de niveau >= 1 au statut
  /// 'préparé' de [characterId], groupés par `character_spells
  /// .source_class_id`, restreint à [classIds] (les classes PRÉPARANTES du
  /// personnage, voir [_resolvePreparingClassAndEnforceLimit]). Le niveau du
  /// sort (pour exclure les sorts mineurs — jamais comptés, jamais limités,
  /// voir `PreparedSpellsLimit._countsTowardPreparedLimit`) est embarqué via
  /// la relation `character_spells.spell_id -> spells.id` plutôt qu'une
  /// requête séparée, puis filtré côté Dart (pas via PostgREST, pour rester
  /// indépendant d'une syntaxe de filtre sur colonne embarquée).
  ///
  /// [excludedSpellIds] (D77, `docs/dette-technique.md`) : identifiants de
  /// sorts par ailleurs accordés par une sous-classe (voir l'appelant) —
  /// jamais comptés, même si leur ligne `character_spells` est bien
  /// 'préparé' : exactement l'exclusion déjà appliquée côté affichage
  /// (`CharacterSpellEntry.isAlwaysPrepared`), pour ne jamais rejeter un
  /// sort que l'écran présente pourtant comme encore cochable.
  Future<Map<String, int>> _preparedSpellCountsByClass({
    required String characterId,
    required List<Object> classIds,
    Set<int> excludedSpellIds = const {},
  }) async {
    if (classIds.isEmpty) return const {};
    final rows = await _client
        .from('character_spells')
        .select('spell_id, source_class_id, spells(level)')
        .eq('character_id', characterId)
        .eq('status', SpellStatus.prepared.value)
        .inFilter('source_class_id', classIds);
    final counts = <String, int>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      if (spellId is num && excludedSpellIds.contains(spellId.toInt())) {
        continue;
      }
      final sourceClassId = row['source_class_id'];
      if (sourceClassId == null) continue;
      final spellRelation = row['spells'];
      final level = spellRelation is Map ? spellRelation['level'] : null;
      if (level is! num || level <= 0) continue;
      final key = sourceClassId.toString();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
  }) async {
    final ownerId = _requireOwnerId();
    final targetId = spellId.toString();

    // D11 : mise en file réelle, même principe que [castSpell].
    if (!await _connectivityChecker.hasConnection()) {
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.innateSpell,
        targetId: targetId,
        payload: {'spellId': spellId, 'usesSpent': usesSpent},
      );
      return WriteOutcome.queued;
    }

    try {
      await _pendingWrites.runExclusive(
        characterId: characterId,
        kind: PendingCharacterWriteKind.innateSpell,
        targetId: targetId,
        action: () async {
          final characterRow = await _client
              .from('characters')
              .select('id')
              .eq('id', characterId)
              .eq('owner_id', ownerId)
              .maybeSingle();
          if (characterRow == null) {
            throw const CharacterFailure('Personnage introuvable.');
          }

          final supersededWrite = await _pendingWriteBeforeOnlineWrite(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.innateSpell,
            targetId: targetId,
          );
          await _client
              .from('character_spells')
              .update({'innate_uses_spent': usesSpent})
              .eq('character_id', characterId)
              .eq('spell_id', spellId)
              // Jamais une ligne ordinaire du même sort (lignes en double
              // possibles) : seul un sort inné porte un compteur d'usage.
              .eq('status', SpellStatus.innate.value);
          await _recordConfirmedWrite(
            characterId: characterId,
            ownerId: ownerId,
            columns: null,
            supersededWrite: supersededWrite,
          );
        },
      );
      return WriteOutcome.synced;
    } on TimeoutException {
      // Dette D12 : même rationale que [updateHp].
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.innateSpell,
        targetId: targetId,
        payload: {'spellId': spellId, 'usesSpent': usesSpent},
      );
      return WriteOutcome.queued;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : même rationale que [updateHp].
      reportNonFatal(error, stackTrace);
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
    final targetId = classFeatureId.toString();

    // D11 : mise en file réelle, même principe que [castSpell].
    if (!await _connectivityChecker.hasConnection()) {
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: targetId,
        payload: {
          'classFeatureId': classFeatureId,
          'usesRemaining': usesRemaining,
        },
      );
      return WriteOutcome.queued;
    }

    try {
      await _pendingWrites.runExclusive(
        characterId: characterId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: targetId,
        action: () async {
          final characterRow = await _client
              .from('characters')
              .select('id')
              .eq('id', characterId)
              .eq('owner_id', ownerId)
              .maybeSingle();
          if (characterRow == null) {
            throw const CharacterFailure('Personnage introuvable.');
          }

          final supersededWrite = await _pendingWriteBeforeOnlineWrite(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.classFeature,
            targetId: targetId,
          );
          await _client.from('character_feature_uses').upsert({
            'character_id': characterId,
            'class_feature_id': classFeatureId,
            'uses_remaining': usesRemaining,
          }, onConflict: 'character_id,class_feature_id');
          await _recordConfirmedWrite(
            characterId: characterId,
            ownerId: ownerId,
            columns: null,
            supersededWrite: supersededWrite,
          );
        },
      );
      return WriteOutcome.synced;
    } on TimeoutException {
      // Dette D12 : même rationale que [updateHp].
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: targetId,
        payload: {
          'classFeatureId': classFeatureId,
          'usesRemaining': usesRemaining,
        },
      );
      return WriteOutcome.queued;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : même rationale que [updateHp].
      reportNonFatal(error, stackTrace);
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
          .update({'equipped': equipped, if (!equipped) 'weapon_slot': null})
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
  Future<WriteOutcome> equipWeaponToSlot({
    required String characterId,
    required String inventoryId,
    required WeaponSlot slot,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('character_inventory')
          .update({'equipped': true, 'weapon_slot': slot.value})
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
  Future<WriteOutcome> setInventoryItemAttuned({
    required String characterId,
    required String inventoryId,
    required bool attuned,
  }) async {
    _requireOwnerId();
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('character_inventory')
          .update({'is_attuned': attuned})
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
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : écriture monétaire, un bug
      // silencieux ici pourrait désynchroniser durablement la bourse
      // affichée de la valeur serveur réelle.
      reportNonFatal(error, stackTrace);
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
          .select('id, category, weight, cost, weapon_properties(properties)')
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

      // `'amelioration_caracteristiques'` (ASI, niveaux 4/8/12/16/19) est
      // traité comme une aptitude automatique, pas une ligne de choix : ce
      // niveau ne déclenche déjà le flux ASI-ou-don qu'au travers de
      // `LevelUpBlockRules.abilityScoreImprovementLevels` (codé en dur, même
      // rationale que l'exclusion de `'invocation'` dans
      // `LevelUpPendingChoiceResolver.resolve`) — sans cette exclusion, cette
      // ligne devient `choiceRow` et bloque tout le flux via
      // `LevelUpBlockRules.evaluate` (`choice_type` non nul et absent de
      // `resolvedChoiceTypes`).
      final choiceRow = featureRows.firstWhere(
        (row) =>
            row['choice_type'] != null &&
            row['choice_type'] != 'amelioration_caracteristiques',
        orElse: () => const <String, dynamic>{},
      );
      final automaticRows = [
        for (final row in featureRows)
          if (row['choice_type'] == null ||
              row['choice_type'] == 'amelioration_caracteristiques')
            row,
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
              // Ni description ni utilisation à afficher ici (pas la carte
              // "Aptitudes de classe" de l'onglet Compétences, juste le
              // récapitulatif de montée de niveau) : maps vides, jamais
              // consommées puisque ces aptitudes viennent d'être obtenues.
              descriptions: const {},
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
  Future<List<LevelUpFeatOption>> fetchAvailableFeats({
    required String characterId,
  }) async {
    try {
      final ownedRows = await _client
          .from('character_feats')
          .select('feat_id')
          .eq('character_id', characterId);
      final ownedIds = {
        for (final row in ownedRows) (row['feat_id'] as num).toInt(),
      };

      final allRows = await _client
          .from('feats')
          .select('id, prerequisites, ability_increase');
      final availableRows = [
        for (final row in allRows)
          if (!ownedIds.contains((row['id'] as num).toInt())) row,
      ];

      final ids = LevelUpFeatRowMapper.collectFeatIds(availableRows);
      final names = await _fetchTranslatedNames(
        entityType: 'feat',
        entityIds: ids,
      );
      final descriptions = await _fetchTranslatedField(
        entityType: 'feat',
        fieldName: 'description',
        entityIds: ids,
      );

      return LevelUpFeatRowMapper.toFeatOptions(
        availableRows,
        names: names,
        descriptions: descriptions,
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<List<LevelUpInvocationOption>> fetchAvailableInvocations({
    required String characterId,
  }) async {
    try {
      final ownedRows = await _client
          .from('character_invocations')
          .select('invocation_id')
          .eq('character_id', characterId);
      final ownedIds = {
        for (final row in ownedRows) (row['invocation_id'] as num).toInt(),
      };

      final allRows = await _client
          .from('invocations')
          .select('id, prerequisites');
      final availableRows = [
        for (final row in allRows)
          if (!ownedIds.contains((row['id'] as num).toInt())) row,
      ];

      final ids = LevelUpInvocationRowMapper.collectInvocationIds(
        availableRows,
      );
      final names = await _fetchTranslatedNames(
        entityType: 'invocation',
        entityIds: ids,
      );
      final descriptions = await _fetchTranslatedField(
        entityType: 'invocation',
        fieldName: 'description',
        entityIds: ids,
      );

      final cantripNames = await _fetchTranslatedNames(
        entityType: 'spell',
        entityIds: LevelUpInvocationRowMapper.collectCantripSpellIds(
          availableRows,
        ),
      );

      return LevelUpInvocationRowMapper.toInvocationOptions(
        availableRows,
        names: names,
        descriptions: descriptions,
        cantripNames: cantripNames,
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<List<LevelUpElementalDisciplineOption>>
  fetchAvailableElementalDisciplines({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async {
    try {
      // Ligne `class_features` de ce `choice_type` — une seule dans TOUTE
      // la base (`'discipline_elementaire'` est globalement unique, confirmé
      // par `regles-dnd`), repérée SANS filtre `class_id`/`subclass_id` (voir
      // la documentation de [fetchAvailableElementalDisciplines] :
      // `class_features.class_id` est NULL sur cette ligne de sous-classe, un
      // filtre `.eq('class_id', classId)` ne la retrouve structurellement
      // jamais — régression corrigée, voir D85 du registre de dette
      // technique, `docs/dette-technique.md`). Réutilisée pour CHAQUE palier
      // (voir la documentation de [applyLevelUp]), jamais filtrée par
      // niveau. `null` si introuvable (défensif : ne devrait pas arriver,
      // cette méthode n'est appelée que pour une classe/sous-classe qui
      // déclenche effectivement cette étape) — dans ce cas, aucune
      // discipline n'est jamais considérée "déjà connue" (le filtre
      // ci-dessous reste vide).
      final disciplineFeatureRows = await _client
          .from('class_features')
          .select('id')
          .eq('choice_type', 'discipline_elementaire')
          .limit(1);

      final knownNames = <String>{};
      if (disciplineFeatureRows.isNotEmpty) {
        final disciplineFeatureId = (disciplineFeatureRows.first['id'] as num)
            .toInt();
        final knownRows = await _client
            .from('character_class_options')
            .select('chosen_value')
            .eq('character_id', characterId)
            .eq('class_feature_id', disciplineFeatureId);
        knownNames.addAll([
          for (final row in knownRows)
            if (row['chosen_value'] is String) row['chosen_value'] as String,
        ]);
      }

      final allRows = await _client
          .from('class_options')
          .select('id, min_level')
          .eq('subclass_id', subclassId)
          .eq('option_type', 'discipline_elementaire')
          .lte('min_level', targetLevel);

      final ids = LevelUpElementalDisciplineRowMapper.collectIds(allRows);
      final names = await _fetchTranslatedNames(
        entityType: 'class_option',
        entityIds: ids,
      );
      final descriptions = await _fetchTranslatedField(
        entityType: 'class_option',
        fieldName: 'description',
        entityIds: ids,
      );

      final availableRows = [
        for (final row in allRows)
          if (!knownNames.contains(names[row['id'].toString()])) row,
      ];

      return LevelUpElementalDisciplineRowMapper.toOptions(
        availableRows,
        names: names,
        descriptions: descriptions,
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<List<LevelUpManeuverOption>> fetchAvailableManeuvers({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async {
    try {
      // Ligne `class_features` de ce `choice_type` — une seule dans TOUTE
      // la base (`'manoeuvre'` est globalement unique, confirmé par
      // `regles-dnd`), repérée SANS filtre `class_id`/`subclass_id` (voir la
      // documentation de [CharacterRepository.fetchAvailableManeuvers] :
      // contrairement à [fetchAvailableElementalDisciplines],
      // `class_features.class_id` est NULL sur cette ligne de sous-classe,
      // un filtre `.eq('class_id', classId)` ne la retrouverait jamais).
      // `null` si introuvable (défensif) — dans ce cas, aucune manœuvre
      // n'est jamais considérée "déjà connue" (le filtre ci-dessous reste
      // vide).
      final maneuverFeatureRows = await _client
          .from('class_features')
          .select('id')
          .eq('choice_type', 'manoeuvre')
          .limit(1);

      final knownNames = <String>{};
      if (maneuverFeatureRows.isNotEmpty) {
        final maneuverFeatureId = (maneuverFeatureRows.first['id'] as num)
            .toInt();
        final knownRows = await _client
            .from('character_class_options')
            .select('chosen_value')
            .eq('character_id', characterId)
            .eq('class_feature_id', maneuverFeatureId);
        knownNames.addAll([
          for (final row in knownRows)
            if (row['chosen_value'] is String) row['chosen_value'] as String,
        ]);
      }

      final allRows = await _client
          .from('class_options')
          .select('id, min_level')
          .eq('subclass_id', subclassId)
          .eq('option_type', 'manoeuvre')
          .lte('min_level', targetLevel);

      final ids = LevelUpManeuverRowMapper.collectIds(allRows);
      final names = await _fetchTranslatedNames(
        entityType: 'class_option',
        entityIds: ids,
      );
      final descriptions = await _fetchTranslatedField(
        entityType: 'class_option',
        fieldName: 'description',
        entityIds: ids,
      );

      final availableRows = [
        for (final row in allRows)
          if (!knownNames.contains(names[row['id'].toString()])) row,
      ];

      return LevelUpManeuverRowMapper.toOptions(
        availableRows,
        names: names,
        descriptions: descriptions,
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required Object classId,
    required String className,
    required bool isMulticlassing,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
    List<int> initialSpellIds = const [],
    List<int> invocationIds = const [],
    List<String> elementalDisciplineNames = const [],
    List<String> maneuverNames = const [],
    List<int> racialInnateSpellIds = const [],
  }) async {
    final ownerId = _requireOwnerId();
    try {
      // D35 du registre de dette technique — voir la documentation de
      // [_blockIfPendingHpOrXpWrites] : avant toute lecture/écriture,
      // synchronise puis bloque si un ajustement PV/XP hors ligne reste en
      // attente pour ce personnage (cette méthode relit `current_hp`/
      // `max_hp` depuis le serveur plus bas, et ne doit jamais partir d'une
      // valeur périmée).
      await _blockIfPendingHpOrXpWrites(
        ownerId: ownerId,
        characterId: characterId,
      );

      final classRows = await _client
          .from('character_classes')
          .select('id, class_id, level')
          .eq('character_id', characterId);
      if (classRows.isEmpty) {
        throw const CharacterFailure(
          'Aucune classe trouvée pour ce personnage : impossible de monter '
          'de niveau.',
        );
      }

      final targetClassIdInt = _classIdAsInt(classId);
      Map<String, dynamic>? existingTargetRow;
      for (final row in classRows) {
        if (_classIdAsInt(row['class_id'] as Object) == targetClassIdInt) {
          existingTargetRow = row;
          break;
        }
      }

      if (isMulticlassing) {
        if (existingTargetRow != null) {
          throw const CharacterFailure(
            'Ce personnage possède déjà cette classe : impossible de la '
            'multiclasser à nouveau.',
          );
        }
        // Défense en profondeur : revérifie les prérequis RAW pour la
        // nouvelle classe ET pour toutes les classes déjà possédées (voir la
        // documentation de [CharacterRepository.applyLevelUp]) — l'UI filtre
        // déjà ces options en amont (`multiclassOptions`,
        // `presentation/providers/level_up_provider.dart`), mais cette
        // méthode ne doit jamais faire confiance uniquement à l'UI pour une
        // écriture, même discipline que le plafond ASI à 20
        // ([_applyAbilityScoreImprovement]).
        final abilityScores = await _fetchAllAbilityScores(characterId);
        if (!MulticlassPrerequisites.meetsRequirement(
          className,
          abilityScores,
        )) {
          throw CharacterFailure(
            "Prérequis de caractéristique non rempli pour '$className' : "
            'multiclassage refusé.',
          );
        }
        final existingClassIds = {
          for (final row in classRows) row['class_id'] as Object,
        };
        final existingClassNames = await _fetchTranslatedNames(
          entityType: 'class',
          entityIds: {for (final id in existingClassIds) id.toString()},
        );
        for (final row in classRows) {
          final existingName =
              existingClassNames[(row['class_id'] as Object).toString()];
          if (existingName == null) {
            // Ne devrait pas arriver (chaque classe possédée a une
            // traduction résolue), mais fail-closed comme partout ailleurs
            // dans cette méthode : impossible de revérifier le prérequis
            // d'une classe déjà possédée sans son nom, donc on refuse le
            // multiclassage par prudence plutôt que de le laisser passer
            // silencieusement sans avoir revérifié son prérequis.
            throw const CharacterFailure(
              "Impossible de vérifier les prérequis d'une classe déjà "
              'possédée : multiclassage refusé par prudence.',
            );
          }
          if (!MulticlassPrerequisites.meetsRequirement(
            existingName,
            abilityScores,
          )) {
            throw CharacterFailure(
              "Prérequis de caractéristique non rempli pour la classe déjà "
              "possédée '$existingName' : multiclassage refusé.",
            );
          }
        }
      } else if (existingTargetRow == null) {
        throw const CharacterFailure(
          'Classe introuvable pour ce personnage : impossible de monter de '
          'niveau.',
        );
      }

      final beforeClassLevel = existingTargetRow == null
          ? 0
          : (existingTargetRow['level'] as num).toInt();
      final newClassLevel = beforeClassLevel + 1;

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
      // 2. `character_classes` (`UPDATE` du niveau si on continue, `INSERT`
      //    d'une nouvelle ligne si on multiclasse) : le choix `subclass_id`
      //    est combiné dans cette même écriture quand [choice] est une
      //    sous-classe, plutôt qu'un appel séparé — même écriture, même
      //    niveau de risque, une requête de moins.
      // 3. `character_spell_slots` (voir [_upsertSpellSlots]), placé ici
      //    plutôt qu'après le choix : ce recalcul ne dépend que des classes/
      //    niveaux déjà écrits à l'étape 2, jamais de [choice], donc rien ne
      //    justifie de le faire attendre derrière un choix optionnel. Même
      //    donnée de jeu vivante que le choix ci-dessous (pas un pur
      //    historique) : un échec à cette étape doit laisser le niveau déjà
      //    incrémenté (visible, corrigible), même rationale que 4.
      // 4. Le choix restant (ASI ou `character_class_options`) et les sorts
      //    de départ d'une nouvelle classe à sorts connus, s'il y en a —
      //    placés ici (juste après le niveau, avant l'historique PV) car ce
      //    sont des données de jeu vivantes au moins aussi significatives
      //    que le niveau lui-même (contrairement à `character_level_hp`, pur
      //    historique) : mieux vaut qu'un échec à cette étape laisse le
      //    niveau déjà incrémenté (visible, corrigible) plutôt que de la
      //    reporter après l'historique, qui doit rester la toute dernière
      //    écriture (voir 5.).
      // 5. `character_level_hp`, purement un historique, toujours en
      //    dernier. Contrairement à `createCharacter`, aucun nettoyage
      //    ("best effort") n'est possible ici : il n'y a pas de ligne
      //    fraîchement créée à supprimer, seulement des colonnes déjà
      //    existantes mises à jour (ou une nouvelle ligne `character_classes`
      //    déjà insérée, cas multiclassage).
      await _client
          .from('characters')
          .update({'max_hp': newMaxHp, 'current_hp': newCurrentHp})
          .eq('id', characterId)
          .eq('owner_id', ownerId);

      if (isMulticlassing) {
        final insertPayload = <String, dynamic>{
          'character_id': characterId,
          'class_id': classId,
          'level': 1,
          'is_primary': false,
          'hit_dice_spent': 0,
        };
        if (choice != null && choice.kind == LevelUpChoiceKind.subclass) {
          insertPayload['subclass_id'] = choice.subclassId;
        }
        await _client.from('character_classes').insert(insertPayload);
      } else {
        final classUpdate = <String, dynamic>{'level': newClassLevel};
        if (choice != null && choice.kind == LevelUpChoiceKind.subclass) {
          classUpdate['subclass_id'] = choice.subclassId;
        }
        await _client
            .from('character_classes')
            .update(classUpdate)
            .eq('id', existingTargetRow!['id']);
      }

      // Classes du personnage avant/après ce niveau, toutes classes
      // confondues — nécessaire au calcul combiné multiclasse des
      // emplacements de sorts (voir [_upsertSpellSlots]). Les noms des
      // classes déjà possédées ont déjà été résolus ci-dessus dans la
      // branche multiclassage ; sinon (branche "continuer"), il faut encore
      // les résoudre ici pour les éventuelles AUTRES classes du personnage
      // (multiclassage antérieur).
      final coClassIds = {
        for (final row in classRows)
          if (_classIdAsInt(row['class_id'] as Object) != targetClassIdInt)
            row['class_id'] as Object,
      };
      final coClassNames = await _fetchTranslatedNames(
        entityType: 'class',
        entityIds: {for (final id in coClassIds) id.toString()},
      );
      final beforeClasses = [
        for (final row in classRows)
          (
            className:
                _classIdAsInt(row['class_id'] as Object) == targetClassIdInt
                ? className
                : (coClassNames[(row['class_id'] as Object).toString()] ?? ''),
            level: (row['level'] as num).toInt(),
          ),
      ];
      final afterClasses = isMulticlassing
          ? [...beforeClasses, (className: className, level: 1)]
          : [
              for (final entry in beforeClasses)
                entry.className == className
                    ? (className: className, level: newClassLevel)
                    : entry,
            ];

      await _upsertSpellSlots(
        characterId: characterId,
        afterClasses: afterClasses,
      );
      await _upsertPactSlot(
        characterId: characterId,
        afterClasses: afterClasses,
      );

      final newTotalLevel = afterClasses.fold(
        0,
        (sum, entry) => sum + entry.level,
      );

      var finalMaxHp = newMaxHp;
      var finalCurrentHp = newCurrentHp;
      if (choice != null) {
        // PV rétroactifs du choix (Constitution augmentée, don Robuste),
        // voir `domain/hit_point_bonus_rules.dart`.
        final retroactiveHp = await _applyChoice(
          characterId: characterId,
          level: newClassLevel,
          totalLevel: newTotalLevel,
          choice: choice,
        );
        if (retroactiveHp != 0) {
          finalMaxHp += retroactiveHp;
          finalCurrentHp += retroactiveHp;
          await _client
              .from('characters')
              .update({'max_hp': finalMaxHp, 'current_hp': finalCurrentHp})
              .eq('id', characterId)
              .eq('owner_id', ownerId);
        }
      }

      if (initialSpellIds.isNotEmpty) {
        // Sorts de départ d'une nouvelle classe "à sorts connus" démarrée au
        // niveau 1 (Barde/Ensorceleur/Occultiste/Rôdeur) — même forme de
        // ligne (`character_spells`, `source_class_id`) que
        // `CharacterCreationRepository.createCharacter` pour les sorts
        // initiaux à la création (voir la documentation de
        // [CharacterRepository.applyLevelUp]) : réutilise la même règle de
        // statut (`SpellcastingRules.statusFor`), sans dupliquer de logique
        // de quotas ici (déjà appliquée côté écran avant d'arriver jusqu'à
        // cette méthode).
        //
        // Revérifiés contre les lignes ORDINAIRES déjà existantes (classe
        // actuelle, autre classe multiclassée...) juste avant l'écriture —
        // même discipline que le bloc [racialInnateSpellIds] plus bas : un
        // multiclassage vers une classe dont la liste de sorts initiaux
        // recoupe un sort déjà connu via sa route ORDINAIRE (ex. "Soins",
        // présent sur plusieurs listes) ne doit jamais tenter de réécrire ce
        // sort (ce qui violerait l'index unique partiel sur
        // `character_spells`, voir dette D10) ; il est ignoré silencieusement
        // et garde son statut/sa classe source d'origine.
        //
        // Jamais filtré contre une ligne 'inné' existante (voir la doc de
        // [initialSpellIds] ci-dessus, D43) : un sort déjà connu UNIQUEMENT
        // via sa route innée garde malgré tout le droit à sa ligne ORDINAIRE
        // séparée — sans conflit avec l'index unique partiel, les deux
        // lignes étant de statuts différents.
        final alreadyOrdinarySpellIds = await _fetchAlreadyOrdinarySpellIds(
          characterId,
        );
        final newInitialSpellIds = {
          for (final spellId in initialSpellIds)
            if (!alreadyOrdinarySpellIds.contains(spellId)) spellId,
        };
        if (newInitialSpellIds.isNotEmpty) {
          final status = SpellcastingRules.statusFor(className).value;
          await _client.from('character_spells').insert([
            for (final spellId in newInitialSpellIds)
              {
                'character_id': characterId,
                'spell_id': spellId,
                'status': status,
                'source_class_id': classId,
              },
          ]);
        }
      }

      if (invocationIds.isNotEmpty) {
        // Invocations occultistes nouvellement choisies (étape
        // "Invocations", voir la documentation de
        // [CharacterRepository.applyLevelUp]) — quota déjà appliqué côté
        // écran (quota effectif, voir `domain/invocations_known_progression.dart`),
        // cette méthode se contente d'écrire les identifiants reçus.
        await _client.from('character_invocations').insert([
          for (final invocationId in invocationIds)
            {'character_id': characterId, 'invocation_id': invocationId},
        ]);
      }

      if (elementalDisciplineNames.isNotEmpty) {
        // Disciplines élémentaires nouvellement choisies (étape
        // "Disciplines élémentaires", Moine/Voie des quatre éléments, voir
        // la documentation de [CharacterRepository.applyLevelUp]) — quota
        // déjà appliqué côté écran (même discipline que [invocationIds]
        // ci-dessus), cette méthode se contente de résoudre le
        // `class_feature_id` et d'écrire les `chosen_value` reçus.
        //
        // Repérée via `choice_type = 'discipline_elementaire'` SEUL (ce
        // `choice_type` est globalement unique dans toute la base, confirmé
        // par `regles-dnd`), jamais via `.eq('class_id', classId)` —
        // `class_features.class_id` est NULL sur cette ligne de sous-classe,
        // un tel filtre ne la retrouve structurellement jamais (régression
        // corrigée, voir D85 du registre de dette technique,
        // `docs/dette-technique.md`, et la documentation de
        // [fetchAvailableElementalDisciplines]). Une seule ligne
        // `class_features` de ce `choice_type` existe en base à ce jour
        // (voir `domain/level_up_block_reason.dart`) — réutilisée pour
        // CHAQUE palier (3/6/11/17), jamais une par palier : contrairement à
        // `fetchLevelUpLevelData` (scopé au niveau ciblé), cette recherche
        // n'est PAS filtrée par niveau.
        final disciplineFeatureRows = await _client
            .from('class_features')
            .select('id')
            .eq('choice_type', 'discipline_elementaire')
            .limit(1);
        if (disciplineFeatureRows.isEmpty) {
          throw const CharacterFailure(
            'Discipline élémentaire : aptitude de classe introuvable pour '
            'cette classe.',
          );
        }
        final disciplineFeatureId = (disciplineFeatureRows.first['id'] as num)
            .toInt();
        await _client.from('character_class_options').insert([
          for (final name in elementalDisciplineNames)
            {
              'character_id': characterId,
              'class_feature_id': disciplineFeatureId,
              'level': newClassLevel,
              'chosen_value': name,
            },
        ]);
      }

      if (maneuverNames.isNotEmpty) {
        // Manœuvres nouvellement choisies (étape "Manœuvres", Guerrier
        // Maître de guerre, voir la documentation de
        // [CharacterRepository.applyLevelUp]) — quota déjà appliqué côté
        // écran (même discipline que [invocationIds]/
        // [elementalDisciplineNames] ci-dessus).
        //
        // **Résolution plus prudente que [elementalDisciplineNames]** :
        // repérée SEULE via `choice_type = 'manoeuvre'` (globalement unique
        // dans toute la base, confirmé par `regles-dnd`), jamais via
        // `.eq('class_id', classId)` — `class_features.class_id` est NULL
        // sur cette ligne de sous-classe (voir D85 du registre de dette
        // technique, `docs/dette-technique.md`, et la documentation de
        // [fetchAvailableManeuvers]). Une seule ligne existe en base à ce
        // jour (niveau 3 uniquement) — réutilisée pour CHAQUE palier
        // (3/7/10/15), jamais une par palier, même convention que
        // [elementalDisciplineNames].
        final maneuverFeatureRows = await _client
            .from('class_features')
            .select('id')
            .eq('choice_type', 'manoeuvre')
            .limit(1);
        if (maneuverFeatureRows.isEmpty) {
          throw const CharacterFailure(
            'Manœuvre : aptitude de classe introuvable.',
          );
        }
        final maneuverFeatureId = (maneuverFeatureRows.first['id'] as num)
            .toInt();
        await _client.from('character_class_options').insert([
          for (final name in maneuverNames)
            {
              'character_id': characterId,
              'class_feature_id': maneuverFeatureId,
              'level': newClassLevel,
              'chosen_value': name,
            },
        ]);
      }

      if (racialInnateSpellIds.isNotEmpty) {
        // Sorts innés raciaux devenus accessibles à ce nouveau niveau TOTAL
        // (voir la documentation de [CharacterRepository.applyLevelUp]) —
        // revérifiés contre les lignes 'inné' DÉJÀ EXISTANTES juste avant
        // l'écriture (jamais de confiance aveugle dans la lecture de
        // l'appelant, même discipline que [_applyAbilityScoreImprovement]) :
        // une ligne 'inné' déjà écrite à un niveau antérieur n'est jamais
        // réécrite (violerait l'index unique partiel dédié, D10).
        //
        // Jamais filtré contre `_fetchKnownSpellIds` (toute route confondue)
        // : décision de Matthias du 10/10/2026, cohérente avec D43 — un sort
        // déjà connu par sa seule route ORDINAIRE (classe) garde malgré tout
        // le droit à sa ligne 'inné' séparée, les deux routes RAW étant
        // indépendantes (voir la doc de [racialInnateSpellIds] ci-dessus).
        // Avant cette décision, filtrer ici aussi (en plus du filtre déjà
        // retiré côté `level_up_provider.dart`) aurait rendu ce correctif
        // sans effet : la ligne 'inné' aurait quand même été silencieusement
        // abandonnée à l'écriture.
        final alreadyInnateSpellIds = await _fetchAlreadyInnateSpellIds(
          characterId,
        );
        final newRacialSpellIds = {
          for (final spellId in racialInnateSpellIds)
            if (!alreadyInnateSpellIds.contains(spellId)) spellId,
        };
        if (newRacialSpellIds.isNotEmpty) {
          await _client.from('character_spells').insert([
            for (final spellId in newRacialSpellIds)
              {
                'character_id': characterId,
                'spell_id': spellId,
                'status': SpellStatus.innate.value,
                'source_class_id': null,
              },
          ]);
        }
      }

      await _client.from('character_level_hp').insert({
        'character_id': characterId,
        'level': newTotalLevel,
        'hp_rolled': hpRolled,
        'method': hpMethod,
      });

      return LevelUpApplyResult(
        newLevel: newTotalLevel,
        newMaxHp: finalMaxHp,
        newCurrentHp: finalCurrentHp,
      );
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : montée de niveau, écriture
      // multi-tables sans vraie transaction — un bug silencieux ici
      // pourrait laisser le personnage dans un état de niveau partiellement
      // appliqué sans jamais être signalé.
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
  }) async {
    final ownerId = _requireOwnerId();

    // D11 du registre de dette technique (09/10/2026) : mise en file réelle
    // si hors ligne — voir la documentation de
    // [CharacterRepository.applyRest]. Contrairement à [castSpell]/
    // [setInnateSpellUsesSpent]/[useClassFeature] (qui vérifient toujours
    // l'appartenance du personnage même hors ligne avant... non, en fait eux
    // non plus : ce cas retourne directement [WriteOutcome.queued] sans
    // tenter aucune lecture/écriture serveur, y compris le garde-fou D35 de
    // [applyRestOnline] (qui ferait un aller-retour réseau best-effort pour
    // rien tant qu'il n'y a aucune connectivité).
    if (!await _connectivityChecker.hasConnection()) {
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        payload: {
          'type': type.name,
          'className': className,
          'hitDiceSpentByClassId': hitDiceSpentByClassId,
          'appliedGain': appliedGain,
          'hitDiceRecoveredByClassId': hitDiceRecoveredByClassId,
        },
      );
      return WriteOutcome.queued;
    }

    // Verrouillé (D33) : même rationale que `updateHp`, cette fois contre une
    // synchronisation différée du MÊME repos mis en file (voir
    // `PendingCharacterWriteSyncer.sync`, qui appelle [applyRestOnline] sous
    // le même verrou `(characterId, rest, '')`).
    try {
      await _pendingWrites.runExclusive(
        characterId: characterId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        action: () async {
          // Relevé AVANT l'écriture en ligne (même principe que `updateHp`) :
          // un repos resté en file depuis une tentative hors ligne
          // précédente, pas encore synchronisée, est désormais périmé par ce
          // nouveau repos EN LIGNE qui vient de (re)calculer l'état correct
          // depuis des lectures serveur fraîches — le laisser serait rejoué
          // par erreur à la prochaine synchro et appliquerait un second
          // repos non désiré par-dessus celui-ci.
          final supersededWrite = await _pendingWriteBeforeOnlineWrite(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.rest,
            targetId: '',
          );
          await applyRestOnline(
            ownerId: ownerId,
            characterId: characterId,
            type: type,
            className: className,
            hitDiceSpentByClassId: hitDiceSpentByClassId,
            appliedGain: appliedGain,
            hitDiceRecoveredByClassId: hitDiceRecoveredByClassId,
          );
          // `columns: null` : un repos touche de nombreuses tables, jamais
          // réductible aux colonnes `characters` que
          // [CharacterDetailCache.applyConfirmedColumns] sait patcher — voir
          // la documentation de [_recordConfirmedWrite].
          await _recordConfirmedWrite(
            characterId: characterId,
            ownerId: ownerId,
            columns: null,
            supersededWrite: supersededWrite,
          );
        },
      );
      return WriteOutcome.synced;
    } on TimeoutException {
      // Dette D12 : même rationale que [updateHp] — connectivité déclarée
      // active, mais la requête n'a jamais abouti dans le délai global.
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        payload: {
          'type': type.name,
          'className': className,
          'hitDiceSpentByClassId': hitDiceSpentByClassId,
          'appliedGain': appliedGain,
          'hitDiceRecoveredByClassId': hitDiceRecoveredByClassId,
        },
      );
      return WriteOutcome.queued;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : repos, écriture multi-étapes
      // sans vraie transaction — même rationale que [applyLevelUp].
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterError();
    }
  }

  /// Exécute la logique complète d'un repos **déjà en ligne** — ancien corps
  /// intégral d'[applyRest] avant D11, extrait dans sa propre méthode pour
  /// être rejouable à l'identique par [PendingCharacterWriteSyncer] quand un
  /// repos mis en file (hors ligne) est enfin synchronisé, sans dupliquer
  /// cette logique à deux endroits (un repos touche trop de tables pour que
  /// la dupliquer soit raisonnable, contrairement aux quelques lignes de
  /// `castSpell`/`setInnateSpellUsesSpent`/`useClassFeature` que
  /// `PendingCharacterWriteSyncer` réimplémente directement).
  ///
  /// Méthode volontairement PUBLIQUE (pas de préfixe `_`) bien que jamais
  /// destinée à un écran : `PendingCharacterWriteSyncer` vit dans un autre
  /// fichier (`pending_character_write_syncer.dart`) et ne peut pas appeler
  /// une méthode privée de cette classe. **Un écran ne doit jamais l'appeler
  /// directement** — toujours via [applyRest] (interface
  /// [CharacterRepository]), seule à gérer la vérification de connectivité
  /// et la mise en file (voir sa documentation).
  ///
  /// Ne catch/mappe plus aucune exception elle-même (contrairement à l'ancien
  /// [applyRest] avant son extraction) : [CharacterFailure]/
  /// [PostgrestException]/toute autre erreur remontent telles quelles — ses
  /// deux appelants ([applyRest] ci-dessus, et
  /// `PendingCharacterWriteSyncer.sync`) ont besoin d'inspecter des choses
  /// différentes sur l'erreur brute ([applyRest] la mappe en
  /// [CharacterFailure] pour l'écran ; le synchroniseur inspecte le `code`
  /// brut d'une [PostgrestException] pour la classification D34) — un seul
  /// mapping ici aurait cassé l'un des deux usages.
  Future<void> applyRestOnline({
    required String ownerId,
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
  }) async {
    // D35 du registre de dette technique — voir la documentation de
    // [_blockIfPendingHpOrXpWrites], appelée en tout premier (avant même
    // la vérification d'appartenance ci-dessous) UNIQUEMENT quand cette
    // méthode va effectivement relire/réécrire `current_hp` plus bas : un
    // repos long (toujours), ou un repos court avec [appliedGain] > 0
    // (seule condition qui déclenche la relecture/écriture de
    // `current_hp`/`max_hp` plus bas, voir le bloc `if (appliedGain > 0)`
    // ci-dessous — un repos court avec seulement [hitDiceSpentByClassId] non
    // vide écrit `hit_dice_spent` mais jamais `current_hp`, par exemple
    // quand les PV sont déjà au maximum). Le RAW 5e interdit `appliedGain >
    // 0` sans dé de vie dépensé, donc cette condition ne risque jamais de
    // sous-bloquer un repos court qui touche réellement `current_hp`. Un
    // repos court sans dé de vie dépensé (ou sans PV restauré) ne lit ni
    // n'écrit jamais ces colonnes et n'a donc aucune raison d'être bloqué
    // par un ajustement PV/XP hors ligne encore en attente pour ce
    // personnage.
    if (type == RestType.long || appliedGain > 0) {
      await _blockIfPendingHpOrXpWrites(
        ownerId: ownerId,
        characterId: characterId,
      );
    }

    // Vérification d'appartenance explicite — avant toute écriture, y
    // compris pour un repos court qui ne touche jamais `characters` : sans
    // ce garde-fou, un repos court n'aurait aucune requête filtrée sur
    // `owner_id`, ne reposant que sur la RLS de
    // `character_classes`/`class_features` (lecture seule) pour
    // l'isolation — insuffisant pour l'écriture `character_feature_uses`
    // qui suit. Existence/`owner_id` uniquement à ce stade : `current_hp`/
    // `max_hp` sont relus juste avant chaque écriture de `current_hp` (plus
    // bas), pas ici — voir la note sur la fenêtre de course dans la
    // documentation de [applyRest], pour que les étapes qui n'en dépendent
    // pas (`character_classes`, dés de vie) soient faites en premier.
    final ownerCheck = await _client
        .from('characters')
        .select('id')
        .eq('id', characterId)
        .eq('owner_id', ownerId)
        .maybeSingle();
    if (ownerCheck == null) {
      throw const CharacterFailure('Personnage introuvable.');
    }

    // Toutes les classes du personnage (multiclassage inclus) — utilisées
    // pour retrouver la classe primaire (savoir à quelle ligne s'applique
    // [className]), pour recalculer les emplacements de sorts (niveau de
    // lanceur combiné de *toutes* les classes, voir [_resetSpellSlots]),
    // pour retrouver un éventuel Occultiste (magie de pacte), pour
    // réinitialiser les aptitudes de *toutes* les classes ET de leurs
    // éventuelles sous-classes déjà choisies (voir [_resetFeatureUses] : la
    // lecture de la fiche, `_buildCharacterDetailPayload`/
    // `_mapCharacterDetailPayload`, gère déjà explicitement ce cas, un repos
    // doit suivre la même règle plutôt qu'ignorer silencieusement les
    // classes secondaires ou les sous-classes — `subclass_id` sélectionné
    // ci-dessous pour cette seule raison, [className]/dés de vie ne s'en
    // servent pas), et pour le suivi des dés de vie de *toutes* les classes
    // (dépense/récupération ci-dessous, décision chef de projet du
    // 10/10/2026 — avant elle, seule la classe primaire était lue/écrite,
    // RAW-incorrect dès qu'il y avait une deuxième classe).
    final classRows = await _client
        .from('character_classes')
        .select('id, class_id, subclass_id, level, is_primary, hit_dice_spent')
        .eq('character_id', characterId);

    // Classe primaire : ne sert plus qu'à savoir à quelle ligne s'applique
    // [className] (emplacements de sorts ci-dessous) — le suivi des dés de
    // vie porte maintenant sur *toutes* les lignes de [classRows], voir
    // plus bas. Reste une map vide (jamais `null`) si aucune classe n'est
    // marquée primaire : chaque site d'utilisation ci-dessous garde déjà
    // cette garde (`isNotEmpty`).
    final primaryClassRow = classRows.firstWhere(
      (row) => row['is_primary'] == true,
      orElse: () => const <String, dynamic>{},
    );

    // Noms (français) de toutes les classes du personnage, résolus une
    // seule fois pour les deux usages ci-dessous : emplacements de sorts
    // multiclasses (repos long) et recherche de l'Occultiste (magie de
    // pacte, repos court ET long). Lecture seule, placée avant toute
    // écriture : si elle échoue, le repos échoue sans avoir rien écrit.
    // Aucune requête si le personnage n'a aucune classe.
    final restClassNames = await _fetchTranslatedNames(
      entityType: 'class',
      entityIds: {
        for (final row in classRows) (row['class_id'] as Object).toString(),
      },
    );

    if (type == RestType.long) {
      if (classRows.isNotEmpty) {
        // Même convention que [applyLevelUp] pour construire la liste des
        // classes : [className] (résolu par l'appelant) nomme la classe
        // primaire, les autres classes sont nommées depuis `translations`
        // (chaîne vide si la traduction manque : classe alors traitée
        // comme non lanceuse, jamais une erreur).
        await _resetSpellSlots(
          characterId: characterId,
          classes: [
            for (final row in classRows)
              (
                className: identical(row, primaryClassRow)
                    ? className
                    : (restClassNames[(row['class_id'] as Object).toString()] ??
                          ''),
                level: (row['level'] as num).toInt(),
              ),
          ],
        );
      }

      // Sorts innés de niveau >= 1 (lancés sans emplacement, une fois par
      // repos long — `domain/innate_spell_usage.dart`) : compteur d'usages
      // dépensés remis à 0 au repos LONG uniquement, jamais au repos court.
      // Hors du bloc `classRows.isNotEmpty` : un sort inné vient de la
      // race, pas d'une classe. Filtré sur les seules lignes réellement
      // dépensées.
      //
      // Placé ICI, avant la récupération des dés de vie ci-dessous : cette
      // dernière est RELATIVE (`hit_dice_spent - max(1, level ~/ 2)`), donc
      // non rejouable. Tout ce qui précède cette remise à zéro (emplacements
      // de sorts) et elle-même sont idempotents : si elle échoue, le repos
      // peut être rejoué sans que le joueur récupère deux fois ses dés de
      // vie.
      await _client
          .from('character_spells')
          .update({'innate_uses_spent': 0})
          .eq('character_id', characterId)
          .gt('innate_uses_spent', 0);

      // Récupération RAW 5e des dés de vie, par classe/pool (décision chef
      // de projet du 10/10/2026) : le NOMBRE récupéré (moitié du niveau
      // TOTAL du personnage, au moins 1) et sa répartition entre pools sont
      // déjà entièrement calculés côté appelant
      // (`domain/hit_dice_recovery_calculator.dart`, voir
      // [hitDiceRecoveredByClassId]) — cette méthode ne fait qu'écrire le
      // résultat, jamais une classe primaire seule comme avant ce correctif
      // (RAW-incorrect dès qu'il y avait une deuxième classe : le niveau
      // total était ignoré). Silencieux côté UI si [hitDiceRecoveredByClassId]
      // est vide (personnage sans aucun dé dépensé) — aucune écriture, pour
      // ne pas générer d'`UPDATE` inutile. Faite avant la relecture de
      // `max_hp` ci-dessous (indépendante de `characters`) — même discipline
      // que le repos court : les étapes qui ne dépendent pas de
      // `current_hp`/`max_hp` sont faites en premier, pour minimiser la
      // fenêtre entre la lecture et l'écriture finale de `current_hp`.
      await _applyHitDiceDeltas(
        classRows,
        deltaByClassId: hitDiceRecoveredByClassId,
        nextSpent: (currentSpent, delta, level) =>
            math.max(0, currentSpent - delta),
      );

      // Relecture de `max_hp` juste avant l'écriture de `current_hp` —
      // dernière chose lue avant cette écriture, voir la documentation de
      // [applyRest]. Moins critique que le delta du repos court
      // (`current_hp = max_hp` reste idempotent quel que soit l'ordre
      // d'arrivée d'écritures concurrentes), mais même discipline
      // appliquée par cohérence.
      final characterRow = await _client
          .from('characters')
          .select('max_hp')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();
      if (characterRow == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }
      final maxHp = (characterRow['max_hp'] as num).toInt();

      await _client
          .from('characters')
          .update({
            'current_hp': maxHp,
            'temporary_hp': 0,
            // `characters.last_long_rest_at` (chantier "Notifications" —
            // `docs/cahier-des-charges/15-profil-parametres.md` section 3) :
            // alimente le rappel de repos long côté backend
            // (edge function/table `notification_preferences`, dépôt web).
            // Même requête que `current_hp`/`temporary_hp` ci-dessus, jamais
            // un aller-retour réseau séparé.
            'last_long_rest_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', characterId)
          .eq('owner_id', ownerId);
    } else {
      // Repos court avec dépense de dés de vie (règle RAW 5e) : les dés
      // sont dépensés que le jet restaure ou non des PV (ex. PV déjà au
      // maximum, voir `rest_sheet.dart`) — ces deux écritures sont donc
      // indépendantes l'une de l'autre, et doivent chacune pouvoir
      // s'exécuter sans l'autre : [appliedGain] > 0 ne doit JAMAIS dépendre
      // de [hitDiceSpentByClassId] non vide (correctif code-reviewer —
      // avant lui, un repos mis en file par une version antérieure de
      // l'app, avec l'ancien payload `diceSpent`/`appliedGain` scalaires
      // (sans les clés `hitDiceSpentByClassId`/`hitDiceRecoveredByClassId`),
      // décodait silencieusement [hitDiceSpentByClassId] en map vide — le
      // bloc entier était alors sauté, perdant les PV restaurés par un dé
      // de vie déjà dépensé par le joueur, sans jamais lever d'erreur ni
      // laisser l'entrée rejouable). Le joueur choisit lui-même, pool par
      // pool, combien de dés de CHAQUE classe il dépense (décision chef de
      // projet du 10/10/2026) : cette méthode ne fait qu'écrire le résultat
      // déjà calculé côté appelant, jamais une classe primaire seule comme
      // avant ce correctif.
      if (hitDiceSpentByClassId.isNotEmpty) {
        await _applyHitDiceDeltas(
          classRows,
          deltaByClassId: hitDiceSpentByClassId,
          nextSpent: (currentSpent, delta, level) =>
              math.min(level, currentSpent + delta),
        );
      }

      if (appliedGain > 0) {
        // Relit `current_hp`/`max_hp` ici, juste avant le calcul et
        // l'écriture du delta — dernière chose lue avant cette écriture,
        // après l'étape ci-dessus (dés de vie) qui n'en dépend pas. Ajoute
        // ensuite [appliedGain] à cette valeur *serveur* fraîchement lue
        // (jamais un `UPDATE` en valeur absolue) puis reclampe à `max_hp`
        // par sécurité — voir la documentation de [applyRest] pour la
        // rationale (même principe que [applyLevelUp]).
        final characterRow = await _client
            .from('characters')
            .select('current_hp, max_hp')
            .eq('id', characterId)
            .eq('owner_id', ownerId)
            .maybeSingle();
        if (characterRow == null) {
          throw const CharacterFailure('Personnage introuvable.');
        }
        final currentHp = (characterRow['current_hp'] as num).toInt();
        final maxHp = (characterRow['max_hp'] as num).toInt();
        final newCurrentHp = math.min(currentHp + appliedGain, maxHp);
        await _client
            .from('characters')
            .update({'current_hp': newCurrentHp})
            .eq('id', characterId)
            .eq('owner_id', ownerId);
      }
    }

    // Magie de pacte de l'Occultiste (RAW 5e) : recharge au repos COURT ET
    // long, contrairement aux emplacements classiques ci-dessus (repos long
    // uniquement) — placé ici, en dehors du `if/else` ci-dessus, pour
    // s'exécuter dans les deux cas. L'Occultiste peut être une classe
    // SECONDAIRE (contrairement à [primaryClassRow], qui ne sert plus qu'à
    // nommer la classe primaire pour les emplacements de sorts ci-dessus) :
    // résolue depuis [classRows] (TOUTES les classes) et [restClassNames]
    // (noms déjà résolus plus haut). Circuit indépendant des emplacements
    // classiques :
    // l'Occultiste n'entre jamais dans le niveau de lanceur combiné
    // ([SpellSlotProgression.totalsForClasses] l'ignore), donc ses charges
    // ne sont jamais comptées deux fois.
    if (classRows.isNotEmpty) {
      Map<String, dynamic>? occultisteRow;
      for (final row in classRows) {
        if (restClassNames[(row['class_id'] as Object).toString()] ==
            'Occultiste') {
          occultisteRow = row;
          break;
        }
      }
      if (occultisteRow != null) {
        await _resetPactSlot(
          characterId: characterId,
          occultisteLevel: (occultisteRow['level'] as num).toInt(),
        );
      }
    }

    if (classRows.isNotEmpty) {
      final classIds = <Object>{
        for (final row in classRows) row['class_id'] as Object,
      };
      final classLevels = <String, int>{
        for (final row in classRows)
          (row['class_id'] as Object).toString(): (row['level'] as num).toInt(),
      };
      final subclassIds = <Object>{
        for (final row in classRows)
          if (row['subclass_id'] != null) row['subclass_id'] as Object,
      };
      final subclassLevels = <String, int>{
        for (final row in classRows)
          if (row['subclass_id'] != null)
            (row['subclass_id'] as Object).toString(): (row['level'] as num)
                .toInt(),
      };
      await _resetFeatureUses(
        characterId: characterId,
        classIds: classIds,
        classLevels: classLevels,
        subclassIds: subclassIds,
        subclassLevels: subclassLevels,
        onlyShortRest: type == RestType.short,
      );
    }
  }

  /// Écrit `character_classes.hit_dice_spent` pour chaque ligne de
  /// [classRows] concernée par [deltaByClassId] (clé = `class_id` en
  /// chaîne, voir [applyRest]/[applyRestOnline]) — un `UPDATE` par ligne
  /// réellement modifiée, jamais pour les autres (même garde-fou "aucune
  /// écriture inutile" que l'ancien code mono-classe-primaire qu'elle
  /// remplace). [nextSpent] calcule la nouvelle valeur à partir du dépensé
  /// courant, du delta demandé et du niveau de CETTE classe (plafond
  /// `level` à la dépense via [math.min], plancher `0` à la récupération via
  /// [math.max] — voir les deux appelants). Une entrée de [deltaByClassId]
  /// dont la clé ne correspond à aucune ligne de [classRows] est simplement
  /// ignorée (défensif, voir la documentation de [applyRest]).
  Future<void> _applyHitDiceDeltas(
    List<Map<String, dynamic>> classRows, {
    required Map<String, int> deltaByClassId,
    required int Function(int currentSpent, int delta, int level) nextSpent,
  }) async {
    if (deltaByClassId.isEmpty) return;
    for (final row in classRows) {
      final delta = deltaByClassId[(row['class_id'] as Object).toString()];
      if (delta == null || delta == 0) continue;
      final level = (row['level'] as num).toInt();
      final currentSpent = (row['hit_dice_spent'] as num?)?.toInt() ?? 0;
      final updatedSpent = nextSpent(currentSpent, delta, level);
      if (updatedSpent != currentSpent) {
        await _client
            .from('character_classes')
            .update({'hit_dice_spent': updatedSpent})
            .eq('id', row['id']);
      }
    }
  }

  @override
  Future<WriteOutcome> updateStoryFields({
    required String characterId,
    String? appearanceText,
    String? traitsText,
    String? idealsText,
    String? bondsText,
    String? flawsText,
    String? backstoryText,
    String? alliesText,
    String? featuresText,
    String? treasureText,
  }) async {
    final ownerId = _requireOwnerId();

    // Voir la documentation de [CharacterRepository.updateStoryFields] :
    // jamais mis en file, même règle que [useInventoryItem].
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }

    try {
      await _client
          .from('characters')
          .update({
            // Coalescé vers `''` (jamais `null` littéral) — voir la
            // documentation de [CharacterRepository.updateStoryFields].
            'appearance_text': appearanceText ?? '',
            'traits_text': traitsText ?? '',
            'ideals_text': idealsText ?? '',
            'bonds_text': bondsText ?? '',
            'flaws_text': flawsText ?? '',
            'backstory_text': backstoryText ?? '',
            'allies_text': alliesText ?? '',
            'features_text': featuresText ?? '',
            'treasure_text': treasureText ?? '',
          })
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

  /// Repos long uniquement : réinitialise `character_spell_slots` pour
  /// [classes] — TOUTES les classes du personnage, multiclassage inclus — en
  /// recalculant les totaux via [SpellSlotProgression.totalsForClasses], la
  /// même fonction que [_upsertSpellSlots] (montée de niveau) : une seule
  /// classe lanceuse garde sa propre table, deux ou plus passent au niveau
  /// de lanceur combiné, l'Occultiste est toujours ignoré (magie de pacte,
  /// voir [_resetPactSlot]). Un calcul sur la seule classe primaire laissait
  /// un Guerrier/Magicien sans aucun emplacement restauré et écrasait à la
  /// baisse les totaux d'un personnage à deux classes lanceuses.
  ///
  /// Recalcul plutôt que simple remise à 0 des lignes existantes (décision
  /// chef de projet, revue QA) : `character_spell_slots` est désormais
  /// initialisée à la création de personnage et à l'import XML
  /// (`CharacterCreationRepository.createCharacter`/
  /// `XmlImportRepository.saveImportedCharacter`, via
  /// [SpellSlotProgression.nonZeroSlotTotals] — voir D14 du registre de
  /// dette), mais ce correctif est seulement partiel : un personnage lanceur
  /// de sorts créé avant ce chantier, ou créé par un autre chemin que ces
  /// deux-là, peut toujours avoir zéro ligne `character_spell_slots`. Un
  /// simple `UPDATE` ne ferait alors rien, et un repos long resterait sans
  /// effet visible sur ses emplacements.
  ///
  /// Pour chaque niveau de sort dont le total calculé est `> 0` : upsert de
  /// `slots_total` (valeur calculée, qui remplace la valeur stockée même si
  /// celle-ci était supérieure — comportement inchangé) et `slots_used = 0`
  /// (jamais préservé, contrairement à [_upsertSpellSlots] : c'est tout le
  /// sens d'un repos long). Aucune ligne créée pour un niveau de sort à 0,
  /// même convention que [_upsertSpellSlots]/
  /// `CharacterDetailRowMapper.parseSpellSlots`.
  ///
  /// Lignes déjà en base pour un niveau de sort HORS calcul (total calculé
  /// à 0 — ex. donnée héritée d'un ancien état du personnage) : jamais
  /// supprimées, `slots_total` jamais modifié, seul `slots_used` est remis à
  /// 0 quand il ne l'est pas déjà (un repos long restaure tous les
  /// emplacements existants ; décider de supprimer ces lignes relèverait
  /// d'un autre chantier). Aucune écriture si rien n'est à restaurer (classe
  /// non lanceuse ou Occultiste seul, sans ligne consommée).
  Future<void> _resetSpellSlots({
    required String characterId,
    required List<({String className, int level})> classes,
  }) async {
    final totals = SpellSlotProgression.totalsForClasses(classes);
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

    final existingRows = await _client
        .from('character_spell_slots')
        .select('slot_level, slots_used')
        .eq('character_id', characterId);
    final staleUsedLevels = <int>[];
    for (final row in existingRows) {
      final slotLevel = (row['slot_level'] as num?)?.toInt();
      if (slotLevel == null) continue;
      final isComputed =
          slotLevel >= 1 &&
          slotLevel <= totals.length &&
          totals[slotLevel - 1] > 0;
      final used = (row['slots_used'] as num?)?.toInt() ?? 0;
      if (!isComputed && used != 0) staleUsedLevels.add(slotLevel);
    }
    staleUsedLevels.sort();

    if (payload.isNotEmpty) {
      await _client
          .from('character_spell_slots')
          .upsert(payload, onConflict: 'character_id,slot_level');
    }
    if (staleUsedLevels.isNotEmpty) {
      await _client
          .from('character_spell_slots')
          .update({'slots_used': 0})
          .eq('character_id', characterId)
          .inFilter('slot_level', staleUsedLevels);
    }
  }

  /// Réinitialise (upsert) `character_feature_uses.uses_remaining` pour les
  /// `class_features` de **toutes** les classes du personnage ([classIds])
  /// ET de leurs éventuelles sous-classes déjà choisies ([subclassIds])
  /// atteintes par leur niveau respectif ([classLevels]/[subclassLevels]) —
  /// personnage multiclassé inclus. Réutilise littéralement
  /// [ClassFeatureRowMapper.filterAttained], même règle de filtrage que la
  /// lecture de la fiche (`_buildCharacterDetailPayload`/
  /// `_mapCharacterDetailPayload`, qui gère déjà explicitement ce cas pour la
  /// même raison : "pour un personnage multiclassé où plusieurs
  /// `class_id`... sont mélangés").
  ///
  /// [subclassIds]/[subclassLevels] ajoutés en même temps que le correctif
  /// d'affichage de `_buildCharacterDetailPayload` (voir sa documentation) —
  /// avant cet ajout, une aptitude de sous-classe à usage limité (ex. une
  /// discipline du Moine Voie des quatre éléments hors coût en ki) n'était
  /// de toute façon jamais affichée nulle part, donc jamais utilisable
  /// (`useClassFeature` n'est atteignable que depuis la carte "APTITUDES DE
  /// CLASSE") ; une fois le correctif d'affichage appliqué seul, une telle
  /// aptitude serait devenue utilisable sans jamais être rechargée par un
  /// repos — corrigé ici en même temps plutôt que livré comme régression
  /// connue.
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
    Set<Object> subclassIds = const {},
    Map<String, int> subclassLevels = const {},
    required bool onlyShortRest,
  }) async {
    if (classIds.isEmpty) return;

    // `choice_type` ajouté (override du dé de supériorité du Guerrier
    // Maître de guerre, voir [_rechargedAmount] et
    // `ClassFeatureRowMapper.effectiveUsesMax`) : sans lui, un repos
    // rechargerait toujours la réserve à la valeur statique de la base
    // (4, RAW-exacte seulement aux niveaux 3-6), en désaccord avec le total
    // affiché par `_mapCharacterDetailPayload` à partir du niveau 7.
    const featureSelect =
        'id, class_id, subclass_id, level, uses_per_rest, choice_type';
    final featureRowsById = <Object, Map<String, dynamic>>{};
    final baseRows = await _client
        .from('class_features')
        .select(featureSelect)
        .inFilter('class_id', classIds.toList());
    for (final featureRow in baseRows) {
      final id = featureRow['id'];
      if (id != null) featureRowsById[id] = featureRow;
    }
    if (subclassIds.isNotEmpty) {
      final subclassFeatureRows = await _client
          .from('class_features')
          .select(featureSelect)
          .inFilter('subclass_id', subclassIds.toList());
      for (final featureRow in subclassFeatureRows) {
        final id = featureRow['id'];
        if (id != null) featureRowsById[id] = featureRow;
      }
    }

    final attainedRows = ClassFeatureRowMapper.filterAttained(
      featureRowsById.values.toList(),
      classLevels: classLevels,
      subclassLevels: subclassLevels,
    );

    final payload = [
      for (final row in attainedRows)
        if (_rechargedAmount(
              row,
              ownerLevel: ClassFeatureRowMapper.ownerLevelOf(
                row,
                classLevels: classLevels,
                subclassLevels: subclassLevels,
              ),
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

  /// Total d'utilisations à écrire pour l'aptitude décrite par [row] si ce
  /// repos doit la recharger, `null` sinon — jamais rien à écrire dans
  /// `character_feature_uses` dans ce cas (aptitude non rechargée par ce
  /// type de repos, ou pas d'usage limité du tout).
  ///
  /// `null` dans 2 cas distincts, tous deux traités identiquement (aucune
  /// ligne écrite) :
  /// - `row['uses_per_rest']` nul — aptitude passive, voir
  ///   `CharacterClassFeature.isPassive`.
  /// - `uses_per_rest->>'amount'` absent alors que `rest_type` est renseigné
  ///   — cas réel constaté côté seed (ex. `class_features.id = 6`,
  ///   `{amount: null, rest_type: 'repos_court'}`, vérifié contre le stack
  ///   local) : même convention que
  ///   `ClassFeatureRowMapper.toCharacterClassFeature` (`usesMax` nul ⇒
  ///   `isPassive`), pour ne jamais écrire un total inconnu.
  ///
  /// Le total réellement écrit passe par
  /// `ClassFeatureRowMapper.effectiveUsesMax` ([ownerLevel]) — jamais
  /// directement `uses_per_rest->>'amount'` — pour que la réserve de dés de
  /// supériorité du Guerrier Maître de guerre (`choice_type == 'manoeuvre'`)
  /// soit rechargée au total RAW du niveau courant, pas à la valeur statique
  /// de la base (voir `domain/superiority_dice_progression.dart`). Sans
  /// effet sur toute autre aptitude.
  int? _rechargedAmount(
    Map<String, dynamic> row, {
    required int? ownerLevel,
    required bool onlyShortRest,
  }) {
    final usesPerRest = row['uses_per_rest'] as Map<String, dynamic>?;
    if (usesPerRest == null) return null;
    if (onlyShortRest && usesPerRest['rest_type'] != 'repos_court') {
      return null;
    }
    return ClassFeatureRowMapper.effectiveUsesMax(row, ownerLevel: ownerLevel);
  }

  /// Recalcule `character_spell_slots` pour [afterClasses] (TOUTES les
  /// classes du personnage après ce niveau, multiclassage inclus — voir
  /// [SpellSlotProgression.totalsForClasses]). **Recalcul complet depuis
  /// zéro** (upsert de tous les paliers dont le total théorique est `> 0`),
  /// jamais un delta incrémental : `character_spell_slots` est aussi écrite
  /// à la création de personnage et à l'import XML
  /// (`CharacterCreationRepository.createCharacter`/
  /// `XmlImportRepository.saveImportedCharacter`, via
  /// [SpellSlotProgression.nonZeroSlotTotals] — voir D14 du registre de
  /// dette, correctif partiel), mais pas ailleurs dans ce dépôt ; pour un
  /// personnage créé avant ce chantier ou par un autre chemin, l'état
  /// antérieur en base n'est donc pas fiable comme point de départ (voir le
  /// point critique de la spec
  /// visuelle direction-artistique de l'étape "Sorts",
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
  /// incohérente ou de planter — ne devrait jamais arriver en pratique pour
  /// une classe continuée (les totaux ne font que croître avec le niveau),
  /// mais reste un filet de sécurité valide aussi pour le passage au calcul
  /// combiné multiclasse (le total combiné ne décroît jamais non plus quand
  /// un niveau s'ajoute, RAW ou pas).
  ///
  /// Ne fait rien si aucune classe de [afterClasses] n'est lanceuse
  /// "non-pacte" ([SpellSlotProgression.isNonPactCasterClass]) — classe non
  /// lanceuse ou Occultiste seul (magie de pacte, mécanisme différent, hors
  /// périmètre) : [SpellSlotProgression.totalsForClasses] retourne alors 9
  /// zéros, donc [nonZeroLevels] est vide.
  Future<void> _upsertSpellSlots({
    required String characterId,
    required List<({String className, int level})> afterClasses,
  }) async {
    final totals = SpellSlotProgression.totalsForClasses(afterClasses);
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

  /// Recalcule `character_pact_slots` (magie de pacte de l'Occultiste, table
  /// séparée de `character_spell_slots` — voir
  /// `domain/spell_slot_progression.dart`) pour [afterClasses] (TOUTES les
  /// classes du personnage après ce niveau). Ne fait rien si le personnage
  /// n'a pas (ou plus) la classe Occultiste parmi [afterClasses], ou si
  /// [SpellSlotProgression.pactMagicFor] retourne `null` pour son niveau
  /// (défensif, ne devrait pas arriver pour un niveau 1-20 valide).
  ///
  /// Préserve `slots_used` d'une ligne déjà existante (clampé à
  /// `min(existingUsed, charges)`), même filet de sécurité que
  /// [_spellSlotUpsertRow] — factorisé séparément plutôt que réutilisé
  /// littéralement : la table cible est différente et sa clé primaire
  /// (`character_id` seul, une seule ligne par personnage — jamais deux fois
  /// la classe Occultiste, jamais deux niveaux de charge de pacte actifs à la
  /// fois, voir la documentation de la table côté dépôt web) rend un helper
  /// dédié plus simple qu'une généralisation du helper existant.
  Future<void> _upsertPactSlot({
    required String characterId,
    required List<({String className, int level})> afterClasses,
  }) async {
    ({String className, int level})? occultisteEntry;
    for (final entry in afterClasses) {
      if (entry.className == 'Occultiste') {
        occultisteEntry = entry;
        break;
      }
    }
    if (occultisteEntry == null) return;

    final pact = SpellSlotProgression.pactMagicFor(occultisteEntry.level);
    if (pact == null) return;

    final existingRow = await _client
        .from('character_pact_slots')
        .select('slots_used')
        .eq('character_id', characterId)
        .maybeSingle();
    final existingUsed = (existingRow?['slots_used'] as num?)?.toInt() ?? 0;
    final used = existingUsed > pact.charges ? pact.charges : existingUsed;

    await _client.from('character_pact_slots').upsert({
      'character_id': characterId,
      'slot_level': pact.slotLevel,
      'slots_total': pact.charges,
      'slots_used': used,
    }, onConflict: 'character_id');
  }

  /// Réinitialise complètement `character_pact_slots` pour l'Occultiste au
  /// niveau [occultisteLevel] — appelée par [applyRest] pour les DEUX types
  /// de repos (court ET long, RAW 5e unique à l'Occultiste : contrairement
  /// aux emplacements classiques, la magie de pacte recharge aussi au repos
  /// court). Recalcul complet depuis zéro (`slots_used` toujours remis à 0,
  /// `slots_total` recalculé via [SpellSlotProgression.pactMagicFor]), même
  /// philosophie que [_resetSpellSlots] (repos long, emplacements
  /// classiques) — upsert plutôt qu'un simple `UPDATE`, la ligne pouvant ne
  /// pas encore exister (gap assumé documenté sur
  /// [CharacterDetail.pactSpellSlot]). Ne fait rien si [occultisteLevel] est
  /// hors 1-20 (défensif).
  Future<void> _resetPactSlot({
    required String characterId,
    required int occultisteLevel,
  }) async {
    final pact = SpellSlotProgression.pactMagicFor(occultisteLevel);
    if (pact == null) return;

    await _client.from('character_pact_slots').upsert({
      'character_id': characterId,
      'slot_level': pact.slotLevel,
      'slots_total': pact.charges,
      'slots_used': 0,
    }, onConflict: 'character_id');
  }

  /// Écrit [choice] pour la table concernée — voir la documentation de
  /// [CharacterRepository.applyLevelUp]. Ne fait rien pour
  /// [LevelUpChoiceKind.subclass] : déjà écrit dans le même `UPDATE` que
  /// `character_classes.level` par l'appelant.
  ///
  /// Renvoie les PV maximum à ajouter rétroactivement ([totalLevel] = niveau
  /// total du personnage après cette montée) : don Robuste pris, ou
  /// modificateur de Constitution augmenté — voir
  /// `domain/hit_point_bonus_rules.dart`. 0 sinon.
  Future<int> _applyChoice({
    required String characterId,
    required int level,
    required int totalLevel,
    required LevelUpChoiceSelection choice,
  }) async {
    switch (choice.kind) {
      case LevelUpChoiceKind.subclass:
        return 0;
      case LevelUpChoiceKind.abilityScoreImprovement:
        if (choice.featId != null) {
          // Don choisi en alternative à l'ASI (spec visuelle
          // direction-artistique section 1) — mutuellement exclusif avec
          // `character_ability_scores`/`character_ability_increases`, voir
          // la documentation de [LevelUpChoiceSelection.featId].
          await _client.from('character_feats').insert({
            'character_id': characterId,
            'feat_id': choice.featId,
            'level_taken': level,
          });
          final featName =
              (await _fetchTranslationRows(
                    entityType: 'feat',
                    fieldName: 'name',
                    entityIds: {'${choice.featId}'},
                  )).firstOrNull?['value']
                  as String?;
          final abilityHp = await _applyFeatAbilityIncrease(
            characterId: characterId,
            featId: choice.featId!,
            ability: choice.featAbility,
            level: level,
            totalLevel: totalLevel,
          );
          return abilityHp +
              HitPointBonusRules.featTakenBonus(
                featName: featName,
                totalLevel: totalLevel,
              );
        }
        return _applyAbilityScoreImprovement(
          characterId: characterId,
          level: level,
          totalLevel: totalLevel,
          allocations: choice.abilityAllocations!,
        );
      case LevelUpChoiceKind.fightingStyle:
      case LevelUpChoiceKind.favoredEnemy:
      case LevelUpChoiceKind.pact:
        await _client.from('character_class_options').insert({
          'character_id': characterId,
          'class_feature_id': choice.classFeatureId,
          'level': level,
          'chosen_value': choice.chosenValue,
        });
        return 0;
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
  ///
  /// Renvoie les PV maximum à ajouter rétroactivement si la Constitution
  /// augmentée change de modificateur (× [totalLevel]), 0 sinon.
  Future<int> _applyAbilityScoreImprovement({
    required String characterId,
    required int level,
    required int totalLevel,
    required Map<String, int> allocations,
  }) async {
    var retroactiveHp = 0;
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

      if (abilityId == 'con') {
        retroactiveHp += HitPointBonusRules.constitutionRetroactiveBonus(
          oldScore: currentScore,
          newScore: newScore,
          totalLevel: totalLevel,
        );
      }
    }
    return retroactiveHp;
  }

  /// +1 d'un demi-don (`feats.ability_increase`) sur [ability] : relu en
  /// base (caractéristiques éligibles, montant, plafond 20 ou 30) plutôt que
  /// pris de l'écran, plafonné sans erreur (un don reste prenable même à
  /// 20), tracé dans `character_ability_increases` (`source: 'feat'`).
  /// Renvoie les PV rétroactifs si la Constitution change de modificateur.
  /// Ne fait rien pour un don sans augmentation ou sans [ability] valide.
  Future<int> _applyFeatAbilityIncrease({
    required String characterId,
    required Object featId,
    required String? ability,
    required int level,
    required int totalLevel,
  }) async {
    if (ability == null) return 0;
    final featRow = await _client
        .from('feats')
        .select('ability_increase')
        .eq('id', featId)
        .maybeSingle();
    final increase = featRow?['ability_increase'];
    if (increase is! Map) return 0;
    final abilities = (increase['abilities'] as List?)?.whereType<String>();
    if (abilities == null || !abilities.contains(ability)) return 0;
    final amount = (increase['amount'] as num?)?.toInt() ?? 1;
    final max = (increase['max'] as num?)?.toInt() ?? 20;

    final scoreRow = await _client
        .from('character_ability_scores')
        .select('score')
        .eq('character_id', characterId)
        .eq('ability_id', ability)
        .maybeSingle();
    if (scoreRow == null) return 0;
    final currentScore = (scoreRow['score'] as num).toInt();
    final newScore = (currentScore + amount).clamp(currentScore, max);
    if (newScore == currentScore) return 0;

    await _client
        .from('character_ability_scores')
        .update({'score': newScore})
        .eq('character_id', characterId)
        .eq('ability_id', ability);
    await _client.from('character_ability_increases').insert({
      'character_id': characterId,
      'level': level,
      'ability_id': ability,
      'increase': newScore - currentScore,
      'source': 'feat',
    });

    return ability == 'con'
        ? HitPointBonusRules.constitutionRetroactiveBonus(
            oldScore: currentScore,
            newScore: newScore,
            totalLevel: totalLevel,
          )
        : 0;
  }

  /// Tous les scores de caractéristiques finaux de [characterId]
  /// (`character_ability_scores.score`, clé `ability_id`) — nécessaire à la
  /// revérification des prérequis de multiclassage
  /// (`domain/multiclass_prerequisites.dart::MulticlassPrerequisites.meetsRequirement`)
  /// côté écriture ([applyLevelUp]), qui doit connaître TOUTES les
  /// caractéristiques (pas seulement celles d'une classe précise, calculée à
  /// l'avance côté UI) pour couvrir n'importe quelle classe candidate.
  Future<Map<String, int>> _fetchAllAbilityScores(String characterId) async {
    final rows = await _client
        .from('character_ability_scores')
        .select('ability_id, score')
        .eq('character_id', characterId);
    return {
      for (final row in rows)
        row['ability_id'] as String: (row['score'] as num).toInt(),
    };
  }

  /// Normalise un `classId` (`Object`, toujours un entier côté Supabase en
  /// pratique — voir `CharacterDetailClassRow.classId`) en `int`, pour
  /// comparer deux identifiants de classe indépendamment de leur type Dart
  /// exact (`int` vs `num`) — voir [applyLevelUp].
  int _classIdAsInt(Object classId) => (classId as num).toInt();

  /// `spell_id` de [characterId] ayant DÉJÀ une ligne `character_spells`
  /// ORDINAIRE ('connu' ou 'préparé', jamais 'inné') — lecture fraîche
  /// utilisée par [applyLevelUp] juste avant l'écriture des sorts initiaux
  /// d'une nouvelle classe à sorts connus ([initialSpellIds]) pour ne jamais
  /// tenter de réécrire une ligne ORDINAIRE déjà existante (violerait
  /// l'index unique partiel sur `character_spells`, voir dette D10).
  ///
  /// Contrairement à [_fetchAlreadyInnateSpellIds] : ignore délibérément
  /// toute ligne 'inné' existante du même sort — décision de Matthias du
  /// 12/10/2026, symétrique de celle du 10/10/2026 sur
  /// [_fetchAlreadyInnateSpellIds] (cohérente avec D43 du registre de dette
  /// technique, `docs/dette-technique.md`) : un sort déjà connu uniquement
  /// via sa route innée (trait racial) garde malgré tout le droit à sa
  /// ligne ORDINAIRE séparée, les deux routes RAW étant indépendantes.
  Future<Set<int>> _fetchAlreadyOrdinarySpellIds(String characterId) async {
    final ordinaryRows = await _client
        .from('character_spells')
        .select('spell_id')
        .eq('character_id', characterId)
        .neq('status', SpellStatus.innate.value);
    return {
      for (final row in ordinaryRows)
        if (row['spell_id'] is num) (row['spell_id'] as num).toInt(),
    };
  }

  /// `spell_id` de [characterId] ayant DÉJÀ une ligne `character_spells` au
  /// statut 'inné' — lecture fraîche utilisée par [applyLevelUp] juste avant
  /// l'écriture des sorts innés raciaux ([racialInnateSpellIds]) pour ne
  /// jamais réécrire une ligne 'inné' déjà existante (violerait l'index
  /// unique partiel dédié, D10, dont [fetchApplicableGrants] cumulatif
  /// réexpose les grants déjà accordés à un niveau antérieur).
  ///
  /// Contrairement à [_fetchAlreadyOrdinarySpellIds] : ignore délibérément
  /// toute ligne ORDINAIRE existante du même sort — décision de Matthias du
  /// 10/10/2026, cohérente avec D43 du registre de dette technique
  /// (`docs/dette-technique.md`) : un sort déjà connu uniquement via sa
  /// route de classe garde malgré tout le droit à sa ligne 'inné' séparée,
  /// les deux routes RAW étant indépendantes.
  Future<Set<int>> _fetchAlreadyInnateSpellIds(String characterId) async {
    final innateRows = await _client
        .from('character_spells')
        .select('spell_id')
        .eq('character_id', characterId)
        .eq('status', SpellStatus.innate.value);
    return {
      for (final row in innateRows)
        if (row['spell_id'] is num) (row['spell_id'] as num).toInt(),
    };
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
    // Vitesse de déplacement (onglet "Personnage", `CharacterStatPillsRow`)
    // : contrairement au nom de race (résolu via `translations` ci-dessus),
    // `speed` est une colonne directe de `races` — requête dédiée plutôt
    // qu'un ajout à `_fetchTranslationRows` (qui ne connaît que la table
    // `translations`). `race_id` est unique par personnage (pas un ensemble
    // comme les classes), un simple `.maybeSingle()` suffit.
    final raceId = row['race_id'];
    final raceRow = raceId == null
        ? null
        : await _client
              .from('races')
              .select('id, speed')
              .eq('id', raceId)
              .maybeSingle();
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
    // Nom de sous-classe, carte "CHOIX DE CLASSE" (`character_classes
    // .subclass_id`) — gap de lecture trouvé en construisant l'export XML
    // (voir le README) : cette colonne était déjà écrite par la montée de
    // niveau mais jamais relue par cette méthode avant cet ajout.
    final subclassNameRows = await _fetchTranslationRows(
      entityType: 'subclass',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectSubclassIds(row),
    );
    // Noms d'invocations occultistes connues, carte "INVOCATIONS CONNUES"
    // (`character_invocations`, déjà embarquée dans [row]) — même gap de
    // lecture que ci-dessus.
    final invocationNameRows = await _fetchTranslationRows(
      entityType: 'invocation',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectInvocationIds(
        CharacterDetailRowMapper.invocationRowsOf(row),
      ).map((id) => id.toString()).toSet(),
    );
    // Noms des dons possédés (`character_feats`) — bonus de PV du don
    // Robuste, voir `domain/hit_point_bonus_rules.dart`.
    final featNameRows = await _fetchTranslationRows(
      entityType: 'feat',
      fieldName: 'name',
      entityIds: CharacterDetailRowMapper.collectFeatIds(
        CharacterDetailRowMapper.featRowsOf(row),
      ),
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

    // Aptitudes de classe ET de sous-classe, carte "APTITUDES DE CLASSE" —
    // `class_features` n'est pas liée directement à `characters` (seulement
    // via `classes`/`subclasses`), donc interrogée séparément : une requête
    // filtrée sur les `class_id` du personnage (aptitudes de classe de
    // base), et, si le personnage a déjà choisi au moins une sous-classe
    // (`character_classes.subclass_id`), une seconde filtrée sur ces
    // `subclass_id` (aptitudes de sous-classe). Aucune requête (ni l'une ni
    // l'autre, ni `translations`) si le personnage n'a aucune classe
    // (brouillon incomplet) : listes vides.
    //
    // **Bug architectural corrigé** (trouvé par l'agent `regles-dnd` en
    // investiguant le Guerrier Maître de guerre, périmètre élargi à toutes
    // les sous-classes) : avant ce correctif, seule la requête `class_id`
    // existait — aucune aptitude de sous-classe n'était jamais résolue ni
    // affichée, pour aucune sous-classe du jeu, voir la documentation de
    // classe de `domain/character_class_feature.dart` et
    // `ClassFeatureRowMapper.filterAttained`.
    //
    // Les deux résultats sont fusionnés dans une map par `id` (jamais une
    // simple concaténation) : défense en profondeur contre un doublon
    // (ne devrait jamais arriver en pratique, `class_id`/`subclass_id` étant
    // mutuellement exclusifs en base, mais une ligne comptée deux fois
    // afficherait l'aptitude deux fois sur la carte).
    //
    // `.order('level', ascending: true)` sur chaque requête : affichage
    // déterministe, important pour un personnage multiclassé où plusieurs
    // `class_id`/`subclass_id` (donc plusieurs jeux d'aptitudes) sont
    // mélangés — sans quoi PostgREST ne garantit aucun ordre particulier.
    // Signalé en revue QA. `ascending: true` explicite, pas la valeur par
    // défaut, même correctif que `skills` ci-dessus. Sans conséquence sur
    // l'ordre final affiché (tri alphabétique français, voir
    // [_mapCharacterDetailPayload]) : seulement sur le déterminisme de ce
    // qui est mis en cache.
    final classIds = CharacterDetailRowMapper.collectClassIdsRaw(row);
    final subclassIds = CharacterDetailRowMapper.collectSubclassIdsRaw(row);
    var classFeatureRows = const <Map<String, dynamic>>[];
    var classFeatureNameRows = const <Map<String, dynamic>>[];
    var classFeatureDescriptionRows = const <Map<String, dynamic>>[];
    if (classIds.isNotEmpty) {
      // Pas de colonne `description` directe sur `class_features` (vérifié
      // contre le schéma réel — une régression avait supposé le contraire,
      // faisant échouer *tout* fetch de fiche avec un personnage classé :
      // 42703 `column class_features.description does not exist`, PostgREST
      // ne renvoyant alors qu'un replis silencieux sur le cache). Elle vit
      // dans `translations`, même pattern que `spells`/`items` ci-dessous.
      //
      // `choice_type` ajouté (override du dé de supériorité du Guerrier
      // Maître de guerre, voir
      // `ClassFeatureRowMapper.effectiveUsesMax`/
      // `domain/superiority_dice_progression.dart`) : seul moyen de repérer
      // "Supériorité martiale" sans dépendre d'un `id` câblé en dur.
      const featureSelect =
          'id, class_id, subclass_id, level, uses_per_rest, choice_type';
      final featureRowsById = <Object, Map<String, dynamic>>{};
      final baseRows = await _client
          .from('class_features')
          .select(featureSelect)
          .inFilter('class_id', classIds.toList())
          .order('level', ascending: true);
      for (final featureRow in baseRows) {
        final id = featureRow['id'];
        if (id != null) featureRowsById[id] = featureRow;
      }
      if (subclassIds.isNotEmpty) {
        final subclassFeatureRows = await _client
            .from('class_features')
            .select(featureSelect)
            .inFilter('subclass_id', subclassIds.toList())
            .order('level', ascending: true);
        for (final featureRow in subclassFeatureRows) {
          final id = featureRow['id'];
          if (id != null) featureRowsById[id] = featureRow;
        }
      }
      classFeatureRows = featureRowsById.values.toList();
      final attainedRows = ClassFeatureRowMapper.filterAttained(
        classFeatureRows,
        classLevels: CharacterDetailRowMapper.collectClassLevels(row),
        subclassLevels: CharacterDetailRowMapper.collectSubclassLevels(row),
      );
      final attainedIds = ClassFeatureRowMapper.collectIds(attainedRows);
      classFeatureNameRows = await _fetchTranslationRows(
        entityType: 'class_feature',
        fieldName: 'name',
        entityIds: attainedIds,
      );
      classFeatureDescriptionRows = await _fetchTranslationRows(
        entityType: 'class_feature',
        fieldName: 'description',
        entityIds: attainedIds,
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
    //
    // Sorts "toujours préparés" des sous-classes (`subclass_spells`, Clerc/
    // Paladin) : table de référence lue en entier pour la/les sous-classe(s)
    // du personnage (jamais filtrée par niveau ici — le filtrage par niveau de
    // classe est fait au mapping, voir [_mapCharacterDetailPayload], pour que
    // le cache hors-ligne reste cohérent) ; seuls les sorts déjà atteints sont
    // ajoutés aux `spells`/`translations` à résoudre. Aucune écriture dans
    // `character_spells`.
    final subclassProgress = CharacterDetailRowMapper.collectSubclassProgress(
      row,
      classNames: CharacterRowMapper.parseTranslatedNames(classNameRows),
    );
    var subclassSpellRows = const <Map<String, dynamic>>[];
    if (subclassProgress.isNotEmpty) {
      subclassSpellRows = await _client
          .from('subclass_spells')
          .select('subclass_id, spell_id, class_level')
          // Les listes ÉTENDUES des patrons d'Occultiste ('extends_list')
          // n'accordent aucun sort d'office.
          .eq('grant_kind', 'always_prepared')
          .inFilter('subclass_id', [
            for (final entry in subclassProgress) entry.subclassId,
          ]);
    }
    final grantedSpellIds = SubclassSpellGrantResolver.resolve(
      progress: subclassProgress,
      grants: CharacterDetailRowMapper.parseSubclassSpellGrants(
        subclassSpellRows,
      ),
    ).keys;
    final classListSpellClassRows =
        await _fetchPreparedCasterClassListSpellRows(
          row,
          classNames: CharacterRowMapper.parseTranslatedNames(classNameRows),
        );
    final classListSpellIds = CharacterSpellRowMapper.collectSpellIds(
      classListSpellClassRows,
    );
    final spellIds = <int>{
      ...CharacterSpellRowMapper.collectSpellIds(
        CharacterDetailRowMapper.characterSpellRowsOf(row),
      ),
      ...grantedSpellIds,
      ...classListSpellIds,
    };
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

    // Forme courante de l'arme de pacte (Pacte de la lame,
    // `character_pact_weapons`) : lue seulement si le personnage a choisi ce
    // pacte, pour ne coûter aucune requête aux autres personnages. Absente
    // (`null`) des payloads mis en cache avant cet ajout.
    Map<String, dynamic>? pactWeaponItemRow;
    var pactWeaponNameRows = const <Map<String, dynamic>>[];
    final hasBladePact = CharacterDetailRowMapper.classOptionRowsOf(row)
        .any((option) => option['chosen_value'] == WarlockPact.blade.key);
    if (hasBladePact) {
      // Carte accessoire : un échec de lecture ne doit jamais empêcher la
      // fiche de se charger (la forme reste simplement non affichée).
      try {
        final pactWeaponRow = await _client
            .from('character_pact_weapons')
            .select('item_id')
            .eq('character_id', row['id'] as String)
            .maybeSingle();
        final pactItemId = pactWeaponRow?['item_id'];
        if (pactItemId != null) {
          final itemRow = await _client
              .from('items')
              .select(
                'id, category, '
                'weapon_properties(damage_dice, damage_type, properties)',
              )
              .eq('id', pactItemId)
              .maybeSingle();
          final nameRows = await _fetchTranslationRows(
            entityType: 'item',
            fieldName: 'name',
            entityIds: {pactItemId.toString()},
          );
          pactWeaponItemRow = itemRow;
          pactWeaponNameRows = nameRows;
        }
      } catch (_) {
        pactWeaponItemRow = null;
        pactWeaponNameRows = const <Map<String, dynamic>>[];
      }
    }

    return <String, dynamic>{
      CharacterDetailCache.rowKey: row,
      'raceRow': raceRow,
      'pactWeaponItemRow': pactWeaponItemRow,
      'pactWeaponNameRows': pactWeaponNameRows,
      'raceNameRows': raceNameRows,
      'subraceNameRows': subraceNameRows,
      'classNameRows': classNameRows,
      'backgroundNameRows': backgroundNameRows,
      'alignmentNameRows': alignmentNameRows,
      'subclassNameRows': subclassNameRows,
      'invocationNameRows': invocationNameRows,
      'featNameRows': featNameRows,
      'skillRows': skillRows,
      'skillNameRows': skillNameRows,
      'classFeatureRows': classFeatureRows,
      'classFeatureNameRows': classFeatureNameRows,
      'classFeatureDescriptionRows': classFeatureDescriptionRows,
      'toolNameRows': toolNameRows,
      'languageNameRows': languageNameRows,
      'spellRows': spellRows,
      'subclassSpellRows': subclassSpellRows,
      'classListSpellClassRows': classListSpellClassRows,
      'spellNameRows': spellNameRows,
      'spellDescriptionRows': spellDescriptionRows,
      'itemNameRows': itemNameRows,
      'itemDescriptionRows': itemDescriptionRows,
    };
  }

  /// Sorts de la liste de classe d'un lanceur à préparation (Clerc, Druide,
  /// Paladin, Artificier — voir `domain/prepared_caster_spell_list.dart`) :
  /// tous les sorts de la classe du niveau 1 au plus haut niveau lançable,
  /// hors contenu incomplet. Ils rejoignent `spellRows` comme les autres ;
  /// ceux sans ligne `character_spells` sont affichés "connu, non préparé"
  /// et [setSpellPrepared] crée leur ligne quand le joueur les prépare.
  ///
  /// Renvoie une ligne `{spell_id, class_id}` par (sort, classe) — PAS un
  /// simple ensemble d'identifiants de sort comme avant ce chantier : un
  /// même sort peut apparaître sur la liste de PLUSIEURS classes préparantes
  /// du personnage (ex. Clerc/Druide multiclassés partageant un sort), et
  /// cette origine est nécessaire pour ventiler la limite de sorts préparés
  /// PAR CLASSE (`CharacterSpellEntry.sourceClassIds`, voir
  /// `domain/prepared_spells_limit.dart::PreparedSpellsLimit.limitsByClass`)
  /// — jusqu'ici perdue dès la sortie de cette méthode (seul l'ENSEMBLE des
  /// identifiants de sort survivait, pas leur classe d'origine). Mise en
  /// cache telle quelle par l'appelant (`payload['classListSpellClassRows']`,
  /// voir [_buildCharacterDetailPayload]/[_mapCharacterDetailPayload]) pour
  /// rester disponible hors ligne — un ancien cache sans cette clé retombe
  /// sur une liste vide, jamais de crash.
  ///
  /// Liste vide (aucune requête) pour un personnage sans classe de ce type.
  Future<List<Map<String, dynamic>>> _fetchPreparedCasterClassListSpellRows(
    Map<String, dynamic> row, {
    required Map<String, String> classNames,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (final classRow in CharacterDetailRowMapper.classRowsOf(row)) {
      final classId = classRow['class_id'];
      if (classId is! num) continue;
      final maxLevel = PreparedCasterSpellList.maxSpellLevelFor(
        classNames[classId.toString()] ?? '',
        (classRow['level'] as num?)?.toInt() ?? 0,
      );
      if (maxLevel < 1) continue;

      final spellClassRows = await _client
          .from('spell_classes')
          .select('spell_id')
          .eq('class_id', classId);
      final candidateIds = CharacterSpellRowMapper.collectSpellIds(
        spellClassRows,
      );
      if (candidateIds.isEmpty) continue;

      final spellRows = await _client
          .from('spells')
          .select('id')
          .inFilter('id', candidateIds.toList())
          .gte('level', 1)
          .lte('level', maxLevel)
          .not('is_incomplete', 'is', true);
      for (final spellRow in spellRows) {
        final id = spellRow['id'];
        if (id is num) {
          rows.add({'spell_id': id.toInt(), 'class_id': classId});
        }
      }
    }
    return rows;
  }

  /// Reconstruit un [CharacterDetail] complet à partir d'un [payload] déjà
  /// construit par [_buildCharacterDetailPayload] — jamais d'accès réseau
  /// ici, seul point de mapping partagé par le chemin réseau (juste après un
  /// succès) et le chemin cache (`_mappedFromCache`, dans
  /// [fetchCharacterDetail]).
  CharacterDetail _mapCharacterDetailPayload(Map<String, dynamic> payload) {
    final row = Map<String, dynamic>.from(
      payload[CharacterDetailCache.rowKey] as Map,
    );

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
    final subclassNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['subclassNameRows']),
    );
    final invocationNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['invocationNameRows']),
    );
    final knownInvocationNames = CharacterDetailRowMapper.parseInvocationNames(
      CharacterDetailRowMapper.invocationRowsOf(row),
      invocationNames: invocationNames,
    );
    // Absente d'un cache écrit avant l'ajout des dons : `_rowsOf` renvoie
    // alors une liste vide (aucun don connu, comportement antérieur).
    final featNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['featNameRows']),
    ).values.toList()..sort();

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

    final classLevelsForFeatures = CharacterDetailRowMapper.collectClassLevels(
      row,
    );
    final subclassLevelsForFeatures =
        CharacterDetailRowMapper.collectSubclassLevels(row);
    final attainedFeatureRows = ClassFeatureRowMapper.filterAttained(
      _rowsOf(payload['classFeatureRows']),
      classLevels: classLevelsForFeatures,
      subclassLevels: subclassLevelsForFeatures,
    );
    final classFeatureNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['classFeatureNameRows']),
    );
    final classFeatureDescriptions = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['classFeatureDescriptionRows']),
    );
    final usesRemaining = ClassFeatureRowMapper.parseUsesRemaining(
      CharacterDetailRowMapper.featureUsesRowsOf(row),
    );
    // Tri alphabétique (demande utilisateur, 2026-10-03) pour l'affichage
    // de la carte "APTITUDES DE CLASSE" — l'ordre `level` de la requête
    // ci-dessus reste utile pour la déterminisme du fetch lui-même (voir le
    // commentaire plus haut), mais n'est plus l'ordre final présenté au
    // joueur. Revient sur l'exclusion initiale de ce chantier de tri
    // alphabétique (ordre de niveau jugé a priori plus parlant) : le chef
    // de projet a confirmé vouloir l'alphabétique ici aussi malgré la
    // perte du regroupement chronologique.
    final classFeatures = [
      for (final featureRow in attainedFeatureRows)
        ClassFeatureRowMapper.toCharacterClassFeature(
          featureRow,
          names: classFeatureNames,
          descriptions: classFeatureDescriptions,
          usesRemaining: usesRemaining,
          // Override du dé de supériorité (Guerrier Maître de guerre), voir
          // `ClassFeatureRowMapper.effectiveUsesMax` — sans effet pour
          // toute autre aptitude (`choice_type != 'manoeuvre'`).
          ownerLevel: ClassFeatureRowMapper.ownerLevelOf(
            featureRow,
            classLevels: classLevelsForFeatures,
            subclassLevels: subclassLevelsForFeatures,
          ),
        ),
    ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    final classChoices = CharacterDetailRowMapper.parseClassChoices(
      CharacterDetailRowMapper.classOptionRowsOf(row),
      featureNames: classFeatureNames,
    );

    final toolNames = CharacterRowMapper.parseTranslatedNames(
      _rowsOf(payload['toolNameRows']),
    );
    final toolProficiencyNames =
        CharacterDetailRowMapper.parseToolProficiencyNames(
          CharacterDetailRowMapper.toolProficiencyRowsOf(row),
          toolNames: toolNames,
        );

    // Carte "CHOIX DE RACE" — `character_race_choices` est déjà embarquée
    // dans [row] (relation réelle vers `characters`), aucune requête
    // supplémentaire : [skillNames] (toutes les 18 compétences, déjà
    // résolues ci-dessus) et [toolNames] (déjà résolues pour la carte
    // "MAÎTRISES D'OUTILS") couvrent déjà tout `skill_id`/`tool_id` qu'une
    // ligne `character_race_choices` peut porter (voir
    // `character_creation/data/character_creation_repository.dart
    // ::createCharacter`, qui écrit toujours la ligne
    // `character_skill_proficiencies`/`character_tool_proficiencies`
    // correspondante en même temps).
    final raceChoiceRows = CharacterDetailRowMapper.raceChoiceRowsOf(row);
    final raceSkillChoiceNames =
        CharacterDetailRowMapper.parseRaceSkillChoiceNames(
          raceChoiceRows,
          skillNames: skillNames,
        );
    final raceToolChoiceNames =
        CharacterDetailRowMapper.parseRaceToolChoiceNames(
          raceChoiceRows,
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
    // Absent des payloads mis en cache avant l'introduction de
    // `subclass_spells` : `_rowsOf(null)` retombe sur une liste vide, donc
    // aucun sort accordé (jamais de crash sur un ancien cache).
    final spellGrants = SubclassSpellGrantResolver.resolve(
      progress: CharacterDetailRowMapper.collectSubclassProgress(
        row,
        classNames: classNames,
      ),
      grants: CharacterDetailRowMapper.parseSubclassSpellGrants(
        _rowsOf(payload['subclassSpellRows']),
      ),
    );
    // Origine connue de chaque sort : priorité à une vraie ligne
    // `character_spells` (`parseSourceClassIds`, autoritaire — un sort
    // réellement choisi/préparé depuis une classe précise) ; repli, pour un
    // sort SANS ligne réelle (jamais encore préparé), sur la liste de classe
    // complète d'un lanceur à préparation (`parseClassListClassIds`, voir la
    // doc de [_fetchPreparedCasterClassListSpellRows]) — un ancien cache
    // sans `classListSpellClassRows` retombe sur une liste vide pour ce
    // repli, jamais de crash. Voir `CharacterSpellEntry.sourceClassIds`.
    final realSourceClassIds = CharacterSpellRowMapper.parseSourceClassIds(
      CharacterDetailRowMapper.characterSpellRowsOf(row),
    );
    final classListClassIds = CharacterSpellRowMapper.parseClassListClassIds(
      _rowsOf(payload['classListSpellClassRows']),
    );
    final sourceClassIds = <int, Set<int>>{...realSourceClassIds};
    for (final entry in classListClassIds.entries) {
      if (sourceClassIds[entry.key]?.isNotEmpty ?? false) continue;
      sourceClassIds[entry.key] = entry.value;
    }
    final spells = CharacterSpellRowMapper.toCharacterSpellEntries(
      _rowsOf(payload['spellRows']),
      grants: spellGrants,
      names: spellNames,
      descriptions: spellDescriptions,
      statuses: CharacterSpellRowMapper.parseStatuses(
        CharacterDetailRowMapper.characterSpellRowsOf(row),
      ),
      favorites: CharacterSpellRowMapper.parseFavorites(
        CharacterDetailRowMapper.characterSpellRowsOf(row),
      ),
      // `source_class_id` est absent d'un payload mis en cache avant sa
      // lecture : aucune origine connue, donc règle « origine inconnue »
      // (à préparer, sauf si toutes les classes lanceuses du personnage sont
      // à sorts connus), jamais de crash.
      classes: CharacterDetailRowMapper.parseClasses(
        row,
        classNames: classNames,
      ),
      sourceClassIds: sourceClassIds,
      // `innate_uses_spent` est absent d'un payload mis en cache avant sa
      // lecture : aucun usage dépensé connu, le sort inné est affiché
      // disponible (jamais de crash).
      innateUsesSpent: CharacterSpellRowMapper.parseInnateUsesSpent(
        CharacterDetailRowMapper.characterSpellRowsOf(row),
      ),
      // D43 du registre de dette technique (`docs/dette-technique.md`) :
      // un sort à la fois inné et connu/préparé garde sa route innée,
      // indépendamment du statut que [parseStatuses] retient ci-dessus —
      // voir `CharacterSpellRowMapper.parseInnateSpellIds`.
      innateSpellIds: CharacterSpellRowMapper.parseInnateSpellIds(
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

    final raceRow = payload['raceRow'] as Map<String, dynamic>?;
    final speed = (raceRow?['speed'] as num?)?.toInt();

    // Absente des payloads mis en cache avant l'arme de pacte : `null`.
    final pactWeaponItemRow = payload['pactWeaponItemRow'];
    final pactWeapon = pactWeaponItemRow is Map
        ? PactWeaponRowMapper.toOption(
            Map<String, dynamic>.from(pactWeaponItemRow),
            names: CharacterRowMapper.parseTranslatedNames(
              _rowsOf(payload['pactWeaponNameRows']),
            ),
          )
        : null;

    return CharacterDetailRowMapper.toCharacterDetail(
      row,
      speed: speed,
      raceNames: raceNames,
      subraceNames: subraceNames,
      classNames: classNames,
      backgroundNames: backgroundNames,
      alignmentNames: alignmentNames,
      subclassNames: subclassNames,
      skills: skills,
      classFeatures: classFeatures,
      classChoices: classChoices,
      raceSkillChoiceNames: raceSkillChoiceNames,
      raceToolChoiceNames: raceToolChoiceNames,
      toolProficiencyNames: toolProficiencyNames,
      knownLanguageNames: knownLanguageNames,
      spells: spells,
      spellSlots: CharacterDetailRowMapper.parseSpellSlots(row),
      knownInvocationNames: knownInvocationNames,
      featNames: featNames,
      inventory: inventory,
      adventures: adventures,
      pactWeapon: pactWeapon,
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
