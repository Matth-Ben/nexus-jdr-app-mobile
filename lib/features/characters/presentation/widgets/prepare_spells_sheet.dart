import 'package:flutter/material.dart';

import '../../../../core/rules/spell_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/checkable_option_tile.dart';
import '../../../../core/widgets/dice_type_badge.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/prepared_spells_limit.dart';
import '../../domain/spell_damage_dice_extractor.dart';
import '../../domain/spell_name_filter.dart';
import '../../domain/spell_status_formatter.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'character_spells_section.dart';
import 'spell_action_sheet.dart';
import 'spell_info_panel.dart';
import 'spell_preparation_card.dart';

/// Ouvre la sheet "Préparer mes sorts" — gabarit B du design système (même
/// patron que [showSpellInfoPanel]) : [SheetHeaderBar] + champ de recherche
/// + compteur + contenu scrollable, `FractionallySizedBox(heightFactor:
/// 0.9)`. Pas de pied fixe/bouton "Valider" : chaque case écrit
/// immédiatement, voir [ToggleSpellFlagCallback].
///
/// Proposée à la fin d'un repos long quand le joueur choisit de changer ses
/// sorts préparés (`rest_sheet.dart`, `character_detail_screen.dart
/// ::_applyRestFromSheet`) — demande utilisateur du 06/10/2026. Ancienne
/// sheet "Ajouter un sort" de l'onglet "Sorts", dont le bouton a été retiré
/// : l'onglet affiche désormais lui-même tous les sorts, préparés ou non.
///
/// [spells] est la liste complète déjà fournie par `CharacterDetail.spells`
/// (déjà fusionnée côté `CharacterRepository`
/// `_fetchPreparedCasterClassListSpellRows`) — aucune requête réseau
/// supplémentaire ici, uniquement du filtrage de présentation.
/// [classLimits] (`CharacterDetail.preparedSpellsByClass`) : liste vide
/// masque tout compteur ; gouverne aussi, depuis le chantier de blocage RAW
/// du 13/10/2026, quelles cases restent cochables (voir [_canCheck]) — le
/// blocage réel reste porté par l'écriture
/// (`CharacterRepository.setSpellPrepared`), cette sheet ne fait
/// qu'empêcher visuellement une action que le serveur rejetterait de toute
/// façon.
Future<void> showPrepareSpellsSheet(
  BuildContext context, {
  required List<CharacterSpellEntry> spells,
  required List<CharacterSpellSlot> spellSlots,
  CharacterSpellSlot? pactSlot,
  List<ClassPreparedSpells> classLimits = const [],
  required ToggleSpellFlagCallback onTogglePrepared,
  required CastSpellCallback onCastSpell,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PrepareSpellsSheetContent(
      spells: spells,
      spellSlots: spellSlots,
      pactSlot: pactSlot,
      classLimits: classLimits,
      onTogglePrepared: onTogglePrepared,
      onCastSpell: onCastSpell,
    ),
  );
}

class _PrepareSpellsSheetContent extends StatefulWidget {
  const _PrepareSpellsSheetContent({
    required this.spells,
    required this.spellSlots,
    this.pactSlot,
    this.classLimits = const [],
    required this.onTogglePrepared,
    required this.onCastSpell,
  });

  final List<CharacterSpellEntry> spells;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final List<ClassPreparedSpells> classLimits;
  final ToggleSpellFlagCallback onTogglePrepared;
  final CastSpellCallback onCastSpell;

  @override
  State<_PrepareSpellsSheetContent> createState() =>
      _PrepareSpellsSheetContentState();
}

