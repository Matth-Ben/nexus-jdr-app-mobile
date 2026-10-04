import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/checkable_option_tile.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/spell_name_filter.dart';
import '../../domain/spell_status_formatter.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'character_spells_section.dart';
import 'spell_action_sheet.dart';
import 'spell_info_panel.dart';

/// Ouvre la sheet "Ajouter un sort" de l'onglet "Sorts" — gabarit B du design
/// système (même patron que [showSpellInfoPanel]) : [SheetHeaderBar] + champ
/// de recherche + contenu scrollable, `FractionallySizedBox(heightFactor:
/// 0.9)`. Pas de pied fixe/bouton "Valider" : chaque case écrit
/// immédiatement, voir [ToggleSpellFlagCallback].
///
/// Seul point d'entrée pour préparer un sort absent de la vue par défaut de
/// l'onglet "Sorts" (`character_spells_tab_body.dart`), qui ne montre que les
/// sorts déjà préparés pour les classes à préparation « liste complète »
/// (Clerc/Druide/Paladin, voir `domain/prepared_caster_spell_list.dart
/// ::PreparedCasterSpellList`) — voir `SpellStatusFormatter
/// .isVisibleInPreparedView`.
///
/// [spells] est la liste complète déjà fournie par `CharacterDetail.spells`
/// (déjà fusionnée côté `CharacterRepository`
/// `_fetchPreparedCasterClassListSpellIds`) — aucune requête réseau
/// supplémentaire ici, uniquement du filtrage de présentation.
Future<void> showAddPreparedSpellsSheet(
  BuildContext context, {
  required List<CharacterSpellEntry> spells,
  required List<CharacterSpellSlot> spellSlots,
  CharacterSpellSlot? pactSlot,
  required ToggleSpellFlagCallback onTogglePrepared,
  required CastSpellCallback onCastSpell,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AddPreparedSpellsSheetContent(
      spells: spells,
      spellSlots: spellSlots,
      pactSlot: pactSlot,
      onTogglePrepared: onTogglePrepared,
      onCastSpell: onCastSpell,
    ),
  );
}

class _AddPreparedSpellsSheetContent extends StatefulWidget {
  const _AddPreparedSpellsSheetContent({
    required this.spells,
    required this.spellSlots,
    this.pactSlot,
    required this.onTogglePrepared,
    required this.onCastSpell,
  });

  final List<CharacterSpellEntry> spells;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final ToggleSpellFlagCallback onTogglePrepared;
  final CastSpellCallback onCastSpell;

  @override
  State<_AddPreparedSpellsSheetContent> createState() =>
      _AddPreparedSpellsSheetContentState();
}

class _AddPreparedSpellsSheetContentState
    extends State<_AddPreparedSpellsSheetContent> {
  final TextEditingController _searchController = TextEditingController();

  /// Identifiants des sorts actuellement cochés, dans cette sheet — état
  /// local tenu à jour à chaque tap (voir [_togglePrepared]), indépendamment
  /// de [widget.spells] (qui, lui, ne se rafraîchit qu'au prochain
  /// `CharacterDetail` reçu par l'appelant une fois la sheet refermée) :
  /// permet de cocher plusieurs sorts de suite sans que la sheet se ferme ni
  /// que son affichage reste figé sur l'état d'ouverture.
  late final Set<int> _preparedIds = {
    for (final spell in widget.spells)
      if (spell.status == 'préparé') spell.id,
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
    final status = _isPrepared(spell) ? 'préparé' : 'connu';
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
    // préparation).
    final candidates = SpellNameFilter.apply(
      spells: widget.spells,
      query: _searchController.text,
    ).where((spell) => spell.level > 0).map(_withCurrentStatus).toList();
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
              const SheetHeaderBar(title: 'AJOUTER UN SORT'),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _SpellSearchField(controller: _searchController),
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
/// `character_spells_tab_body.dart::_NoSearchMatchState`.
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
    required this.onTogglePrepared,
    required this.onCastSpell,
  });

  final SpellLevelGroup group;
  final CharacterSpellSlot? slot;
  final List<CharacterSpellSlot> spellSlots;
  final CharacterSpellSlot? pactSlot;
  final bool Function(CharacterSpellEntry spell) isPrepared;
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
    required this.spellSlots,
    this.pactSlot,
    required this.togglePrepared,
    required this.onCastSpell,
  });

  final CharacterSpellEntry spell;
  final bool checked;
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

    final tile = CheckableOptionTile(
      title: spell.name,
      subtitle: SpellStatusFormatter.subtitle(spell),
      checked: checked,
      enabled: !grantedBySubclass,
      onTap: grantedBySubclass ? null : () => togglePrepared(spell),
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