class _PrepareSpellsSheetContentState
    extends State<_PrepareSpellsSheetContent> {
  final TextEditingController _searchController = TextEditingController();

  /// Identifiants des sorts actuellement cochés, dans cette sheet — état
  /// local tenu à jour à chaque tap (voir [_togglePrepared]), indépendamment
  /// de [widget.spells] (qui, lui, ne se rafraîchit qu'au prochain
  /// `CharacterDetail` reçu par l'appelant une fois la sheet refermée) :
  /// permet de cocher plusieurs sorts de suite sans que la sheet se ferme ni
  /// que son affichage reste figé sur l'état d'ouverture.
  late final Set<int> _preparedIds = {
    for (final spell in widget.spells)
      if (spell.status == SpellStatus.prepared) spell.id,
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  bool _isPrepared(CharacterSpellEntry spell) =>
      _preparedIds.contains(spell.id);

  /// Sorts proposés par la sheet : niveau >= 1, et soit réellement
  /// préparables ([SpellStatusFormatter.canTogglePrepared] : ni sort inné,
  /// ni sort d'une classe à sorts connus), soit accordés par une sous-classe
  /// (affichés cochés, non modifiables). Un sort inné n'est jamais listé :
  /// le cocher ferait passer sa ligne de 'inné' à 'préparé'.
  static bool _isListed(CharacterSpellEntry spell) =>
      spell.level > 0 &&
      (spell.isAlwaysPrepared || SpellStatusFormatter.canTogglePrepared(spell));

  /// Même décompte que `CharacterDetail.preparedSpellCount` (sorts mineurs,
  /// innés, accordés et sorts qui ne se préparent pas exclus), mais sur
  /// l'état local [_preparedIds] : le compteur suit chaque case cochée sans attendre le rafraîchissement de
  /// la fiche.
  int get _preparedCount => widget.spells
      .where(
        (spell) =>
            SpellStatusFormatter.canTogglePrepared(spell) && _isPrepared(spell),
      )
      .length;

  /// Même principe que [_preparedCount], restreint aux sorts cochés
  /// attribués à [classId] (voir [CharacterSpellEntry.sourceClassIds]) —
  /// seulement pertinent quand [widget.classLimits] compte 2+ classes (voir
  /// [_canCheck] : jamais utilisé dans le cas mono-classe, qui garde
  /// [_preparedCount] tel quel).
  int _preparedCountForClass(Object classId) => widget.spells
      .where(
        (spell) =>
            SpellStatusFormatter.canTogglePrepared(spell) &&
            _isPrepared(spell) &&
            spell.sourceClassIds
                .map((id) => id.toString())
                .contains(classId.toString()),
      )
      .length;

  /// `true` si [spell] peut être cochée dans cette sheet — toujours vrai
  /// pour dé-cocher (voir la doc de classe de [showPrepareSpellsSheet] :
  /// aucune limite ne s'applique à la baisse). Pour cocher un sort pas
  /// encore préparé, empêche visuellement de dépasser la limite de SA
  /// classe (demande de Matthias du 09/10/2026, précisée le 10/10) :
  /// - une seule classe qui prépare ([widget.classLimits] à un élément) :
  ///   même règle globale que le rendu mono-classe historique
  ///   ([_preparedCount] contre sa limite unique), sans tenir compte de
  ///   [CharacterSpellEntry.sourceClassIds] — aucune ambiguïté possible
  ///   avec une seule classe candidate.
  /// - plusieurs classes qui préparent : résout LA classe de [spell] via
  ///   [CharacterSpellEntry.sourceClassIds]. Une origine non ambiguë
  ///   (exactement une classe candidate parmi [widget.classLimits]) est
  ///   comparée à sa propre limite ([_preparedCountForClass]). Une origine
  ///   inconnue ou ambiguë (zéro ou 2+ candidats : donnée antérieure à ce
  ///   chantier, ou sort partagé par les listes complètes de deux classes
  ///   du personnage jamais encore préparé d'aucune des deux) reste
  ///   cochable ici — **fail-open**, l'écriture serveur
  ///   (`CharacterRepository.setSpellPrepared`) reste le filet de sécurité
  ///   final et affiche un message explicite si elle rejette malgré tout.
  bool _canCheck(CharacterSpellEntry spell) {
    if (_isPrepared(spell)) return true;
    if (widget.classLimits.isEmpty) return true;
    if (widget.classLimits.length == 1) {
      return _preparedCount < widget.classLimits.single.limit;
    }
    final candidates = [
      for (final classLimit in widget.classLimits)
        if (spell.sourceClassIds
            .map((id) => id.toString())
            .contains(classLimit.classId.toString()))
          classLimit,
    ];
    if (candidates.length != 1) return true;
    final target = candidates.single;
    return _preparedCountForClass(target.classId) < target.limit;
  }

  /// Reconstruit [spell] avec un [CharacterSpellEntry.status] à jour de
  /// [_preparedIds] — `character_detail_screen.dart::_toggleSpellPrepared`
  /// dérive la direction de la bascule (`prepared: spell.status != 'préparé'`)
  /// depuis ce champ : sans cette reconstruction, un second toggle du même
  /// sort dans une même ouverture de sheet transmettrait toujours le `status`
  /// figé de [widget.spells] (snapshot pris à l'ouverture), renvoyant deux
  /// fois la même direction au serveur au lieu d'alterner — régression
  /// trouvée en revue de code sur ce fichier. Les sorts accordés par une
  /// sous-classe ([CharacterSpellEntry.isAlwaysPrepared]) ne sont jamais
  /// reconstruits : leur statut ne bouge jamais, non togglable.
  CharacterSpellEntry _withCurrentStatus(CharacterSpellEntry spell) {
    if (spell.isAlwaysPrepared) return spell;
    // Jamais de réécriture du statut d'un sort sans préparation à faire
    // varier (sort inné notamment) : il ne doit pas ressortir 'connu'.
    if (!SpellStatusFormatter.canTogglePrepared(spell)) return spell;
    final status = _isPrepared(spell)
        ? SpellStatus.prepared
        : SpellStatus.known;
    if (spell.status == status) return spell;
    return CharacterSpellEntry(
      id: spell.id,
      name: spell.name,
      level: spell.level,
      school: spell.school,
      status: status,
      castingTime: spell.castingTime,
      range: spell.range,
      components: spell.components,
      duration: spell.duration,
      concentration: spell.concentration,
      description: spell.description,
      isFavorite: spell.isFavorite,
      grantSource: spell.grantSource,
      isPersisted: spell.isPersisted,
      storedStatus: spell.storedStatus,
      requiresPreparation: spell.requiresPreparation,
      innateUsesSpent: spell.innateUsesSpent,
      // Transmis explicitement (jamais ré-déduit de [status] ci-dessus,
      // toujours ordinaire ici) : un sort à double route (D43,
      // `docs/dette-technique.md`) listé dans cette sheet (préparable via sa
      // route de classe) garde sa route innée gratuite, indépendante — sans
      // ce champ explicite, le repli par défaut du constructeur de
      // [CharacterSpellEntry] l'aurait effacée de cette copie, affectant au
      // minimum le panneau "Infos" rouvert depuis cette sheet (voir
      // `_SpellCheckRow`).
      hasInnateRoute: spell.hasInnateRoute,
    );
  }

  /// Appelle [widget.onTogglePrepared] (écriture optimiste + réseau déléguée
  /// à l'appelant, voir `character_detail_screen.dart::_toggleSpellPrepared`)
  /// avec [spell] déjà corrigé par [_withCurrentStatus] (voir sa doc), ET met
  /// à jour [_preparedIds] — transmis tel quel au panneau "Infos"
  /// ([showSpellInfoPanel]) pour que basculer la préparation depuis ce
  /// panneau reste synchronisé avec les cases de cette sheet.
  void _togglePrepared(CharacterSpellEntry spell) {
    widget.onTogglePrepared(spell);
    setState(() {
      if (_preparedIds.contains(spell.id)) {
        _preparedIds.remove(spell.id);
      } else {
        _preparedIds.add(spell.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sorts mineurs exclus (voir la doc de la fonction) : jamais rien à
    // cocher d'utile pour eux (toujours visibles ailleurs, sans notion de
    // préparation). Même raison pour les sorts d'une classe à sorts connus
    // (`CharacterSpellEntry.requiresPreparation` faux, ex. sorts de Barde
    // d'un Barde/Clerc) : rien à préparer, ils restent dans l'onglet "Sorts".
    // Les sorts accordés par une sous-classe restent listés (cochés, figés).
    final candidates = SpellNameFilter.apply(
      spells: widget.spells,
      query: _searchController.text,
    ).where(_isListed).map(_withCurrentStatus).toList();
    final groups = SpellsByLevelGrouper.group(candidates);
    final slotsByLevel = {
      for (final slot in widget.spellSlots) slot.level: slot,
    };

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'PRÉPARER MES SORTS'),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _SpellSearchField(controller: _searchController),
              ),
              // Une seule classe qui prépare : rendu historique inchangé
              // (un seul compteur, décompte local [_preparedCount]).
              // Plusieurs classes : un compteur par classe, décompte local
              // par classe ([_preparedCountForClass]) — remplace l'ancien
              // masquage total, même principe que `SpellPreparationCard`.
              if (widget.classLimits.length == 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: PreparedSpellsCounter(
                    count: _preparedCount,
                    limit: widget.classLimits.single.limit,
                  ),
                )
              else if (widget.classLimits.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (final classLimit in widget.classLimits) ...[
                        PreparedSpellsCounter(
                          count: _preparedCountForClass(classLimit.classId),
                          limit: classLimit.limit,
                          label:
                              'SORTS PRÉPARÉS — '
                              '${classLimit.className.toUpperCase()}',
                        ),
                        if (classLimit != widget.classLimits.last)
                          const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: groups.isEmpty
                    ? _NoMatchState(query: _searchController.text.trim())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        children: [
                          for (var i = 0; i < groups.length; i++) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.md),
                            _SheetSpellLevelGroup(
                              group: groups[i],
                              slot: slotsByLevel[groups[i].level],
                              spellSlots: widget.spellSlots,
                              pactSlot: widget.pactSlot,
                              isPrepared: _isPrepared,
                              canCheck: _canCheck,
                              onTogglePrepared: _togglePrepared,
                              onCastSpell: widget.onCastSpell,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champ "Rechercher un sort" — même style que
/// `character_spells_tab_body.dart::_SpellSearchField` (composant privé à ce
/// fichier, non partagé : même précédent que `SpellRowMapper`/`ToolRowMapper`
/// dupliqués plutôt que couplés entre deux écrans).
class _SpellSearchField extends StatelessWidget {
  const _SpellSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTypography.body(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Rechercher un sort',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: controller.clear,
              ),
      ),
    );
  }
}

/// Aucun sort de niveau >= 1 ne correspond à la recherche en cours (ou la
/// fiche n'en a aucun du tout, garde défensive) — même gabarit minimal que
/// `character_spells_tab_body.dart::_NoMatchState`.
class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              query.isEmpty
                  ? 'Aucun sort disponible.'
                  : 'Aucun sort pour « $query ».',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un groupe de niveau de la sheet — même en-tête que
/// `character_spells_section.dart::_SpellLevelGroupSection` (libellé "Niveau
/// N" + [SpellSlotDots] si des emplacements existent pour ce niveau).
class _SheetSpellLevelGroup extends StatelessWidget {
  const _SheetSpellLevelGroup({
    required this.group,
    required this.slot,
    required this.spellSlots,
    this.pactSlot,
    required this.isPrepared,
    required this.canCheck,
    required this.onTogglePrepared,
    required this.onCastSpell,
  });

  final SpellLevelGroup group;
  final CharacterSpellSlot? slot;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final bool Function(CharacterSpellEntry spell) isPrepared;

  /// Voir `_PrepareSpellsSheetContentState._canCheck` : `false` désactive la
  /// case d'un sort PAS encore préparé qui ferait dépasser la limite de SA
  /// classe (sans effet sur un sort déjà préparé, toujours dé-cochable).
  final bool Function(CharacterSpellEntry spell) canCheck;
  final ToggleSpellFlagCallback onTogglePrepared;
  final CastSpellCallback onCastSpell;

  @override
  Widget build(BuildContext context) {
    final showPips = slot != null && slot!.total > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              group.label,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showPips) ...[
              const SizedBox(width: AppSpacing.xs),
              SpellSlotDots(slot: slot!),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final spell in group.spells)
          _SpellCheckRow(
            spell: spell,
            checked: spell.isAlwaysPrepared || isPrepared(spell),
            canCheck: canCheck(spell),
            spellSlots: spellSlots,
            pactSlot: pactSlot,
            togglePrepared: onTogglePrepared,
            onCastSpell: onCastSpell,
          ),
      ],
    );
  }
}

/// Une ligne de sort de la sheet : [CheckableOptionTile] + bouton ⓘ séparé
/// ouvrant [showSpellInfoPanel] — même gabarit exact que
/// `character_creation/presentation/spells_step_screen.dart::_spellTile`.
class _SpellCheckRow extends StatelessWidget {
  const _SpellCheckRow({
    required this.spell,
    required this.checked,
    required this.canCheck,
    required this.spellSlots,
    this.pactSlot,
    required this.togglePrepared,
    required this.onCastSpell,
  });

  final CharacterSpellEntry spell;
  final bool checked;

  /// Voir `_PrepareSpellsSheetContentState._canCheck` — sans effet si
  /// [checked] est déjà vrai (toujours dé-cochable, voir [enabled]
  /// ci-dessous).
  final bool canCheck;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final ToggleSpellFlagCallback togglePrepared;
  final CastSpellCallback onCastSpell;

  @override
  Widget build(BuildContext context) {
    // Un sort accordé par une sous-classe est toujours préparé, jamais
    // retirable — voir `CharacterSpellEntry.isAlwaysPrepared` et
    // `SpellStatusFormatter.canTogglePrepared`.
    final grantedBySubclass = spell.isAlwaysPrepared;
    // Limite de sorts préparés atteinte pour la classe de ce sort (voir
    // `_canCheck`) : case estompée et non cochable, MÊME rendu que l'étape
    // 6/9 "Sorts" de l'assistant de création pour un quota déjà atteint
    // (`spells_step_screen.dart`) — jamais pour un sort déjà coché, qui
    // reste toujours dé-cochable.
    final enabled = !grantedBySubclass && (checked || canCheck);
    final dice = SpellDamageDiceExtractor.extract(spell.description);

    final tile = CheckableOptionTile(
      title: spell.name,
      subtitle: SpellStatusFormatter.subtitle(spell),
      checked: checked,
      enabled: enabled,
      onTap: enabled ? () => togglePrepared(spell) : null,
      titleTrailing: dice == null
          ? null
          : DiceTypeBadge(
              sides: dice.sides,
              label: '${dice.count}d${dice.sides}',
            ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: tile),
          IconButton(
            tooltip: 'Description de ${spell.name}',
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => showSpellInfoPanel(
              context,
              spell: spell,
              spellSlots: spellSlots,
              pactSlot: pactSlot,
              onCastSpell: onCastSpell,
              onTogglePrepared: togglePrepared,
            ),
          ),
        ],
      ),
    );
  }
}
